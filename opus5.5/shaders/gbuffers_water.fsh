#version 330 compatibility

#define KOMOREBI_GEOMETRY
#define KOMOREBI_WATER

#include "/lib/util.glsl"
#include "/lib/water.glsl"

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
in float waterDepthHint;

/* RENDERTARGETS: 1,2,3,7 */

void main() {
    vec4 color = texture2D(gtexture, texcoord) * tint;
    if (color.a < 0.02) discard;

    vec2 lightmap = lightmapLevels(lmcoord);
    vec3 albedo = srgbToLinear(color.rgb);

#ifdef WATER_WAVES
    vec3 normal = waterNormal(worldPos, frameTimeCounter, 1.0);
#else
    vec3 normal = normalize(worldNormal);
#endif
    // 法线转到世界空间, 若几何法线朝下则翻转气泡面
    if (dot(normalize(worldNormal), vec3(0.0, 1.0, 0.0)) < -0.5) normal.y = -normal.y;

    gl_FragData[0] = vec4(encodeNormal(normal), 0.0, materialId / 255.0);
    gl_FragData[1] = vec4(lightmap.x, lightmap.y, 0.0, 0.0);
    gl_FragData[2] = vec4(0.02, 0.0, clamp(normal.y * 0.5 + 0.5, 0.0, 1.0), waterDepthHint);
    gl_FragData[3] = vec4(albedo, 1.0);
}
