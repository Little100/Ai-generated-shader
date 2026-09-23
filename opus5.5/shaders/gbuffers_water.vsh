#version 330 compatibility

#define KOMOREBI_GEOMETRY

#include "/lib/common.glsl"

in vec2 mc_Entity;
in vec4 at_midBlock;

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
    vec3 wpos = worldPos4.xyz + cameraPosition;
    vec3 nrm = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));

    // 水面只在顶面做波形位移, 侧面保持贴合地形
    float topFace = clamp(dot(nrm, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
#ifdef WATER_WAVES
    vec3 ripple = waterVertexOffset(wpos, frameTimeCounter) * topFace;
    worldPos4.xyz += ripple;
    viewPos = gbufferModelView * worldPos4;
    wpos += ripple;
#endif
    worldPos = wpos;
    worldNormal = nrm;

    slot = float(SLOT_WATER);
    roughness = 0.03;
    metalness = 0.0;
    subsurface = 0.0;
    waveAmount = 1.0;
    emissiveHint = 0.0;
    normalStrength = 0.0;
    aoBias = 0.0;

    gl_Position = gl_ProjectionMatrix * viewPos;
}
