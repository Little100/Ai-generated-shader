/*
    Skyweave - the shared surface shading model.

    Terrain, entities, the hand, particles and the sky all funnel through
    shadeSurface, which is what keeps every object in the world lit by the same
    sun, the same shadow map and the same sky. A change to the atmosphere shows
    up everywhere at once.
*/

#if !defined(SKYWEAVE_SURFACE_INCLUDED)
#define SKYWEAVE_SURFACE_INCLUDED

#include "/lib/math.glsl"
#include "/lib/config.glsl"
#include "/lib/atmosphere.glsl"
#include "/lib/color.glsl"
#include "/lib/lighting.glsl"
#include "/lib/materials.glsl"
#include "/lib/shadow.glsl"

/*  block classification  */

// how much light a thin surface lets through from behind, and how glossy it is
void classifySurface(int blockId, float rawSmoothness, out float smoothness, out float metalness, out float emission, out float thinness) {
    smoothness = rawSmoothness;
    metalness = blockMetalness(blockId);
    emission = 0.0;
    thinness = 0.0;

    if (isLightSourceBlock(blockId)) {
        emission = 1.0;
    } else if (isFoliageBlock(blockId)) {
        thinness = 0.65;
        smoothness *= 0.55;
    }
}

/*  the environment term  */

vec3 sunLightColor(float altitude) {
    vec3 direction = normalize(shadowLightPosition);
    vec3 transmitted = sunTransmittance(altitude, direction);
    float upness = saturate(shadowLightPosition.y * 5.0);

    // below the horizon the moon takes over and picks up the same reddening
    vec3 intensity = mix(vec3(MOON_IRRADIANCE), vec3(SUN_IRRADIANCE), upness);
    return transmitted * intensity;
}

float sunVisibility(vec3 worldPos, vec3 normal, float viewDistance, vec3 lightDir) {
    // nothing to test once the light is under the horizon
    if (shadowLightPosition.y < -0.03) {
        return 1.0;
    }
    return shadowVisibility(worldPos, normal, viewDistance, dot(normal, lightDir));
}

/*  the main entry point  */

struct SurfaceResult {
    vec3 color;
    float ambientOcclusion;
    float directVisibility;
};

SurfaceResult shadeSurface(
    vec3 albedo,
    vec3 worldNormal,
    vec3 worldPos,
    vec3 viewDir,
    vec2 lightLevel,
    vec3 lightmapColor,
    int blockId,
    float viewDistance,
    float skyExposure,
    float smoothnessIn,
    float aoIn,
    float emissiveGlow,
    float isHand
) {
    SurfaceResult result;
    result.color = vec3(0.0);
    result.ambientOcclusion = aoIn;
    result.directVisibility = 1.0;

    float smoothness;
    float metalness;
    float emission;
    float thinness;
    classifySurface(blockId, smoothnessIn, smoothness, metalness, emission, thinness);

    emission = max(emission, emissiveGlow);

    vec3 f0 = computeF0(albedo, metalness, 0.5);
    vec3 diffuseAlbedo = albedo * (1.0 - metalness);

    float altitude = eyeAltitude;
    vec3 lightDir = normalize(shadowLightPosition);
    float normalDotLight = dot(worldNormal, lightDir);

    /*  direct light  */

    vec3 direct = vec3(0.0);
    if (normalDotLight > 0.0) {
        float visibility = sunVisibility(worldPos, worldNormal, viewDistance, lightDir);
        result.directVisibility = visibility;
        if (visibility > 0.0) {
            vec3 radiance = sunLightColor(altitude);

            // thin surfaces glow when the light is behind them
            float transmission = 0.0;
            if (thinness > 0.0) {
                float back = saturate(dot(-lightDir, viewDir));
                transmission = pow(back, 2.5) * thinness * 0.9;
            }

            float lambert = normalDotLight * (1.0 - thinness * 0.5) + transmission * 0.5;
            vec3 diffuse = diffuseAlbedo * lambert / PI;
            vec3 specular = specularBRDF(worldNormal, viewDir, lightDir, smoothness, f0)
                          * normalDotLight
                          * SPECULAR_STRENGTH;

            direct = (diffuse + specular) * radiance * visibility * DIRECT_LIGHT_STRENGTH;
        }
    }

    /*  sky and block light  */

    float occlusion = mix(1.0, aoIn, SSAO_STRENGTH);
    float skyLevel = lightLevel.y;
    float blockLevel = lightLevel.x;

    vec3 skyAmbient = skyIrradiance(worldNormal, normalize(sunPosition), altitude);
    vec3 skyContribution = diffuseAlbedo * skyAmbient * pow(skyLevel, 1.35) * occlusion / PI;

    // the ambient specular lobe, cheap but it stops rough metals going flat
    vec3 ambientFresnel = fresnelSchlickRoughness(max(dot(worldNormal, viewDir), 0.0), f0, smoothness);
    vec3 skySpecular = skyAmbient * ambientFresnel * (1.0 - smoothness) * 0.35 * occlusion / PI;

    // the lamp hue comes from the baked lightmap so a torch reads warm without
    // any per block lookup, and the player's own lamp overrides it when lit
    vec3 lampHue = lightmapColor / max(max(lightmapColor.r, max(lightmapColor.g, lightmapColor.b)), 1e-4);
    vec3 blockTint = mix(vec3(1.0, 0.72, 0.42), lampHue, 0.35);

    vec3 blockLight = diffuseAlbedo * blockTint * pow(blockLevel, 2.1)
                    * BLOCK_LIGHT_STRENGTH * 1.15 * occlusion;

    // the lamp a player carries lights the world around them
    if (heldBlockLightValue > 0) {
        float held = float(heldBlockLightValue) / 15.0;
        blockLight += diffuseAlbedo * heldBlockLightColor * pow(held, 2.1) * 0.55 * occlusion;
    }

    /*  emission  */

    vec3 emitted = vec3(0.0);
    if (emission > 0.0) {
        vec3 tint = blockEmissionTint(blockId);
        emitted = albedo * tint * emission * 1.6;
    }

    /*  night vision and blindness, matching what vanilla would do  */

    if (nightVision > 0.0) {
        emitted += albedo * vec3(0.12, 0.14, 0.10) * nightVision;
    }

    vec3 total = direct + skyContribution + skySpecular + blockLight + emitted;

    if (blindness > 0.0) {
        total = mix(total, vec3(luminance(total) * 0.4), blindness);
    }
    if (darknessFactor > 0.0) {
        total *= (1.0 - darknessFactor * 0.85);
    }

    result.color = max(total, vec3(0.0));
    result.ambientOcclusion = occlusion;
    return result;
}

#endif
