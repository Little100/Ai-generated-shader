#version 120
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec2 vUv;
varying vec4 vColor;
varying vec3 vViewPos;

void main() {
    gl_Position = ftransform();
    vUv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vColor = gl_Color;
    vViewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
}
