#version 120
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 vColor;
varying vec3 vViewPos;

void main() {
    gl_Position = ftransform();
    vColor = gl_Color;
    vViewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
}
