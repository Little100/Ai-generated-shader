#version 330 compatibility

// Bloom bright pass with horizontal blur, stored in the lower-left quarter of colortex6

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 outColor;

vec3 brightPass(vec2 uv) {
    vec3 c = texture(colortex0, uv).rgb;
    float l = luminance(c);
    float k = smoothstep(0.65, 2.2, l);
    return c * k;
}

void main() {
    if (texcoord.x > 0.25 || texcoord.y > 0.25) discard;
    #ifndef BLOOM
    outColor = vec4(0.0);
    return;
    #endif
    vec2 uv = texcoord * 4.0;
    vec2 px = vec2(1.0 / viewWidth, 0.0) * 4.0;
    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++) {
        float w = exp(-float(i * i) / 14.0);
        sum += brightPass(saturate(uv + px * float(i) * 1.5)) * w;
        wsum += w;
    }
    outColor = vec4(sum / wsum, 1.0);
}
