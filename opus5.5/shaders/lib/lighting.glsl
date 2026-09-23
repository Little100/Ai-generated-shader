#ifndef KOMOREBI_LIGHTING
#define KOMOREBI_LIGHTING

#include "/lib/shadow.glsl"

// 光照合成, 包含环境光, 方块光, 高光与雾

// 布利恩光泽, 用于水与打磨过的方块
float specularGGX(vec3 normal, vec3 lightDir, vec3 viewDir, float roughness) {
    vec3 h = normalize(lightDir + viewDir);
    float a = max(roughness * roughness, 0.0016);
    float ndh = max(dot(normal, h), 0.0);
    float ndl = max(dot(normal, lightDir), 0.0);
    float ndv = max(dot(normal, viewDir), 0.0);
    float d = a * a / (PI * pow(ndh * ndh * (a * a - 1.0) + 1.0, 2.0));
    float k = a * 0.5;
    float g = (ndl / (ndl * (1.0 - k) + k)) * (ndv / (ndv * (1.0 - k) + k));
    return d * g / max(4.0 * ndl * ndv, EPS);
}

// 方块发出的光, 从光照贴图取出后做平方衰减以强调光源本身
vec3 blockLightColor(float lightLevel, vec3 worldPos) {
    float flicker = 0.96 + 0.04 * hash12(floor(worldPos.xz * 4.0) + frameTimeCounter * 0.4);
    float e = pow(clamp(lightLevel, 0.0, 1.0), 2.6) * flicker;
    vec3 warm = vec3(1.0, 0.62, 0.30);
    vec3 cool = vec3(0.78, 0.86, 1.0);
    return mix(warm, cool, smoothstep(0.55, 0.95, lightLevel) * 0.35) * e * BLOCK_LIGHT_GAIN;
}

// 环境光增益, 下界与末地没有太阳, 需要单独补偿
vec3 dimensionAmbientGain() {
    int dim = currentDimension();
    if (dim == DIM_NETHER) return vec3(1.25, 0.72, 0.55) * 0.55;
    if (dim == DIM_END) return vec3(0.62, 0.52, 0.86) * 0.42;
    return vec3(1.0);
}

// 环境天光, 用预先烘进缓冲的遮蔽做半球压暗
vec3 skyAmbient(vec3 worldNormal, float skyOcclusion, float skyLight, float blockLight) {
    LightInfo li = getLightInfo();
    vec3 sky = mix(skyHorizonColor(), skyZenithColor(), clamp(dot(worldNormal, normalize(li.direction)) * 0.5 + 0.5, 0.0, 1.0));
    float open = clamp(skyLight, 0.0, 1.0) * skyOcclusion;
    vec3 ambient = sky * open * 0.34 * dimensionAmbientGain();
    // 方块光在地面上反弹一次, 给暗部一点暖色
    vec3 bounce = vec3(0.30, 0.26, 0.21) * blockLight * blockLight * BLOCK_LIGHT_GAIN * 0.28;
    return ambient + bounce;
}

// 介质散射近似, 让迎光面产生一点点透亮感
vec3 translucentScatter(vec3 normal, vec3 lightDir, vec3 lightColor, float amount) {
    return lightColor * pow(clamp(dot(-normal, lightDir), 0.0, 1.0), 3.0) * amount;
}

// 掠射角的轮廓亮边, 逆光时把物体边缘勾出来
vec3 rimHighlight(vec3 normal, vec3 viewDir, vec3 lightDir, vec3 lightColor, float amount) {
    float rim = pow(1.0 - clamp(dot(normal, viewDir), 0.0, 1.0), 3.6);
    float facing = clamp(dot(-viewDir, lightDir) * 0.5 + 0.5, 0.0, 1.0);
    return lightColor * rim * facing * amount * 0.16;
}

// 高光, 附带阴影与遮挡的可见度
vec3 sunSpecular(vec3 normal, vec3 viewDir, vec3 lightDir, vec3 lightColor, float roughness, float visibility, float strength) {
    return lightColor * specularGGX(normal, lightDir, viewDir, roughness) * visibility * strength;
}

// 水面高光, 用更紧的高光宽度模拟太阳在水上的碎光
vec3 waterSunGlitter(vec3 normal, vec3 viewDir, vec3 lightDir, vec3 lightColor, float visibility) {
    vec3 h = normalize(lightDir + viewDir);
    float ndh = max(dot(normal, h), 0.0);
    return lightColor * (pow(ndh, 380.0) * 7.0 + pow(ndh, 64.0) * 0.55) * visibility;
}

// 雾的透过率与散射色
struct FogResult {
    vec3 color;
    float transmittance;
};

// 下界的雾由岩浆与菌光提供暖色, 末地的雾偏紫黑
vec3 dimensionFogColor(vec3 worldDir) {
    int dim = currentDimension();
    if (dim == DIM_NETHER) {
        return mix(vec3(0.42, 0.11, 0.045), vec3(0.16, 0.07, 0.09), clamp(worldDir.y * 1.6 + 0.3, 0.0, 1.0));
    }
    if (dim == DIM_END) {
        return mix(vec3(0.055, 0.042, 0.075), vec3(0.098, 0.076, 0.132), clamp(worldDir.y * 1.2 + 0.4, 0.0, 1.0));
    }
    vec3 fogColor = mix(skyHorizonColor(), skyZenithColor(), clamp(worldDir.y * 1.4, 0.0, 1.0));
    fogColor *= mix(0.85, 1.0, dayFactor());
    // 阴天把雾色压向灰蓝
    fogColor = mix(fogColor, vec3(0.30, 0.33, 0.38) * max(dayFactor(), 0.12), rainStrength * 0.6);
    return mix(fogColor, fogColor * 0.12, nightFactor() * 0.55);
}

FogResult applyFog(vec3 worldPos, vec3 worldDir, vec3 inColor, vec3 fogColorIn, float distance, float densityScale) {
    FogResult r;
    int dim = currentDimension();
    float base = fogDensity * densityScale * (1.0 + rainStrength * 1.6);
    // 下界的雾整体更浓
    if (dim == DIM_NETHER) base *= 2.6;
    if (dim == DIM_END) base *= 1.2;
    float density = fogDensityAt(worldPos, base, fogHeightFalloff);
    float optical = density * distance * 60.0;
    // 地平线方向光程更长, 雾因此更厚
    optical *= mix(1.0, 2.4, pow(1.0 - clamp(worldDir.y, 0.0, 1.0), 2.0));
    float t = exp(-optical);
    vec3 sunGlow = sunLightColor() * pow(max(dot(worldDir, skyLightDir()), 0.0), 8.0) * 0.16 * densityScale;
    r.color = inColor * t + (fogColorIn + sunGlow) * (1.0 - t);
    r.transmittance = t;
    return r;
}

// 水下雾, 随距离迅速吸光并染上水色
vec3 underwaterFog(vec3 inColor, vec3 lightColor, float distance, float densityScale) {
    float absorption = exp(-distance * 0.055 * densityScale);
    return inColor * absorption + waterScatter(lightColor) * (1.0 - absorption);
}

#endif
