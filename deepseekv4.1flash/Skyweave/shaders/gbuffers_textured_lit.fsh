#version 330 compatibility

/*
    The workhorse for entities, particles, the held item and weather. Terrain
    uses the same lighting model, only with block identification on top.
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

    vec3 albedo = srgbToLinear(base.rgb);
    albedo *= entityColor.rgb;

    vec3 normal = normalize(worldNormal);
    vec3 viewDir = normalize(worldPos + vec3(0.0, 0.0, 1e-5));
    vec3 lightmapColor = texture(lightmap, lmcoord).rgb;

    float wetAmount = wetness * rainStrength;
    float smoothness = clamp(0.42 + SMOOTHNESS_BIAS, 0.05, 1.0);
    vec3 rippled = rainRipples(worldPos + cameraPosition, normal, wetAmount);
    applyWetness(albedo, smoothness, wetAmount, lightLevel.y);

    SurfaceResult lit = shadeSurface(albedo, rippled, worldPos, viewDir, lightLevel, lightmapColor,
                                    0, viewDistance, lightLevel.y, smoothness, 1.0, 0.0, 0.0);

    outScene = vec4(lit.color, 1.0);
    outAlbedo = vec4(albedo, MAT_ENTITY);
    outNormal = vec4(encodeNormal(rippled), smoothness);
    outLight = vec4(lightLevel, lit.directVisibility, lit.ambientOcclusion);
}
