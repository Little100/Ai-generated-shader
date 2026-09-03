#version 330 compatibility
#define DIM_NETHER

// Final grade: godrays, bloom, filmic tonemap, color grading, vignette and grain

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/sky.glsl"

in vec2 texcoord;

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA8;
const int colortex2Format = RGB10_A2;
const int colortex3Format = RGBA8;
const int colortex4Format = RGBA16F;
const int colortex5Format = R11F_G11F_B10F;
const int colortex6Format = R11F_G11F_B10F;
const bool colortex3Clear = true;
const vec4 colortex3ClearColor = vec4(0.5, 0.5, 0.0, 0.0);
const bool colortex4Clear = true;
const vec4 colortex4ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
*/

layout(location = 0) out vec4 outColor;

// Custom S-curve with a gentle toe so nights keep their blacks without crushing
vec3 tonemap(vec3 x) {
    x = max(x, 0.0);
    vec3 a = x * (x * 1.6 + 0.05);
    vec3 b = x * (x * 1.4 + 0.6) + 0.14;
    return saturate(a / b);
}

vec3 grade(vec3 c) {
    float l = luminance(c);
    c = mix(vec3(l), c, SATURATION);
    c = mix(c, smoothstep(0.0, 1.0, c), CONTRAST * 0.35);
    // Split tone: cool shadows, warm highlights
    vec3 shadowTint = vec3(0.97, 0.99, 1.04);
    vec3 highTint = vec3(1.03, 1.0, 0.96);
    c *= mix(shadowTint, highTint, smoothstep(0.1, 0.8, l));
    return c;
}

vec3 sampleQuarter(sampler2D tex, vec2 uv) {
    vec2 q = uv * 0.25;
    q = clamp(q, vec2(0.5 / viewWidth, 0.5 / viewHeight), vec2(0.25) - vec2(1.5 / viewWidth, 1.5 / viewHeight));
    return texture(tex, q).rgb;
}

void main() {
    vec3 color = texture(colortex0, texcoord).rgb;

    #ifdef GODRAYS
    color += sampleQuarter(colortex5, texcoord);
    #endif
    #ifdef BLOOM
    vec3 bloom = sampleQuarter(colortex6, texcoord);
    color += bloom * BLOOM_STRENGTH;
    #endif

    // Exposure follows how much sky the eye sees so caves darken and daylight stays controlled
    float eyeSky = float(eyeBrightnessSmooth.y) / 240.0;
    float eyeBlock = float(eyeBrightnessSmooth.x) / 240.0;
    #if defined DIM_NETHER || defined DIM_END
    float auto = 1.35;
    #else
    float auto = mix(1.9, 0.75, smoothstep(0.0, 1.0, eyeSky));
    auto = mix(auto, min(auto, 1.3), eyeBlock * 0.5);
    vec3 sunDir = sunDirWorld();
    auto *= mix(1.8, 1.0, dayFactor(sunDir));
    #endif
    color *= EXPOSURE * auto * mix(0.9, 1.15, screenBrightness);

    color = tonemap(color);
    color = grade(color);
    color = linearToSrgb(color);

    #ifdef VIGNETTE
    vec2 v = texcoord * 2.0 - 1.0;
    color *= 1.0 - dot(v, v) * 0.18;
    #endif
    #ifdef FILM_GRAIN
    float g = hash12(gl_FragCoord.xy + fract(frameTimeCounter) * 971.0) - 0.5;
    color += g * GRAIN_STRENGTH * (1.0 - luminance(color) * 0.6);
    #endif

    outColor = vec4(saturate(color), 1.0);
}
