#version 330 compatibility

#define KOMOREBI_GEOMETRY
#define KOMOREBI_HAND

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
    roughness = 0.62;
    metalness = 0.0;
    subsurface = 0.4;
    waveAmount = 0.0;
    specularTint = vec3(1.0);
    emissiveHint = 0.0;

    // 手中光源方块会照亮周围, 用手持亮度提升自发光
    vec2 lightmap = lightmapLevels(lmcoord);
    if (heldBlockLightValue > 0 && lightmap.x > 0.6 && lightmap.y < 0.2) {
        emissiveHint = clamp(float(heldBlockLightValue) / 15.0, 0.0, 1.0);
    }

    vec3 nrm = normalize(mat3(gbufferModelViewInverse) * viewNormal);
    tangentVec = normalize(mat3(gbufferModelViewInverse) * vec3(1.0, 0.0, 0.0));
    bitangentVec = normalize(cross(nrm, tangentVec));

    gl_Position = gl_ProjectionMatrix * viewPos;
}
