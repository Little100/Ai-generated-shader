#version 120
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 vColor;
varying vec3 vNormal;
varying vec2 vUv;

void main() {
    gl_Position = ftransform();
    vColor = gl_Color;
    vNormal = normalize(gl_NormalMatrix * gl_Normal);
    vUv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
