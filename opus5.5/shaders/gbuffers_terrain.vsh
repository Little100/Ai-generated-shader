#version 330 compatibility

#define KOMOREBI_GEOMETRY

#include "/lib/common.glsl"

in vec2 mc_Entity;
in vec2 mc_midTexCoord;
in vec4 at_tangent;
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

    vec2 lightmap = lightmapLevels(lmcoord);
    vec4 albedoSample = gl_Color * texture2D(gtexture, texcoord);
    MaterialInfo mat = materialFromBlock(mc_Entity.x, mc_Entity.y, lightmap, srgbToLinear(albedoSample.rgb));

    slot = float(mat.slot);
    roughness = mat.roughness;
    metalness = mat.metalness;
    subsurface = mat.subsurface;
    waveAmount = mat.waveAmount;
    normalStrength = mat.normalStrength;
    aoBias = mat.aoBias;

    // 自发光方块由分类槽直接给出, 缺表时靠光照贴图推断
    emissiveHint = mat.emissive;
    if (mat.emissive < 0.5) {
        float lowSky = 1.0 - smoothstep(0.05, 0.35, lightmap.y);
        float hot = smoothstep(0.72, 0.99, lightmap.x);
        emissiveHint = hot * lowSky;
    }

    worldNormal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));

    // 草与树叶随风摆动, 摆动量按方块内部位置加权
    if (mat.waveAmount > 0.001) {
        vec3 offset = blockWave(wpos, at_midBlock.xyz, frameTimeCounter, 0.075 * mat.waveAmount);
        worldPos4.xyz += offset;
        viewPos = gbufferModelView * worldPos4;
        wpos += offset;
    }
    worldPos = wpos;

    // 叶片靠近方块上沿时透光更强
    if (mat.slot == SLOT_FOLIAGE || mat.slot == SLOT_PLANT) {
        float leafTop = clamp((texcoord.y - mc_midTexCoord.y) * 5.0, 0.0, 1.0);
        subsurface = clamp(subsurface * (0.7 + leafTop * 0.5), 0.0, 1.5);
    }

    gl_Position = gl_ProjectionMatrix * viewPos;
}
