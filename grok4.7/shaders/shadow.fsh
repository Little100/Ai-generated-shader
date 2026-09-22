#version 120
/* RENDERTARGETS: 0 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/material.glsl"

uniform sampler2D tex;

varying vec2 vUv;
varying vec4 vColor;
flat varying int vId;

void main() {
    vec4 albedo = texture2D(tex, vUv);
    if (albedo.a < 0.1 && vId != ID_WATER) {
        discard;
    }
    float alpha = vId == ID_WATER ? 0.35 : albedo.a;
    vec3 tint = srgbToLinear(albedo.rgb * vColor.rgb);
    if (vId == ID_WATER) {
        tint = waterScatterColor();
        alpha = 0.45;
    } else if (vId == ID_LEAVES || vId == ID_GRASS) {
        alpha *= 0.55;
    }
    gl_FragData[0] = vec4(tint, alpha);
}
