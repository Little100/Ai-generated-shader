#version 120
/* RENDERTARGETS: 0 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D gtexture;

varying vec2 vUv;
varying vec4 vColor;

void main() {
    vec4 tex = texture2D(gtexture, vUv);
    vec3 col = vec3(0.55, 0.35, 0.85) * tex.r * (0.6 + 0.4 * sin(K_TIME * 3.0 + vUv.x * 12.0));
    gl_FragData[0] = vec4(col, tex.a * 0.65);
}
