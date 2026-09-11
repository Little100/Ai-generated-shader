#version 330 compatibility

/*
    Bright pass at half resolution. The four taps cover a full resolution two by
    two block exactly once, so this is a clean box downsample rather than a
    point sample.
*/

#include "/lib/buffers.glsl"
#include "/lib/post.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 8 */
layout(location = 0) out vec4 outBloom;

uniform sampler2D colortex0;

void main() {
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);

    vec3 sum = texture(colortex0, texcoord).rgb * 0.5;
    sum += texture(colortex0, texcoord + vec2(texel.x, texel.y) * 0.5).rgb * 0.125;
    sum += texture(colortex0, texcoord + vec2(-texel.x, texel.y) * 0.5).rgb * 0.125;
    sum += texture(colortex0, texcoord + vec2(texel.x, -texel.y) * 0.5).rgb * 0.125;
    sum += texture(colortex0, texcoord + vec2(-texel.x, -texel.y) * 0.5).rgb * 0.125;

    outBloom = vec4(brightPass(sum), 1.0);
}
