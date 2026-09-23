#ifndef KOMOREBI_BUFFERS
#define KOMOREBI_BUFFERS

// 通道格式只声明一次, 由 common.glsl 引入到每个程序
// colortex0 场景颜色, 需要高动态范围承载太阳与泛光
const int colortex0Format = RGBA16F;
// colortex1 法线加材质号, 需要带符号精度
const int colortex1Format = RGBA16;
// colortex2 光照贴图与自发光
const int colortex2Format = RGBA16;
// colortex3 材质参数与水面厚度提示
const int colortex3Format = RGBA16;
// colortex4 辅助通道, 天光, 遮蔽, 材质号, 树叶透光
const int colortex4Format = RGBA16;
// colortex5 前段存放云的散射与不透明度, 后段用作泛光金字塔
const int colortex5Format = RGBA16F;
// colortex6 泛光结果
const int colortex6Format = RGBA16F;
// colortex7 反照率, 只存线性色
const int colortex7Format = RGBA16;

const bool colortex1Clear = true;
const bool colortex2Clear = true;
const bool colortex3Clear = true;
const bool colortex4Clear = true;
const bool colortex5Clear = true;
const bool colortex6Clear = true;
const bool colortex7Clear = true;

const vec4 colortex1ClearColor = vec4(0.5, 0.5, 0.0, 0.0);
const vec4 colortex2ClearColor = vec4(0.0, 1.0, 0.0, 0.0);
const vec4 colortex3ClearColor = vec4(1.0, 0.0, 0.5, 0.0);
const vec4 colortex4ClearColor = vec4(1.0, 1.0, 0.0, 0.0);
const vec4 colortex5ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex6ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const vec4 colortex7ClearColor = vec4(0.5, 0.5, 0.5, 1.0);

#endif
