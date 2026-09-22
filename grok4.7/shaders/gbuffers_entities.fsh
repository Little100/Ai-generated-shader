#version 120
/* RENDERTARGETS: 0,1,2,3 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/material.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform vec4 entityColor;
uniform int entityId;

varying vec2 vUv;
varying vec2 vLm;
varying vec4 vColor;
varying vec3 vViewPos;
varying vec3 vNormal;
varying vec3 vTangent;
varying float vAo;
flat varying int vId;

void main() {
    vec4 albedoTex = texture2D(gtexture, vUv);
    if (albedoTex.a < 0.1) {
        discard;
    }
    vec3 albedo = srgbToLinear(albedoTex.rgb * vColor.rgb);
    albedo = mix(albedo, entityColor.rgb, entityColor.a);
    vec3 n = normalize(vNormal);
    Material m = makeMaterial(albedo, n, vUv, 0, vAo);
    m.roughness = min(m.roughness, 0.55);

    float blockLight = max(vLm.x, float(heldBlockLightValue) / 15.0 * 0.35);
    float skyLight = vLm.y;
    vec3 lit = m.albedo * (0.045 + skyLight * 0.05 * skyLightColor() + blockLight * blockLight * blockLightColor() * 0.4 * K_TORCH_INTENSITY);
    lit += m.albedo * m.emission * 2.0;

    gl_FragData[0] = vec4(lit, 0.0);
    gl_FragData[1] = vec4(m.albedo, 0.0);
    gl_FragData[2] = vec4(encodeNormal(m.normal), m.roughness, m.metal);
    gl_FragData[3] = vec4(m.emission, 0.12, m.ao, skyLight);
}
