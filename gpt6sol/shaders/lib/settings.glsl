#ifndef LOOMLIGHT_SETTINGS
#define LOOMLIGHT_SETTINGS

#define SHADOWS // Soft shadows
#define SHADOW_SAMPLES 9 // [4 9]
#define CLOUDS // Painted clouds
#define CLOUD_DENSITY 0.48 // [0.28 0.48 0.68]
#define FOG_DENSITY 1.0 // [0.5 1.0 1.5]
#define BLOOM_STRENGTH 0.18 // [0.0 0.1 0.18 0.3]
#define OUTLINE_STRENGTH 0.14 // [0.0 0.14 0.28]
#define WIND_STRENGTH 0.65 // [0.0 0.35 0.65 1.0]
#define SATURATION 1.0 // [0.85 1.0 1.15]

const int shadowMapResolution = 2048; // [1024 2048 4096]
const float shadowDistance = 112.0; // [64.0 112.0 160.0]

#endif

