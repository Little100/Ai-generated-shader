#ifndef KOMOREBI_MATH
#define KOMOREBI_MATH

// 常数, 哈希与纯数学工具, 位于包含链最底部, 只依赖 uniforms
// 这样噪声, 大气, 材质之间不会形成循环包含

// 材质槽编号, 与 block.properties 中的编号严格对应
#define SLOT_NONE 0
#define SLOT_FOLIAGE 1
#define SLOT_WATER 2
#define SLOT_GLASS 3
#define SLOT_METAL 4
#define SLOT_EMISSIVE 5
#define SLOT_SAND 6
#define SLOT_SNOW 7
#define SLOT_WOOD 8
#define SLOT_PLANT 9
#define SLOT_ENTITY 250

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float EPS = 1e-5;

// 直射光的亮度, 单位是相对值, 由最终阶段的曝光收回
const float SUN_LUMINANCE = 12.0;
const float MOON_LUMINANCE = 0.32;
const float BLOCK_LIGHT_GAIN = 1.35;

// 材质槽压进单个通道的编码系数
const float SLOT_ENCODE = 255.0;

// 整数哈希, 用于抖动与噪声
float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash12(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

float hash13(vec3 p) {
    p = fract(p * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.x + p.y) * p.z);
}

vec3 hash33(vec3 p) {
    p = fract(p * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.xxy + p.yxx) * p.zyx);
}

vec2 hash22(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.xx + q.yz) * q.zy);
}

// 交错梯度抖动, 逐帧变化以打散采样图案
float ign(vec2 p, int frame) {
    return hash12(p + float(frame) * 0.6180339887);
}

float srgbToLinear(float c) {
    return c < 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}

vec3 srgbToLinear(vec3 c) {
    return vec3(srgbToLinear(c.r), srgbToLinear(c.g), srgbToLinear(c.b));
}

float linearToSrgb(float c) {
    return c < 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1.0 / 2.4) - 0.055;
}

vec3 linearToSrgb(vec3 c) {
    return vec3(linearToSrgb(c.r), linearToSrgb(c.g), linearToSrgb(c.b));
}

float luminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// 把 v 从 a 到 b 的区间线性映射到 c 到 d
float remap(float v, float a, float b, float c, float d) {
    return c + (v - a) / (b - a) * (d - c);
}

// 法线八面体编码, 两个通道即可还原单位向量
vec2 encodeNormal(vec3 n) {
    n /= max(abs(n.x) + abs(n.y) + abs(n.z), EPS);
    vec2 enc = n.z >= 0.0 ? n.xy : (1.0 - abs(n.yx)) * sign(n.xy);
    return enc * 0.5 + 0.5;
}

vec3 decodeNormal(vec2 enc) {
    vec2 f = enc * 2.0 - 1.0;
    vec3 n = vec3(f.xy, 1.0 - abs(f.x) - abs(f.y));
    float t = max(-n.z, 0.0);
    n.xy += vec2(n.x >= 0.0 ? -t : t, n.y >= 0.0 ? -t : t);
    return normalize(n);
}

float encodeSlot(int slot) {
    return float(slot) / SLOT_ENCODE;
}

int decodeSlot(float encoded) {
    return int(encoded * SLOT_ENCODE + 0.5);
}

// 黑体辐射近似, 用于日出日落的色温推移
vec3 blackbody(float temp) {
    float t = clamp(temp, 1000.0, 40000.0) / 100.0;
    float r, g, b;
    if (t <= 66.0) {
        r = 255.0;
    } else {
        r = 329.698727446 * pow(t - 60.0, -0.1332047592);
    }
    if (t <= 66.0) {
        g = 99.4708025861 * log(t) - 161.1195681661;
    } else {
        g = 288.1221695283 * pow(t - 60.0, -0.0755148492);
    }
    if (t >= 66.0) {
        b = 255.0;
    } else if (t <= 19.0) {
        b = 0.0;
    } else {
        b = 138.5177312231 * log(t - 10.0) - 305.0447927307;
    }
    return clamp(vec3(r, g, b) / 255.0, 0.0, 1.0);
}

// 明度与饱和度分离调整, 避免整体发灰
vec3 saturateColor(vec3 c, float amount) {
    return mix(vec3(luminance(c)), c, amount);
}

vec3 desaturateForNight(vec3 c, float night) {
    return mix(c, vec3(luminance(c)), night * 0.35);
}

// 电影级色调映射, 高光收束而中间调保持对比
vec3 acesFilm(vec3 x) {
    const mat3 inMat = mat3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777);
    const mat3 outMat = mat3(
        1.60475, -0.10208, -0.00327,
        -0.53108, 1.10813, -0.07276,
        -0.07367, -0.00605, 1.07602);
    vec3 v = inMat * x;
    vec3 a = v * (v + 0.0245786) - 0.000090537;
    vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return clamp(outMat * (a / b), 0.0, 1.0);
}

vec3 hableFilmic(vec3 x) {
    const float A = 0.15, B = 0.50, C = 0.10, D = 0.20, E = 0.02, F = 0.30;
    vec3 c = ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
    float white = 11.2;
    float wc = ((white * (A * white + C * B) + D * E) / (white * (A * white + B) + D * F)) - E / F;
    return clamp(c / wc, 0.0, 1.0);
}

#endif
