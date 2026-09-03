#version 330 compatibility
#define DIM_NETHER

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/materials.glsl"
#include "/lib/wind.glsl"
#include "/lib/shadow.glsl"

in vec2 mc_Entity;
in vec2 mc_midTexCoord;

out vec2 texcoord;
out vec4 glcolor;
flat out int blockId;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    blockId = int(mc_Entity.x + 0.5);

    vec3 shadowViewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    vec3 playerPos = (shadowModelViewInverse * vec4(shadowViewPos, 1.0)).xyz;
    bool isTop = gl_MultiTexCoord0.t < mc_midTexCoord.t;
    float skyGate = smoothstep(0.2, 0.6, remapLightmap((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy).y);
    playerPos += windForBlock(blockId, playerPos + cameraPosition, isTop, skyGate);
    shadowViewPos = (shadowModelView * vec4(playerPos, 1.0)).xyz;

    vec4 clip = gl_ProjectionMatrix * vec4(shadowViewPos, 1.0);
    clip.xyz = distortShadow(clip.xyz);
    gl_Position = clip;
}
