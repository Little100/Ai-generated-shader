/*
    Skyweave - colour spaces, tone curves and grading.

    The whole pipeline keeps linear light in the colour buffers and only encodes
    to sRGB at the very end, so every multiply along the way behaves like real
    light rather than like a display value.
*/

#if !defined(SKYWEAVE_COLOR_INCLUDED)
#define SKYWEAVE_COLOR_INCLUDED

#include "/lib/math.glsl"
#include "/lib/config.glsl"

vec3 srgbToLinear(vec3 c) {
    vec3 low = c / 12.92;
    vec3 high = pow((c + 0.055) / 1.055, vec3(2.4));
    return mix(low, high, step(vec3(0.04045), c));
}

vec3 linearToSrgb(vec3 c) {
    c = max(c, vec3(0.0));
    vec3 low = c * 12.92;
    vec3 high = 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055;
    return mix(low, high, step(vec3(0.0031308), c));
}

float srgbToLinear(float c) {
    return c < 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}

/*  tone curves  */

// stephen hill's fit of the aces rrt and odt, the industry baseline
vec3 acesFitted(vec3 color) {
    const mat3 inputMatrix = mat3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777
    );
    const mat3 outputMatrix = mat3(
         1.60475, -0.10208, -0.00327,
        -0.53108,  1.10813, -0.07276,
        -0.07367, -0.00605,  1.07602
    );

    color = inputMatrix * color;
    vec3 a = color * (color + 0.0245786) - 0.000090537;
    vec3 b = color * (0.983729 * color + 0.4329510) + 0.238081;
    color = a / b;
    color = outputMatrix * color;
    return saturate(color);
}

// the compact agx approximation, noticeably better at holding highlights
vec3 agxContrastApprox(vec3 x) {
    vec3 x2 = x * x;
    vec3 x4 = x2 * x2;
    return 15.5 * x4 * x2
         - 40.14 * x4 * x
         + 31.96 * x4
         - 6.868 * x2 * x
         + 0.4298 * x2
         + 0.1191 * x
         - 0.00232;
}

vec3 agxToneMap(vec3 color) {
    const mat3 agxInput = mat3(
        0.842479062253094, 0.0423282422610123, 0.0423756549057051,
        0.0784335999999992, 0.878468636469772, 0.0784336,
        0.0792237451477643, 0.0791661274605434, 0.879142973793104
    );
    const mat3 agxOutput = mat3(
         1.19687900512017, -0.0528968517574562, -0.0529716355144438,
        -0.0980208811401368,  1.15190312990417, -0.0980434501171241,
        -0.0990297440797205, -0.0989611768448433,  1.15107367264116
    );

    const float minEv = -12.47393;
    const float maxEv = 4.026069;

    color = agxInput * max(color, vec3(0.0));
    color = log2(max(color, vec3(1e-10)));
    color = (color - minEv) / (maxEv - minEv);
    color = agxContrastApprox(saturate(color));
    color = agxOutput * color;
    return saturate(color);
}

// the uncharted 2 curve, still the most filmic looking of the three
vec3 unchartedCurve(vec3 x) {
    const float a = 0.15;
    const float b = 0.50;
    const float c = 0.10;
    const float d = 0.20;
    const float e = 0.02;
    const float f = 0.30;
    return ((x * (a * x + c * b) + d * e) / (x * (a * x + b) + d * f)) - e / f;
}

vec3 filmicToneMap(vec3 color) {
    const float exposureBias = 2.0;
    const float whitePoint = 11.2;
    vec3 curved = unchartedCurve(color * exposureBias);
    vec3 white = unchartedCurve(vec3(whitePoint));
    return saturate(curved / white);
}

vec3 toneMap(vec3 color) {
#if TONEMAP == 0
    return acesFitted(color);
#elif TONEMAP == 2
    return filmicToneMap(color);
#elif TONEMAP == 3
    return saturate(color);
#else
    return agxToneMap(color);
#endif
}

/*  grading  */

vec3 rgbToHsv(vec3 c) {
    vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}

vec3 hsvToRgb(vec3 c) {
    vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
    return c.z * mix(k.xxx, saturate(p - k.xxx), c.y);
}

// saturation applied around the luminance axis so greys stay put
vec3 applySaturation(vec3 color, float amount) {
    float grey = luminance(color);
    return mix(vec3(grey), color, amount);
}

// contrast pivoting on middle grey, matching how a graded print behaves
vec3 applyContrast(vec3 color, float amount) {
    const float pivot = 0.18;
    return max(vec3(0.0), (color - pivot) * amount + pivot);
}

// cools the shadows and warms the highlights, the classic teal and orange look
vec3 splitTone(vec3 color, float amount) {
    float weight = saturate(luminance(color) * 3.0);
    vec3 shadowTint = vec3(0.90, 0.98, 1.10);
    vec3 highlightTint = vec3(1.06, 1.01, 0.94);
    vec3 tint = mix(shadowTint, highlightTint, weight);
    return mix(color, color * tint, amount);
}

// a gentle shoulder that keeps very bright pixels from clipping to flat white
vec3 highlightRolloff(vec3 color) {
    return color / (1.0 + max(vec3(0.0), color - 1.0) * 0.35);
}

vec3 applyGrade(vec3 color) {
    color = applyContrast(color, CONTRAST);
    color = applySaturation(color, SATURATION);
    color = splitTone(color, 0.35);
    color = highlightRolloff(color);
    return color;
}

/*  screen effects  */

float vignetteFactor(vec2 uv, float amount) {
    vec2 centered = uv - 0.5;
    centered.x *= aspectRatio;
    float radius = length(centered) * 1.35;
    return mix(1.0, 1.0 - amount, smoothstep(0.35, 1.15, radius));
}

// grain that reseeds every frame so it reads as film rather than as noise
vec3 filmGrain(vec2 uv, float amount) {
    if (amount <= 0.0) {
        return vec3(1.0);
    }
    float seed = hash12(uv * vec2(viewWidth, viewHeight) + float(frameCounter) * 17.13);
    return vec3(1.0 + (seed - 0.5) * amount * 0.25);
}

#endif
