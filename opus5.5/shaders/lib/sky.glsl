#ifndef KOMOREBI_SKY
#define KOMOREBI_SKY

#include "/lib/atmosphere.glsl"

// 三层色带的插值权重, 天顶到地平按高度指数衰减
vec3 skyGradient(vec3 worldDir) {
    float h = clamp(worldDir.y * 0.5 + 0.5, 0.0, 1.0);
    float upper = pow(h, 1.35);
    float lower = pow(h, 3.2);
    vec3 zenith = skyZenithColor();
    vec3 horizon = skyHorizonColor();
    vec3 mid = mix(horizon, zenith, 0.5) * 1.02;
    vec3 col = mix(horizon, mid, lower);
    col = mix(col, zenith, upper * 0.92);
    // 地表以下给一点暗色, 避免看到天空的底部
    col = mix(col, horizon * 0.42, smoothstep(0.0, -0.14, worldDir.y));
    return col;
}

// 日侧散射, 大范围暖晕加上紧实的焦点
vec3 sunScatter(vec3 worldDir, vec3 lightDir, vec3 lightColor) {
    float mu = clamp(dot(worldDir, lightDir), -1.0, 1.0);
    float forward = pow(max(mu, 0.0), 6.0) * 0.22 + pow(max(mu, 0.0), 64.0) * 0.42;
    float around = pow(max(mu, 0.0), 1.5) * 0.10;
    float gradient = smoothstep(-0.10, 0.35, lightDir.y);
    return lightColor * (forward + around) * gradient * 0.55;
}

// 下界的天空被岩顶与雾遮蔽, 只留下层叠的暗红
vec3 netherSky(vec3 worldDir) {
    float h = clamp(worldDir.y * 0.5 + 0.5, 0.0, 1.0);
    vec3 low = vec3(0.20, 0.055, 0.026);
    vec3 high = vec3(0.055, 0.026, 0.040);
    vec3 col = mix(low, high, pow(h, 1.4));
    // 缓慢滚动的烟尘
    float smoke = fbm3(worldDir * 3.4 + vec3(frameTimeCounter * 0.006, 0.0, 0.0), 3);
    col *= 0.82 + smoke * 0.36;
    return col * 0.85;
}

// 末地是空无一物的虚空, 只有极暗的紫黑与零星的光点
vec3 endSky(vec3 worldDir) {
    float h = clamp(worldDir.y * 0.5 + 0.5, 0.0, 1.0);
    vec3 col = mix(vec3(0.030, 0.024, 0.046), vec3(0.072, 0.058, 0.104), pow(h, 1.1));
    // 稀疏的紫光尘埃
    vec3 p = worldDir * 46.0;
    vec3 cell = floor(p);
    vec3 f = fract(p) - 0.5;
    float h1 = hash13(cell);
    if (h1 > 0.9955) {
        float d = length(f - (hash33(cell * 1.7) - 0.5) * 0.6);
        col += vec3(0.62, 0.52, 0.95) * exp(-d * d * 130.0) * 0.9;
    }
    return col;
}

// 完整天空, 按维度分派, 供天空像素与水面反射共用
vec3 renderSky(vec3 worldDir, bool includeStars) {
    int dim = currentDimension();
    if (dim == DIM_NETHER) return netherSky(worldDir);
    if (dim == DIM_END) return endSky(worldDir);

    vec3 lightDir = normalize(sunPosition);
    vec3 lightColor = sunLightColor();
    vec3 col = skyGradient(worldDir);
    col += sunScatter(worldDir, lightDir, lightColor);

    if (includeStars) {
        float night = nightFactor();
        col += starField(worldDir, night);
        col += galaxyBand(worldDir, night);
        // 极光只在寒冷群系且晴朗时出现
        float cold = smoothstep(0.15, -0.35, temperature);
        col += aurora(worldDir, night * cold * (1.0 - rainStrength) * 0.55);
    }

    col = applyWeatherToSky(col, smoothstep(0.25, -0.05, worldDir.y));
    return col;
}

// 天体本体, 单独绘制以便泛光能拾取到它
vec3 renderCelestial(vec3 worldDir) {
    if (currentDimension() != DIM_OVERWORLD) return vec3(0.0);
    vec3 col = vec3(0.0);
    vec3 sunDir = normalize(sunPosition);
    vec3 moonDir = normalize(moonPosition);
    float sunVisible = smoothstep(-0.06, 0.09, sunDir.y);
    float moonVisible = smoothstep(-0.06, 0.09, moonDir.y);

    if (sunVisible > 0.001) {
        col += celestialDisk(worldDir, sunDir, sunLightColor(), 0.0078, 26.0) * sunVisible;
    }
    if (moonVisible > 0.001) {
        vec3 moonCol = moonLightColor() * 1.5;
        float phase = moonPhaseMask(worldDir, moonDir);
        col += celestialDisk(worldDir, moonDir, moonCol, 0.0185, 2.4) * moonVisible * max(phase, 0.12);
    }
    return col;
}

#endif
