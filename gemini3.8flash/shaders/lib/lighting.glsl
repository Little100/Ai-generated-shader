#ifndef AETHERIA_LIGHTING_GLSL
#define AETHERIA_LIGHTING_GLSL

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

// ==============================================================================
// Aetheria: Illumination Model, Soft Shadows, Dynamic Torchlight & Subsurface Glow
// ==============================================================================

// Sample Shadow Map with Poisson Disk PCF Filtering and Dynamic Bias
float calculateShadow(sampler2D shadowMap, vec3 playerPos, vec3 normal, vec3 lightDir, mat4 sModelView, mat4 sProj) {
#if SHADOW_QUALITY == 0
    return 1.0;
#else
    vec3 shadowCoord = playerToShadowScreen(playerPos, sModelView, sProj);

    // If outside shadow frustum, consider fully illuminated
    if (shadowCoord.x < 0.0 || shadowCoord.x > 1.0 ||
        shadowCoord.y < 0.0 || shadowCoord.y > 1.0 ||
        shadowCoord.z < 0.0 || shadowCoord.z > 1.0) {
        return 1.0;
    }

    // Adaptive slope-scaled normal depth bias to completely eliminate shadow acne
    float cosTheta = clamp(dot(normal, lightDir), 0.0, 1.0);
    float bias = max(0.0018 * (1.0 - cosTheta), 0.0004);

    float shadowFactor = 0.0;
    float filterRadius = 0.0012;

    int sampleCount = SHADOW_SAMPLES;
    for (int i = 0; i < sampleCount; ++i) {
        vec2 sampleOffset = poissonDisk[i] * filterRadius;
        float sampleDepth = texture(shadowMap, shadowCoord.xy + sampleOffset).r;
        if (sampleDepth + bias >= shadowCoord.z) {
            shadowFactor += 1.0;
        }
    }

    return shadowFactor / float(sampleCount);
#endif
}

// Calculate blocklight (torches, lanterns, campfires, glowstone)
vec3 calculateBlockLight(float blockLightUV, vec3 worldPos, float time) {
    if (blockLightUV <= 0.01) return vec3(0.0);

    // Cubic falloff for realistic inverse-square light decay
    float lightIntensity = pow(blockLightUV, 2.85);

#ifdef TORCH_FLICKER
    // Organic microscopic flame flicker based on time and position
    float flicker = sin(time * 11.5 + worldPos.x * 1.5) * 0.025 +
                    cos(time * 16.3 + worldPos.z * 1.5) * 0.02;
    lightIntensity *= (1.0 + flicker);
#endif

    // Warm golden-amber spectrum (approximately 2400K blackbody radiation)
    vec3 torchWarmColor = vec3(1.15, 0.72, 0.38);
    return torchWarmColor * lightIntensity * 1.8;
}

// Calculate ambient indirect skylight
vec3 calculateAmbientLight(float skyLightUV, vec3 normal, vec3 skyColor, float dayFactor) {
    float skyIntensity = pow(skyLightUV, 2.0);

    // Hemispherical directional ambient: upward faces catch sky, downward faces catch ground bounce
    float upFactor = clamp(normal.y * 0.5 + 0.5, 0.0, 1.0);
    vec3 skyHemisphere = mix(vec3(0.08, 0.07, 0.06), skyColor * 0.45, upFactor);

    // Cave minimum ambient light to avoid pitch black
    float caveAmbient = 0.035 * AMBIENT_BRIGHTNESS;

    return (skyHemisphere * skyIntensity + vec3(caveAmbient)) * AMBIENT_BRIGHTNESS;
}

// Foliage Subsurface Scattering (SSS) / Backlight Translucency
vec3 calculateSubsurfaceGlow(vec3 normal, vec3 viewDir, vec3 lightDir, vec3 sunColor, float shadowFactor, float isFoliage) {
#ifdef SUBSURFACE_SCATTERING
    if (isFoliage > 0.5) {
        // Backlighting occurs when view vector is nearly opposite to light vector
        float backLight = pow(clamp(-dot(viewDir, lightDir), 0.0, 1.0), 3.0);
        // Emerald translucent scatter
        vec3 foliageScatterColor = vec3(0.35, 0.85, 0.28) * sunColor;
        return foliageScatterColor * backLight * shadowFactor * 0.65;
    }
#endif
    return vec3(0.0);
}

#endif // AETHERIA_LIGHTING_GLSL
