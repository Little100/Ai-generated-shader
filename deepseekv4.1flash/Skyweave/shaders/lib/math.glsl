/*
    Skyweave - noise, low discrepancy sequences and spatial transforms.

    Nothing here touches the Minecraft data model, so the routines are safe to
    pull into any program, vertex or fragment.
*/

#if !defined(SKYWEAVE_MATH_INCLUDED)
#define SKYWEAVE_MATH_INCLUDED

#include "/lib/uniforms.glsl"

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float HALF_PI = 1.57079632679;
const float GOLDEN_ANGLE = 2.39996322973;

const int noiseTextureResolution = 256;

float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

vec2 saturate(vec2 x) {
    return clamp(x, vec2(0.0), vec2(1.0));
}

vec3 saturate(vec3 x) {
    return clamp(x, vec3(0.0), vec3(1.0));
}

float luminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// weighted for how the eye reacts rather than radiometric power
float perceptualLuminance(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

float remap(float value, float lowIn, float highIn, float lowOut, float highOut) {
    return lowOut + (value - lowIn) / max(highIn - lowIn, 1e-6) * (highOut - lowOut);
}

float smoothMax(float a, float b, float k) {
    float h = saturate(0.5 + 0.5 * (a - b) / max(k, 1e-5));
    return mix(b, a, h) + k * h * (1.0 - h);
}

// perceptually smoother than a plain lerp for brightness-like quantities
float exponentialStep(float edge0, float edge1, float x) {
    float t = saturate((x - edge0) / max(edge1 - edge0, 1e-6));
    return 1.0 - exp2(-10.0 * t);
}

mat2 rotate2D(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

// Rodrigues rotation, used to spin the celestial sphere around its pole
vec3 rotateAboutAxis(vec3 v, vec3 axis, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return v * c + cross(axis, v) * s + axis * dot(axis, v) * (1.0 - c);
}

/*  hashing  */

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p3) {
    p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec3 hash33(vec3 p3) {
    p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

// cheap hash that stays stable for large world coordinates
vec3 hash33Stable(vec3 p) {
    p = mod(p, 512.0);
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));
    return fract(sin(p) * 43758.5453);
}

/*  low discrepancy sequences  */

// two dimensional R2 sequence, ideal for temporal rotation of a sample kernel
vec2 r2Sequence(int index) {
    const float plastic = 1.324717957244746;
    vec2 alpha = vec2(1.0 / plastic, 1.0 / (plastic * plastic));
    return fract(alpha * (float(index) + 0.5));
}

// golden angle spiral over a unit disc, returns a point inside the disc
vec2 discSample(int index, int count) {
    float r = sqrt((float(index) + 0.5) / float(count));
    float theta = float(index) * GOLDEN_ANGLE;
    return vec2(r * cos(theta), r * sin(theta));
}

// the classic per pixel gradient noise, still the cheapest usable dither
float interleavedGradientNoise(vec2 pixel) {
    const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
    return fract(magic.z * fract(dot(pixel, magic.xy)));
}

// blue noise pulled from the pack noise texture, decorrelated over time
float blueNoise(vec2 fragCoord, int frame) {
    vec2 jitter = r2Sequence(frame) * float(noiseTextureResolution);
    vec2 uv = (fragCoord + jitter) / float(noiseTextureResolution);
    return texture(noisetex, uv).x;
}

// two decorrelated channels, for passes that need independent jitter
vec2 blueNoise2(vec2 fragCoord, int frame) {
    vec2 jitter = r2Sequence(frame) * float(noiseTextureResolution);
    vec2 uv = (fragCoord + jitter) / float(noiseTextureResolution);
    return texture(noisetex, uv).xy;
}

/*  procedural noise  */

float valueNoise3D(vec3 p) {
    vec3 cell = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float n000 = hash13(cell + vec3(0.0, 0.0, 0.0));
    float n100 = hash13(cell + vec3(1.0, 0.0, 0.0));
    float n010 = hash13(cell + vec3(0.0, 1.0, 0.0));
    float n110 = hash13(cell + vec3(1.0, 1.0, 0.0));
    float n001 = hash13(cell + vec3(0.0, 0.0, 1.0));
    float n101 = hash13(cell + vec3(1.0, 0.0, 1.0));
    float n011 = hash13(cell + vec3(0.0, 1.0, 1.0));
    float n111 = hash13(cell + vec3(1.0, 1.0, 1.0));

    float x00 = mix(n000, n100, f.x);
    float x10 = mix(n010, n110, f.x);
    float x01 = mix(n001, n101, f.x);
    float x11 = mix(n011, n111, f.x);

    return mix(mix(x00, x10, f.y), mix(x01, x11, f.y), f.z);
}

// gradient noise, smoother than value noise at the cost of a few multiplies
float gradientNoise3D(vec3 p) {
    vec3 cell = floor(p);
    vec3 f = fract(p);

    vec3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float n000 = dot(hash33Stable(cell + vec3(0.0, 0.0, 0.0)) * 2.0 - 1.0, f - vec3(0.0, 0.0, 0.0));
    float n100 = dot(hash33Stable(cell + vec3(1.0, 0.0, 0.0)) * 2.0 - 1.0, f - vec3(1.0, 0.0, 0.0));
    float n010 = dot(hash33Stable(cell + vec3(0.0, 1.0, 0.0)) * 2.0 - 1.0, f - vec3(0.0, 1.0, 0.0));
    float n110 = dot(hash33Stable(cell + vec3(1.0, 1.0, 0.0)) * 2.0 - 1.0, f - vec3(1.0, 1.0, 0.0));
    float n001 = dot(hash33Stable(cell + vec3(0.0, 0.0, 1.0)) * 2.0 - 1.0, f - vec3(0.0, 0.0, 1.0));
    float n101 = dot(hash33Stable(cell + vec3(1.0, 0.0, 1.0)) * 2.0 - 1.0, f - vec3(1.0, 0.0, 1.0));
    float n011 = dot(hash33Stable(cell + vec3(0.0, 1.0, 1.0)) * 2.0 - 1.0, f - vec3(0.0, 1.0, 1.0));
    float n111 = dot(hash33Stable(cell + vec3(1.0, 1.0, 1.0)) * 2.0 - 1.0, f - vec3(1.0, 1.0, 1.0));

    float x00 = mix(n000, n100, u.x);
    float x10 = mix(n010, n110, u.x);
    float x01 = mix(n001, n101, u.x);
    float x11 = mix(n011, n111, u.x);

    return mix(mix(x00, x10, u.y), mix(x01, x11, u.y), u.z);
}

float fbm3D(vec3 p, int octaves, float lacunarity, float gain) {
    float sum = 0.0;
    float amplitude = 1.0;
    float norm = 0.0;
    for (int i = 0; i < octaves; i++) {
        sum += gradientNoise3D(p) * amplitude;
        norm += amplitude;
        p *= lacunarity;
        amplitude *= gain;
    }
    return sum / max(norm, 1e-5);
}

// ridged variant, the sharp creases read as filaments in aurora and clouds
float ridgedFbm3D(vec3 p, int octaves, float lacunarity, float gain) {
    float sum = 0.0;
    float amplitude = 1.0;
    float norm = 0.0;
    for (int i = 0; i < octaves; i++) {
        float n = 1.0 - abs(gradientNoise3D(p));
        n *= n;
        sum += n * amplitude;
        norm += amplitude;
        p *= lacunarity;
        amplitude *= gain;
    }
    return sum / max(norm, 1e-5);
}

/*  spatial transforms  */

// screen uv plus a depth in [0,1] back to view space
vec3 screenToView(vec2 uv, float depth, mat4 projectionInverse) {
    vec4 ndc = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 view = projectionInverse * ndc;
    return view.xyz / view.w;
}

// view space back to the [0,1] depth range the depth textures use
float viewToDepth(vec3 viewPos, mat4 projection) {
    vec4 clip = projection * vec4(viewPos, 1.0);
    return (clip.z / clip.w) * 0.5 + 0.5;
}

// eye space position to screen uv, used to reproject a point onto the screen
vec2 viewToScreen(vec3 viewPos, mat4 projection) {
    vec4 clip = projection * vec4(viewPos, 1.0);
    return (clip.xy / clip.w) * 0.5 + 0.5;
}

// standard perspective linearisation, valid for the Minecraft projection
float linearizeDepth(float depth, float nearPlane, float farPlane) {
    return (2.0 * nearPlane * farPlane) /
           (farPlane + nearPlane - (depth * 2.0 - 1.0) * (farPlane - nearPlane));
}

// distance along the view ray, which is what fog and volumetric passes want
float depthToViewDistance(float depth, mat4 projectionInverse) {
    vec3 viewPos = screenToView(vec2(0.5), depth, projectionInverse);
    return -viewPos.z;
}

// direction from the eye through a screen pixel
vec3 screenToViewDirection(vec2 uv, mat4 projectionInverse) {
    return normalize(screenToView(uv, 1.0, projectionInverse));
}

// reconstruct a world space position from a screen pixel and its depth
vec3 screenToWorld(vec2 uv, float depth, mat4 projectionInverse, mat4 modelViewInverse) {
    vec3 viewPos = screenToView(uv, depth, projectionInverse);
    return (modelViewInverse * vec4(viewPos, 1.0)).xyz;
}

// eye relative position back to world space, accounting for camera movement
vec3 viewToWorld(vec3 viewPos, mat4 modelViewInverse) {
    return (modelViewInverse * vec4(viewPos, 1.0)).xyz;
}

/*  sampling helpers  */

// normals travel through the gbuffer as unsigned values
vec3 encodeNormal(vec3 n) {
    return n * 0.5 + 0.5;
}

vec3 decodeNormal(vec3 encoded) {
    return normalize(encoded * 2.0 - 1.0);
}

// window space depth back to the view space distance along the view axis
float viewDistanceFromDepth(float depth, mat4 projectionInverse) {
    vec3 viewPos = screenToView(vec2(0.5), depth, projectionInverse);
    return -viewPos.z;
}

// keeps a blur kernel from smearing across a depth discontinuity
float depthWeight(float centerDepth, float sampleDepth, float scale) {
    return exp2(-abs(centerDepth - sampleDepth) * scale);
}

vec2 snapToTexel(vec2 uv, vec2 texelSize, float scale) {
    return floor(uv / texelSize / scale) * texelSize * scale;
}

#endif
