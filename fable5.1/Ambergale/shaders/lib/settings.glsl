#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL

// Shadow pipeline constants read by Iris
const int shadowMapResolution = 2048; // [1024 2048 3072 4096]
const float shadowDistance = 160.0; // [96.0 128.0 160.0 192.0 256.0]
const float shadowDistanceRenderMul = 1.0;
const float shadowIntervalSize = 2.0;
const float sunPathRotation = -35.0; // [-60.0 -50.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 20.0 30.0 40.0]
const bool shadowHardwareFiltering = false;

// Smoothing half-lives for weather and eye adaptation uniforms
const float wetnessHalfLife = 250.0;
const float drynessHalfLife = 40.0;
const float eyeBrightnessHalfLife = 6.0;
const float ambientOcclusionLevel = 1.0;

// Lighting
#define SUN_INTENSITY 1.0 // [0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.6]
#define SKY_AMBIENT 1.0 // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define BLOCKLIGHT_INTENSITY 1.0 // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.75 2.0]
#define BLOCKLIGHT_WARMTH 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define EMBER_FLICKER
#define HAND_LIGHT
#define WIND_STRENGTH 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]

// Shadows
#define SHADOW_QUALITY 1 // [0 1 2]
#define SHADOW_SOFTNESS 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0 2.5]

// Atmosphere
#define CLOUDS
#define CLOUD_COVERAGE 0.45 // [0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7]
#define STARS
#define GODRAYS
#define GODRAYS_STRENGTH 0.6 // [0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.25 1.5]
#define FOG_DENSITY 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.5 3.0]

// Water
#define WATER_WAVE_HEIGHT 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define WATER_REFRACTION
#define WATER_CLARITY 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0 3.0]

// Post processing
#define BLOOM
#define BLOOM_STRENGTH 0.35 // [0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.5 0.6 0.8 1.0]
#define EXPOSURE 1.0 // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.75 2.0]
#define CONTRAST 1.0 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5]
#define SATURATION 1.05 // [0.0 0.25 0.5 0.75 0.9 1.0 1.05 1.1 1.15 1.2 1.3 1.5]
#define VIGNETTE
#define FILM_GRAIN
#define GRAIN_STRENGTH 0.03 // [0.01 0.02 0.03 0.04 0.05 0.07 0.1]

#endif
