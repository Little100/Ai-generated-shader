#ifndef TIDELUME_MATH
#define TIDELUME_MATH
const float TL_PI = 3.14159265359;
const float TL_TAU = 6.28318530718;
float sat(float a) { return clamp(a, 0.0, 1.0); }
vec2 sat(vec2 a) { return clamp(a, 0.0, 1.0); }
vec3 sat(vec3 a) { return clamp(a, 0.0, 1.0); }
float sq(float x) { return x * x; }
float luminance(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }
vec3 safeNormalize(vec3 v) { return v * inversesqrt(max(dot(v,v), 1e-12)); }
vec3 toLinear(vec3 c) { return pow(max(c, vec3(0.0)), vec3(2.2)); }
vec3 toDisplay(vec3 c) { return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2)); }
// Integer mixing is deterministic across frames, and avoids sine-hash banding.
uint mixBits(uint n) {
    n ^= n >> 16u; n *= 2146121005u;
    n ^= n >> 15u; n *= 2221713035u;
    return n ^ (n >> 16u);
}
float hash21(vec2 p) {
    uvec2 q = uvec2(ivec2(floor(p)));
    return float(mixBits(q.x ^ mixBits(q.y + 173u))) / 4294967295.0;
}
float valueNoise2(vec2 p) {
    vec2 cell = floor(p), f = fract(p);
    vec2 w = f*f*(3.0 - 2.0*f);
    return mix(mix(hash21(cell), hash21(cell+vec2(1,0)), w.x),
               mix(hash21(cell+vec2(0,1)), hash21(cell+vec2(1,1)), w.x), w.y);
}
float cloudNoise(vec2 p) {
    mat2 turn = mat2(0.83, 0.56, -0.56, 0.83);
    float n = valueNoise2(p) * 0.57;
    p = turn*p*2.13 + vec2(13.7, 2.1);
    n += valueNoise2(p)*0.28;
    p = turn*p*2.07 + vec2(3.2, 17.8);
    return n + valueNoise2(p)*0.15;
}
vec3 screenToView(vec2 uv, float depth) {
    vec4 p = gbufferProjectionInverse * vec4(uv*2.0-1.0, depth*2.0-1.0, 1.0);
    return p.xyz / max(p.w, 1e-7);
}
vec3 viewToPlayer(vec3 p) { return (gbufferModelViewInverse * vec4(p,1.0)).xyz; }
vec3 cameraOrigin() { return gbufferModelViewInverse[3].xyz; }
vec3 viewRay(vec2 uv) { return safeNormalize(mat3(gbufferModelViewInverse)*screenToView(uv, 1.0)); }
vec3 sunDirection() { return safeNormalize(mat3(gbufferModelViewInverse)*sunPosition); }
vec3 lightDirection() { return safeNormalize(mat3(gbufferModelViewInverse)*shadowLightPosition); }
float daylight() { return smoothstep(-0.10, 0.18, sunDirection().y); }
float skyAccess() { return sat(float(eyeBrightnessSmooth.y)/240.0); }
vec2 pixelSize() { return 1.0 / max(vec2(viewWidth,viewHeight), vec2(1.0)); }
#endif
