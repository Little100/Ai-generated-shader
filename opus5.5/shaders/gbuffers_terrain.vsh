#version 330 compatibility

#define KOMOREBI_GEOMETRY
#define KOMOREBI_TERRAIN

#include "/lib/util.glsl"

uniform sampler2D gtexture;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 tint;
in vec3 worldNormal;
in vec3 viewNormal;
in vec3 worldPos;
in vec3 viewDir;
in float materialId;
in float roughness;
in float metalness;
in float subsurface;
in float waveAmount;
in vec3 specularTint;
in float emissiveHint;
in vec3 tangentVec;
in vec3 bitangentVec;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    tint = gl_Color;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 worldPos4 = gbufferModelViewInverse * viewPos;
    vec3 wpos = worldPos4.xyz + cameraPosition;
    viewDir = normalize(wpos - cameraPosition);

    vec2 lightmap = lightmapLevels(lmcoord);
    vec4 albedoSample = gl_Color * texture2D(gtexture, texcoord);
    MaterialInfo mat = materialFromBlock(mc_Entity.x, mc_Entity.y, lightmap, srgbToLinear(albedoSample.rgb));

    materialId = float(mat.id);
    roughness = mat.roughness;
    metalness = mat.metalness;
    subsurface = mat.subsurface;
    waveAmount = mat.waveAmount;
    specularTint = mat.specularTint;

    // 没有材质表时用光照贴图推断自发光
    emissiveHint = mat.emissive;
    if (mat.emissive < 0.5) {
        float lowSky = 1.0 - smoothstep(0.05, 0.35, lightmap.y);
        float hot = smoothstep(0.72, 0.99, lightmap.x);
        emissiveHint = hot * lowSky;
    }

    // 草与树叶随风摆动
    if (mat.waveAmount > 0.001) {
        vec3 offset = blockWave(wpos, at_midBlock.xyz, frameTimeCounter, 0.075 * mat.waveAmount);
        worldPos4.xyz += offset;
        viewPos = gbufferModelView * worldPos4;
        wpos += offset;
    }
    worldPos = wpos;

    // 切线基用于水面与叶片细节
    vec3 tangent = normalize(mat3(gbufferModelViewInverse) * at_tangent.xyz);
    tangentVec = tangent;
    vec3 nrm = normalize(mat3(gbufferModelViewInverse) * viewNormal);
    bitangentVec = normalize(cross(nrm, tangent) * sign(at_tangent.w));

    // 叶片靠近方块上沿时透光更强
    float leafTop = clamp((texcoord.y - mc_midTexCoord.y) * 5.0, 0.0, 1.0);
    subsurface = clamp(subsurface * (0.7 + leafTop * 0.5), 0.0, 1.5);

    gl_Position = gl_ProjectionMatrix * viewPos;
}
