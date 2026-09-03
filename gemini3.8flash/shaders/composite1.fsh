#version 330 compatibility

/* RENDERTARGETS: 3 */

#include "/lib/settings.glsl"

// ==============================================================================
// Aetheria: Secondary Composite Pass Fragment Shader (Bloom Diffusion)
// Performs a wide multi-tap blurred convolution of extracted highlights
// ==============================================================================

uniform sampler2D colortex3;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texCoord;

void main() {
#if BLOOM_QUALITY == 0
    gl_FragData[0] = vec4(0.0);
    return;
#else
    vec2 texelSize = vec2(1.0 / max(viewWidth, 1.0), 1.0 / max(viewHeight, 1.0));
    float spread = float(BLOOM_QUALITY) * 2.5;

    // 13-tap tent filter kernel for smooth atmospheric diffusion
    vec3 bloom = texture(colortex3, texCoord).rgb * 4.0;

    bloom += texture(colortex3, texCoord + vec2(-1.0, -1.0) * texelSize * spread).rgb * 1.0;
    bloom += texture(colortex3, texCoord + vec2( 0.0, -1.0) * texelSize * spread).rgb * 2.0;
    bloom += texture(colortex3, texCoord + vec2( 1.0, -1.0) * texelSize * spread).rgb * 1.0;

    bloom += texture(colortex3, texCoord + vec2(-1.0,  0.0) * texelSize * spread).rgb * 2.0;
    bloom += texture(colortex3, texCoord + vec2( 1.0,  0.0) * texelSize * spread).rgb * 2.0;

    bloom += texture(colortex3, texCoord + vec2(-1.0,  1.0) * texelSize * spread).rgb * 1.0;
    bloom += texture(colortex3, texCoord + vec2( 0.0,  1.0) * texelSize * spread).rgb * 2.0;
    bloom += texture(colortex3, texCoord + vec2( 1.0,  1.0) * texelSize * spread).rgb * 1.0;

    // Additional wide samples for soft atmospheric halo
    bloom += texture(colortex3, texCoord + vec2(-2.0, 0.0) * texelSize * spread * 1.8).rgb * 0.75;
    bloom += texture(colortex3, texCoord + vec2( 2.0, 0.0) * texelSize * spread * 1.8).rgb * 0.75;
    bloom += texture(colortex3, texCoord + vec2(0.0, -2.0) * texelSize * spread * 1.8).rgb * 0.75;
    bloom += texture(colortex3, texCoord + vec2(0.0,  2.0) * texelSize * spread * 1.8).rgb * 0.75;

    bloom /= 20.0;

    gl_FragData[0] = vec4(bloom, 1.0);
#endif
}
