#ifndef FOG_GLSL
#define FOG_GLSL

// Height-weighted atmospheric fog tinted by the sky toward the horizon
vec3 applyFog(vec3 color, vec3 playerPos, vec3 viewDirWorld, vec3 sunDir, bool isSky) {
    float dist = length(playerPos);
    float worldY = playerPos.y + cameraPosition.y;

    float density = 0.0032 * FOG_DENSITY;
    density *= 1.0 + rainStrength * 2.5;
    density *= mix(1.0, 0.4, saturate((worldY - 70.0) / 90.0));
    float duskBoost = 1.0 + duskFactor(sunDir) * 0.8;
    density *= duskBoost;

    float fogAmount = 1.0 - exp(-dist * density);
    // Far distances always settle toward the horizon so chunk edges dissolve
    float edge = smoothstep(far * 0.55, far * 0.95, dist);
    fogAmount = max(fogAmount, edge * 0.9);

    vec3 fogCol = skyGradient(normalize(vec3(viewDirWorld.x, max(viewDirWorld.y, 0.02), viewDirWorld.z)), sunDir);
    fogCol = mix(fogCol, horizonColor(sunDir), 0.35);

    if (isSky) {
        // Sky only receives a faint haze band so clouds stay crisp overhead
        float haze = (1.0 - saturate(viewDirWorld.y * 3.0)) * rainStrength * 0.5;
        return mix(color, fogCol, haze);
    }
    return mix(color, fogCol, saturate(fogAmount));
}

vec3 applyWaterFog(vec3 color, float dist, vec3 skyAmb) {
    vec3 absorb = exp(-waterAbsorption() * dist * 0.5);
    vec3 scatter = vec3(0.05, 0.22, 0.32) * skyAmb * (1.0 - exp(-dist * 0.045));
    return color * absorb + scatter;
}

vec3 applyLavaFog(vec3 color, float dist) {
    float a = 1.0 - exp(-dist * 1.8);
    return mix(color, vec3(1.0, 0.32, 0.05), a);
}

vec3 applySnowFog(vec3 color, float dist) {
    float a = 1.0 - exp(-dist * 1.2);
    return mix(color, vec3(0.85, 0.9, 1.0), a);
}

#endif
