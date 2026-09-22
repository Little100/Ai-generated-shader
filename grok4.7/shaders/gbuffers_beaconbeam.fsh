#version 120
/* RENDERTARGETS: 0 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 vColor;
varying vec3 vViewPos;

void main() {
    float dist = length(vViewPos);
    float fade = exp(-dist * 0.01);
    vec3 col = srgbToLinear(vColor.rgb) * (1.6 + fade);
    gl_FragData[0] = vec4(col, vColor.a * 0.55 * fade);
}
