#version 120
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec2 texcoord;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
