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
    vec3 albedo = srgbToLinear(color.rgb);
    // 手持物品的光照贴图不可靠, 用手持光源亮度补齐
    lightmap.x = max(lightmap.x, clamp(float(heldBlockLightValue) / 15.0, 0.0, 1.0));

    vec3 normal = normalize(worldNormal);
    float upFacing = clamp(dot(normal, vec3(0.0, 1.0, 0.0)) * 0.5 + 0.5, 0.0, 1.0);

    gl_FragData[0] = vec4(encodeNormal(normal), 0.0, encodeSlot(int(slot + 0.5)));
    gl_FragData[1] = vec4(lightmap.x, lightmap.y, emissiveHint, color.a);
    gl_FragData[2] = vec4(roughness, metalness, upFacing, clamp(subsurface * 0.4, 0.0, 1.0));
    gl_FragData[3] = vec4(albedo, 1.0);
}
