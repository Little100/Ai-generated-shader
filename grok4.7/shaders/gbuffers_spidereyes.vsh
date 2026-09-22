#version 120
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 vColor;

void main() {
    gl_Position = ftransform();
    vColor = gl_Color;
}
