#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/color.glsl"

// ==============================================================================
// Aetheria: Final Post-Processing Pass Fragment Shader
// Performs chromatic aberration, bloom composition, ACES filmic tonemapping,
// color grading, vignette, and gamma correction before display.
// ==============================================================================

uniform sampler2D colortex0; // Shaded scene color
uniform sampler2D colortex3; // Blurred atmospheric bloom

in vec2 texCoord;

void main() {
    vec3 sceneColor;

#ifdef CHROMATIC_ABERRATION
    // Subtle radial chromatic aberration at screen periphery
    vec2 centerOffset = texCoord - 0.5;
    float distSq = dot(centerOffset, centerOffset);
    vec2 caOffset = centerOffset * distSq * 0.0055;

    float r = texture(colortex0, texCoord + caOffset).r;
    float g = texture(colortex0, texCoord).g;
    float b = texture(colortex0, texCoord - caOffset).b;
    sceneColor = vec3(r, g, b);
#else
    sceneColor = texture(colortex0, texCoord).rgb;
#endif

#if BLOOM_QUALITY > 0
    // Blend atmospheric bloom glow into HDR color
    vec3 bloomColor = texture(colortex3, texCoord).rgb;
    float bloomWeight = float(BLOOM_QUALITY) * 0.12;
    sceneColor += bloomColor * bloomWeight;
#endif

    // Apply master tone mapping curve (ACES Filmic by default)
    vec3 toneMappedColor = applyToneMapping(sceneColor);

    // Apply color saturation grading
    vec3 gradedColor = adjustSaturation(toneMappedColor, SATURATION);

#ifdef VIGNETTE
    // Natural lens vignetting
    gradedColor = applyVignette(gradedColor, texCoord);
#endif

    // Gamma correction
    vec3 finalColor = linearTosRGB(gradedColor);

    gl_FragColor = vec4(finalColor, 1.0);
}
