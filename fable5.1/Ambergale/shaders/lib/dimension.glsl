#ifndef DIMENSION_GLSL
#define DIMENSION_GLSL

// Dimension-specific sky and ambient, selected by DIM_NETHER / DIM_END macros from the world folders

#ifdef DIM_NETHER
vec3 dimAmbient() {
    return vec3(0.34, 0.13, 0.07) * 1.1 + fogColor * 0.35;
}

vec3 dimSky(vec3 dir) {
    vec3 base = mix(vec3(0.16, 0.05, 0.03), fogColor * 0.9, 0.5);
    float haze = fbm(dir.xz * 3.0 + vec2(frameTimeCounter * 0.02), 3);
    vec3 glow = vec3(0.6, 0.2, 0.06) * (0.3 + 0.7 * haze) * (1.0 - abs(dir.y));
    return base + glow * 0.35;
}
#endif

#ifdef DIM_END
vec3 dimAmbient() {
    return vec3(0.12, 0.10, 0.19);
}

vec3 dimSky(vec3 dir) {
    vec3 base = vec3(0.03, 0.02, 0.06);
    float nebula = fbm(dir.xz * 2.5 + dir.y * 1.5 + 3.0, 4);
    vec3 neb = vec3(0.22, 0.12, 0.38) * pow(nebula, 2.5) * 0.9;
    vec3 p = dir * 220.0;
    vec3 cell = floor(p);
    vec3 r = hash33(cell);
    float star = smoothstep(0.3, 0.0, length(p - (cell + 0.5 + (r - 0.5) * 0.6))) * step(0.9, r.x);
    return base + neb + vec3(0.7, 0.75, 1.0) * star * 1.2;
}
#endif

#endif
