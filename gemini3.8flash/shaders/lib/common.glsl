#ifndef AETHERIA_COMMON_GLSL
#define AETHERIA_COMMON_GLSL

// ==============================================================================
// Aetheria: Common Mathematical Functions, Projections, and Coordinate Transforms
// ==============================================================================

const float PI = 3.14159265358979323846;
const float TWO_PI = 6.28318530717958647692;
const float HALF_PI = 1.57079632679489661923;

// Fast analytical pseudo-random hash functions
float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
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

// Smooth 2D Value Noise with quintic Hermite interpolation
float valueNoise2D(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float a = hash21(i + vec2(0.0, 0.0));
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 2D Fractal Brownian Motion (FBM)
float fbm2D(vec2 p) {
    float total = 0.0;
    float amp = 0.5;
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
    for (int i = 0; i < 4; ++i) {
        total += amp * valueNoise2D(p);
        p = rot * p * 2.02;
        amp *= 0.5;
    }
    return total;
}

// Linearize perspective depth buffer value (0..1) into view distance
float linearizeDepth(float depth, float nearVal, float farVal) {
    return (2.0 * nearVal * farVal) / (farVal + nearVal - (depth * 2.0 - 1.0) * (farVal - nearVal));
}

// Reconstruct view space position from screen UV (0..1) and raw hardware depth (0..1)
vec3 screenToView(vec2 uv, float depth, mat4 projInv) {
    vec4 clipPos = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 viewPos = projInv * clipPos;
    return viewPos.xyz / viewPos.w;
}

// Transform view space position to player feet space
vec3 viewToPlayer(vec3 viewPos, mat4 modelViewInv) {
    vec4 playerPos = modelViewInv * vec4(viewPos, 1.0);
    return playerPos.xyz;
}

// Transform player feet space position to world space
vec3 playerToWorld(vec3 playerPos, vec3 camPos) {
    return playerPos + camPos;
}

// Transform player feet space position to shadow screen coordinate (0..1 UV and depth)
vec3 playerToShadowScreen(vec3 playerPos, mat4 sModelView, mat4 sProj) {
    vec4 shadowViewPos = sModelView * vec4(playerPos, 1.0);
    vec4 shadowClipPos = sProj * shadowViewPos;
    vec3 shadowNDC = shadowClipPos.xyz / max(shadowClipPos.w, 0.0001);
    return shadowNDC * 0.5 + 0.5;
}

// 8-tap Poisson disk distribution for soft contact shadow filtering
const vec2 poissonDisk[16] = vec2[](
    vec2(-0.326212, -0.405810),
    vec2(-0.840144, -0.073580),
    vec2(-0.695914,  0.457137),
    vec2(-0.203345,  0.620716),
    vec2( 0.962340, -0.194983),
    vec2( 0.473434, -0.480026),
    vec2( 0.519456,  0.767022),
    vec2( 0.185461, -0.893124),
    vec2( 0.507431,  0.064425),
    vec2( 0.896420,  0.412458),
    vec2(-0.321940, -0.932615),
    vec2(-0.791559, -0.597710),
    vec2(-0.024240,  0.165410),
    vec2( 0.386510,  0.373110),
    vec2(-0.521450, -0.124510),
    vec2( 0.142510, -0.362140)
);

#endif // AETHERIA_COMMON_GLSL
