#version 120
/* RENDERTARGETS: 0 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D gtexture;

varying vec2 vUv;
varying vec4 vColor;
varying vec3 vViewPos;

void main() {
    vec4 tex = texture2D(gtexture, vUv);
    if (tex.a < 0.02) {
        discard;
    }
    float dist = length(vViewPos);
    float streak = pow(saturate(1.0 - abs(vUv.y * 2.0 - 1.0)), 1.5);
    vec3 col = mix(vec3(0.62, 0.68, 0.75), vec3(0.85, 0.9, 0.95), 1.0 - rainStrength);
    float alpha = tex.a * vColor.a * streak * 0.45 * exp(-dist * 0.02);
    gl_FragData[0] = vec4(col * (0.35 + rainStrength * 0.4), alpha);
}
