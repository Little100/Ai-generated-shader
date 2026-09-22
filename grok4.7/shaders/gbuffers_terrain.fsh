#version 120
/* RENDERTARGETS: 0,1,2,3 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/material.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;

varying vec2 vUv;
varying vec2 vLm;
varying vec4 vColor;
varying vec3 vViewPos;
varying vec3 vNormal;
varying vec3 vTangent;
varying vec3 vWorldPos;
varying float vAo;
flat varying int vId;

void main() {
    vec4 albedoTex = texture2D(gtexture, vUv);
    if (albedoTex.a < 0.1) {
        discard;
    }
    vec3 albedo = srgbToLinear(albedoTex.rgb * vColor.rgb);
    vec3 bitangent = normalize(cross(vNormal, vTangent));
    vec4 ntex = texture2D(normals, vUv);
    vec3 n = decodeNormalMap(ntex, normalize(vNormal), normalize(vTangent), bitangent);
    Material m = makeMaterial(albedo, n, vUv, vId, vAo);

    float blockLight = vLm.x;
    float skyLight = vLm.y;
    vec3 emission = m.albedo * m.emission * (3.5 + blockLight * 2.0) * K_TORCH_INTENSITY;
    if (m.id == ID_LAVA) {
        float pulse = 0.75 + 0.25 * sin(K_TIME * 1.4 + vWorldPos.x * 0.4);
        emission = vec3(1.0, 0.32, 0.05) * 6.0 * pulse;
    } else if (m.id == ID_FIRE) {
        emission = vec3(1.0, 0.45, 0.08) * 5.0;
    } else if (m.id == ID_PORTAL) {
        emission = vec3(0.45, 0.1, 0.85) * (2.5 + sin(K_TIME * 2.0 + vWorldPos.y) * 0.4);
    } else if (m.id == ID_AMETHYST) {
        emission += vec3(0.45, 0.25, 0.7) * 0.35;
    }

    vec3 lit = m.albedo * (0.02 + skyLight * 0.04 * skyLightColor() + blockLight * blockLight * blockLightColor() * 0.35 * K_TORCH_INTENSITY);
    lit += emission;

    gl_FragData[0] = vec4(lit, float(m.id) / 255.0);
    gl_FragData[1] = vec4(m.albedo, float(m.id) / 255.0);
    gl_FragData[2] = vec4(encodeNormal(m.normal), m.roughness, m.metal);
    gl_FragData[3] = vec4(m.emission, m.subsurface, m.ao, skyLight);
}
