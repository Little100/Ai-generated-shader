#ifndef LOOMLIGHT_LIGHTING
#define LOOMLIGHT_LIGHTING

#include "/lib/settings.glsl"

float daylightAmount(float angle) {
    return smoothstep(-0.10, 0.22, sin(angle * 6.2831853));
}

float shadowVisibility(vec3 playerPos, vec3 normal, vec3 lightDir) {
#ifndef SHADOWS
    return 1.0;
#else
    if (dot(normal, lightDir) <= 0.01) return 1.0;
    vec4 projected = shadowProjection * shadowModelView * vec4(playerPos + normal * 0.045, 1.0);
    vec3 uv = projected.xyz / projected.w * 0.5 + 0.5;
    if (uv.x < 0.005 || uv.x > 0.995 || uv.y < 0.005 || uv.y > 0.995 || uv.z < 0.0 || uv.z > 1.0) return 1.0;
    float bias = mix(0.0012, 0.0038, 1.0 - max(dot(normal, lightDir), 0.0));
    float visibility = 0.0;
    vec2 pixel = vec2(1.0 / float(shadowMapResolution));
#if SHADOW_SAMPLES == 4
    for (int y = 0; y < 2; ++y) {
        for (int x = 0; x < 2; ++x) {
            float depth = texture2D(shadowtex0, uv.xy + (vec2(x, y) - 0.5) * pixel).r;
            visibility += step(uv.z - bias, depth);
        }
    }
    return visibility * 0.25;
#else
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            float depth = texture2D(shadowtex0, uv.xy + vec2(x, y) * pixel * 1.35).r;
            visibility += step(uv.z - bias, depth);
        }
    }
    return visibility / 9.0;
#endif
#endif
}

vec3 illuminate(vec3 albedo, vec3 normal, vec3 playerPos, vec2 lm, float emissive) {
    float daylight = hasSkylight ? daylightAmount(sunAngle) : 0.0;
    vec3 lightDir = normalize(shadowLightPosition);
    float sky = hasSkylight ? clamp((lm.y - 0.03) * 1.2, 0.0, 1.0) : 0.0;
    float torch = clamp((lm.x - 0.03) * 1.2, 0.0, 1.0);
    float facing = max(dot(normal, lightDir), 0.0);
    float shadow = shadowVisibility(playerPos, normal, lightDir);
    float rain = clamp(rainStrength, 0.0, 1.0);
    vec3 ambient = mix(vec3(0.15, 0.20, 0.29), vec3(0.37, 0.43, 0.43), daylight);
    ambient *= 0.63 + sky * 0.57;
    if (!hasSkylight) ambient = vec3(0.20, 0.13, 0.16);
    vec3 direct = mix(vec3(0.22, 0.31, 0.43), vec3(1.05, 0.82, 0.64), daylight);
    direct *= facing * shadow * sky * (1.0 - rain * 0.54) * mix(0.38, 0.82, daylight);
    vec3 blockLight = vec3(1.12, 0.57, 0.26) * torch * torch * 0.78;
    return albedo * (ambient + direct + blockLight) + albedo * emissive * 0.65;
}

#endif


