#version 120
/* RENDERTARGETS: 0,8 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/water.glsl"

varying vec4 vColor;
varying vec3 vNormal;

void main() {
    vec3 n = normalize(vNormal);
    vec3 scatter = waterScatterColor();
    gl_FragData[0] = vec4(scatter * 0.45, 0.55);
    gl_FragData[1] = vec4(1.0);
}
