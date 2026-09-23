#ifndef KOMOREBI_SHADOW
#define KOMOREBI_SHADOW

#include "/lib/noise.glsl"

// 阴影贴图使用径向压缩, 近处分配更多纹素, 远处压缩以换取覆盖范围
const float SHADOW_SCALE = 0.55;

// 采样数由宏决定, 循环上界必须是常量才能通过编译
#if shadowSamples == 4
#define SHADOW_LOOP 4
#elif shadowSamples == 8
#define SHADOW_LOOP 8
#elif shadowSamples == 20
#define SHADOW_LOOP 20
#elif shadowSamples == 32
#define SHADOW_LOOP 32
#else
#define SHADOW_LOOP 12
#endif

// 归一化坐标的径向压缩, 顶点与采样端必须使用同一套系数
vec2 shadowDistortUV(vec2 uv) {
    float len = length(uv - 0.5) * 2.0;
    float factor = 1.0 - SHADOW_SCALE * len;
    return (uv - 0.5) * factor + 0.5;
}

// 由世界坐标得到阴影贴图坐标, 已包含压缩
vec3 worldToShadow(vec3 worldPos) {
    vec4 clip = shadowProjection * (shadowModelView * vec4(worldPos, 1.0));
    vec3 ndc = clip.xyz / clip.w;
    return vec3(shadowDistortUV(ndc.xy * 0.5 + 0.5), ndc.z * 0.5 + 0.5);
}

// 倾斜偏置, 掠射角下加深以免自阴影渗漏
float shadowSlopeBias(vec3 worldNormal, vec3 lightDir) {
    float cosTheta = clamp(dot(worldNormal, lightDir), 0.0, 1.0);
    float slope = sqrt(max(1.0 - cosTheta * cosTheta, 0.0)) / max(cosTheta, 0.12);
    return 0.00010 + slope * 0.00026;
}

// 主体采样, 叠上泊松盘抖动, 树叶与玻璃的透射单独提亮
float sampleShadow(vec3 worldPos, vec3 worldNormal, vec3 lightDir, float softness) {
    // 沿法线偏移采样起点, 避免薄面片自遮挡
    float texelW = 1.0 / 512.0;
    vec3 offsetPos = worldPos - worldNormal * texelW * 2.0;
    vec3 sPos = worldToShadow(offsetPos);
    if (any(lessThan(sPos, vec3(0.0))) || any(greaterThan(sPos, vec3(1.0)))) return 1.0;

    float bias = shadowSlopeBias(worldNormal, lightDir);
    float texel = 1.0 / float(shadowMapResolution);
    float radius = mix(1.0, 3.0, softness) * shadowSoftness * texel;
    float depthHere = sPos.z - bias;

    float jitter = ign(gl_FragCoord.xy, frameCounter);
    float visible = 0.0;
    for (int i = 0; i < SHADOW_LOOP; i++) {
        float fi = float(i);
        float r = sqrt((fi + jitter) / float(SHADOW_LOOP)) * radius;
        float a = jitter * TAU + fi * 2.39996323;
        vec2 uv = sPos.xy + vec2(cos(a), sin(a)) * r;
        float solid = texture2D(shadowtex1, uv).r;
        float all = texture2D(shadowtex0, uv).r;
        // 完全不透明的遮挡记满, 只挡住一部分的记部分
        float opaque = depthHere <= solid ? 1.0 : 0.0;
        float partial = (depthHere <= all && depthHere > solid) ? 0.62 : 0.0;
        visible += opaque + partial;
    }
    visible /= float(SHADOW_LOOP);

    // 做一次平滑, 让半影过渡更接近自然散射
    visible = visible * visible * (3.0 - 2.0 * visible);
    return clamp(visible, 0.0, 1.0);
}

// 彩色阴影的染色量, 从 shadowcolor0 取出后与遮挡度混合
vec4 sampleShadowColor(vec3 worldPos) {
    vec3 sPos = worldToShadow(worldPos);
    vec4 c = texture2D(shadowcolor0, sPos.xy);
    return vec4(max(c.rgb, 0.0), clamp(c.a, 0.0, 1.0));
}

// 树叶光斑, 用有方向性的噪声在阴影上凿出孔洞
float dappleMask(vec3 worldPos, vec3 worldNormal, float amount) {
    if (amount <= 0.001) return 1.0;
    vec3 p = worldPos * (0.42 * dappleScale);
    p += vec3(0.0, frameTimeCounter * 0.02, frameTimeCounter * 0.012);
    float n = ridge3(p, 3);
    float n2 = valueNoise3(p * 2.7 + vec3(31.0, 7.0, 13.0));
    float holes = remap(n * 0.7 + n2 * 0.3, 0.34, 0.86, 0.0, 1.0);
    float patch = smoothstep(0.18, 0.92, holes);
    float up = clamp(dot(worldNormal, vec3(0.0, 1.0, 0.0)) * 0.5 + 0.5, 0.0, 1.0);
    return mix(1.0, patch, amount * up);
}

// 云影, 从体积云的高度场二维投影, 缓慢漂移
float cloudShadowAmount(vec3 worldPos) {
#ifdef CLOUD_SHADOW
    float cover = cloudShadowField(worldPos);
    return 1.0 - cover * 0.82;
#else
    return 1.0;
#endif
}

// 树叶本身透光, 背面朝向阳光下会发亮
float foliageTransmission(vec3 worldNormal, vec3 lightDir, float thickness) {
    float back = clamp(dot(-worldNormal, lightDir), 0.0, 1.0);
    float wrap = clamp(dot(worldNormal, lightDir) * 0.5 + 0.5, 0.0, 1.0);
    float through = pow(back, 2.2) * 0.75 + pow(wrap, 3.2) * 0.32;
    return through * thickness;
}

#endif
