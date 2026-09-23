#ifndef LOOMLIGHT_GEOMETRY_FRAGMENT
#define LOOMLIGHT_GEOMETRY_FRAGMENT

#include "/lib/settings.glsl"
#include "/lib/noise.glsl"

uniform sampler2D texture;
uniform sampler2D shadowtex0;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform float sunAngle;
uniform float rainStrength;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform bool hasSkylight;
#include "/lib/lighting.glsl"

in vec2 vUv;
in vec2 vLm;
in vec4 vColor;
in vec3 vNormal;
in vec3 vPlayerPos;
in vec3 vViewPos;
in float vBlockId;

void main() {
    vec4 texel = vec4(1.0);
#if !defined(PASS_BASIC) && !defined(PASS_SKYBASIC)
    texel = texture2D(texture, vUv);
#endif
    vec4 base = texel * vColor;
    if (base.a < 0.1) discard;

#if defined(PASS_SKYBASIC) || defined(PASS_SKYTEXTURED) || defined(PASS_WEATHER) || defined(PASS_EMISSIVE) || defined(PASS_GLINT)
    gl_FragData[0] = base;
#else
    vec3 normal = normalize(vNormal);
    vec3 color;
#ifdef PASS_WATER
    if (abs(vBlockId - 10020.0) < 0.5) {
        vec3 worldPos = vPlayerPos + cameraPosition;
        vec2 flow = worldPos.xz * 0.18 + frameTimeCounter * vec2(0.10, -0.07);
        float ripples = noise2(flow * 2.4) * 0.5 + sin(dot(worldPos.xz, vec2(3.3, 2.7)) + frameTimeCounter * 2.6) * 0.5;
        vec3 viewDir = normalize(-vViewPos);
        float fresnel = pow(1.0 - abs(dot(normal, viewDir)), 3.0);
        vec3 waterTint = mix(vec3(0.025, 0.20, 0.25), vec3(0.22, 0.47, 0.49), 0.45 + ripples * 0.15);
        float shimmer = pow(max(dot(reflect(-normalize(shadowLightPosition), normal), viewDir), 0.0), 72.0);
        color = waterTint * (0.65 + clamp(vLm.y, 0.0, 1.0) * 0.48) + vec3(0.72, 0.85, 0.74) * (fresnel * 0.42 + shimmer * 0.46);
        base.a = clamp(0.64 + fresnel * 0.20, 0.0, 0.94);
    } else {
        color = illuminate(base.rgb, normal, vPlayerPos, vLm, 0.0);
    }
#else
#ifdef PASS_HAND
    color = base.rgb * vec3(0.91, 0.95, 0.97);
#else
    color = illuminate(base.rgb, normal, vPlayerPos, vLm, 0.0);
#endif
#endif
    gl_FragData[0] = vec4(color, base.a);
#endif
}

#endif

