#version 120
/* RENDERTARGETS: 0,1,2,3 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/material.glsl"

uniform sampler2D gtexture;

varying vec2 vUv;
varying vec2 vLm;
varying vec4 vColor;
varying vec3 vNormal;
varying float vAo;
flat varying int vId;

void main() {
    vec4 albedoTex = texture2D(gtexture, vUv);
    if (albedoTex.a < 0.1) {
        discard;
    }
    vec3 albedo = srgbToLinear(albedoTex.rgb * vColor.rgb);
    Material m = makeMaterial(albedo, normalize(vNormal), vUv, 0, 1.0);
    float held = float(heldBlockLightValue) / 15.0;
    vec3 lit = m.albedo * (0.18 + held * held * blockLightColor() * K_TORCH_INTENSITY);
    lit += m.albedo * m.emission * 2.5;
    gl_FragData[0] = vec4(lit, 1.0);
    gl_FragData[1] = vec4(m.albedo, 0.0);
    gl_FragData[2] = vec4(encodeNormal(m.normal), m.roughness, m.metal);
    gl_FragData[3] = vec4(m.emission, 0.0, 1.0, 1.0);
}
