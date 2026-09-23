#version 330 compatibility

#define KOMOREBI_GEOMETRY

#include "/lib/common.glsl"

in vec2 texcoord;
in vec2 lmcoord;
in vec4 tint;
in vec3 worldNormal;
in vec3 worldPos;
in float slot;
in float roughness;
in float metalness;
in float subsurface;
in float waveAmount;
in float emissiveHint;
in float normalStrength;
in float aoBias;

/* RENDERTARGETS: 1,2,3,7 */

void main() {
    vec4 color = texture2D(gtexture, texcoord) * tint;
    if (color.a < 0.02) discard;

    vec2 lightmap = lightmapLevels(lmcoord);
    int matSlot = int(slot + 0.5);

    vec3 normal = normalize(worldNormal);
    normal = surfaceDetailNormal(normal, worldPos, normalStrength, matSlot);

    vec3 albedo = srgbToLinear(color.rgb);
    float upFacing = clamp(dot(normal, vec3(0.0, 1.0, 0.0)) * 0.5 + 0.5, 0.0, 1.0);
    float pass = matSlot == SLOT_FOLIAGE ? clamp(subsurface * 0.35 + 0.22, 0.0, 1.0) : clamp(subsurface * 0.4, 0.0, 1.0);

    // 第三通道存放遮蔽偏置, 让延迟阶段按材质调整接触遮蔽
    gl_FragData[0] = vec4(encodeNormal(normal), aoBias, encodeSlot(matSlot));
    gl_FragData[1] = vec4(lightmap.x, lightmap.y, emissiveHint, color.a);
    // 第四通道: 玻璃存自身透明度, 其余材质存透光量
    float transparency = matSlot == SLOT_GLASS ? smoothstep(0.0, 0.55, 1.0 - color.a) : pass;
    gl_FragData[2] = vec4(roughness, metalness, upFacing, transparency);
    gl_FragData[3] = vec4(albedo, 1.0);
}
