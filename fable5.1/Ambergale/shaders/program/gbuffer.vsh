// Shared vertex stage for every opaque gbuffer program.
// Callers define one of: GB_TERRAIN, GB_BLOCK, GB_ENTITY, GB_HAND, GB_PARTICLE, GB_TEXTURED, GB_BASIC

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/materials.glsl"
#include "/lib/wind.glsl"

#ifdef GB_TERRAIN
in vec2 mc_Entity;
in vec2 mc_midTexCoord;
#endif

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 normalWorld;
out vec3 playerPos;
flat out int material;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = remapLightmap((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy);
    glcolor = gl_Color;

    vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    playerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 nView = normalize(gl_NormalMatrix * gl_Normal);
    normalWorld = normalize(mat3(gbufferModelViewInverse) * nView);
    material = MAT_DEFAULT;

    #ifdef GB_TERRAIN
    int blockId = int(mc_Entity.x + 0.5);
    material = materialFromBlock(blockId);
    bool isTop = gl_MultiTexCoord0.t < mc_midTexCoord.t;
    vec3 worldPos = playerPos + cameraPosition;
    playerPos += windForBlock(blockId, worldPos, isTop, smoothstep(0.2, 0.6, lmcoord.y));
    viewPos = (gbufferModelView * vec4(playerPos, 1.0)).xyz;
    // Cross-shaped plants light better with an upward facing normal
    if (material == MAT_PLANT) normalWorld = vec3(0.0, 1.0, 0.0);
    #endif

    #ifdef GB_ENTITY
    material = MAT_ENTITY;
    #endif
    #ifdef GB_HAND
    material = MAT_HAND;
    #endif
    #ifdef GB_PARTICLE
    material = MAT_PARTICLE;
    normalWorld = vec3(0.0, 1.0, 0.0);
    #endif
    #if defined GB_TEXTURED || defined GB_BASIC
    material = MAT_UNLIT;
    normalWorld = vec3(0.0, 1.0, 0.0);
    #endif
    #ifdef GB_EMISSIVE
    material = MAT_EMISSIVE;
    #endif

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);
}
