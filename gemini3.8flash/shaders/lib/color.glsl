#ifndef AETHERIA_COLOR_GLSL
#define AETHERIA_COLOR_GLSL

#include "/lib/settings.glsl"

// ==============================================================================
// Aetheria: Color Space, Tone Mapping Curves, Optics and Color Grading
// ==============================================================================

// Fast sRGB to linear conversion
vec3 sRGBToLinear(vec3 color) {
    return pow(color, vec3(2.2));
}

// Fast linear to sRGB conversion
vec3 linearTosRGB(vec3 color) {
    return pow(color, vec3(1.0 / 2.2));
}

// Perceptual luminance calculation (Rec. 709)
float getLuminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

// ACES Filmic Tone Mapping (Krzysztof Narkowicz analytical approximation)
vec3 toneMapACES(vec3 color) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

// Smooth Reinhard-Jodie Tone Mapping with luminance preservation
vec3 toneMapReinhard(vec3 color) {
    float lum = getLuminance(color);
    vec3 tv = color / (1.0 + color);
    return mix(color / (1.0 + lum), tv, tv);
}

// Vibrant Fantasy Tone Mapping (High-contrast, glowing, dreamlike)
vec3 toneMapFantasy(vec3 color) {
    vec3 aces = toneMapACES(color * 1.15);
    // Lift midtones, rich contrast
    return pow(aces, vec3(0.92));
}

// Master Tone Mapping Selector
vec3 applyToneMapping(vec3 hdrColor) {
#if TONE_MAPPING == 0
    return toneMapACES(hdrColor);
#elif TONE_MAPPING == 1
    return toneMapReinhard(hdrColor);
#else
    return toneMapFantasy(hdrColor);
#endif
}

// Adjust saturation while preserving luminance
vec3 adjustSaturation(vec3 color, float saturation) {
    float lum = getLuminance(color);
    return mix(vec3(lum), color, saturation);
}

// Optical Lens Vignette
vec3 applyVignette(vec3 color, vec2 uv) {
    vec2 coord = (uv - 0.5) * 2.0;
    float distSq = dot(coord, coord);
    float vignette = 1.0 - smoothstep(0.45, 1.45, distSq) * 0.42;
    return color * vignette;
}

#endif // AETHERIA_COLOR_GLSL
