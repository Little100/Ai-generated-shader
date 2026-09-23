#version 330 compatibility

/* RENDERTARGETS: 0 */
/*
const int colortex0Format = RGBA16F;
*/

#include "/lib/sky.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float sunAngle;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform float near;
uniform float far;
uniform int isEyeInWater;
uniform bool hasSkylight;
uniform bool hasCeiling;
uniform float viewWidth;
uniform float viewHeight;

in vec2 vUv;

vec3 viewAt(vec2 uv, float depth) {
    vec4 view = gbufferProjectionInverse * vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    return view.xyz / view.w;
}

float linearDepth(float depth) {
    return (2.0 * near * far) / max(far + near - (depth * 2.0 - 1.0) * (far - near), 0.00001);
}

void main() {
    float depth = texture2D(depthtex0, vUv).r;
    vec3 rayView = normalize(viewAt(vUv, 1.0));
    vec3 ray = normalize(mat3(gbufferModelViewInverse) * rayView);
    vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 moonDir = normalize(mat3(gbufferModelViewInverse) * moonPosition);
    float daylight = daylightAmount(sunAngle);
    float rain = clamp(rainStrength, 0.0, 1.0);
    vec3 sky = skyRadiance(ray, sunDir, moonDir, cameraPosition, frameTimeCounter, daylight, rain, hasSkylight, hasCeiling);
    vec3 color;

    if (depth >= 0.99999) {
        color = sky;
    } else {
        color = texture2D(colortex0, vUv).rgb;
        float distanceToCamera = length(viewAt(vUv, depth));
        vec3 fog = skyPalette(ray, daylight, rain, hasSkylight, hasCeiling);
        fog = mix(fog, vec3(0.07, 0.24, 0.28), 0.18);
        float density = (hasCeiling ? 0.010 : 0.0042) * FOG_DENSITY * (1.0 + rain * 1.4);
        if (isEyeInWater == 1) {
            density = 0.075 * FOG_DENSITY;
            fog = vec3(0.015, 0.18, 0.21);
        } else if (isEyeInWater == 2) {
            density = 0.16;
            fog = vec3(0.47, 0.065, 0.014);
        } else if (isEyeInWater == 3) {
            density = 0.13;
            fog = vec3(0.38, 0.28, 0.21);
        }
        float fogAmount = 1.0 - exp(-distanceToCamera * density);
        color = mix(color, fog, clamp(fogAmount, 0.0, 0.96));

    if (OUTLINE_STRENGTH > 0.0) {
        vec2 pixel = vec2(1.0 / viewWidth, 1.0 / viewHeight);
        float center = linearDepth(depth);
        float difference = 0.0;
        difference = max(difference, abs(linearDepth(texture2D(depthtex0, vUv + vec2(pixel.x, 0.0)).r) - center));
        difference = max(difference, abs(linearDepth(texture2D(depthtex0, vUv - vec2(pixel.x, 0.0)).r) - center));
        difference = max(difference, abs(linearDepth(texture2D(depthtex0, vUv + vec2(0.0, pixel.y)).r) - center));
        difference = max(difference, abs(linearDepth(texture2D(depthtex0, vUv - vec2(0.0, pixel.y)).r) - center));
        float edge = smoothstep(0.07, 0.31, difference / max(center, 1.0));
        color *= 1.0 - edge * OUTLINE_STRENGTH * (1.0 - fogAmount);
    }
    }
    gl_FragData[0] = vec4(color, 1.0);
}



