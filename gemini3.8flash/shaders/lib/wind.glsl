#ifndef AETHERIA_WIND_GLSL
#define AETHERIA_WIND_GLSL

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

// ==============================================================================
// Aetheria: Organic Wind Vector Fields & Flora Motion Simulation
// ==============================================================================

// Speed multipliers based on settings
float getWindSpeedMultiplier() {
#if WIND_SPEED == 1
    return 0.65;
#elif WIND_SPEED == 3
    return 1.45;
#else
    return 1.0;
#endif
}

// Amplitude multipliers based on settings
float getWindStrengthMultiplier() {
#if WIND_STRENGTH == 1
    return 0.55;
#elif WIND_STRENGTH == 3
    return 1.60;
#else
    return 1.0;
#endif
}

// Calculate waving offset for grass and ground flora
vec3 calculateGrassWave(vec3 worldPos, float time, float isTopVertex) {
#ifndef WAVING_GRASS
    return vec3(0.0);
#else
    if (isTopVertex < 0.5) return vec3(0.0);

    float speed = getWindSpeedMultiplier();
    float strength = getWindStrengthMultiplier();

    // Low frequency rolling wind gust
    float gust = sin(worldPos.x * 0.25 + worldPos.z * 0.18 + time * 1.5 * speed);
    // Higher frequency flutter
    float flutter = sin(worldPos.x * 1.6 + worldPos.z * 1.3 + time * 3.8 * speed);

    vec2 windDir = normalize(vec2(1.0, 0.6));
    float totalWave = (gust * 0.12 + flutter * 0.04) * strength;

    return vec3(windDir.x * totalWave, -abs(totalWave) * 0.05, windDir.y * totalWave);
#endif
}

// Calculate waving offset for tree leaves
vec3 calculateLeavesWave(vec3 worldPos, float time) {
#ifndef WAVING_LEAVES
    return vec3(0.0);
#else
    float speed = getWindSpeedMultiplier();
    float strength = getWindStrengthMultiplier();

    float w1 = sin(worldPos.x * 1.1 + worldPos.y * 1.4 + worldPos.z * 0.8 + time * 2.2 * speed);
    float w2 = cos(worldPos.x * 0.8 - worldPos.y * 1.2 + worldPos.z * 1.5 - time * 1.8 * speed);
    float w3 = sin(worldPos.x * 2.0 + worldPos.z * 2.2 + time * 4.0 * speed);

    float waveX = (w1 * 0.035 + w3 * 0.015) * strength;
    float waveY = (w2 * 0.025) * strength;
    float waveZ = (w2 * 0.035 + w3 * 0.015) * strength;

    return vec3(waveX, waveY, waveZ);
#endif
}

#endif // AETHERIA_WIND_GLSL
