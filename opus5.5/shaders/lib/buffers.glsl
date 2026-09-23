// 缓冲区元数据, Iris 会从块注释里读取这些声明, 而 GLSL 编译器把它们当注释跳过
// 格式名 RGBA16F 等不是 GLSL 内建标识符, 必须包在块注释里否则驱动会报未定义变量
// 每条声明独占一行且行内不能有其它文字, 否则 Iris 的探测会失败

// colortex0 场景颜色, 需要高动态范围承载太阳与泛光
/* const int colortex0Format = RGBA16F; */
// colortex1 法线(八面体) + 遮蔽偏置 + 材质槽
/* const int colortex1Format = RGBA16; */
// colortex2 光照贴图 + 自发光 + 不透明度
/* const int colortex2Format = RGBA16; */
// colortex3 粗糙度 + 金属度 + 朝向 + 透光
/* const int colortex3Format = RGBA16; */
// colortex4 辅助通道, 天光, 遮蔽, 材质槽, 透光
/* const int colortex4Format = RGBA16; */
// colortex5 体积光的光柱强度
/* const int colortex5Format = RGBA16F; */
// colortex6 泛光, 以半分辨率渲染
/* const int colortex6Format = RGBA16F; */
// colortex7 反照率, 只存线性色
/* const int colortex7Format = RGBA16; */

/* const bool colortex1Clear = true; */
/* const bool colortex2Clear = true; */
/* const bool colortex3Clear = true; */
/* const bool colortex4Clear = true; */
/* const bool colortex5Clear = true; */
/* const bool colortex6Clear = true; */
/* const bool colortex7Clear = true; */

/* const vec4 colortex1ClearColor = vec4(0.5, 0.5, 0.0, 0.0); */
/* const vec4 colortex2ClearColor = vec4(0.0, 1.0, 0.0, 0.0); */
/* const vec4 colortex3ClearColor = vec4(1.0, 0.0, 0.5, 0.0); */
/* const vec4 colortex4ClearColor = vec4(1.0, 1.0, 0.0, 0.0); */
/* const vec4 colortex5ClearColor = vec4(0.0, 0.0, 0.0, 0.0); */
/* const vec4 colortex6ClearColor = vec4(0.0, 0.0, 0.0, 1.0); */
/* const vec4 colortex7ClearColor = vec4(0.5, 0.5, 0.5, 1.0); */
