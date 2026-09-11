#version 330 compatibility

/*
    Horizontal half of the bloom blur. Nine taps on binomial weights give a
    smooth falloff without needing a second mip level.
*/

#include "/lib/buffers.glsl"
#include "/lib/post.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 7 */
layout(location = 0) out vec4 outBloom;

uniform sampler2D colortex6;

void main() {
    vec2 texel = 4.0 / vec2(viewWidth, viewHeight);

    vec3 sum = texture(colortex6, texcoord).rgb * 0.2270270270;
    sum += texture(colortex6, texcoord + vec2(texel.x, 0.0) * 1.0).rgb * 0.1945945946;
    sum += texture(colortex6, texcoord - vec2(texel.x, 0.0) * 1.0).rgb * 0.1945945946;
    sum += texture(colortex6, texcoord + vec2(texel.x, 0.0) * 2.0).rgb * 0.1216216216;
    sum += texture(colortex6, texcoord - vec2(texel.x, 0.0) * 2.0).rgb * 0.1216216216;
    sum += texture(colortex6, texcoord + vec2(texel.x, 0.0) * 3.0).rgb * 0.0540540541;
    sum += texture(colortex6, texcoord - vec2(texel.x, 0.0) * 3.0).rgb * 0.0540540541;
    sum += texture(colortex6, texcoord + vec2(texel.x, 0.0) * 4.0).rgb * 0.0162162162;
    sum += texture(colortex6, texcoord - vec2(texel.x, 0.0) * 4.0).rgb * 0.0162162162;

    outBloom = vec4(sum, 1.0);
}
