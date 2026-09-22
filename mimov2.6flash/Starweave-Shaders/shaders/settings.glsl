#ifndef STARWEAVE_SETTINGS
#define STARWEAVE_SETTINGS

// HDR 缓冲格式指令放在块注释里: GLSL 编译器忽略它, Iris 从行文本解析格式名
/* const int colortex0Format = RGBA16F; */
/* const int colortex3Format = RGBA16F; */
/* const int colortex4Format = RGBA16F; */
/* const int colortex5Format = RGBA16F; */

#define SHADOWS
#define SHADOW_RES 2048 // [1024 2048 4096]
#define SSAO
#define VOLUMETRICS
#define VOLUMETRIC_STEPS 16 // [8 12 16 24 32]
#define CLOUD_SHADOWS
#define BLOOM
#define BLOOM_STRENGTH 0.08 // [0.04 0.08 0.14 0.22]
#define EXPOSURE 1.0 // [0.7 0.85 1.0 1.25 1.5]
#define WAVING
#define WATER_WAVES
#define AURORA
#define FXAA
#define VIGNETTE

// 深度重建得到的坐标是否为绝对世界坐标, 若出现全图雾效或阴影错乱可改为 0
#define RAW_SPACE_IS_ABSOLUTE 1

const float sunPathRotation = -25.0;
const float shadowDistance = 128.0;
const int shadowMapResolution = SHADOW_RES;

#endif
