#ifndef KOMOREBI_UTIL
#define KOMOREBI_UTIL

#include "/lib/common.glsl"
#include "/lib/noise.glsl"
#include "/lib/material.glsl"

// 从深度纹理取出线性距离, 供水面折射与雾使用
float depthToLinear(float depth) {
    vec4 view = gbufferProjectionInverse * vec4(vec3(depth) * 2.0 - 1.0, 1.0);
    return -view.z / view.w;
}

// 屏幕坐标归一化, 像素中心加半格避免采样落回自身
vec2 screenUV(vec2 fragCoord) {
    return (fragCoord + 0.5) / vec2(viewWidth, viewHeight);
}

// 光源方向与颜色的统一入口, 阴影阶段也复用
struct LightInfo {
    vec3 direction;
    vec3 color;
    float intensity;
    float shadowSoft;
};

LightInfo getLightInfo() {
    LightInfo li;
    int dim = currentDimension();
    float sunAmount = smoothstep(-0.08, 0.06, sunHeight());
    vec3 dir = normalize(mix(normalize(moonPosition), normalize(sunPosition), sunAmount));
    li.direction = dir;
    li.color = mix(moonLightColor() * MOON_LUMINANCE, sunLightColor() * SUN_LUMINANCE, sunAmount);
    li.intensity = mix(MOON_LUMINANCE, SUN_LUMINANCE, sunAmount);
    // 日落时阴影更软, 阴天更软
    li.shadowSoft = clamp(0.35 + (1.0 - sunAmount) * 0.4 + rainStrength * 0.5, 0.0, 1.0);

    // 下界与末地没有天体, 直射光几乎为零, 靠环境光与方块光支撑
    if (dim == DIM_NETHER) {
        li.color = vec3(1.0, 0.42, 0.20) * 0.55;
        li.intensity = 0.55;
        li.shadowSoft = 1.0;
    } else if (dim == DIM_END) {
        li.color = vec3(0.72, 0.66, 1.0) * 0.30;
        li.intensity = 0.30;
        li.shadowSoft = 1.0;
    }
    return li;
}

// 光照贴图通道换算, 0 到 1 的方块光与天空光
vec2 lightmapLevels(vec2 lmcoord) {
    return clamp(lmcoord / 1.06667, 0.0, 1.0);
}

// 树叶与草的摆动, 以方块中心为相位保证同一方块整体移动
vec3 blockWave(vec3 worldPos, vec3 midBlock, float time, float amount) {
    float phase = worldPos.x * 0.7 + worldPos.z * 0.53 + worldPos.y * 0.21;
    float sway = sin(time * 1.7 + phase) * 0.5 + sin(time * 0.93 + phase * 1.7) * 0.25;
    float gust = 0.6 + 0.4 * sin(time * 0.21 + worldPos.x * 0.02);
    float local = clamp(length(midBlock), 0.0, 1.4);
    return vec3(sin(phase * 0.6) * sway, -abs(sway) * 0.35, cos(phase * 0.8) * sway) * amount * gust * local;
}

// 顶点位置对相机的相对化, 保证大坐标下仍有精度
vec3 toCameraRelative(vec3 vertex) {
    return vertex - cameraPosition;
}

#endif
