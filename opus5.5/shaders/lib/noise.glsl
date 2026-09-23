#ifndef KOMOREBI_NOISE
#define KOMOREBI_NOISE

#include "/lib/common.glsl"

// 值噪声, 三次插值, 便宜且足够柔和
float valueNoise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float valueNoise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * (3.0 - 2.0 * f);
    float n000 = hash13(i);
    float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
    float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
    float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
    float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
    float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
    float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
    float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
    return mix(mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y),
               mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y), u.z);
}

// 分形叠加, 层数由外部控制以适配性能档
float fbm2(vec2 p, int octaves) {
    float sum = 0.0;
    float amp = 0.5;
    float norm = 0.0;
    for (int i = 0; i < octaves; i++) {
        sum += amp * valueNoise2(p);
        norm += amp;
        amp *= 0.5;
        p = p * 2.03 + vec2(17.3, 9.1);
    }
    return sum / max(norm, EPS);
}

float fbm3(vec3 p, int octaves) {
    float sum = 0.0;
    float amp = 0.5;
    float norm = 0.0;
    for (int i = 0; i < octaves; i++) {
        sum += amp * valueNoise3(p);
        norm += amp;
        amp *= 0.5;
        p = p * 2.07 + vec3(11.7, 5.3, 23.1);
    }
    return sum / max(norm, EPS);
}

// 山脊噪声, 用来塑形云团的边缘与丝缕感
float ridge3(vec3 p, int octaves) {
    float sum = 0.0;
    float amp = 0.5;
    float norm = 0.0;
    for (int i = 0; i < octaves; i++) {
        float n = 1.0 - abs(valueNoise3(p) * 2.0 - 1.0);
        sum += amp * n * n;
        norm += amp;
        amp *= 0.5;
        p = p * 2.11 + vec3(7.9, 13.4, 3.7);
    }
    return sum / max(norm, EPS);
}

// 云的三维密度场, 沿高度收成穹顶形, 避免方块状边界
float cloudDensity(vec3 worldPos, float coverage, float thickness, float lod) {
    vec3 p = worldPos;
    p.xz *= 0.0018;
    float base = fbm3(p * vec3(1.0, 0.45, 1.0), 3);
    float detail = ridge3(p * vec3(3.2, 1.6, 3.2) + vec3(frameTimeCounter * 0.004, 0.0, frameTimeCounter * 0.002), 3) * lod;
    float shape = base * 0.72 + detail * 0.28;
    float h = clamp((worldPos.y - cloudAltitude) / max(thickness, EPS), 0.0, 1.0);
    float profile = smoothstep(0.0, 0.28, h) * smoothstep(1.0, 0.62, h);
    float c = remap(shape, 1.0 - coverage * 0.82, 1.0, 0.0, 1.0);
    return clamp(c, 0.0, 1.0) * profile;
}

// 二维云影场, 供地表使用, 与体积云共用风场方向
float cloudShadowField(vec3 worldPos) {
    vec2 wind = vec2(0.86, 0.51);
    vec2 p = worldPos.xz * 0.0022 - wind * frameTimeCounter * 0.006;
    float n = fbm2(p, 3);
    float cover = remap(n, 1.0 - cloudCoverage * 0.86, 1.0, 0.0, 1.0);
    return clamp(cover, 0.0, 1.0);
}

#endif
