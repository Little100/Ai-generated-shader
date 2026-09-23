#version 330 compatibility

#define KOMOREBI_GEOMETRY
#define KOMOREBI_ENTITY

#include "/lib/util.glsl"

uniform sampler2D gtexture;

out vec2 texcoord;
out vec2 lmcoord;
out vec4 tint;
out vec3 worldNormal;
out vec3 viewNormal;
out vec3 worldPos;
out vec3 viewDir;
out float materialId;
out float roughness;
out float metalness;
out float subsurface;
out float waveAmount;
out vec3 specularTint;
out float emissiveHint;
out vec3 tangentVec;
out vec3 bitangentVec;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    tint = gl_Color;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 worldPos4 = gbufferModelViewInverse * viewPos;
    worldPos = worldPos4.xyz + cameraPosition;
    viewDir = normalize(worldPos - cameraPosition);

    materialId = float(MATERIAL_ENTITY);
    roughness = 0.68;
    metalness = 0.0;
    subsurface = 0.35;
    waveAmount = 0.0;
    specularTint = vec3(1.0);
    emissiveHint = 0.0;

    // 发光实体, 例如岩浆怪与萤火虫, 由光照贴图与顶点色共同判断
    vec2 lightmap = lightmapLevels(lmcoord);
    if (lightmap.x > 0.7 && lightmap.y < 0.15) emissiveHint = 0.55;

    vec3 nrm = normalize(mat3(gbufferModelViewInverse) * viewNormal);
    tangentVec = normalize(mat3(gbufferModelViewInverse) * vec3(1.0, 0.0, 0.0));
    bitangentVec = normalize(cross(nrm, tangentVec));

    gl_Position = gl_ProjectionMatrix * viewPos;
}
