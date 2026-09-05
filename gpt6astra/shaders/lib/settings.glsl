#ifndef TIDELUME_SETTINGS
#define TIDELUME_SETTINGS
// Tidelume: all visual code authored from an empty workspace.
#define SHADOWS // Directional terrain and entity shadows.
const int shadowMapResolution = 2048; // [1024 2048 3072 4096]
const float shadowDistance = 128.0; // [64.0 96.0 128.0 160.0 192.0]
#define SHADOW_SAMPLES 12 // [4 8 12 20]
#define SHADOW_SOFTNESS 1.4 // [0.7 1.0 1.4 1.8 2.4]
#define COLORED_SHADOWS // Tinted transmission through stained glass.
#define AMBIENT_OCCLUSION // Short-range screen-space contact shading.
#define AO_STRENGTH 0.65 // [0.0 0.35 0.5 0.65 0.8 1.0]
#define SUN_BRIGHTNESS 1.0 // [0.6 0.8 1.0 1.2 1.4]
#define NIGHT_BRIGHTNESS 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0]
#define BLOCKLIGHT_BRIGHTNESS 1.0 // [0.6 0.8 1.0 1.2 1.5]
#define HAND_LIGHT // Main/offhand non-shadowed local light.
#define CLOUDS // Procedural layered clouds, not a texture asset.
#define CLOUD_STEPS 8 // [4 6 8 12]
#define CLOUD_COVERAGE 0.52 // [0.3 0.4 0.52 0.65 0.75]
#define CLOUD_HEIGHT 208.0 // [160.0 192.0 208.0 240.0 288.0]
#define VOLUMETRIC_LIGHT // Half-resolution shadow-map light integration.
#define VOLUMETRIC_STEPS 12 // [6 8 12 18]
#define FOG_DENSITY 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0]
#define STARS // Procedural star field.
#define END_HALO // Original elliptical ribbons in the End sky.
#define WATER_REFLECTIONS // Screen-space reflection, analytic sky fallback.
#define SSR_STEPS 20 // [10 16 20 28]
#define WATER_WAVE_STRENGTH 1.0 // [0.0 0.5 0.75 1.0 1.25 1.5]
#define WATER_CLARITY 1.0 // [0.5 0.75 1.0 1.5 2.0]
#define WATER_REFRACTION 1.0 // [0.0 0.5 1.0 1.5]
#define WIND // Root-anchored plants and gentle leaves.
#define WIND_STRENGTH 1.0 // [0.0 0.5 0.75 1.0 1.5]
#define WET_SURFACES // Procedural rain sheen on exposed upward faces.
#define BLOOM // Half-resolution separable highlight diffusion.
#define BLOOM_STRENGTH 0.14 // [0.0 0.06 0.1 0.14 0.2 0.3]
#define EXPOSURE 1.0 // [0.65 0.8 1.0 1.15 1.3 1.5]
#define SATURATION 1.04 // [0.8 0.9 1.0 1.04 1.1 1.2]
#define EDGE_AA // Single-frame edge-aware antialiasing; no history ghosting.
#define VIGNETTE_STRENGTH 0.12 // [0.0 0.06 0.12 0.2 0.3]
const float sunPathRotation = -24.0;
const float shadowIntervalSize = 2.0;
const float ambientOcclusionLevel = 0.85;
const float wetnessHalflife = 75.0;
const float drynessHalflife = 160.0;
const float eyeBrightnessHalflife = 5.0;
const bool shadowHardwareFiltering = false;
#endif
