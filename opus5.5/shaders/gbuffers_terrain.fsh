#version 330 compatibility

#define KOMOREBI_GEOMETRY
#define KOMOREBI_TERRAIN

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
    int matId = int(materialId + 0.5);

    vec3 normal = normalize(worldNormal);
    float detail = matId == MATERIAL_FOLIAGE ? 1.1 : (matId == MATERIAL_METAL ? 0.5 : 0.7);
    normal = surfaceDetailNormal(normal, worldPos, detail, matId);

    vec3 albedo = srgbToLinear(color.rgb);
    float upFacing = clamp(dot(normal, vec3(0.0, 1.0, 0.0)) * 0.5 + 0.5, 0.0, 1.0);
    float leafPass = matId == MATERIAL_FOLIAGE ? clamp(subsurface * 0.35 + 0.22, 0.0, 1.0) : clamp(subsurface * 0.4, 0.0, 1.0);

    gl_FragData[0] = vec4(encodeNormal(normal), 0.0, materialId / 255.0);
    gl_FragData[1] = vec4(lightmap.x, lightmap.y, emissiveHint, 0.0);
    gl_FragData[2] = vec4(roughness, metalness, upFacing, leafPass);
    gl_FragData[3] = vec4(albedo, 1.0);
}
