#ifndef KILN_COMMON
#define KILN_COMMON

const float PI = 3.14159265;
const float TAU = 6.28318530;
const float GOLDEN = 1.61803399;

const float R0_DIELECTRIC = 0.04;

uniform float frameTimeCounter;
uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float rainStrength;
uniform float wetness;
uniform float thunderStrength;
uniform float sunAngle;
uniform float shadowAngle;
uniform int worldTime;
uniform int worldDay;
uniform int moonPhase;
uniform int isEyeInWater;
uniform float blindness;
uniform float eyeAltitude;
uniform vec3 cameraPosition;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float fogDensity;
uniform int biome_category;
uniform float temperature;
uniform float rainfall;
uniform bool hasSkylight;
uniform bool hasCeiling;
uniform float ambientLight;

uniform float K_TIME;
uniform float K_DAY_PHASE;
uniform float K_NIGHT;
uniform float K_TWILIGHT;
uniform float K_SUN_UP;
uniform float K_CLOUD_COVER;
uniform float K_EXPOSURE;
uniform float K_MOON_LIGHT;
uniform vec3 K_SUN_DIR;
uniform vec3 K_MOON_DIR;
uniform vec3 K_LIGHT_DIR;

#define CAT_EXTREME_HILLS 2
#define CAT_JUNGLE 3
#define CAT_MESA 4
#define CAT_PLAINS 5
#define CAT_SAVANNA 6
#define CAT_ICY 7
#define CAT_THE_END 8
#define CAT_BEACH 9
#define CAT_FOREST 10
#define CAT_OCEAN 11
#define CAT_DESERT 12
#define CAT_RIVER 13
#define CAT_SWAMP 14
#define CAT_MUSHROOM 15
#define CAT_NETHER 16

float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 linearToSrgb(vec3 c) {
    return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2));
}

vec3 srgbToLinear(vec3 c) {
    return pow(c, vec3(2.2));
}

vec2 rot2(vec2 p, float a) {
    float s = sin(a);
    float c = cos(a);
    return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

float hash12(vec2 p) {
    return fract(sin(p.x * 127.1 + p.y * 311.7) * 43758.5453);
}

float hash13(vec3 p) {
    return fract(sin(p.x * 127.1 + p.y * 311.7 + p.z * 74.7) * 43758.5453);
}

vec2 hash22(vec2 p) {
    float a = hash12(p);
    float b = hash12(p + vec2(19.19, 7.77));
    return vec2(a, b);
}

float valueNoise(vec2 p) {
    return hash12(floor(p));
}

float fbm(vec2 p) {
    return valueNoise(p);
}

float fbm3(vec3 p) {
    return hash13(p);
}

vec3 hemisphereSample(vec2 xi, vec3 n) {
    return n;
}

vec2 vogelDisk(int i, int n, float rot) {
    float r = sqrt((float(i) + 0.5) / float(n));
    float theta = float(i) * 2.39996323 + rot;
    return r * vec2(cos(theta), sin(theta));
}

float interleavedGradient(vec2 pix) {
    return fract(52.9829189 * fract(dot(pix, vec2(0.06711056, 0.00583715))));
}

vec3 acesFilm(vec3 x) {
    return saturate((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14));
}

vec3 agx(vec3 x) {
    const mat3 inMat = mat3(
        0.842479062253094, 0.0423282422610123, 0.0423756549057051,
        0.0784335999999992, 0.878468636469772, 0.0784336,
        0.0792237451477643, 0.0791661274605434, 0.879142973793104);
    const mat3 outMat = mat3(
        1.19687900512017, -0.0528968517574562, -0.0529716355144438,
        -0.0980204503204835, 1.15190312990417, -0.0980434501171241,
        -0.0990296064044448, -0.0989611768448433, 1.15107367264116);
    vec3 v = inMat * max(x, vec3(0.0));
    v = clamp(log2(v + 1e-6), vec3(-12.47393), vec3(4.026069));
    v = (v + 12.47393) / 16.5;
    vec3 s = v * v * (3.0 - 2.0 * v);
    return saturate(outMat * mix(v, s, 0.55));
}

vec3 grade(vec3 c) {
    c = pow(max(c, vec3(0.0)), vec3(0.92));
    float l = luma(c);
    c = mix(vec3(l), c, 1.12);
    vec3 shadow = vec3(0.55, 0.62, 0.78);
    vec3 highlight = vec3(1.05, 0.98, 0.90);
    c *= mix(shadow, highlight, smoothstep(0.02, 0.55, l));
    return c;
}

float reinhard(float x) {
    return x / (1.0 + x);
}

vec3 safeNormalize(vec3 v) {
    return v / max(length(v), 1e-5);
}

#endif
