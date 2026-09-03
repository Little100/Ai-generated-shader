#ifndef SHADOW_GLSL
#define SHADOW_GLSL

// Pull shadow texels toward the camera so nearby shadows get most of the map
vec3 distortShadow(vec3 clipPos) {
    float d = length(clipPos.xy);
    float factor = mix(1.0, d, 0.85) + 0.05;
    clipPos.xy /= factor;
    clipPos.z *= 0.2;
    return clipPos;
}

vec3 playerToShadowScreen(vec3 playerPos, out float distortFactor) {
    vec3 sv = (shadowModelView * vec4(playerPos, 1.0)).xyz;
    vec4 sc = shadowProjection * vec4(sv, 1.0);
    vec3 clip = sc.xyz / sc.w;
    distortFactor = mix(1.0, length(clip.xy), 0.85) + 0.05;
    clip = distortShadow(clip);
    return clip * 0.5 + 0.5;
}

vec2 vogelDisk(int i, int count, float phi) {
    float r = sqrt((float(i) + 0.5) / float(count));
    float theta = float(i) * 2.39996323 + phi;
    return vec2(cos(theta), sin(theta)) * r;
}

// Returns rgb transmittance: 1 lit, tinted for stained glass and water, 0 in solid shadow
vec3 sampleShadow(vec3 playerPos, vec3 normalWorld, vec3 lightDir, float screenNoise) {
    float NoL = dot(normalWorld, lightDir);
    // Offset along the normal to fight acne on grazing angles
    playerPos += normalWorld * (0.03 + 0.08 * (1.0 - saturate(NoL)));
    float distortFactor;
    vec3 ss = playerToShadowScreen(playerPos, distortFactor);
    if (ss.x < 0.0 || ss.x > 1.0 || ss.y < 0.0 || ss.y > 1.0) return vec3(1.0);

    float bias = 0.00012 * distortFactor * distortFactor;
    float depth = ss.z - bias;

    #if SHADOW_QUALITY == 0
    const int taps = 1;
    #elif SHADOW_QUALITY == 1
    const int taps = 8;
    #else
    const int taps = 16;
    #endif

    float radius = SHADOW_SOFTNESS * 1.6 / float(shadowMapResolution) * distortFactor;
    float phi = screenNoise * TAU;
    vec3 result = vec3(0.0);
    for (int i = 0; i < taps; i++) {
        vec2 off = taps == 1 ? vec2(0.0) : vogelDisk(i, taps, phi) * radius;
        vec2 uv = ss.xy + off;
        float opaque = step(depth, texture(shadowtex1, uv).r);
        float all = step(depth, texture(shadowtex0, uv).r);
        vec4 tint = texture(shadowcolor0, uv);
        vec3 translucent = mix(tint.rgb * (1.0 - tint.a * 0.4), vec3(1.0), all);
        result += mix(vec3(0.0), translucent, opaque);
    }
    return result / float(taps);
}

#endif
