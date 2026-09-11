/*
    Skyweave - screen space effects shared by the post chain.

    Everything here reads the depth buffer and the gbuffer that the world passes
    wrote, so none of it needs geometry of its own. The depth samplers are
    declared here rather than in each program because these helpers use them.
*/

#if !defined(SKYWEAVE_POST_INCLUDED)
#define SKYWEAVE_POST_INCLUDED

#include "/lib/math.glsl"
#include "/lib/config.glsl"
#include "/lib/color.glsl"
#include "/lib/atmosphere.glsl"
#include "/lib/materials.glsl"
#include "/lib/lighting.glsl"
#include "/lib/shadow.glsl"

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

/*  ambient occlusion  */

// The horizon over each of several slices around the pixel is found by stepping
// outwards, and the occlusion follows from the sine of that horizon angle,
// which is just the dot product against the surface normal.
float computeOcclusion(vec2 uv, vec3 viewPos, vec3 viewNormal) {
#if SSAO_QUALITY == 0
    return 1.0;
#else
    const float radius = 0.85;
#if SSAO_QUALITY == 1
    const int slices = 4;
    const int steps = 4;
#elif SSAO_QUALITY == 3
    const int slices = 12;
    const int steps = 8;
#else
    const int slices = 8;
    const int steps = 6;
#endif

    float projScale = 0.5 * viewHeight * gbufferProjection[1][1];
    float radiusPixels = radius / max(-viewPos.z, 0.25) * projScale;
    float stepPixels = radiusPixels / float(steps);

    float phase = blueNoise(gl_FragCoord.xy, frameCounter) * TAU;
    float occlusion = 0.0;

    for (int s = 0; s < slices; s++) {
        float angle = (float(s) + 0.5) * (TAU / float(slices)) + phase;
        vec2 dir = vec2(cos(angle), sin(angle));
        float sinHorizon = 0.0;

        for (int i = 1; i <= steps; i++) {
            vec2 sampleUV = uv + dir * stepPixels * float(i) / vec2(viewWidth, viewHeight);
            if (sampleUV.x < 0.0 || sampleUV.x > 1.0 || sampleUV.y < 0.0 || sampleUV.y > 1.0) {
                break;
            }

            float sampleDepth = texture(depthtex1, sampleUV).r;
            if (sampleDepth >= 1.0) {
                continue;
            }

            vec3 samplePos = screenToView(sampleUV, sampleDepth, gbufferProjectionInverse);
            vec3 delta = samplePos - viewPos;
            float len = length(delta);
            if (len < 1e-4) {
                continue;
            }

            // a blocker further away covers a smaller solid angle, so its
            // effective horizon sinks back toward the tangent plane
            float sine = dot(delta / len, viewNormal);
            float attenuation = saturate(1.0 - (len * len) / (radius * radius));
            sinHorizon = max(sinHorizon, sine * attenuation);
        }

        occlusion += sinHorizon * sinHorizon;
    }

    return saturate(1.0 - occlusion / float(slices));
#endif
}

/*  aerial perspective  */

// Distant air scatters the sky back toward the camera. Because the colour comes
// from the same scattering model the dome uses, terrain disappears into exactly
// the shade of sky it is standing against.
vec3 aerialPerspective(vec3 color, vec3 cameraRelativePos, vec3 viewDir, float viewDistance) {
    // the option is a literal, so this folds away entirely when haze is off
    if (FOG_STRENGTH <= 0.0) {
        return color;
    }

    vec3 sunDir = normalize(sunPosition);

    // density is sampled at the middle of the segment, which is accurate enough
    // for a smooth exponential and costs one evaluation
    float midHeight = eyeAltitude + cameraRelativePos.y * 0.5;
    float layer = exp(-max(midHeight, 0.0) / max(FOG_HEIGHT, 1.0));

    float weather = 1.0 + rainStrength * RAIN_FOG_BOOST * 1.3;
    float density = FOG_STRENGTH * weather * layer / max(FOG_DISTANCE, 1.0);

    float amount = 1.0 - exp(-viewDistance * density);
    vec3 inscatter = atmosphericHaze(viewDir, sunDir, eyeAltitude);

    return mix(color, inscatter, saturate(amount));
}

/*  volumetric light shafts  */

// Marches the shadow map along the view ray. Sampling shadowtex1 rather than
// shadowtex0 keeps water and glass from casting solid beams.
vec3 lightShafts(vec3 viewDir, float viewDistance) {
#if VOLUMETRIC_QUALITY == 0
    return vec3(0.0);
#else
    const float marchDistance = 110.0;
#if VOLUMETRIC_QUALITY == 1
    const int marchSteps = 8;
#elif VOLUMETRIC_QUALITY == 3
    const int marchSteps = 28;
#else
    const int marchSteps = 16;
#endif

    vec3 sunDir = normalize(sunPosition);
    if (sunDir.y < -0.05) {
        return vec3(0.0);
    }

    float marchLength = min(viewDistance, marchDistance);
    float dt = marchLength / float(marchSteps);

    // one blue noise offset per pixel spreads the banding into noise that the
    // bloom pass then softens away
    float dither = blueNoise(gl_FragCoord.xy, frameCounter);

    vec3 sunRadiance = sunTransmittance(eyeAltitude, sunDir) * SUN_IRRADIANCE;
    float phase = miePhase(dot(viewDir, sunDir));

    float accumulated = 0.0;

    for (int i = 0; i < marchSteps; i++) {
        float t = (float(i) + dither) * dt;
        vec3 samplePos = viewDir * t;

        float visibility = 1.0;
        vec2 shadowUV;
        float referenceDepth;
        if (shadowProjectionFor(samplePos, shadowUV, referenceDepth)) {
            visibility = step(referenceDepth - 0.0006, texture(shadowtex1, shadowUV).r);
        }

        // the haze pools near the ground just as the fog does
        float altitude = eyeAltitude + samplePos.y;
        accumulated += visibility * exp(-max(altitude, 0.0) / max(FOG_HEIGHT, 1.0));
    }

    // accumulated * dt is the march length, so this constant is the scattering
    // coefficient scaled to blocks: raising it much past this blows the frame out
    float weight = dt * (1.0 + rainStrength * RAIN_FOG_BOOST) * 0.00005;
    return sunRadiance * (phase * accumulated * weight * VOLUMETRIC_STRENGTH);
#endif
}

/*  bloom  */

// a soft knee, so a bright surface fades into the glow instead of clipping on
vec3 brightPass(vec3 color) {
    float brightness = luminance(color);
    const float threshold = 0.75;
    const float knee = 0.55;

    float contribution = max(brightness - threshold, 0.0);
    contribution = contribution / max(contribution + knee, 1e-4);

    return color * contribution;
}

#endif
