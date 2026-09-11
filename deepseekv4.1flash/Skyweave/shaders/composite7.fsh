#version 330 compatibility

/*
    Mirrors the exposure across so both single texel buffers carry this frame's
    value. Like the measurement pass, this renders one fragment.
*/

#include "/lib/buffers.glsl"
#include "/lib/post.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 outExposure;

uniform sampler2D colortex9;

void main() {
    outExposure = vec4(texture(colortex9, vec2(0.5)).r, 0.0, 0.0, 1.0);
}
