#ifndef KOMOREBI_COMMON
#define KOMOREBI_COMMON

#include "/lib/settings.glsl"
#include "/lib/buffers.glsl"

// 缓冲区约定
// colortex1 法线八面体编码 + 材质号
// colortex2 光照贴图 + 自发光
// colortex3 粗糙度 + 金属度 + 朝向 + 透光
// colortex4 辅助通道, 天光, 遮蔽, 材质号, 透光
// colortex5 云的散射与不透明度, 之后转为泛光金字塔
// colortex7 反照率

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

// 贴图尺寸, 用于把 0 到 1 的材质号压进一个通道
const float SLOT_ENCODE = 255.0;

// 矩阵
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

// 相机与玩家
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform float eyeAltitude;
uniform vec3 relativeEyePosition;
uniform int isEyeInWater;
uniform int frameCounter;
uniform float frameTime;
uniform float frameTimeCounter;

// 时间与天体
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;
uniform float sunAngle;
uniform float shadowAngle;
uniform int moonPhase;
uniform int worldTime;

// 天气与生物群系
uniform float rainStrength;
uniform float wetness;
uniform float thunderStrength;
uniform int biome;
uniform float temperature;
uniform float rainfall;
uniform vec2 eyeBrightness;
uniform vec2 eyeBrightnessSmooth;

// 屏幕
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform int heldBlockLightValue;

const float PI = 3.14159265359;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;

// 维度属性, 用于区分主世界, 下界与末地
uniform bool hasCeiling;
uniform bool hasSkylight;

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float EPS = 1e-5;
const float SUN_LUMINANCE = 12.0;
const float MOON_LUMINANCE = 0.32;
const float BLOCK_LIGHT_GAIN = 1.35;

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

// 屏幕空间蓝噪声近似, 用哈希格点代替查找贴图
vec2 screenBlueNoise(vec2 fragCoord, int frame) {
    ivec2 g = ivec2(mod(fragCoord, 64.0));
    return hash22(vec2(g) + float(frame) * 17.0);
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

// 材质号在缓冲中的存取
float encodeSlot(int slot) {
    return float(slot) / SLOT_ENCODE;
}

int decodeSlot(float encoded) {
    return int(encoded * SLOT_ENCODE + 0.5);
}

// 世界空间与视角空间的换算, 相机相对坐标加上相机位置即世界坐标
vec4 toWorldSpace(vec4 viewPos) {
    return gbufferModelViewInverse * viewPos;
}

vec4 toViewSpace(vec4 worldPos) {
    return gbufferModelView * worldPos;
}

vec4 toClipSpace(vec4 viewPos) {
    return gbufferProjection * viewPos;
}

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

// 由深度纹理取出线性距离
float depthToLinear(float depth) {
    return -screenToViewPos(vec3(0.5, 0.5, depth)).z;
}

// 屏幕坐标归一化, 像素中心加半格避免采样落回自身
vec2 screenUV(vec2 fragCoord) {
    return (fragCoord + 0.5) / vec2(viewWidth, viewHeight);
}

float linstep(float low, float high, float v) {
    return clamp((v - low) / (high - low), 0.0, 1.0);
}

float remap(float v, float a, float b, float c, float d) {
    return c + (v - a) / (b - a) * (d - c);
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

// 明度与饱和度分离调整, 避免整体发灰
vec3 saturateColor(vec3 c, float amount) {
    float l = luminance(c);
    return mix(vec3(l), c, amount);
}

vec3 desaturateForNight(vec3 c, float night) {
    return mix(c, vec3(luminance(c)), night * 0.35);
}

#endif
