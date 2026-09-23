#version 330 compatibility

#define KOMOREBI_GEOMETRY

#include "/lib/util.glsl"
#include "/lib/shadow.glsl"

uniform sampler2D gtexture;

in vec2 mc_Entity;
in vec4 at_midBlock;

out vec2 texcoord;
out vec4 tint;
out vec3 worldNormal;
out vec3 worldPos;
out float materialId;
out vec2 lmcoord;
out vec4 shadowColor;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    tint = gl_Color;
    // 阴影阶段的法线用世界空间, 光照方向也在同一空间
    worldNormal = normalize(mat3(gbufferModelViewInverse) * gl_Normal);

    vec3 wpos = (gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz + cameraPosition;
    vec2 lightmap = lightmapLevels(lmcoord);
    vec4 albedoSample = gl_Color * texture2D(gtexture, texcoord);
    MaterialInfo mat = materialFromBlock(mc_Entity.x, mc_Entity.y, lightmap, srgbToLinear(albedoSample.rgb));
    materialId = float(mat.id);

    // 阴影阶段同样需要摆动, 否则草地阴影与本体错位
    if (mat.waveAmount > 0.001) {
        wpos += blockWave(wpos, at_midBlock.xyz, frameTimeCounter, 0.075 * mat.waveAmount);
    }
    worldPos = wpos;

    // 彩色阴影, 玻璃透色而树叶偏绿
    vec3 tintColor = vec3(1.0);
    float occlusiveness = 1.0;
    if (mat.id == MATERIAL_GLASS) {
        tintColor = srgbToLinear(albedoSample.rgb) + 0.08;
        occlusiveness = 0.35;
    } else if (mat.id == MATERIAL_FOLIAGE) {
        tintColor = vec3(0.72, 1.0, 0.62);
        occlusiveness = 0.62;
    } else if (mat.id == MATERIAL_WATER) {
        tintColor = vec3(0.55, 0.82, 0.92);
        occlusiveness = 0.25;
    }
    shadowColor = vec4(tintColor, occlusiveness);

    gl_Position = shadowProjection * (shadowModelView * vec4(wpos, 1.0));
}
