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

    slot = float(SLOT_ENTITY);
    roughness = 0.62;
    metalness = 0.0;
    subsurface = 0.4;
    waveAmount = 0.0;
    normalStrength = 0.35;
    aoBias = 0.0;
    emissiveHint = 0.0;

    // 手中光源方块会照亮周围, 用手持亮度抬高自发光
    vec2 lightmap = lightmapLevels(lmcoord);
    if (heldBlockLightValue > 0 && lightmap.x > 0.6 && lightmap.y < 0.2) {
        emissiveHint = clamp(float(heldBlockLightValue) / 15.0, 0.0, 1.0);
    }

    gl_Position = gl_ProjectionMatrix * viewPos;
}
