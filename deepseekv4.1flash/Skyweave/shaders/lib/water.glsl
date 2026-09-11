/*
    Skyweave - water surface maths.

    The waves are a small sum of directional sines so the surface normal has a
    closed form derivative. No texture lookups, no derivative instructions, and
    the whole thing stays stable at any distance from the camera.
*/

#if !defined(SKYWEAVE_WATER_INCLUDED)
#define SKYWEAVE_WATER_INCLUDED

#include "/lib/math.glsl"
#include "/lib/config.glsl"

// sum of three crossing wave trains, returns a unit normal
vec3 waterWaveNormal(vec2 position, float time) {
    float speed = frameTimeCounter * WATER_WAVE_SPEED;
    float amplitude = WATER_WAVE_HEIGHT;

    vec2 dirA = normalize(vec2(1.0, 0.35));
    vec2 dirB = normalize(vec2(-0.62, 1.0));
    vec2 dirC = normalize(vec2(0.25, -0.92));

    float freqA = 0.30;
    float freqB = 0.68;
    float freqC = 1.45;

    float ampA = 1.0;
    float ampB = 0.42;
    float ampC = 0.18;

    float phaseA = dot(position, dirA) * freqA + speed * 0.85;
    float phaseB = dot(position, dirB) * freqB + speed * 1.35;
    float phaseC = dot(position, dirC) * freqC + speed * 2.10;

    // the analytic gradient of the summed heights, which is the slope we need
    vec2 slope = dirA * (cos(phaseA) * freqA * ampA)
               + dirB * (cos(phaseB) * freqB * ampB)
               + dirC * (cos(phaseC) * freqC * ampC);

    // a fine ripple layer keeps the surface from looking like glass up close
    float ripple = gradientNoise3D(vec3(position * 1.7, speed * 0.6)) * 0.35;
    slope += vec2(ripple, ripple * 0.7);

    return normalize(vec3(-slope.x * amplitude * 0.55, 1.0, -slope.y * amplitude * 0.55));
}

// how much light survives a trip through water of the given depth
vec3 waterAbsorption(float depth) {
    vec3 extinction = vec3(0.32, 0.11, 0.075) * WATER_ABSORPTION;
    return exp(-extinction * max(depth, 0.0));
}

// deep water keeps only the blue end, shallow water stays nearly clear
vec3 waterTint(float depth) {
    vec3 shallow = vec3(0.16, 0.42, 0.42);
    vec3 deep = vec3(0.015, 0.085, 0.16);
    return mix(shallow, deep, saturate(depth / 12.0));
}

#endif
