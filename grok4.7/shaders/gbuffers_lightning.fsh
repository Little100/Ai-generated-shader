#version 120
/* RENDERTARGETS: 0 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 vColor;

void main() {
    vec3 col = vec3(0.75, 0.85, 1.0) * (3.0 + thunderStrength * 4.0);
    gl_FragData[0] = vec4(col * vColor.rgb, vColor.a);
}
