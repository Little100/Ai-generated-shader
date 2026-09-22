#version 120
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec2 vUv;
varying vec2 vLm;
varying vec4 vColor;
varying vec3 vNormal;

void main() {
    gl_Position = ftransform();
    vUv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vLm = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
    vNormal = normalize(gl_NormalMatrix * gl_Normal);
}
