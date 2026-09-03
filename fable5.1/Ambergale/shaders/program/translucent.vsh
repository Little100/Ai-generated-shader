#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/materials.glsl"

// mc_Entity is only bound for terrain style programs; everything else sees the undefined id
#if defined GB_ENTITY || defined GB_PARTICLE || defined GB_BLOCK || defined GB_HAND_WATER
const vec2 mc_Entity = vec2(-1.0);
#else
in vec2 mc_Entity;
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

    int blockId = int(mc_Entity.x + 0.5);
    material = blockId == BLOCK_WATER ? MAT_WATER : MAT_DEFAULT;
    #ifdef GB_HAND_WATER
    material = MAT_HAND;
    #endif
    #ifdef GB_ENTITY
    material = MAT_ENTITY;
    #endif
    #ifdef GB_PARTICLE
    material = MAT_PARTICLE;
    normalWorld = vec3(0.0, 1.0, 0.0);
    #endif

    gl_Position = gl_ProjectionMatrix * vec4(viewPos, 1.0);
}
