#version 330 compatibility

/*
    Vertical half of the bloom blur, writing back into the first bloom buffer so
    the finished glow lives in colortex6.
*/

#include "/lib/buffers.glsl"
#include "/lib/post.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 outBloom;

uniform sampler2D colortex7;

void main() {
    vec2 texel = 4.0 / vec2(viewWidth, viewHeight);

    vec3 sum = texture(colortex7, texcoord).rgb * 0.2270270270;
    sum += texture(colortex7, texcoord + vec2(0.0, texel.y) * 1.0).rgb * 0.1945945946;
    sum += texture(colortex7, texcoord - vec2(0.0, texel.y) * 1.0).rgb * 0.1945945946;
    sum += texture(colortex7, texcoord + vec2(0.0, texel.y) * 2.0).rgb * 0.1216216216;
    sum += texture(colortex7, texcoord - vec2(0.0, texel.y) * 2.0).rgb * 0.1216216216;
    sum += texture(colortex7, texcoord + vec2(0.0, texel.y) * 3.0).rgb * 0.0540540541;
    sum += texture(colortex7, texcoord - vec2(0.0, texel.y) * 3.0).rgb * 0.0540540541;
    sum += texture(colortex7, texcoord + vec2(0.0, texel.y) * 4.0).rgb * 0.0162162162;
    sum += texture(colortex7, texcoord - vec2(0.0, texel.y) * 4.0).rgb * 0.0162162162;

    outBloom = vec4(sum, 1.0);
}
