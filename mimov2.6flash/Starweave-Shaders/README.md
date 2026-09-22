# Starweave Shaders 星织光影

完全从零设计的 Iris 光影包, 未读取或借鉴任何现有光影的代码与效果实现, 全部效果基于独立想象与 Iris 官方 API 文档完成。

目标版本: Minecraft 1.21.11 (或任意 Iris 支持的 1.21.x), 加载器仅需 Iris (含 Sodium)。

## 安装

将整个 `Starweave-Shaders` 文件夹放入 `.minecraft/shaderpacks/`, 启动 Iris 后在视频设置的光影选项中选择 `Starweave Shaders`。

也可把该文件夹压缩为 zip 放入 shaderpacks, 效果相同。

## 设计理念

星织的主线是把天空当作织物: 星光、极光、云影、体积光束都是同一套程序化天空的经线, 地面光照从中纬出。

主世界包含程序化渐变天穹、太阳月亮圆盘、星空闪烁、夜晚极光光幕、分形云层与实时云影、阴影贴图 PCF 软阴影、阴影贴图体积光束、屏幕空间环境光遮蔽、湿润表面的天空反射、水面波浪折射与菲涅尔反射、岸边泡沫、水下光焦散、植被风场摇曳、暖色方块光斜坡、闪电瞬间补光、辉光、ACES 色调映射、轻量抗锯齿与暗角。

下界为暗红穹顶加飘散火星与浓重红雾, 终界为紫色虚空星尘与传送门闪光补光, 均由维度文件夹独立覆盖。

## 设置入口

游戏内光影设置界面提供四个档位预设 (低中高极高) 与逐项开关, 包括阴影分辨率、体积光步数、辉光强度、曝光等滑条。

## 材质约定

本光影读取标准 specular 材质贴图通道: 红色平滑度, 绿色金属度, 蓝色自发光强度。无 PBR 贴图的材质包走 `block.properties` 的分类兜底。

## 方块 ID 分配

`shaders/block.properties` 中 10000 段为发光方块, 10100 段为摇曳植物, 10200 段为水与光滑面。新增方块按段追加即可, 各段含义见文件头注释。

## 结构与维护

`shaders/lib/` 存放全部公共算法: `common` 数学与坐标重建, `lighting` 光照斜坡与高光, `sky` 程序化天空, `shadow` 阴影扭曲与体积光, `wave` 风场与水波, `deferred_core` 延迟光照主流程, `water_core` 水面主流程, `final_core` 后期主流程。维度差异通过 `DIM_NETHER` 与 `DIM_END` 宏在同一套核心里分支。

着色器统一使用 `#version 140`, 因为 `ftransform`、`gl_MultiTexCoord0`、`gl_TextureMatrix`、`gl_FragData` 这类兼容档内置在 140 之后被移除, 更高版本 (如 150 不带 compatibility 档) 会在部分驱动上报 C7616 错误。顶点变换一律写显式矩阵 `gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex`, 不使用 `ftransform()`, 避免 Iris 的 lines 程序补丁链把它抬到高版本后再次触发 C7616。

缓冲格式指令必须放在块注释中 (`/* const int colortex0Format = RGBA16F; */`): 既让 GLSL 编译器忽略非 GLSL 标识符, 又让 Iris 按行文本解析到格式名, 桩宏方案会被 Iris 展开成整数导致 Unrecognized 警告并丢失 HDR。

`shaders.properties` 与 `block.properties` 必须保持纯 ASCII 注释, Iris 的属性预处理器遇到中文等非 ASCII 字节会在 `#` 注释行上报 Bad token 并导致方块 ID 映射加载失败 (摇曳与自发光分类全部失效), 中文文案一律放 `lang` 与本 README。

若出现全图雾效或阴影整体错乱, 尝试把 `settings.glsl` 中的 `RAW_SPACE_IS_ABSOLUTE` 改为 0, 该开关控制深度重建坐标的原点约定, 是整包唯一需要成对对齐的空间假设。

缓冲约定: colortex0 场景色, colortex1 法线与天空光, colortex2 材质与 AO, colortex3 折射用场景副本, colortex4 与 colortex5 辉光乒乓。

## 原创声明

效果实现、命名、参数与代码结构均为独立创作, 编写过程仅查询了 Iris 与 OptiFine 的公开 API 文档, 未打开、复制或翻译任何现有光影包的源码。

## 开发校验

仓库根目录的 `validate.py` 做结构校验(包含路径、括号配对、重复 uniform、vsh/fsh varying 对齐、DRAWBUFFERS 一致性), `compile_check.py` 展开全部 include 后用 glslang 逐文件编译, 两者对任意改动跑一遍即可确认语法层面完好。
