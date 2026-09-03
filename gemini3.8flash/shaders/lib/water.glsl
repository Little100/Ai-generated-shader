#ifndef AETHERIA_WATER_GLSL
#define AETHERIA_WATER_GLSL

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

// ==============================================================================
// Aetheria: Gerstner Waves, Optical Absorption (Beer-Lambert), and Caustics
// ==============================================================================

// Gerstner Wave Component Structure
struct Wave {
    vec2 dir;
    float amplitude;
    float frequency;
    float speed;
};

// Procedural water wave height evaluation
float evaluateWaterHeight(vec2 pos, float time) {
#ifndef WATER_WAVES
    return 0.0;
#else
    float h = 0.0;
    // Harmonic wave parameters
    h += sin(pos.x * 0.85 + pos.y * 0.45 + time * 1.8) * 0.065;
    h += cos(pos.x * 0.42 - pos.y * 0.95 + time * 2.2) * 0.045;
    h += sin(pos.x * 1.60 + pos.y * 1.20 - time * 3.1) * 0.025;
    return h;
#endif
}

// Procedural water normal generation via central finite difference
vec3 calculateWaterNormal(vec2 worldXZ, float time) {
    float eps = 0.08;
    float hL = evaluateWaterHeight(worldXZ - vec2(eps, 0.0), time);
    float hR = evaluateWaterHeight(worldXZ + vec2(eps, 0.0), time);
    float hD = evaluateWaterHeight(worldXZ - vec2(0.0, eps), time);
    float hU = evaluateWaterHeight(worldXZ + vec2(0.0, eps), time);

    vec3 normal = normalize(vec3(hL - hR, eps * 2.0, hD - hU));
    return normal;
}

// Beer-Lambert Optical Absorption Vector
vec3 getWaterExtinctionCoefficient() {
#if WATER_CLARITY == 0
    // Crystal Clear: Minimal red/green absorption
    return vec3(0.12, 0.05, 0.02);
#elif WATER_CLARITY == 2
    // Tropical Turquoise: Absorbs red heavily, keeps cyan/teal
    return vec3(0.35, 0.06, 0.08);
#else
    // Oceanic Sapphire: Natural deep blue absorption
    return vec3(0.26, 0.10, 0.035);
#endif
}

// Apply Beer-Lambert law across water optical depth
vec3 applyWaterExtinction(vec3 floorColor, float opticalDepth) {
    vec3 extinction = getWaterExtinctionCoefficient();
    vec3 transmittance = exp(-extinction * max(opticalDepth, 0.0));
    
    // Deep water ambient scatter tint
    vec3 waterScatterColor = vec3(0.04, 0.22, 0.38);
    return mix(waterScatterColor, floorColor, transmittance);
}

// Dynamic Underwater Sun Caustics
float calculateWaterCaustics(vec2 worldXZ, float time) {
#ifndef WATER_CAUSTICS
    return 1.0;
#else
    vec2 p = worldXZ * 1.2;
    float c1 = sin(p.x * 1.8 + p.y * 1.2 + time * 2.4);
    float c2 = cos(p.x * 1.4 - p.y * 1.9 - time * 2.0);
    float c3 = sin(p.x * 3.1 + p.y * 2.8 + time * 3.2);

    float caustic = pow(clamp((c1 + c2 + c3) / 3.0 * 0.5 + 0.5, 0.0, 1.0), 3.0);
    return 1.0 + caustic * 1.5;
#endif
}

// Schlick's Fresnel approximation for water surface reflections
float calculateFresnel(vec3 normal, vec3 viewDir) {
    float cosTheta = clamp(dot(normal, -viewDir), 0.0, 1.0);
    const float R0 = 0.02; // Water base reflectance at normal incidence
    return R0 + (1.0 - R0) * pow(1.0 - cosTheta, 5.0);
}

#endif // AETHERIA_WATER_GLSL
