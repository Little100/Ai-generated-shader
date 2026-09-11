/*
    Skyweave - surface response and light colour.

    Microfacet specular follows the usual cook torrance arrangement so that
    highlights behave sensibly at every roughness, and the light colours are
    derived from the block that actually emits them rather than being a single
    global tint.
*/

#if !defined(SKYWEAVE_LIGHTING_INCLUDED)
#define SKYWEAVE_LIGHTING_INCLUDED

#include "/lib/math.glsl"
#include "/lib/config.glsl"
#include "/lib/materials.glsl"

const float MIN_ROUGHNESS = 0.045;

float distributionGGX(float normalDotHalf, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float d = normalDotHalf * normalDotHalf * (a2 - 1.0) + 1.0;
    return a2 / max(PI * d * d, 1e-7);
}

float geometrySchlickGGX(float normalDotDir, float roughness) {
    float k = roughness * roughness * 0.5;
    return normalDotDir / max(normalDotDir * (1.0 - k) + k, 1e-7);
}

float geometrySmith(float normalDotView, float normalDotLight, float roughness) {
    return geometrySchlickGGX(normalDotView, roughness) * geometrySchlickGGX(normalDotLight, roughness);
}

vec3 fresnelSchlick(float cosTheta, vec3 f0) {
    return f0 + (1.0 - f0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

// a soft rim that keeps grazing reflections from going black on rough surfaces
vec3 fresnelSchlickRoughness(float cosTheta, vec3 f0, float roughness) {
    vec3 grazing = max(vec3(1.0 - roughness), f0);
    return f0 + (grazing - f0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

// the full specular lobe for a single light direction
vec3 specularBRDF(vec3 normal, vec3 viewDir, vec3 lightDir, float roughness, vec3 f0) {
    vec3 halfDir = normalize(viewDir + lightDir);
    float normalDotLight = max(dot(normal, lightDir), 0.0);
    float normalDotView = max(dot(normal, viewDir), 1e-4);
    float normalDotHalf = max(dot(normal, halfDir), 0.0);
    float viewDotHalf = max(dot(viewDir, halfDir), 0.0);

    float clampedRoughness = max(roughness, MIN_ROUGHNESS);
    float distribution = distributionGGX(normalDotHalf, clampedRoughness);
    float geometry = geometrySmith(normalDotView, normalDotLight, clampedRoughness);
    vec3 fresnel = fresnelSchlick(viewDotHalf, f0);

    return (distribution * geometry * fresnel) / max(4.0 * normalDotView * normalDotLight, 1e-4);
}

// converts a dielectric specular reflectance into an f0 for the cook torrance
// term, taking the metal flag into account
vec3 computeF0(vec3 albedo, float metalness, float reflectance) {
    vec3 dielectric = vec3(0.16 * reflectance * reflectance);
    return mix(dielectric, albedo, metalness);
}

// how much the environment hugs a surface, used to fade between the analytic
// sky and the cheap ambient term on rough metals
float ambientOcclusionFactor(float ao, float roughness) {
    return mix(1.0, ao, clamp(1.0 - roughness * 0.75, 0.0, 1.0));
}

/*  emitted light colour  */

// warm lamps, aqua lanterns, cyan soul fire and the rest, keyed off the block
// identifiers declared in block.properties
vec3 blockEmissionTint(int blockId) {
#ifndef COLORED_LIGHTS
    return vec3(1.0);
#else
    if (blockId <= 0) {
        return vec3(1.0);
    }

    vec3 tint = vec3(1.0);

    if (blockId == BLOCK_TORCH || blockId == BLOCK_WALL_TORCH) {
        tint = vec3(1.0, 0.72, 0.38);
    } else if (blockId == BLOCK_SOUL_TORCH || blockId == BLOCK_SOUL_WALL_TORCH || blockId == BLOCK_SOUL_LANTERN) {
        tint = vec3(0.30, 0.92, 0.98);
    } else if (blockId == BLOCK_LANTERN || blockId == BLOCK_CAMPFIRE || blockId == BLOCK_JACK_O_LANTERN) {
        tint = vec3(1.0, 0.78, 0.45);
    } else if (blockId == BLOCK_SOUL_CAMPFIRE || blockId == BLOCK_SOUL_FIRE) {
        tint = vec3(0.34, 0.88, 0.96);
    } else if (blockId == BLOCK_GLOWSTONE || blockId == BLOCK_FIRE) {
        tint = vec3(1.0, 0.84, 0.55);
    } else if (blockId == BLOCK_LAVA || blockId == BLOCK_MAGMA) {
        tint = vec3(1.0, 0.46, 0.14);
    } else if (blockId == BLOCK_SEA_LANTERN || blockId == BLOCK_CONDUIT) {
        tint = vec3(0.52, 0.92, 0.98);
    } else if (blockId == BLOCK_SHROOMLIGHT || blockId == BLOCK_OCHRE_FROGLIGHT) {
        tint = vec3(1.0, 0.70, 0.42);
    } else if (blockId == BLOCK_VERDANT_FROGLIGHT) {
        tint = vec3(0.72, 1.0, 0.66);
    } else if (blockId == BLOCK_PEARLESCENT_FROGLIGHT) {
        tint = vec3(0.92, 0.80, 1.0);
    } else if (blockId == BLOCK_REDSTONE_LAMP || blockId == BLOCK_CRYING_OBSIDIAN) {
        tint = vec3(1.0, 0.55, 0.30);
    } else if (blockId == BLOCK_AMETHYST) {
        tint = vec3(0.78, 0.58, 1.0);
    } else if (blockId == BLOCK_END_ROD || blockId == BLOCK_BEACON) {
        tint = vec3(0.88, 0.95, 1.0);
    } else if (blockId == BLOCK_RESPAWN_ANCHOR) {
        tint = vec3(0.92, 0.42, 1.0);
    } else if (blockId == BLOCK_NETHER_PORTAL) {
        tint = vec3(0.72, 0.42, 1.0);
    }

    // the tint is normalised so switching it on never changes overall brightness
    tint /= max(luminance(tint), 1e-4);
    tint = mix(vec3(1.0), tint, saturate(COLORED_LIGHT_SATURATION));
    return mix(vec3(1.0), tint, 0.85);
#endif
}

// surfaces in the metal list get their albedo promoted to f0 and lose their
// diffuse lobe, which is what makes polished blocks read as metal
float blockMetalness(int blockId) {
    if (blockId == BLOCK_IRON_BLOCK || blockId == BLOCK_GOLD_BLOCK || blockId == BLOCK_COPPER_BLOCK) {
        return 1.0;
    }
    if (blockId == BLOCK_DIAMOND_BLOCK || blockId == BLOCK_NETHERITE_BLOCK || blockId == BLOCK_EMERALD_BLOCK) {
        return 1.0;
    }
    return 0.0;
}

// rain and splashes make everything slightly glossy and much darker
void applyWetness(inout vec3 albedo, inout float smoothness, float wetAmount, float skyExposure) {
#ifdef WET_SURFACES
    if (wetAmount <= 0.001) {
        return;
    }

    float gloss = wetAmount * WET_SURFACE_STRENGTH * saturate(skyExposure);

    albedo *= mix(1.0, 0.55, gloss * 0.8);
    smoothness = mix(smoothness, 1.0, gloss * 0.75);
#endif
}

// the small scale normal disturbance left by falling rain, only worth sampling
// on upward faces the sky can actually reach
vec3 rainRipples(vec3 worldPos, vec3 normal, float wetAmount) {
#ifdef WET_SURFACES
    if (wetAmount <= 0.01 || normal.y < 0.25) {
        return normal;
    }

    float strength = wetAmount * WET_SURFACE_STRENGTH;
    vec2 p = worldPos.xz * 1.6;
    float t = frameTimeCounter * 1.4;

    vec2 offset = vec2(0.0);
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        vec2 cell = floor(p * 2.0 + fi * 13.0);
        vec2 drop = hash22(cell + fi);
        float phase = fract(t * (0.7 + fi * 0.21) + hash12(cell + fi * 3.0));
        vec2 delta = fract(p * 2.0) - drop;
        float distance = length(delta);
        float ring = sin((distance - phase * 1.1) * 26.0) * exp(-distance * 4.0) * (1.0 - phase);
        offset += (delta / max(distance, 1e-4)) * ring;
    }

    return normalize(normal + vec3(offset.x, 0.0, offset.y) * strength * 0.25);
#else
    return normal;
#endif
}

#endif
