#version 330 compatibility

/*
    Quarter resolution step of the bloom chain. The source is half resolution,
    so one source texel is two full resolution texels across.
*/

#include "/lib/buffers.glsl"
#include "/lib/post.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 outBloom;

uniform sampler2D colortex8;

void main() {
    vec2 texel = 2.0 / vec2(viewWidth, viewHeight);

    vec3 sum = texture(colortex8, texcoord).rgb * 0.5;
    sum += texture(colortex8, texcoord + vec2(texel.x, texel.y) * 0.5).rgb * 0.125;
    sum += texture(colortex8, texcoord + vec2(-texel.x, texel.y) * 0.5).rgb * 0.125;
    sum += texture(colortex8, texcoord + vec2(texel.x, -texel.y) * 0.5).rgb * 0.125;
    sum += texture(colortex8, texcoord + vec2(-texel.x, -texel.y) * 0.5).rgb * 0.125;

    outBloom = vec4(sum, 1.0);
}
