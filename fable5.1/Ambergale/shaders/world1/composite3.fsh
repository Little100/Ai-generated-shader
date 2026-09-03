#version 330 compatibility
#define DIM_END

// Vertical bloom blur over the quarter-resolution region of colortex6

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 outColor;

void main() {
    if (texcoord.x > 0.25 || texcoord.y > 0.25) discard;
    #ifndef BLOOM
    outColor = vec4(0.0);
    return;
    #endif
    vec2 px = vec2(0.0, 1.0 / viewHeight);
    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++) {
        float w = exp(-float(i * i) / 14.0);
        vec2 uv = texcoord + px * float(i) * 1.5;
        uv = clamp(uv, vec2(0.0), vec2(0.25 - 1.0 / viewWidth, 0.25 - 1.0 / viewHeight));
        sum += texture(colortex6, uv).rgb * w;
        wsum += w;
    }
    outColor = vec4(sum / wsum, 1.0);
}
