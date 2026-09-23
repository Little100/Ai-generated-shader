#ifndef KOMOREBI_SETTINGS
#define KOMOREBI_SETTINGS

// 所有选项集中在此文件, 每个程序都通过 common.glsl 引用, 保证宏定义完全一致

// 光照
#define DAPPLED_LIGHT 1 // [0 1] 树叶光斑
const float dappleScale = 1.0; // [0.0 0.5 1.0 1.5 2.0 3.0] 光斑尺寸
const float dappleDepth = 0.55; // [0.0 0.25 0.55 0.8 1.0] 光斑强度
const float shadowSoftness = 1.0; // [0.0 0.5 1.0 1.75 2.5] 阴影柔度
const float shadowDistance = 160.0; // [96.0 128.0 160.0 224.0 320.0] 阴影距离
#define CLOUD_SHADOW 1 // 云影

// 环境
#define SSAO 1 // 屏幕空间遮蔽
const float aoStrength = 1.0; // [0.0 0.5 1.0 1.5 2.0] 遮蔽强度
const float aoRadius = 1.25; // [0.5 0.75 1.25 2.0 3.0] 遮蔽半径
#define SP_SKY 1 // 程序化天空
#define SP_CLOUDS 1 // 体积云
const float cloudCoverage = 0.52; // [0.2 0.35 0.52 0.68 0.85] 云量
const float cloudAltitude = 320.0; // [180.0 240.0 320.0 420.0 560.0] 云高度
const float cloudThickness = 90.0; // [40.0 60.0 90.0 140.0 220.0] 云厚度

// 水
#define WATER_WAVES 1 // 水面波动
const float waveHeight = 1.0; // [0.0 0.5 1.0 1.5 2.5] 波高
#define WATER_REFLECTION 1 // 水面反射
const float fresnelBias = 0.35; // [0.0 0.15 0.35 0.6 0.9] 水面反射率
const float causticsStrength = 1.0; // [0.0 0.4 1.0 1.8 3.0] 焦散强度
const float wetHighlight = 0.6; // [0.0 0.3 0.6 1.0] 雨后湿润

// 大气
#define VOLUMETRIC_FOG 1 // 体积雾
const float fogDensity = 0.7; // [0.2 0.45 0.7 1.1 1.6] 雾浓度
const float fogHeightFalloff = 0.35; // [0.1 0.2 0.35 0.6 1.0] 雾沉降
#define GOD_RAYS 1 // 体积光柱
const float godrayStrength = 1.0; // [0.0 0.5 1.0 1.75 2.5] 光柱强度

// 后期
#define BLOOM 1 // 泛光
const float bloomStrength = 0.42; // [0.0 0.15 0.42 0.8 1.4] 泛光强度
const float exposure = 1.0; // [0.5 0.75 1.0 1.35 1.8] 曝光
const float colSat = 1.06; // [0.6 0.8 1.06 1.25 1.5] 饱和度
#define TONEMAP_ACES 1 // ACES 色调映射

// 性能
const int shadowMapResolution = 2048; // [1024 1536 2048 3072 4096] 阴影分辨率
#define shadowSamples 12 // [4 8 12 20 32] 阴影采样数
#define godraySteps 24 // [8 16 24 40 64] 体积光步数
#define cloudSteps 24 // [12 18 24 36 56] 云步数

// 兼容
#define NETHER_SHADING 0 // [0 1] 下界着色
#define END_SHADING 1 // [0 1] 末地着色

#endif
