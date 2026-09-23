#version 330 compatibility

#define KOMOREBI_GEOMETRY

#include "/lib/common.glsl"

in vec2 texcoord;
in vec2 lmcoord;
in vec4 tint;
in vec3 worldNormal;
in vec3 worldPos;
in float slot;
in float roughness;
in float metalness;
in float subsurface;
in float waveAmount;
in float emissiveHint;
in float normalStrength;
in float aoBias;

/* RENDERTARGETS: 1,2,3,7 */

void main() {
    vec4 color = texture2D(gtexture, texcoord) * tint;
    if (color.a < 0.02) discard;

    vec2 lightmap = lightmapLevels(lmcoord);
    vec3 albedo = srgbToLinear(color.rgb);

    // 只在朝上的水面替换为程序化法线, 侧面仍用几何法线
    float topFace = clamp(dot(worldNormal, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
#ifdef WATER_WAVES
    vec3 waveNormal = waterNormal(worldPos, frameTimeCounter, topFace);
    vec3 normal = mix(worldNormal, waveNormal, topFace);
#else
    vec3 normal = worldNormal;
#endif
    // 从水下看时水面朝下, 法线需要翻转
    if (isEyeInWater == 1) normal.y = -abs(normal.y);

    gl_FragData[0] = vec4(encodeNormal(normal), 0.0, encodeSlot(SLOT_WATER));
    gl_FragData[1] = vec4(lightmap.x, lightmap.y, 0.0, color.a);
    // 第四通道留给水体厚度提示, 由延迟阶段按深度重新估计
    gl_FragData[2] = vec4(0.02, 0.0, clamp(normal.y * 0.5 + 0.5, 0.0, 1.0), 1.0);
    gl_FragData[3] = vec4(albedo, 1.0);
}
