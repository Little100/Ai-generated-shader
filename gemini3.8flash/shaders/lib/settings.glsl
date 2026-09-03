#ifndef AETHERIA_SETTINGS_GLSL
#define AETHERIA_SETTINGS_GLSL

// ==============================================================================
// Aetheria: Celestial Dreams - Global Settings & Configuration Constants
// ==============================================================================

// Lighting & Shadows
#define SHADOW_QUALITY 3            // [0 1 2 3 4] 0:Off, 1:Low, 2:Medium, 3:High, 4:Ultra
#define SHADOW_SAMPLES 8            // [4 8 16] Soft shadow PCF sample count
#define TORCH_FLICKER               // Dynamic subtle organic torch flicker
#define SUBSURFACE_SCATTERING       // Leaf and foliage backlit glow
#define AMBIENT_BRIGHTNESS 1.0      // [0.5 0.75 1.0 1.25 1.5 2.0]

// Atmosphere & Sky
#define ATMOSPHERIC_FOG             // Height-based atmospheric fog
#define CELESTIAL_NEBULA            // Glowing celestial cosmic ribbon at night
#define VIBRANT_SUNSET              // Rich amber/rose sunset scattering
#define TWINKLING_STARS             // Procedural stellar scintillation
#define FOG_DENSITY 1.0             // [0.3 0.5 0.75 1.0 1.25 1.5 2.0]

// Water Dynamics & Optics
#define WATER_WAVES                 // Procedural Gerstner wave displacement
#define WATER_CAUSTICS              // Dynamic underwater sunlight ripples
#define WATER_CLARITY 1             // [0 1 2] 0:Clear, 1:Oceanic, 2:Tropical
#define WATER_REFLECTIONS           // Screen-space celestial reflection

// Wind & Flora Motion
#define WAVING_GRASS                // Waving flowers and tall grass
#define WAVING_LEAVES               // Swaying foliage and tree canopies
#define WIND_SPEED 2                // [1 2 3] 1:Gentle, 2:Normal, 3:Breezy
#define WIND_STRENGTH 2             // [1 2 3] 1:Subtle, 2:Moderate, 3:Vivid

// Post-Processing & Cinematic Optics
#define BLOOM_QUALITY 2             // [0 1 2 3] 0:Off, 1:Subtle, 2:Dreamy, 3:Cinematic
#define TONE_MAPPING 0              // [0 1 2] 0:ACES Filmic, 1:Reinhard, 2:Vibrant Fantasy
#define VIGNETTE                    // Lens edge darkening
#define CHROMATIC_ABERRATION        // Subtle screen-edge prism dispersion
#define SATURATION 1.05             // [0.8 0.9 1.0 1.05 1.1 1.2]

#endif // AETHERIA_SETTINGS_GLSL
