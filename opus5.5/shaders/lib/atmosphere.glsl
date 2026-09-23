#ifndef KOMOREBI_ATMOSPHERE
#define KOMOREBI_ATMOSPHERE

#include "/lib/noise.glsl"

// 天空被拆成三层色带, 天顶, 中段, 地平, 这样日出日落时地平线能独立染成暖色
const vec3 ZENITH_DAY = vec3(0.128, 0.268, 0.585);
const vec3 HORIZON_DAY = vec3(0.612, 0.706, 0.878);
const vec3 ZENITH_NIGHT = vec3(0.008, 0.013, 0.036);
const vec3 HORIZON_NIGHT = vec3(0.036, 0.048, 0.090);
const vec3 SUNSET_WARM = vec3(1.0, 0.44, 0.17);
const vec3 SUNSET_SOFT = vec3(0.94, 0.62, 0.36);

// 维度编号, 与 common.glsl 保持一致
#define DIM_OVERWORLD 0
#define DIM_NETHER 1
#define DIM_END 2

// 由天空属性区分维度, 不依赖外部配置文件
int currentDimension() {
    if (hasCeiling && !hasSkylight) return DIM_NETHER;
    if (!hasSkylight && !hasCeiling) return DIM_END;
    return DIM_OVERWORLD;
}

// 太阳高度角, 0 为地平, 1 为天顶
float sunHeight() {
    return clamp(sunPosition.y, -1.0, 1.0);
}

// 白昼权重, 带柔和过渡
float dayFactor() {
    return smoothstep(-0.045, 0.16, sunHeight());
}

// 晨昏权重, 在地平线附近达到峰值
float twilightFactor() {
    float h = abs(sunHeight());
    return exp(-h * h * 26.0);
}

float nightFactor() {
    return 1.0 - smoothstep(-0.10, 0.06, sunHeight());
}

bool sunIsUp() {
    return sunHeight() > -0.02;
}

vec3 skyZenithColor() {
    int dim = currentDimension();
    if (dim == DIM_NETHER) return vec3(0.085, 0.030, 0.034);
    if (dim == DIM_END) return vec3(0.048, 0.038, 0.070);
    vec3 base = mix(ZENITH_NIGHT, ZENITH_DAY, dayFactor());
    return mix(base, base * vec3(1.12, 0.86, 0.78), twilightFactor() * 0.35);
}

vec3 skyHorizonColor() {
    int dim = currentDimension();
    if (dim == DIM_NETHER) return vec3(0.22, 0.055, 0.030);
    if (dim == DIM_END) return vec3(0.030, 0.026, 0.048);
    vec3 base = mix(HORIZON_NIGHT, HORIZON_DAY, dayFactor());
    vec3 warm = mix(SUNSET_SOFT, SUNSET_WARM, 1.0 - abs(sunHeight()) * 3.0);
    return mix(base, warm, clamp(twilightFactor() * 1.05, 0.0, 1.0));
}

// 太阳光色, 高度越低越红, 并且被雨云压暗
vec3 sunLightColor() {
    float h = clamp(sunHeight(), 0.0, 1.0);
    vec3 warm = mix(SUNSET_WARM, vec3(1.0, 0.96, 0.90), smoothstep(0.0, 0.24, h));
    vec3 tone = mix(warm, blackbody(6500.0), smoothstep(0.18, 0.62, h));
    vec3 storm = mix(vec3(1.0), vec3(0.42, 0.47, 0.56), rainStrength * 0.85);
    return tone * storm;
}

vec3 moonLightColor() {
    return vec3(0.44, 0.56, 0.90);
}

// 星空, 用球面分格哈希撒点, 靠近地平线处削减避免堆积
vec3 starField(vec3 worldDir, float brightness) {
    if (brightness <= 0.001) return vec3(0.0);
    vec3 acc = vec3(0.0);
    for (int layer = 0; layer < 4; layer++) {
        float sc = 90.0 + float(layer) * 74.0;
        vec3 p = worldDir * sc;
        vec3 cell = floor(p);
        vec3 f = fract(p) - 0.5;
        float h = hash13(cell + float(layer) * 13.7);
        if (h > 0.982) {
            vec3 offset = (hash33(cell * 1.37 + float(layer)) - 0.5) * 0.7;
            float d = length(f - offset);
            float core = exp(-d * d * 190.0);
            float mag = hash13(cell * 2.1 - float(layer));
            float twinkle = 0.72 + 0.28 * sin(frameTimeCounter * (2.4 + mag * 5.0) + h * 90.0);
            vec3 tint = mix(vec3(0.72, 0.82, 1.0), vec3(1.0, 0.88, 0.74), hash13(cell + 3.3));
            acc += tint * core * (0.35 + mag * 0.9) * twinkle;
        }
    }
    float horizonFade = smoothstep(-0.03, 0.28, worldDir.y);
    return acc * brightness * 0.85 * horizonFade;
}

// 银河, 沿一条倾斜带堆放暗弱星云
vec3 galaxyBand(vec3 worldDir, float brightness) {
    if (brightness <= 0.001) return vec3(0.0);
    vec3 axis = normalize(vec3(0.42, 0.72, -0.55));
    float band = dot(worldDir, axis);
    float mask = exp(-band * band * 12.0);
    float n = fbm3(worldDir * 7.0, 4);
    float shade = smoothstep(0.36, 0.78, n);
    vec3 tint = mix(vec3(0.30, 0.36, 0.62), vec3(0.62, 0.50, 0.58), n);
    return tint * mask * shade * brightness * 0.16;
}

// 极光, 由高度与方位共同调制的慢速帘幕
vec3 aurora(vec3 worldDir, float strength) {
    if (strength <= 0.001) return vec3(0.0);
    float h = clamp(worldDir.y, 0.0, 1.0);
    float curtain = smoothstep(0.06, 0.42, h) * smoothstep(0.95, 0.34, h);
    vec2 p = vec2(atan(worldDir.z, worldDir.x) * 2.4, h * 3.2 - frameTimeCounter * 0.012);
    float n = fbm2(p * vec2(1.6, 0.9), 4);
    float fold = smoothstep(0.44, 0.86, n);
    vec3 tint = mix(vec3(0.12, 0.86, 0.52), vec3(0.28, 0.36, 0.94), n);
    tint = mix(tint, vec3(0.86, 0.24, 0.62), smoothstep(0.72, 0.98, n) * 0.5);
    return tint * fold * curtain * strength;
}

// 太阳与月亮的圆盘, 带一层柔和外晕
vec3 celestialDisk(vec3 worldDir, vec3 lightDir, vec3 lightColor, float angularRadius, float intensity) {
    float cosAngle = dot(worldDir, lightDir);
    float cosRadius = cos(angularRadius);
    float disk = smoothstep(cosRadius - 0.0006, cosRadius + 0.0009, cosAngle);
    float halo = pow(max(cosAngle, 0.0), 420.0) * 0.35 + pow(max(cosAngle, 0.0), 24.0) * 0.06;
    return lightColor * (disk * intensity + halo * intensity * 0.55);
}

// 月亮相位遮罩, 用横向偏移切出月牙
float moonPhaseMask(vec3 worldDir, vec3 lightDir) {
    if (moonPhase == 0) return 1.0;
    vec3 up = normalize(vec3(0.0, 1.0, 0.0));
    if (abs(dot(up, lightDir)) > 0.99) up = normalize(vec3(1.0, 0.0, 0.0));
    vec3 right = normalize(cross(up, lightDir));
    vec3 upOrtho = cross(lightDir, right);
    float x = dot(worldDir, right);
    float y = dot(worldDir, upOrtho);
    float phase = float(moonPhase) / 8.0;
    float dirSign = sin(phase * TAU) >= 0.0 ? 1.0 : -1.0;
    float shift = mix(0.012, 0.058, abs(sin(phase * TAU)));
    float radius = length(vec2(x + shift * dirSign, y));
    // 相位越接近满月, 允许的半径越大
    float limit = sin(0.0205);
    return step(radius, limit);
}

// 有云时天空整体压暗并偏灰
vec3 applyWeatherToSky(vec3 sky, float horizonWeight) {
    float storm = rainStrength * (0.55 + thunderStrength * 0.35);
    vec3 overcast = vec3(dot(sky, vec3(0.30, 0.58, 0.12)));
    overcast = mix(overcast, sky * 0.5, 0.25);
    vec3 stormy = mix(vec3(0.36, 0.39, 0.44), vec3(0.14, 0.15, 0.19), thunderStrength);
    vec3 base = mix(sky, overcast * 0.7, clamp(storm, 0.0, 1.0));
    return mix(base, stormy, clamp(storm * (0.35 + horizonWeight * 0.4), 0.0, 1.0));
}

// 洞穴与室内的环境光, 依赖玩家所处亮度而不是时间
float caveAmbientSkylight() {
    float exposure = clamp(float(eyeBrightness.y) / 240.0, 0.0, 1.0);
    return mix(0.12, 1.0, exposure * exposure);
}

// 高度雾密度, 低处堆积, 高处稀薄, 洞穴内另有一层静雾
float fogDensityAt(vec3 worldPos, float base, float falloff) {
    float rel = worldPos.y;
    float heightTerm = exp(-max(rel - 62.0, 0.0) * falloff * 0.006);
    float lowTerm = exp(-max(62.0 - rel, 0.0) * 0.018);
    float cave = (1.0 - caveAmbientSkylight()) * 0.35;
    return base * (heightTerm * 0.6 + lowTerm * 0.55 + cave) * 0.0016;
}

#endif
