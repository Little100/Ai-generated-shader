#version 120
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 vColor;
varying vec3 vNormal;

void main() {
    gl_Position = ftransform();
    vColor = gl_Color;
    vNormal = normalize(gl_NormalMatrix * gl_Normal);
}
