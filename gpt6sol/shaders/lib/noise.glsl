#ifndef LOOMLIGHT_NOISE
#define LOOMLIGHT_NOISE

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise2(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash12(cell);
    float b = hash12(cell + vec2(1.0, 0.0));
    float c = hash12(cell + vec2(0.0, 1.0));
    float d = hash12(cell + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float cloudNoise(vec2 p) {
    float result = 0.0;
    float weight = 0.55;
    for (int i = 0; i < 4; ++i) {
        result += weight * noise2(p);
        p = p * 2.03 + vec2(17.7, 9.4);
        weight *= 0.5;
    }
    return result / 1.03125;
}

#endif
