#ifndef KOMOREBI_UTIL
#define KOMOREBI_UTIL

#include "/lib/clouds.glsl"

// 几何与网格相关的通用工具, 不含光照逻辑
// 放在包含链末尾, 因为光照与云都会用到它

// 由屏幕坐标与深度反推视角空间位置
vec3 screenToViewPos(vec3 screenPos) {
    vec4 clip = gbufferProjectionInverse * vec4(screenPos * 2.0 - 1.0, 1.0);
    return clip.xyz / clip.w;
}

vec3 viewToWorldDir(vec3 viewDir) {
    return mat3(gbufferModelViewInverse) * viewDir;
}

vec3 worldToViewDir(vec3 worldDir) {
    return mat3(gbufferModelView) * worldDir;
}

// 由深度纹理取出到相机的线性距离
float depthToLinear(float depth) {
    return -screenToViewPos(vec3(0.5, 0.5, depth)).z;
}

// 光照贴图通道换算到 0 到 1
vec2 lightmapLevels(vec2 lmcoord) {
    return clamp(lmcoord / 1.06667, 0.0, 1.0);
}

// 草与树叶的摆动, 以方块中心为相位保证同一方块整体移动
vec3 blockWave(vec3 worldPos, vec3 midBlock, float time, float amount) {
    float phase = worldPos.x * 0.7 + worldPos.z * 0.53 + worldPos.y * 0.21;
    float sway = sin(time * 1.7 + phase) * 0.5 + sin(time * 0.93 + phase * 1.7) * 0.25;
    float gust = 0.6 + 0.4 * sin(time * 0.21 + worldPos.x * 0.02);
    float local = clamp(length(midBlock), 0.0, 1.4);
    return vec3(sin(phase * 0.6) * sway, -abs(sway) * 0.35, cos(phase * 0.8) * sway) * amount * gust * local;
}

#endif
