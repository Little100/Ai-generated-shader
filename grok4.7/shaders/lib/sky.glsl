#ifndef KILN_SKY
#define KILN_SKY

vec3 sunDiskColor() {
    return vec3(1.0, 0.93, 0.78) * 18.0;
}

vec3 moonDiskColor() {
    return vec3(0.72, 0.78, 0.92) * (1.4 + K_MOON_LIGHT * 2.2);
}

vec3 rayleighPhase(float cosTheta) {
    return vec3(0.75 * (1.0 + cosTheta * cosTheta));
}

float miePhase(float cosTheta, float g) {
    float g2 = g * g;
    float num = (1.0 - g2) * (1.0 + cosTheta * cosTheta);
    float den = (2.0 + g2) * pow(1.0 + g2 - 2.0 * g * cosTheta, 1.5);
    return num / max(den, 1e-4);
}

vec3 atmosphere(vec3 viewDir, vec3 sunDir) {
    float up = viewDir.y;
    float mu = dot(viewDir, sunDir);
    float height = saturate(up * 0.5 + 0.5);
    float horizon = exp(-abs(up) * 7.5);

    vec3 zenithDay = vec3(0.18, 0.42, 0.92);
    vec3 horizonDay = vec3(0.78, 0.86, 0.95);
    vec3 zenithNight = vec3(0.012, 0.016, 0.038);
    vec3 horizonNight = vec3(0.045, 0.05, 0.07);
    vec3 twilight = vec3(0.95, 0.38, 0.16);

    vec3 day = mix(horizonDay, zenithDay, pow(height, 0.65));
    vec3 night = mix(horizonNight, zenithNight, pow(height, 0.8));
    vec3 sky = mix(night, day, K_SUN_UP);

    float sunsetBand = K_TWILIGHT * exp(-abs(up) * 3.2) * pow(saturate(mu * 0.5 + 0.5), 2.0);
    sky = mix(sky, twilight, sunsetBand * 0.85);

    vec3 betaR = vec3(5.8, 13.5, 33.1) * 1e-3;
    float optical = exp(-max(up, -0.05) * 3.5);
    vec3 scatter = betaR * rayleighPhase(mu) * optical * (0.35 + K_SUN_UP * 1.6);
    sky += scatter;

    float mie = miePhase(mu, 0.78) * horizon * (0.15 + K_SUN_UP * 0.55);
    sky += vec3(1.0, 0.85, 0.62) * mie;

    float dust = K_CLOUD_COVER * horizon * 0.35;
    sky = mix(sky, vec3(0.55, 0.52, 0.48), dust);

    if (!hasSkylight) {
        vec3 cave = vec3(0.01, 0.008, 0.012);
        if (biome_category == CAT_NETHER) {
            cave = vec3(0.22, 0.05, 0.02);
        } else if (biome_category == CAT_THE_END) {
            cave = vec3(0.04, 0.02, 0.06);
        }
        sky = cave * (0.35 + ambientLight);
    }

    return sky;
}

vec3 sunMoonDisk(vec3 viewDir) {
    vec3 col = vec3(0.0);
    float sunDot = dot(viewDir, K_SUN_DIR);
    float moonDot = dot(viewDir, K_MOON_DIR);
    float sunDisk = smoothstep(0.9996, 0.99985, sunDot);
    float moonDisk = smoothstep(0.99955, 0.9998, moonDot);
    col += sunDiskColor() * sunDisk * K_SUN_UP;
    col += moonDiskColor() * moonDisk * K_NIGHT;
    float corona = pow(saturate(sunDot), 256.0) * K_SUN_UP;
    col += vec3(1.0, 0.72, 0.38) * corona * 0.65;
    return col;
}

vec3 stars(vec3 viewDir) {
    if (!hasSkylight || K_SUN_UP > 0.85) {
        return vec3(0.0);
    }
    vec3 p = viewDir * 180.0;
    float n = hash13(floor(p));
    float spark = smoothstep(0.992, 0.999, n);
    float twinkle = 0.65 + 0.35 * sin(K_TIME * 1.7 + n * 40.0);
    vec3 tint = mix(vec3(0.7, 0.8, 1.0), vec3(1.0, 0.85, 0.65), hash13(floor(p) + 3.0));
    return tint * spark * twinkle * (1.0 - K_SUN_UP) * (1.0 - K_CLOUD_COVER * 0.7);
}

vec3 skyRadiance(vec3 viewDir) {
    return atmosphere(viewDir, K_SUN_DIR) + sunMoonDisk(viewDir) + stars(viewDir);
}

vec3 skyLightColor() {
    vec3 day = vec3(0.92, 0.95, 1.0);
    vec3 dusk = vec3(1.0, 0.55, 0.28);
    vec3 night = vec3(0.18, 0.24, 0.42) * (0.35 + K_MOON_LIGHT);
    vec3 c = mix(night, day, K_SUN_UP);
    c = mix(c, dusk, K_TWILIGHT * 0.7);
    if (!hasSkylight) {
        c = vec3(0.02);
    }
    return c;
}

vec3 sunLightColor() {
    vec3 noon = vec3(1.0, 0.96, 0.88);
    vec3 low = vec3(1.0, 0.45, 0.16);
    float lowSun = pow(1.0 - abs(K_SUN_DIR.y), 2.2) * K_SUN_UP;
    vec3 c = mix(noon, low, saturate(lowSun));
    c *= K_SUN_UP;
    if (!hasSkylight) {
        c = vec3(0.0);
    }
    return c * 4.5;
}

vec3 blockLightColor() {
    return vec3(1.0, 0.62, 0.28);
}

float cloudDensity(vec2 xz, float t) {
    vec2 p = xz * 0.004 + vec2(t * 0.012, t * 0.004);
    float base = fbm(p);
    float detail = fbm(p * 3.7 + 11.0);
    float d = base * 0.75 + detail * 0.25;
    float cover = mix(0.52, 0.28, K_CLOUD_COVER);
    return saturate((d - cover) * 3.2);
}

vec3 cloudColor(vec3 viewDir, float dist) {
    if (!hasSkylight || viewDir.y < 0.02) {
        return vec3(0.0);
    }
    float plane = 140.0;
    float t = plane / max(viewDir.y, 0.02);
    if (t > 4000.0) {
        return vec3(0.0);
    }
    vec2 xz = (cameraPosition.xz + viewDir.xz * t);
    float d = cloudDensity(xz, K_TIME);
    if (d <= 0.001) {
        return vec3(0.0);
    }
    float shade = saturate(0.35 + 0.65 * K_SUN_DIR.y);
    vec3 lit = skyLightColor() * (0.55 + shade) + sunLightColor() * 0.15 * shade;
    vec3 col = lit * mix(0.45, 1.0, d);
    float fade = exp(-t * 0.00035);
    return col * d * fade * (1.0 - rainStrength * 0.45);
}

#endif
