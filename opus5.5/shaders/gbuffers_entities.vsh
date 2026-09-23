#version 330 compatibility

#define KOMOREBI_GEOMETRY

#include "/lib/common.glsl"

in vec2 mc_Entity;

out vec2 texcoord;
out vec2 lmcoord;
out vec4 tint;
out vec3 worldNormal;
out vec3 worldPos;
out float slot;
out float roughness;
out float metalness;
out float subsurface;
out float waveAmount;
out float emissiveHint;
out float normalStrength;
out float aoBias;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    tint = gl_Color;

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 worldPos4 = gbufferModelViewInverse * viewPos;
    worldPos = worldPos4.xyz + cameraPosition;
    worldNormal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));

    // 实体默认按生物材质处理, 部分方块实体走方块分类
    vec2 lightmap = lightmapLevels(lmcoord);
    vec4 albedoSample = gl_Color * texture2D(gtexture, texcoord);
    MaterialInfo mat = materialFromBlock(mc_Entity.x, mc_Entity.y, lightmap, srgbToLinear(albedoSample.rgb));
    if (mat.slot == SLOT_NONE) {
        mat.slot = SLOT_ENTITY;
        mat.roughness = 0.68;
        mat.subsurface = 0.35;
        mat.normalStrength = 0.4;
    }

    slot = float(mat.slot);
    roughness = mat.roughness;
    metalness = mat.metalness;
    subsurface = mat.subsurface;
    waveAmount = 0.0;

    // 发光实体靠光照贴图与分类槽共同判断
    emissiveHint = mat.emissive;
    if (emissiveHint < 0.5 && lightmap.x > 0.7 && lightmap.y < 0.15) emissiveHint = 0.55;

    gl_Position = gl_ProjectionMatrix * viewPos;
}
