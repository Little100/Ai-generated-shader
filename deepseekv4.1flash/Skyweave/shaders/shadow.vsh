#version 330 compatibility

/*
    Shadow pass. Only the depth buffer is written, but the warp has to be
    applied here as well as in the lookup, otherwise fragments sample texels
    that were never written at the position they think they are.
*/

#include "/lib/shadow.glsl"

out vec2 texcoord;
out vec4 tint;

void main() {
    vec4 clip = ftransform();

    // the warp is defined on normalised device coordinates, and scaling the
    // clip space xy by the same factor has the same effect after the divide
    float radius = length(clip.xy / clip.w);
    if (radius > 1e-5) {
        clip.xy *= warpRadius(radius) / radius;
    }

    gl_Position = clip;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    tint = gl_Color;
}
