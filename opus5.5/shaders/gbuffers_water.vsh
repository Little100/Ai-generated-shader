#version 330 compatibility

#define KOMOREBI_GEOMETRY
#define KOMOREBI_WATER

#include "/lib/util.glsl"
#include "/lib/water.glsl"

uniform sampler2D gtexture;

in vec2 mc_Entity;
in vec4 at_midBlock;

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
out float waterDepthHint;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    tint = gl_Color;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 worldPos4 = gbufferModelViewInverse * viewPos;
    vec3 wpos = worldPos4.xyz + cameraPosition;
    viewDir = normalize(wpos - cameraPosition);

    // 水面只在顶面做波形位移, 侧面保持贴合
    vec3 nrm = normalize(mat3(gbufferModelViewInverse) * viewNormal);
    float topFace = clamp(dot(nrm, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
#ifdef WATER_WAVES
    vec3 ripple = waterVertexOffset(wpos, frameTimeCounter) * topFace;
    worldPos4.xyz += ripple;
    viewPos = gbufferModelView * worldPos4;
    wpos += ripple;
#endif
    worldPos = wpos;

    materialId = float(MATERIAL_WATER);
    roughness = 0.03;
    metalness = 0.0;
    subsurface = 0.0;
    waveAmount = 1.0;
    specularTint = vec3(0.92, 0.97, 1.0);
    emissiveHint = 0.0;

    vec3 tangent = normalize(mat3(gbufferModelViewInverse) * vec3(1.0, 0.0, 0.0));
    tangentVec = tangent;
    bitangentVec = normalize(cross(nrm, tangent));

    // 顶点与眼高的差用于估计水体厚度的粗略量级
    waterDepthHint = clamp((eyeAltitude - wpos.y) * 0.05, 0.0, 1.0);

    gl_Position = gl_ProjectionMatrix * viewPos;
}
