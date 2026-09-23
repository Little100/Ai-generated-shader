#ifndef KOMOREBI_WATER
#define KOMOREBI_WATER

#include "/lib/material.glsl"

// 水面数学, 波浪, 焦散与吸收

// 三组正弦波叠加成水面, 波长与方向互质, 避免出现明显重复
const vec2 WAVE_DIR_A = vec2(0.86, 0.51);
const vec2 WAVE_DIR_B = vec2(-0.42, 0.91);
const vec2 WAVE_DIR_C = vec2(0.62, -0.78);

vec2 waveGradient(vec2 worldXZ, float t, float scale) {
    vec2 grad = vec2(0.0);
    float amp = 1.0;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float freq = (0.42 + fi * 0.37) * scale;
        float speed = 1.15 + fi * 0.42;
        vec2 dir = i == 0 ? WAVE_DIR_A : (i == 1 ? WAVE_DIR_B : WAVE_DIR_C);
        float phase = dot(worldXZ, dir) * freq + t * speed;
        grad += dir * cos(phase) * freq * amp;
        amp *= 0.62;
    }
    return grad * 0.16 * waveHeight;
}

// 细碎涟漪, 让近处水面不显得塑料
vec2 rippleGradient(vec2 worldXZ, float t) {
    vec2 g = vec2(0.0);
    vec2 p = worldXZ * 1.7;
    g.x = valueNoise2(p + vec2(t * 0.15, 0.0)) - valueNoise2(p - vec2(0.35, 0.0) + vec2(t * 0.15, 0.0));
    g.y = valueNoise2(p + vec2(0.0, t * 0.15)) - valueNoise2(p - vec2(0.0, 0.35) + vec2(0.0, t * 0.15));
    return g * 1.6 * waveHeight;
}

vec3 waterNormal(vec3 worldPos, float t, float detail) {
    vec2 grad = waveGradient(worldPos.xz, t, 1.0);
    grad += rippleGradient(worldPos.xz * 1.3, t) * clamp(detail, 0.0, 1.0);
    return normalize(vec3(-grad.x, 1.0, -grad.y));
}

// 顶点位移, 只在几何体本身有一定细分时才明显
vec3 waterVertexOffset(vec3 worldPos, float t) {
    vec2 grad = waveGradient(worldPos.xz, t, 1.0);
    return vec3(0.0, -length(grad) * 0.35, 0.0);
}

// 焦散, 由俯视的山脊噪声生成网状亮纹
float caustics(vec2 worldXZ, float t, float scale) {
    vec2 p = worldXZ * scale;
    vec2 q = p + vec2(t * 0.06, t * 0.045);
    float a = ridge3(vec3(q.x, q.y, t * 0.05));
    float b = ridge3(vec3(q.x * 1.9 + 5.0, q.y * 1.9, t * 0.08));
    float ridgeMix = a * 0.62 + b * 0.38;
    return pow(clamp(ridgeMix, 0.0, 1.0), 5.0) * 3.2;
}

// 施里克近似, 反射随视角陡增
float fresnelSchlick(float cosTheta, float f0) {
    return f0 + (1.0 - f0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float fresnelWater(float cosTheta) {
    return fresnelSchlick(cosTheta, fresnelBias * 0.06);
}

// 水下看水面的全反射, 内表面几乎全反
float fresnelUnderwater(float cosTheta) {
    return fresnelSchlick(cosTheta, 0.02);
}

// 水下吸收, 红光衰减最快, 于是深水自然偏青
vec3 waterAbsorb(vec3 color, float depth) {
    vec3 coeff = vec3(0.42, 0.11, 0.06);
    return color * exp(-coeff * max(depth, 0.0) * 1.35);
}

vec3 waterScatter(vec3 lightColor) {
    return mix(vec3(0.026, 0.086, 0.104), lightColor * 0.05, 0.55);
}

// 湿润表面的高光增强, 雨天石材与木材会出现薄水膜
float wetnessSpecularBoost(vec3 worldPos) {
    return wetness * wetHighlight * (0.4 + 0.6 * valueNoise2(worldPos.xz * 0.6));
}

#endif
