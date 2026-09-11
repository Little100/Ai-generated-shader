/*
    Skyweave - shadow map lookup and filtering.

    The map is warped toward the player so the texels we have are spent where
    they are seen. The warp is a pure function of normalised device coordinates,
    so the fragment side can apply the identical function to a world position
    and land on the exact texel the shadow pass wrote.

    Self shadowing is pushed back with a normal offset measured in shadow texels
    rather than with a depth bias, which holds up far better on grazing faces
    such as the tops of fences and the sides of stairs.
*/

#if !defined(SKYWEAVE_SHADOW_INCLUDED)
#define SKYWEAVE_SHADOW_INCLUDED

#include "/lib/math.glsl"
#include "/lib/config.glsl"

uniform sampler2D shadowtex1;

const int shadowMapResolution = 2048;
const bool shadowHardwareFiltering = false;
const bool shadowtex1Nearest = true;

#if SHADOW_DISTANCE == 0
const float shadowDistance = 64.0;
#elif SHADOW_DISTANCE == 1
const float shadowDistance = 128.0;
#elif SHADOW_DISTANCE == 3
const float shadowDistance = 256.0;
#else
const float shadowDistance = 192.0;
#endif

// how hard the warp pulls texels toward the centre of the map
const float SHADOW_DISTORTION = 1.0;

// residual depth bias, tiny because the normal offset does the real work
const float SHADOW_DEPTH_BIAS = 0.00002;

// angular radius of the sun expressed against the shadow frustum, this sets how
// quickly penumbrae open up as the receiver moves away from its blocker
const float SUN_ANGULAR_SIZE = 0.0026;

// the frustum spans roughly this many blocks across the whole map
float shadowFrustumExtent() {
    return 2.0 * shadowDistance;
}

// world size of one shadow texel before the warp tightens it near the centre
float shadowTexelWorldSize() {
    return shadowFrustumExtent() / float(shadowMapResolution);
}

// The warp is a mobius map: it magnifies the middle of the frustum where the
// player actually looks and squeezes the rim, while still sending radius one to
// radius one so the whole map stays in use. A plain radius + k * radius^3 would
// do the opposite and spill past the edge of the texture.
float warpRadius(float radius) {
    return radius * (1.0 + SHADOW_DISTORTION) / (1.0 + SHADOW_DISTORTION * radius);
}

float unwarpRadius(float warped) {
    return warped / max(1.0 + SHADOW_DISTORTION * (1.0 - warped), 1e-4);
}

vec2 distortShadowNDC(vec2 ndc) {
    float radius = length(ndc);
    if (radius < 1e-5) {
        return ndc;
    }
    return ndc * (warpRadius(radius) / radius);
}

// local texel size in shadow uv, scaled by the inverse derivative of the warp
// so that a filter keeps a roughly constant world space radius across the map
vec2 shadowTexelSize(vec2 distortedNDC) {
    float warped = length(distortedNDC);
    float radius = unwarpRadius(warped);
    float denominator = 1.0 + SHADOW_DISTORTION * radius;
    float derivative = (1.0 + SHADOW_DISTORTION) / (denominator * denominator);
    return vec2(1.0 / (float(shadowMapResolution) * max(derivative, 1e-3)));
}

// world position to shadow map uv plus the reference depth, returns false when
// the point falls outside the map
bool shadowProjectionFor(vec3 worldPos, out vec2 shadowUV, out float shadowDepth) {
    vec4 clip = shadowProjection * (shadowModelView * vec4(worldPos, 1.0));
    shadowUV = vec2(0.0);
    shadowDepth = 0.0;

    if (clip.w <= 0.0) {
        return false;
    }

    vec3 ndc = clip.xyz / clip.w;
    vec2 warped = distortShadowNDC(ndc.xy);
    if (abs(warped.x) > 1.0 || abs(warped.y) > 1.0) {
        return false;
    }

    shadowUV = warped * 0.5 + 0.5;
    // the depth texture holds window space depth, near maps to zero
    shadowDepth = ndc.z * 0.5 + 0.5;

    return shadowDepth >= 0.0 && shadowDepth <= 1.0;
}

// fixed radius pcf
float sampleShadowPCF(vec2 shadowUV, float referenceDepth, float radius, int samples) {
    vec2 texel = shadowTexelSize(shadowUV * 2.0 - 1.0) * radius;
    float visible = 0.0;

    for (int i = 0; i < samples; i++) {
        vec2 offset = discSample(i, samples) * texel;
        float stored = texture(shadowtex1, shadowUV + offset).r;
        visible += step(referenceDepth - SHADOW_DEPTH_BIAS, stored);
    }

    return visible / float(samples);
}

// blocker search plus variable radius filter, this is what opens the wide soft
// penumbrae under distant occluders such as a tree canopy
float sampleShadowPCSS(vec2 shadowUV, float referenceDepth, int blockerSamples, int filterSamples) {
    vec2 distortedNDC = shadowUV * 2.0 - 1.0;
    vec2 searchStep = shadowTexelSize(distortedNDC) * 3.0;

    float blockerSum = 0.0;
    float blockerCount = 0.0;
    for (int i = 0; i < blockerSamples; i++) {
        vec2 offset = discSample(i, blockerSamples) * searchStep;
        float stored = texture(shadowtex1, shadowUV + offset).r;
        if (stored < referenceDepth - SHADOW_DEPTH_BIAS) {
            blockerSum += stored;
            blockerCount += 1.0;
        }
    }

    if (blockerCount < 0.5) {
        return 1.0;
    }

    // similar triangles between the light, the blocker and the receiver give the
    // penumbra width in shadow map units
    float averageBlocker = blockerSum / blockerCount;
    float penumbra = (referenceDepth - averageBlocker) / max(averageBlocker, 1e-5);
    float radius = clamp(penumbra * SUN_ANGULAR_SIZE * float(shadowMapResolution) * SHADOW_SOFTNESS,
                         1.0, 22.0);

    vec2 texel = shadowTexelSize(distortedNDC);
    float visible = 0.0;
    for (int i = 0; i < filterSamples; i++) {
        vec2 offset = discSample(i, filterSamples) * texel * radius;
        float stored = texture(shadowtex1, shadowUV + offset).r;
        visible += step(referenceDepth - SHADOW_DEPTH_BIAS, stored);
    }

    return visible / float(filterSamples);
}

// distance from the eye, used to fade shadows out before the frustum ends so
// the boundary never shows up as a line across the ground
float shadowFade(float viewDistance) {
    return 1.0 - smoothstep(shadowDistance * 0.70, shadowDistance * 0.97, viewDistance);
}

// the single entry point every lit pass uses
float shadowVisibility(vec3 worldPos, vec3 worldNormal, float viewDistance, float normalDotLight) {
    float fade = shadowFade(viewDistance);
    if (fade <= 0.0) {
        return 1.0;
    }

    // grazing faces need a larger push or they shadow themselves
    float slope = clamp(1.0 - normalDotLight * normalDotLight, 0.0, 1.0);
    vec3 offsetPos = worldPos + worldNormal * (shadowTexelWorldSize() * (1.0 + slope * 1.6));

    vec2 shadowUV;
    float referenceDepth;
    if (!shadowProjectionFor(offsetPos, shadowUV, referenceDepth)) {
        return 1.0;
    }

#if SHADOW_FILTER == 0
    float visibility = sampleShadowPCF(shadowUV, referenceDepth, 1.25 * SHADOW_SOFTNESS, 5);
#elif SHADOW_FILTER == 2
    float visibility = sampleShadowPCSS(shadowUV, referenceDepth, 8, 18);
#else
    float visibility = sampleShadowPCF(shadowUV, referenceDepth, 5.0 * SHADOW_SOFTNESS, 12);
#endif

    return mix(1.0, visibility, fade);
}

#endif
