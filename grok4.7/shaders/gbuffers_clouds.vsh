#version 120
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec2 vUv;
varying vec4 vColor;

void main() {
    gl_Position = ftransform();
    vUv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;
}
