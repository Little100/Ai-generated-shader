#version 330 compatibility

/*
    Terrain. This is also the fallback for the solid, cutout, damaged block and
    hand variants, and it is the only surface program that knows which block it
    belongs to, so material classification happens here.
*/

#include "/lib/buffers.glsl"
#include "/lib/surface.glsl"

in vec2 texcoord;
in vec2 lmcoord;
in vec2 lightLevel;
in vec4 tint;
in vec3 worldNormal;
in vec3 worldPos;
in float viewDistance;
flat in float blockId;

/* RENDERTARGETS: 0,1,2,3 */
layout(location = 0) out vec4 outScene;
layout(location = 1) out vec4 outAlbedo;
layout(location = 2) out vec4 outNormal;
layout(location = 3) out vec4 outLight;

void main() {
    vec4 base = texture(gtexture, texcoord) * tint;
    if (base.a < alphaTestRef) {
        discard;
    }

    int id = int(blockId + 0.5);
    vec3 absolutePos = worldPos + cameraPosition;

    vec3 albedo = srgbToLinear(base.rgb);
    vec3 normal = normalize(worldNormal);
    vec3 viewDir = normalize(worldPos + vec3(0.0, 0.0, 1e-5));
    vec3 lightmapColor = texture(lightmap, lmcoord).rgb;

    float smoothness = clamp(0.42 + SMOOTHNESS_BIAS, 0.05, 1.0);
    if (blockMetalness(id) > 0.5) {
        smoothness = clamp(0.62 + SMOOTHNESS_BIAS, 0.20, 1.0);
    }
    if (isFoliageBlock(id)) {
        smoothness = clamp(0.34 + SMOOTHNESS_BIAS, 0.05, 1.0);
    }

    float wetAmount = wetness * rainStrength;
    applyWetness(albedo, smoothness, wetAmount, lightLevel.y);
    vec3 shadedNormal = rainRipples(absolutePos, normal, wetAmount);

    SurfaceResult lit = shadeSurface(albedo, shadedNormal, worldPos, viewDir, lightLevel, lightmapColor,
                                     id, viewDistance, lightLevel.y, smoothness, 1.0, 0.0, 0.0);

    float material = MAT_OPAQUE;
    if (isLightSourceBlock(id)) {
        material = MAT_EMISSIVE;
    } else if (isFoliageBlock(id)) {
        material = MAT_FOLIAGE;
    } else if (blockMetalness(id) > 0.5) {
        material = MAT_METAL;
    }

    outScene = vec4(lit.color, 1.0);
    outAlbedo = vec4(albedo, material);
    outNormal = vec4(encodeNormal(shadedNormal), smoothness);
    outLight = vec4(lightLevel, lit.directVisibility, lit.ambientOcclusion);
}
