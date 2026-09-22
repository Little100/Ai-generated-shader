#version 120
/* RENDERTARGETS: 0,1,2,3 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/material.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform int blockEntityId;

varying vec2 vUv;
varying vec2 vLm;
varying vec4 vColor;
varying vec3 vNormal;
varying vec3 vWorldPos;
varying float vAo;
flat varying int vId;

void main() {
    vec4 albedoTex = texture2D(gtexture, vUv);
    if (albedoTex.a < 0.1) {
        discard;
    }
    vec3 albedo = srgbToLinear(albedoTex.rgb * vColor.rgb);
    Material m = makeMaterial(albedo, normalize(vNormal), vUv, 0, vAo);
    float glow = 0.0;
    vec3 glowCol = albedo;
    if (blockEntityId == 16 || blockEntityId == 5) {
        glow = 1.0;
        glowCol = vec3(1.0, 0.62, 0.28);
    }
    vec3 lit = m.albedo * (0.03 + vLm.y * 0.05 * skyLightColor() + vLm.x * vLm.x * blockLightColor() * 0.35 * K_TORCH_INTENSITY);
    lit += glowCol * glow * 3.0 * K_TORCH_INTENSITY;
    gl_FragData[0] = vec4(lit, 0.0);
    gl_FragData[1] = vec4(m.albedo, float(blockEntityId) / 255.0);
    gl_FragData[2] = vec4(encodeNormal(m.normal), m.roughness, m.metal);
    gl_FragData[3] = vec4(max(m.emission, glow), 0.0, m.ao, vLm.y);
}
