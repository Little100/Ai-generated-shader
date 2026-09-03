#ifndef WIND_GLSL
#define WIND_GLSL

// Gusty displacement field in world space, stronger during rain
vec3 windOffset(vec3 worldPos, float t) {
    float gust = valueNoise(worldPos.xz * 0.04 + vec2(t * 0.11, t * 0.07));
    float amp = (0.035 + 0.075 * gust) * (1.0 + rainStrength * 1.2) * WIND_STRENGTH;
    float ph = dot(worldPos.xz, vec2(0.7, 0.4)) + worldPos.y * 0.3 + t * 1.9;
    float ph2 = dot(worldPos.xz, vec2(-0.3, 0.8)) + t * 2.7;
    vec3 dir = vec3(
        sin(ph) + 0.4 * sin(ph2 * 1.7),
        0.25 * sin(ph * 0.6 + 1.0),
        0.7 * cos(ph * 0.9) + 0.3 * cos(ph2)
    );
    return dir * amp;
}

// isTop marks vertices on the upper half of the sprite, skyGate suppresses sway underground
vec3 windForBlock(int id, vec3 worldPos, bool isTop, float skyGate) {
    vec3 w = windOffset(worldPos, frameTimeCounter) * skyGate;
    if (id == BLOCK_PLANT_SHORT) return isTop ? w : vec3(0.0);
    if (id == BLOCK_PLANT_TALL_LOWER) return isTop ? w * 0.5 : vec3(0.0);
    if (id == BLOCK_PLANT_TALL_UPPER) return isTop ? w : w * 0.5;
    if (id == BLOCK_LEAVES) return w * 0.45;
    if (id == BLOCK_HANGING) return w * 0.4;
    if (id == BLOCK_SEAGRASS) return isTop ? w * 0.6 : vec3(0.0);
    return vec3(0.0);
}

#endif
