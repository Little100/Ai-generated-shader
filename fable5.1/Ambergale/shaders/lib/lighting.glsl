#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL

// Block light warms from amber toward a cooler tone as it fades out
vec3 blocklightColor(float level) {
    vec3 hot = vec3(1.0, 0.72, 0.42);
    vec3 warm = vec3(1.0, 0.55, 0.25);
    vec3 col = mix(warm, hot, level);
    vec3 neutral = vec3(1.0, 0.9, 0.78);
    return mix(neutral, col, saturate(BLOCKLIGHT_WARMTH * 0.5));
}

float emberFlicker(vec3 worldPos) {
    #ifdef EMBER_FLICKER
    float t = frameTimeCounter;
    float n = valueNoise(vec2(t * 3.1, dot(worldPos, vec3(0.13, 0.31, 0.17))));
    return 0.92 + 0.08 * n;
    #else
    return 1.0;
    #endif
}

vec3 blocklight(float level, vec3 worldPos) {
    float l = pow(level, 2.2);
    l = l * 1.15 + pow(level, 6.0) * 0.6;
    return blocklightColor(level) * l * BLOCKLIGHT_INTENSITY * 1.4 * emberFlicker(worldPos);
}

float handLightLevel(vec3 viewPos) {
    #ifdef HAND_LIGHT
    float lv = float(max(heldBlockLightValue, heldBlockLightValue2)) / 15.0;
    float dist = length(viewPos);
    float falloff = saturate(1.0 - dist / (lv * 14.0 + 0.01));
    return lv * falloff * falloff;
    #else
    return 0.0;
    #endif
}

// Sky-facing ambient with a soft hemispheric tilt so ceilings read darker than floors
vec3 ambientLight(vec3 skyAmb, vec3 normalWorld, float skyLevel, float ao) {
    float up = normalWorld.y * 0.5 + 0.5;
    float hemi = mix(0.55, 1.0, up);
    float skyOcc = pow(skyLevel, 1.6);
    vec3 ambient = skyAmb * hemi * skyOcc;
    vec3 cave = vec3(0.012, 0.014, 0.02) * (1.0 - skyOcc);
    return (ambient + cave) * ao;
}

vec3 directLight(vec3 lightCol, vec3 normalWorld, vec3 lightDir, vec3 shadow, float skyLevel, int mat) {
    float NoL = dot(normalWorld, lightDir);
    float wrap = mat == MAT_LEAVES || mat == MAT_PLANT ? 0.45 : 0.0;
    float diff = saturate((NoL + wrap) / (1.0 + wrap));
    // Leaves and grass let some light through their backside
    float translucency = (mat == MAT_LEAVES || mat == MAT_PLANT) ? saturate(-NoL) * 0.35 : 0.0;
    float skyGate = smoothstep(0.0, 0.35, skyLevel);
    return lightCol * (diff + translucency) * shadow * skyGate;
}

// Blinn-Phong style highlight, only on wet or glossy surfaces
vec3 specularHighlight(vec3 lightCol, vec3 normalWorld, vec3 lightDir, vec3 viewDirWorld, float gloss, vec3 shadow) {
    vec3 h = normalize(lightDir + viewDirWorld);
    float NoH = saturate(dot(normalWorld, h));
    float power = mix(12.0, 160.0, gloss);
    float spec = pow(NoH, power) * (power + 8.0) / 25.0;
    float fresnel = pow(1.0 - saturate(dot(normalWorld, viewDirWorld)), 5.0);
    return lightCol * spec * mix(0.04, 0.35, fresnel) * gloss * shadow;
}

#endif
