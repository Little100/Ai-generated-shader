#version 120
/* RENDERTARGETS: 0,1,2,3,8 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/material.glsl"
#include "/lib/water.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;

varying vec2 vUv;
varying vec2 vLm;
varying vec4 vColor;
varying vec3 vViewPos;
varying vec3 vNormal;
varying vec3 vWorldPos;
varying float vAo;
flat varying int vId;

void main() {
    vec3 n = normalize(vNormal);
    vec3 viewDir = normalize(-vViewPos);
    bool water = vId == ID_WATER || vId <= 0 && vColor.a < 0.95 && vColor.b > vColor.r;

    if (water) {
        vec3 displaced;
        vec3 wn;
        waterSurface(vWorldPos, displaced, wn);
        n = normalize(mix(n, wn, K_WATER_WAVES));
        float ndotv = saturate(dot(n, viewDir));
        vec3 f0 = vec3(0.02);
        float fresnel = fresnelSchlick(ndotv, f0).r;
        vec3 scatter = waterScatterColor() * (0.35 + vLm.y * 0.8);
        vec3 col = scatter * (0.25 + fresnel * 0.15);
        float alpha = saturate(0.12 + fresnel * 0.72);
        gl_FragData[0] = vec4(col, alpha);
        gl_FragData[1] = vec4(scatter, float(ID_WATER) / 255.0);
        gl_FragData[2] = vec4(encodeNormal(n), 0.05, 0.0);
        gl_FragData[3] = vec4(0.0, 0.0, 1.0, vLm.y);
        gl_FragData[4] = vec4(1.0);
        return;
    }

    vec4 albedoTex = texture2D(gtexture, vUv);
    if (albedoTex.a < 0.02) {
        discard;
    }
    vec3 albedo = srgbToLinear(albedoTex.rgb * vColor.rgb);
    Material m = makeMaterial(albedo, n, vUv, vId, vAo);
    float fresnel = fresnelSchlick(saturate(dot(n, viewDir)), vec3(m.f0)).r;
    vec3 lit = m.albedo * (0.04 + vLm.y * 0.08 + vLm.x * vLm.x * 0.3);
    if (m.id == ID_LAVA) {
        lit = vec3(1.0, 0.28, 0.04) * (2.5 + sin(K_TIME + vWorldPos.x) * 0.3);
        gl_FragData[0] = vec4(lit, 0.92);
    } else {
        float alpha = saturate(albedoTex.a * vColor.a * 0.85 + fresnel * 0.25);
        gl_FragData[0] = vec4(lit, alpha);
    }
    gl_FragData[1] = vec4(m.albedo, float(m.id) / 255.0);
    gl_FragData[2] = vec4(encodeNormal(n), m.roughness, m.metal);
    gl_FragData[3] = vec4(m.emission, m.subsurface, m.ao, vLm.y);
    gl_FragData[4] = vec4(m.id == ID_LAVA ? 0.0 : 1.0);
}
