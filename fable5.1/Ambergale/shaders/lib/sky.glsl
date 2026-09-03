#ifndef SKY_GLSL
#define SKY_GLSL

vec3 sunDirWorld() { return normalize(mat3(gbufferModelViewInverse) * sunPosition); }
vec3 moonDirWorld() { return normalize(mat3(gbufferModelViewInverse) * moonPosition); }
vec3 shadowLightDirWorld() { return normalize(mat3(gbufferModelViewInverse) * shadowLightPosition); }

// Daylight factor centered on the sun's elevation, with a wide dusk band
float dayFactor(vec3 sunDir) { return smoothstep(-0.12, 0.18, sunDir.y); }
float duskFactor(vec3 sunDir) { return saturate(1.0 - abs(sunDir.y) * 4.5) * smoothstep(-0.28, 0.05, sunDir.y); }
float nightFactor(vec3 sunDir) { return smoothstep(0.05, -0.2, sunDir.y); }

vec3 sunColor(vec3 sunDir) {
    vec3 noon = vec3(1.0, 0.94, 0.86);
    vec3 dusk = vec3(1.0, 0.52, 0.22);
    float horizon = saturate(1.0 - sunDir.y * 3.0);
    vec3 c = mix(noon, dusk, horizon * horizon);
    return c * dayFactor(sunDir) * SUN_INTENSITY * 3.2;
}

vec3 moonColor(vec3 sunDir) {
    vec3 c = vec3(0.32, 0.46, 0.68);
    float phaseDim = 1.0 - 0.45 * float(moonPhase == 4) - 0.25 * float(moonPhase == 3 || moonPhase == 5);
    return c * nightFactor(sunDir) * 0.22 * phaseDim;
}

vec3 zenithColor(vec3 sunDir) {
    vec3 day = vec3(0.16, 0.36, 0.72);
    vec3 dusk = vec3(0.14, 0.15, 0.36);
    vec3 night = vec3(0.012, 0.022, 0.05);
    vec3 c = mix(night, day, dayFactor(sunDir));
    return mix(c, dusk, duskFactor(sunDir) * 0.6);
}

vec3 horizonColor(vec3 sunDir) {
    vec3 day = vec3(0.62, 0.74, 0.88);
    vec3 dusk = vec3(0.95, 0.5, 0.3);
    vec3 night = vec3(0.04, 0.06, 0.1);
    vec3 c = mix(night, day, dayFactor(sunDir));
    return mix(c, dusk, duskFactor(sunDir) * 0.8);
}

// Ambient light arriving from the sky dome, used for terrain lighting
vec3 skyAmbient(vec3 sunDir) {
    vec3 c = mix(zenithColor(sunDir), horizonColor(sunDir), 0.4) * 1.35;
    c = mix(c, vec3(luminance(c)) * vec3(0.85, 0.9, 1.0), rainStrength * 0.6);
    return c * SKY_AMBIENT;
}

vec3 skyGradient(vec3 dir, vec3 sunDir) {
    float up = saturate(dir.y);
    float horizonBand = pow(1.0 - up, 4.0);
    vec3 col = mix(zenithColor(sunDir), horizonColor(sunDir), horizonBand);

    // Warm scatter halo around the sun that stretches along the horizon at dusk
    float sunDot = saturate(dot(dir, sunDir));
    float halo = pow(sunDot, 6.0) * 0.55 + pow(sunDot, 48.0) * 0.9;
    vec3 haloCol = mix(vec3(1.0, 0.85, 0.6), vec3(1.0, 0.45, 0.15), duskFactor(sunDir));
    col += haloCol * halo * dayFactor(sunDir) * (1.0 - up * 0.5);

    // Cool opposing glow at night keeps the moon side readable
    vec3 moonDir = -sunDir;
    float moonDot = saturate(dot(dir, moonDir));
    col += vec3(0.18, 0.26, 0.42) * pow(moonDot, 5.0) * nightFactor(sunDir) * 0.25;

    // Below the horizon the void fades into a darker version of the horizon
    float below = smoothstep(0.0, -0.15, dir.y);
    col = mix(col, horizonColor(sunDir) * 0.35, below);

    float grey = luminance(col);
    col = mix(col, vec3(grey) * vec3(0.8, 0.85, 0.92), rainStrength * 0.75);
    return col;
}

float sunDisc(vec3 dir, vec3 sunDir) {
    float d = dot(dir, sunDir);
    return smoothstep(0.9993, 0.9997, d);
}

float moonDisc(vec3 dir, vec3 moonDir) {
    float d = dot(dir, moonDir);
    return smoothstep(0.9990, 0.9995, d);
}

float stars(vec3 dir, vec3 sunDir) {
    if (dir.y < 0.0) return 0.0;
    vec3 p = dir * 180.0;
    vec3 cell = floor(p);
    vec3 r = hash33(cell);
    vec3 center = cell + 0.5 + (r - 0.5) * 0.6;
    float dist = length(p - center);
    float star = smoothstep(0.32, 0.0, dist) * step(0.93, r.x);
    float twinkle = 0.6 + 0.4 * sin(frameTimeCounter * (1.5 + r.y * 3.0) + r.z * TAU);
    return star * twinkle * nightFactor(sunDir) * (1.0 - rainStrength) * smoothstep(0.0, 0.25, dir.y);
}

// Two cloud layers projected on a flat plane above the camera
float cloudDensity(vec2 uv, float t) {
    float base = fbm(uv * 0.55 + vec2(t * 0.015, t * 0.006), 5);
    float detail = fbm(uv * 2.3 - vec2(t * 0.03, 0.0), 3);
    float coverage = CLOUD_COVERAGE + rainStrength * 0.35;
    float d = base * 0.8 + detail * 0.2;
    return smoothstep(1.0 - coverage - 0.15, 1.0 - coverage + 0.25, d);
}

vec4 cloudLayer(vec3 dir, vec3 sunDir, float height, float scale, vec3 baseTint) {
    if (dir.y <= 0.01) return vec4(0.0);
    float dist = height / dir.y;
    vec2 uv = (cameraPosition.xz + dir.xz * dist) * scale;
    float t = frameTimeCounter;
    float d = cloudDensity(uv, t);
    if (d <= 0.001) return vec4(0.0);

    // Cheap directional lighting from a density gradient toward the sun
    vec2 toSun = sunDir.xz * 0.8;
    float dSun = cloudDensity(uv + toSun * scale * 40.0, t);
    float lit = saturate(1.0 - (dSun - d) * 2.0);

    vec3 sc = sunColor(sunDir) * 0.32 + moonColor(sunDir) * 1.5;
    vec3 amb = skyAmbient(sunDir) * 0.6;
    vec3 col = amb + sc * lit;
    col *= baseTint;
    col = mix(col, vec3(luminance(col)) * 0.7, rainStrength * 0.6);
    float fade = smoothstep(0.02, 0.18, dir.y);
    return vec4(col, d * fade * 0.92);
}

vec4 clouds(vec3 dir, vec3 sunDir) {
    vec4 high = cloudLayer(dir, sunDir, 900.0, 0.0011, vec3(1.02, 0.98, 0.94));
    vec4 low = cloudLayer(dir, sunDir, 420.0, 0.0026, vec3(0.97, 0.98, 1.0));
    vec3 col = mix(high.rgb, low.rgb, low.a);
    float a = low.a + high.a * (1.0 - low.a);
    return vec4(col, a);
}

vec3 renderSky(vec3 dir, vec3 sunDir, bool withClouds) {
    vec3 col = skyGradient(dir, sunDir);
    vec3 moonDir = -sunDir;
    col += sunColor(sunDir) * 12.0 * sunDisc(dir, sunDir) * (1.0 - rainStrength * 0.7);
    col += vec3(0.95, 0.98, 1.05) * 1.6 * moonDisc(dir, moonDir) * nightFactor(sunDir) * (1.0 - rainStrength * 0.7);
    #ifdef STARS
    col += vec3(0.85, 0.9, 1.0) * stars(dir, sunDir) * 1.8;
    #endif
    #ifdef CLOUDS
    if (withClouds) {
        vec4 c = clouds(dir, sunDir);
        col = mix(col, c.rgb, c.a);
    }
    #endif
    return col;
}

#endif
