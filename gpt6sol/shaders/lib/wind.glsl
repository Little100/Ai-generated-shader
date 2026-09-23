#ifndef LOOMLIGHT_WIND
#define LOOMLIGHT_WIND

#include "/lib/settings.glsl"

vec3 foliageOffset(vec3 worldPos, float blockId, float time) {
    float leaves = 1.0 - step(0.5, abs(blockId - 10010.0));
    float grass = 1.0 - step(0.5, abs(blockId - 10011.0));
    float amount = leaves * 0.045 + grass * 0.075;
    float phase = dot(worldPos.xz, vec2(0.81, 1.27)) + time * 1.35;
    float gust = sin(phase) * 0.65 + sin(phase * 0.43 + worldPos.y * 1.8) * 0.35;
    return vec3(gust, 0.0, cos(phase * 0.73)) * amount * WIND_STRENGTH;
}

#endif
