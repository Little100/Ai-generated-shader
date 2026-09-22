#version 120
/* RENDERTARGETS: 0 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 vColor;

void main() {
    gl_FragData[0] = vec4(vColor.rgb, vColor.a);
}
