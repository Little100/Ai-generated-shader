#ifndef KOMOREBI_SCREEN
#define KOMOREBI_SCREEN

// 屏幕空间与坐标换算, 只依赖 uniforms, 因此放在包含链最前
// 水面与阴影都要用它, 不能留在后面的库里

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

#endif
