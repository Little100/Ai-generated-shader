#ifndef AETHERIA_ATMOSPHERE_GLSL
#define AETHERIA_ATMOSPHERE_GLSL

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

// ==============================================================================
// Aetheria: Celestial Atmosphere, Sky Gradient, Nebula, Stars & Volumetric Fog
// ==============================================================================

// Procedural stars calculation for night sky
vec3 calculateStars(vec3 viewDir, float time) {
    if (viewDir.y < 0.02) return vec3(0.0);

    // Map 3D direction vector onto spherical celestial coordinates
    vec2 celestialUV = vec2(atan(viewDir.z, viewDir.x) / TWO_PI + 0.5, acos(clamp(viewDir.y, -1.0, 1.0)) / PI);
    vec2 gridPos = celestialUV * 220.0;
    vec2 cell = floor(gridPos);
    vec2 fracPos = fract(gridPos) - 0.5;

    float starRandom = hash21(cell);
    if (starRandom > 0.975) {
        // Scintillation / twinkling
        float twinkle = sin(time * 3.5 + starRandom * 40.0) * 0.45 + 0.55;
        float dist = length(fracPos);
        float starIntensity = smoothstep(0.18, 0.01, dist) * twinkle * (starRandom - 0.975) * 40.0;
        // Subtle star color temperature variations (blue-white to warm-white)
        vec3 starColor = mix(vec3(0.85, 0.92, 1.0), vec3(1.0, 0.95, 0.8), hash21(cell + 4.5));
        return starColor * starIntensity * smoothstep(0.02, 0.25, viewDir.y);
    }
    return vec3(0.0);
}

// Procedural Celestial Nebula / Aurora ribbon across the night sky
vec3 calculateCelestialNebula(vec3 viewDir, float time) {
    if (viewDir.y < 0.05) return vec3(0.0);

    float elevation = clamp(viewDir.y, 0.0, 1.0);
    // Flowing ribbon coordinate
    vec2 ribbonUV = vec2(viewDir.x + viewDir.z * 0.5, viewDir.z - viewDir.x * 0.5) / (elevation + 0.15);
    float flowTime = time * 0.035;

    float wave1 = sin(ribbonUV.x * 2.2 + ribbonUV.y * 1.5 + flowTime) * 0.5 + 0.5;
    float wave2 = cos(ribbonUV.x * 3.8 - ribbonUV.y * 2.1 - flowTime * 1.3) * 0.5 + 0.5;
    float ribbon = pow(wave1 * wave2, 2.5);

    // Cyan and amethyst dual-tone nebula colors
    vec3 colorTeal = vec3(0.08, 0.55, 0.65);
    vec3 colorViolet = vec3(0.48, 0.18, 0.72);
    vec3 nebulaColor = mix(colorTeal, colorViolet, wave1);

    return nebulaColor * ribbon * 0.35 * smoothstep(0.05, 0.3, elevation);
}

// Compute atmospheric sky dome color based on view direction, sun direction, and weather
vec3 calculateSkyColor(vec3 viewDir, vec3 sunDir, float time, float rainStrength) {
    float sunElevation = sunDir.y;
    float dayFactor = smoothstep(-0.15, 0.25, sunElevation);
    float sunsetFactor = smoothstep(0.35, 0.0, abs(sunElevation)) * (1.0 - rainStrength);

    float viewSunDot = max(dot(viewDir, sunDir), 0.0);
    float elevation = clamp(viewDir.y, 0.0, 1.0);

    // 1. Day Sky Palette (Crisp Azure to Horizon Cyan)
    vec3 dayZenith = vec3(0.18, 0.44, 0.88);
    vec3 dayHorizon = vec3(0.62, 0.78, 0.96);
    vec3 daySky = mix(dayHorizon, dayZenith, pow(elevation, 0.6));

    // 2. Sunset Palette (Deep Indigo Zenith to Fiery Amber Horizon)
    vec3 sunsetZenith = vec3(0.12, 0.14, 0.32);
    vec3 sunsetMid = vec3(0.75, 0.28, 0.38);
    vec3 sunsetHorizon = vec3(1.0, 0.45, 0.12);
    vec3 sunsetSky = mix(mix(sunsetHorizon, sunsetMid, elevation * 1.8), sunsetZenith, pow(elevation, 0.5));
    // Solar halo glow during sunset
    sunsetSky += vec3(1.0, 0.65, 0.25) * pow(viewSunDot, 6.0) * 1.2 * sunsetFactor;

    // 3. Night Sky Palette (Deep Indigo to Cosmic Navy)
    vec3 nightZenith = vec3(0.015, 0.022, 0.045);
    vec3 nightHorizon = vec3(0.04, 0.065, 0.11);
    vec3 nightSky = mix(nightHorizon, nightZenith, pow(elevation, 0.7));

    // Blend time-of-day sky states
    vec3 baseSky = mix(nightSky, daySky, dayFactor);
#ifdef VIBRANT_SUNSET
    baseSky = mix(baseSky, sunsetSky, sunsetFactor * 0.85);
#endif

    // Rain atmospheric desaturation & dimming
    vec3 overcastSky = vec3(0.28, 0.31, 0.36) * (dayFactor * 0.65 + 0.1);
    baseSky = mix(baseSky, overcastSky, rainStrength);

    // Add night celestial features
    if (dayFactor < 0.4 && rainStrength < 0.2) {
        float nightWeight = (1.0 - dayFactor / 0.4) * (1.0 - rainStrength);
#ifdef TWINKLING_STARS
        baseSky += calculateStars(viewDir, time) * nightWeight;
#endif
#ifdef CELESTIAL_NEBULA
        baseSky += calculateCelestialNebula(viewDir, time) * nightWeight;
#endif
    }

    return baseSky;
}

// Exponential height fog with forward Mie scattering
vec3 calculateAtmosphericFog(vec3 sceneColor, vec3 worldPos, vec3 camPos, vec3 viewDir, vec3 sunDir, float time, float rainStrength) {
#ifndef ATMOSPHERIC_FOG
    return sceneColor;
#endif

    float dist = length(worldPos - camPos);
    if (dist < 1.0) return sceneColor;

    // Height-based exponential attenuation
    float camHeight = camPos.y;
    float targetHeight = worldPos.y;
    float avgHeight = (camHeight + targetHeight) * 0.5;

    // Fog density drops off smoothly above sea level (y=64)
    float heightFactor = exp(-max(avgHeight - 64.0, 0.0) * 0.025);
    float fogExtinction = 1.0 - exp(-dist * 0.0035 * FOG_DENSITY * heightFactor * (1.0 + rainStrength * 2.5));
    fogExtinction = clamp(fogExtinction, 0.0, 0.95);

    // Forward Mie scattering toward the sun/moon
    float sunElevation = sunDir.y;
    float dayFactor = smoothstep(-0.1, 0.2, sunElevation);
    float cosTheta = max(dot(viewDir, sunDir), 0.0);
    float forwardScattering = pow(cosTheta, 8.0) * 0.8;

    // Ambient fog color derived from horizon sky
    vec3 fogAmbient = calculateSkyColor(vec3(viewDir.x, 0.05, viewDir.z), sunDir, time, rainStrength);
    vec3 sunLightColor = mix(vec3(0.9, 0.6, 0.3), vec3(1.0, 0.95, 0.85), dayFactor);
    vec3 finalFogColor = fogAmbient + sunLightColor * forwardScattering * dayFactor * (1.0 - rainStrength);

    return mix(sceneColor, finalFogColor, fogExtinction);
}

#endif // AETHERIA_ATMOSPHERE_GLSL
