#version 120
#define KILN_COMPOSITE
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;

varying vec2 texcoord;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
