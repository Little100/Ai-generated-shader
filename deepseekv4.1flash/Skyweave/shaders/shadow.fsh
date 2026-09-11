#version 330 compatibility

/*
    Shadow pass. Only the depth buffer matters, so this does nothing beyond the
    cutout test. Translucent geometry is deliberately excluded so water and
    glass do not cast solid shadows.
*/

#include "/lib/buffers.glsl"
#include "/lib/uniforms.glsl"

in vec2 texcoord;
in vec4 tint;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 shadowColor;

void main() {
    vec4 color = texture(gtexture, texcoord) * tint;
    if (color.a < alphaTestRef) {
        discard;
    }
    shadowColor = vec4(1.0);
}
