#ifndef WATER_GLSL
#define WATER_GLSL

// Layered drifting noise, returns roughly [0, 1]
float waterWave(vec2 p, float t) {
    vec2 d1 = vec2(0.86, 0.5);
    vec2 d2 = vec2(-0.5, 0.86);
    vec2 d3 = vec2(0.2, -0.98);
    float h = 0.0;
    h += valueNoise(p * 0.35 + d1 * t * 0.35) * 0.55;
    h += valueNoise(p * 0.9 - d2 * t * 0.5) * 0.28;
    h += valueNoise(p * 2.1 + d3 * t * 0.8) * 0.12;
    h += sin(dot(p, d1) * 1.7 + t * 1.6) * 0.05;
    return h;
}

vec3 waterNormal(vec2 p, float t, float strength) {
    float e = 0.06;
    float h0 = waterWave(p, t);
    float hx = waterWave(p + vec2(e, 0.0), t);
    float hz = waterWave(p + vec2(0.0, e), t);
    float s = strength * WATER_WAVE_HEIGHT;
    return normalize(vec3((h0 - hx) / e * s, 1.0, (h0 - hz) / e * s));
}

vec3 waterAbsorption() {
    return vec3(0.45, 0.12, 0.07) / WATER_CLARITY;
}

#endif
