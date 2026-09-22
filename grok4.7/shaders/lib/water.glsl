#ifndef KILN_WATER
#define KILN_WATER

float gerstnerWave(vec2 xz, vec2 dir, float steep, float length, float speed, float t, out vec3 disp, out vec3 ncontrib) {
    float k = TAU / length;
    float phase = k * dot(dir, xz) - speed * t * sqrt(9.8 * k);
    float s = sin(phase);
    float c = cos(phase);
    disp = vec3(dir.x * steep / k * c, steep / k * s, dir.y * steep / k * c);
    ncontrib = vec3(-dir.x * steep * s, steep * c, -dir.y * steep * s);
    return s;
}

void waterSurface(vec3 worldPos, out vec3 displaced, out vec3 normal) {
    vec2 xz = worldPos.xz;
    float t = K_TIME;
    vec3 disp = vec3(0.0);
    vec3 n = vec3(0.0, 1.0, 0.0);
    vec3 d;
    vec3 nc;

    gerstnerWave(xz, normalize(vec2(1.0, 0.35)), 0.18, 9.0, 1.15, t, d, nc);
    disp += d;
    n.y -= nc.y;
    n.xz -= nc.xz;
    gerstnerWave(xz, normalize(vec2(-0.4, 1.0)), 0.14, 5.5, 1.45, t, d, nc);
    disp += d;
    n.y -= nc.y;
    n.xz -= nc.xz;
    gerstnerWave(xz, normalize(vec2(0.2, -1.0)), 0.09, 2.8, 1.9, t, d, nc);
    disp += d;
    n.y -= nc.y;
    n.xz -= nc.xz;
    gerstnerWave(xz, normalize(vec2(-0.8, -0.3)), 0.05, 1.3, 2.4, t, d, nc);
    disp += d;
    n.y -= nc.y;
    n.xz -= nc.xz;

    float rainRipple = rainStrength * sin(dot(xz, vec2(6.0, 4.0)) * 3.0 - t * 8.0) * 0.015;
    disp.y += rainRipple;
    displaced = worldPos + disp * (0.65 + rainStrength * 0.25);
    normal = normalize(n);
}

vec3 waterScatterColor() {
    vec3 clearC = vec3(0.02, 0.18, 0.28);
    vec3 swamp = vec3(0.08, 0.14, 0.06);
    vec3 ocean = vec3(0.01, 0.12, 0.28);
    vec3 warm = vec3(0.02, 0.28, 0.32);
    vec3 frozen = vec3(0.08, 0.16, 0.24);
    vec3 c = clearC;
    if (biome_category == CAT_SWAMP) {
        c = swamp;
    } else if (biome_category == CAT_OCEAN) {
        c = mix(ocean, warm, saturate(temperature));
    } else if (biome_category == CAT_ICY || biome_category == CAT_RIVER && temperature < 0.15) {
        c = frozen;
    }
    return c;
}

float waterAbsorption(float dist) {
    return exp(-dist * mix(0.08, 0.18, rainStrength));
}

vec3 beerLambert(vec3 coeff, float dist) {
    return exp(-coeff * dist);
}

#endif
