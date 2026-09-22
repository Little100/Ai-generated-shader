#ifndef KILN_SETTINGS
#define KILN_SETTINGS

#define K_QUALITY 2 // [0 1 2 3]
const int shadowMapResolution = 2048; // [1024 2048 4096]
const float shadowDistance = 160.0; // [96.0 128.0 160.0 192.0]
#define K_SUN_INTENSITY 1.0 // [0.6 0.8 1.0 1.2 1.5]
#define K_MOON_INTENSITY 1.0 // [0.5 0.8 1.0 1.3]
#define K_TORCH_INTENSITY 1.0 // [0.6 0.8 1.0 1.3 1.6]
#define K_EXPOSURE_BIAS 0.0 // [-1.0 -0.5 0.0 0.5 1.0]
#define K_SATURATION 1.0 // [0.8 0.9 1.0 1.1 1.2]
#define K_VIGNETTE 1.0 // [0.0 0.5 1.0 1.4]
#define K_BLOOM 1.0 // [0.0 0.5 1.0 1.5]
#define K_VOLUMETRIC 1.0 // [0.0 0.6 1.0 1.4]
#define K_SSGI 1.0 // [0.0 0.5 1.0 1.5]
#define K_SSR 1.0 // [0.0 0.6 1.0]
#define K_AO 1.0 // [0.0 0.6 1.0 1.4]
#define K_WATER_WAVES 1.0 // [0.0 0.6 1.0 1.4]
#define K_CLOUD 1.0 // [0.0 0.7 1.0 1.3]
#define K_GRADE 1 // [0 1 2]
#define K_TA 1 // [0 1]

const float ambientOcclusionLevel = 1.0;

#endif
