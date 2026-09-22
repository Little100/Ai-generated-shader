#version 120
/* RENDERTARGETS: 0 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/material.glsl"

uniform sampler2D gtexture;

varying vec2 vUv;
varying vec4 vColor;
varying vec3 vNormal;
varying vec3 vViewPos;

void main() {
    vec4 albedoTex = texture2D(gtexture, vUv);
    if (albedoTex.a < 0.02) {
        discard;
    }
    vec3 albedo = srgbToLinear(albedoTex.rgb * vColor.rgb);
    float fresnel = fresnelSchlick(saturate(dot(normalize(vNormal), normalize(-vViewPos))), vec3(0.04)).r;
    gl_FragData[0] = vec4(albedo * (0.2 + fresnel), albedoTex.a * 0.65 + fresnel * 0.2);
}
