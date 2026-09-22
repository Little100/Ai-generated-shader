#ifndef KILN_SHADOW
#define KILN_SHADOW

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

float shadowCompare(sampler2D tex, vec3 coord, float bias) {
    if (coord.x < 0.0 || coord.x > 1.0 || coord.y < 0.0 || coord.y > 1.0) {
        return 1.0;
    }
    float occluder = texture2D(tex, coord.xy).r;
    return step(coord.z - bias, occluder);
}

float shadowPenumbra(vec3 coord) {
    float d = texture2D(shadowtex0, coord.xy).r;
    float blocker = max(coord.z - d, 0.0);
    return clamp(blocker * 18.0, 0.35, 6.0);
}

float sampleShadow(vec3 playerPos, vec3 normal) {
    float ndotl = saturate(dot(normal, K_LIGHT_DIR));
    float bias = mix(0.0018, 0.00025, ndotl) + length(playerPos) * 0.000015;
    vec3 base = shadowFromPlayer(playerPos + normal * 0.04);
    if (base.x <= 0.0 || base.x >= 1.0 || base.y <= 0.0 || base.y >= 1.0) {
        return 1.0;
    }

    float radius = shadowPenumbra(base) / 2048.0;
    float rot = interleavedGradient(gl_FragCoord.xy) * TAU;
    float sum = 0.0;
    int taps = 12;
    for (int i = 0; i < taps; i++) {
        vec2 o = vogelDisk(i, taps, rot) * radius;
        sum += shadowCompare(shadowtex1, base + vec3(o, 0.0), bias);
    }
    float opaque = sum / float(taps);

    float water = shadowCompare(shadowtex0, base, bias);
    vec4 tint = texture2D(shadowcolor0, base.xy);
    float colored = mix(water, 1.0, opaque);
    float transmit = luma(tint.rgb) * tint.a;
    return mix(colored, mix(opaque, 1.0, transmit), 1.0 - opaque);
}

float contactShadow(vec3 viewPos, vec3 viewN, vec3 viewL, sampler2D depthMap) {
    float acc = 0.0;
    float stepLen = 0.08;
    vec3 pos = viewPos + viewN * 0.03;
    for (int i = 0; i < 8; i++) {
        pos += viewL * stepLen;
        stepLen *= 1.25;
        vec2 uv = screenFromView(pos);
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            break;
        }
        float sceneZ = texture2D(depthMap, uv).r;
        vec3 scene = viewFromScreen(uv, sceneZ);
        float dz = scene.z - pos.z;
        if (dz > 0.02 && dz < 0.45) {
            acc += 0.22;
        }
    }
    return saturate(1.0 - acc);
}

#endif
