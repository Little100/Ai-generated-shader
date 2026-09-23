#ifndef LOOMLIGHT_SKY
#define LOOMLIGHT_SKY

#include "/lib/settings.glsl"
#include "/lib/noise.glsl"

float daylightAmount(float angle) {
    return smoothstep(-0.10, 0.22, sin(angle * 6.2831853));
}

vec3 skyPalette(vec3 ray, float daylight, float rain, bool skylight, bool ceiling) {
    if (ceiling) return vec3(0.17, 0.070, 0.062);
    if (!skylight) {
        float glow = pow(max(1.0 - abs(ray.y + 0.08), 0.0), 3.0);
        return mix(vec3(0.014, 0.010, 0.031), vec3(0.15, 0.083, 0.22), glow);
    }
    float horizon = pow(1.0 - clamp(ray.y, 0.0, 1.0), 2.25);
    vec3 night = mix(vec3(0.014, 0.031, 0.079), vec3(0.12, 0.12, 0.17), horizon);
    vec3 day = mix(vec3(0.095, 0.31, 0.43), vec3(0.47, 0.70, 0.70), horizon);
    float twilight = 1.0 - smoothstep(0.05, 0.80, abs(daylight - 0.48) * 2.0);
    day = mix(day, vec3(0.82, 0.47, 0.33), twilight * horizon * 0.65);
    vec3 result = mix(night, day, daylight);
    return mix(result, vec3(0.35, 0.40, 0.45), rain * 0.65);
}

vec3 skyRadiance(vec3 ray, vec3 sunDir, vec3 moonDir, vec3 cameraPos, float time, float daylight, float rain, bool skylight, bool ceiling) {
    vec3 color = skyPalette(ray, daylight, rain, skylight, ceiling);
    if (ceiling || !skylight) return color;

    float sunDot = max(dot(ray, sunDir), 0.0);
    float sunDisc = smoothstep(0.99955, 0.99980, sunDot);
    float halo = pow(sunDot, 18.0) * 0.33 + pow(sunDot, 320.0) * 0.40;
    color += vec3(1.0, 0.69, 0.43) * (sunDisc * 2.1 + halo) * daylight * (1.0 - rain * 0.9);

    vec2 starSpace = ray.xz / (ray.y + 1.4) * 340.0;
    vec2 cell = floor(starSpace);
    vec2 starPoint = vec2(hash12(cell), hash12(cell + 53.7));
    float star = (1.0 - smoothstep(0.008, 0.052, length(fract(starSpace) - starPoint)));
    star *= step(0.990, hash12(cell + 11.3)) * smoothstep(-0.08, 0.19, ray.y);
    float moonDisc = smoothstep(0.99955, 0.99980, max(dot(ray, moonDir), 0.0));
    color += vec3(0.54, 0.70, 0.92) * moonDisc * 1.15 * (1.0 - daylight) * (1.0 - rain);
    color += vec3(0.65, 0.80, 1.0) * star * (1.0 - daylight) * (1.0 - rain);

#ifdef CLOUDS
    float layerOffset = 180.0 - cameraPos.y;
    if (abs(ray.y) > 0.015 && layerOffset * ray.y > 0.0) {
        float travel = layerOffset / ray.y;
        if (travel < 6500.0) {
            vec2 p = (cameraPos.xz + ray.xz * travel) * 0.0035;
            p += vec2(time * 0.0032, -time * 0.0015);
            float shape = cloudNoise(p + vec2(noise2(p * 0.32), noise2(p * 0.32 + 7.0)) * 0.36);
            float cloud = smoothstep(0.57 - CLOUD_DENSITY * 0.20, 0.76 - CLOUD_DENSITY * 0.11, shape);
            cloud *= smoothstep(0.015, 0.11, abs(ray.y)) * (1.0 - rain * 0.25);
            float shade = cloudNoise(p + vec2(0.13, -0.11));
            vec3 cloudColor = mix(vec3(0.13, 0.17, 0.28), vec3(0.90, 0.88, 0.76), daylight);
            cloudColor *= 0.77 + shade * 0.29;
            if (layerOffset < 0.0) cloudColor *= 0.74;
            color = mix(color, cloudColor, cloud * 0.82);
        }
    }
#endif
    return color;
}

#endif




