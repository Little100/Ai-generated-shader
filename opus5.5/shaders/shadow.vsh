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

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    tint = gl_Color;

    vec3 wpos = (gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz + cameraPosition;
    worldNormal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));

    // 方块分类决定是否随风摆动, 其余参数在阴影阶段用不到
    vec2 lightmap = lightmapLevels(lmcoord);
    MaterialInfo mat = materialFromBlock(mc_Entity.x, mc_Entity.y, lightmap, vec3(0.5));
    slot = float(mat.slot);

    // 阴影阶段同样需要摆动, 否则草地阴影与本体错位
    if (mat.waveAmount > 0.001) {
        wpos += blockWave(wpos, at_midBlock.xyz, frameTimeCounter, 0.075 * mat.waveAmount);
    }
    worldPos = wpos;

    gl_Position = shadowProjection * (shadowModelView * vec4(wpos, 1.0));
}
