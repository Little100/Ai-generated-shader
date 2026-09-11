#version 330 compatibility

/*
    Vanilla clouds are lit by the same sun and the same sky as the ground, which
    is what makes them read as part of the same world rather than as a flat
    decal. The underside keeps a share of the ground bounce so the bottoms of
    thick cloud do not go black at noon.
*/

#include "/lib/buffers.glsl"
#include "/lib/surface.glsl"
#include "/lib/sky.glsl"

in vec2 texcoord;
in vec2 lmcoord;
in vec2 lightLevel;
in vec4 tint;
in vec3 worldNormal;
in vec3 worldPos;
in float viewDistance;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outScene;

void main() {
    if (tint.a < 0.02) {
        discard;
    }

    vec3 cloudColor = srgbToLinear(tint.rgb);
    vec3 normal = normalize(worldNormal);
    vec3 sunDir = normalize(sunPosition);
    float altitude = eyeAltitude + max(worldPos.y, 0.0);

    float sunAmount = saturate(dot(normal, sunDir) * 0.5 + 0.5);
    float skyAmount = saturate(dot(normal, PLANET_UP) * 0.5 + 0.5);

    vec3 sunlight = sunTransmittance(altitude, sunDir) * SUN_IRRADIANCE;
    vec3 ambient = skyRadianceCheap(normalize(mix(normal, PLANET_UP, 0.5)), sunDir, altitude) * PI;

    vec3 lit = cloudColor * (ambient * (0.35 + 0.65 * skyAmount)
                           + sunlight * pow(sunAmount, 1.6) * 0.85);
    lit += cloudColor * vec3(0.25, 0.24, 0.22) * 0.25 * skyAmount;

    // clouds fade into the same haze everything else does with distance
    vec3 viewDir = normalize(worldPos + vec3(0.0, 0.0, 1e-5));
    float hazeAmount = 1.0 - exp(-viewDistance / max(FOG_DISTANCE, 1.0));
    vec3 haze = atmosphericHaze(viewDir, sunDir, eyeAltitude);
    lit = mix(lit, haze, saturate(hazeAmount * 0.85 + rainStrength * 0.4));

    // clouds are translucent, so the vanilla alpha rides along and the blend
    // state composites them over the sky
    outScene = vec4(lit, tint.a);
}
