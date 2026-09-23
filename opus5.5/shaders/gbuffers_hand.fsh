#version 330 compatibility

#define KOMOREBI_GEOMETRY
#define KOMOREBI_HAND

#include "/lib/util.glsl"

uniform sampler2D gtexture;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 tint;
in vec3 worldNormal;
in vec3 viewNormal;
in vec3 worldPos;
in vec3 viewDir;
in float materialId;
in float roughness;
in float metalness;
in float subsurface;
in float waveAmount;
in vec3 specularTint;
in float emissiveHint;
in vec3 tangentVec;
in vec3 bitangentVec;

/* RENDERTARGETS: 1,2,3,7 */

void main() {
    vec4 color = texture2D(gtexture, texcoord) * tint;
    if (color.a < 0.02) discard;

    vec2 lightmap = lightmapLevels(lmcoord);
    vec3 albedo = srgbToLinear(color.rgb);
    // 手持物品的光照贴图不可靠, 用手持光源亮度补齐
    float handLight = clamp(float(heldBlockLightValue) / 15.0, 0.0, 1.0);
    lightmap.x = max(lightmap.x, handLight);

    float upFacing = clamp(dot(worldNormal, vec3(0.0, 1.0, 0.0)) * 0.5 + 0.5, 0.0, 1.0);

    gl_FragData[0] = vec4(encodeNormal(normalize(worldNormal)), 0.0, materialId / 255.0);
    gl_FragData[1] = vec4(lightmap.x, lightmap.y, emissiveHint, 0.0);
    gl_FragData[2] = vec4(roughness, metalness, upFacing, subsurface);
    gl_FragData[3] = vec4(albedo, 1.0);
}
