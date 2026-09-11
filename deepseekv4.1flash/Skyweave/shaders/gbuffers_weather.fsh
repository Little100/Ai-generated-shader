#version 330 compatibility

/*
    Rain and snow. Distant streaks fade out instead of being drawn as thin
    aliased slivers, and the colour is pulled toward the haze so a downpour
    reads as weather rather than as a texture pasted over the screen.
*/

#include "/lib/buffers.glsl"
#include "/lib/surface.glsl"

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
    vec4 base = texture(gtexture, texcoord) * tint;
    if (base.a < 0.02) {
        discard;
    }

    float fade = 1.0 - smoothstep(12.0, 42.0, viewDistance);
    if (fade <= 0.01) {
        discard;
    }

    vec3 viewDir = normalize(worldPos + vec3(0.0, 0.0, 1e-5));
    vec3 sunDir = normalize(sunPosition);

    vec3 albedo = srgbToLinear(base.rgb);
    vec3 sunlight = sunTransmittance(eyeAltitude, sunDir) * SUN_IRRADIANCE;
    vec3 ambient = skyRadianceCheap(normalize(mix(-viewDir, PLANET_UP, 0.6)), sunDir, eyeAltitude) * PI;

    // rain is thin, so it lights up strongly when the sun is behind it
    float backlight = pow(saturate(dot(viewDir, sunDir)), 3.0);

    vec3 lit = albedo * (ambient * 0.6 + sunlight * (0.35 + backlight * 1.6));
    lit += albedo * lightLevel.x * 0.4;

    // the texture alpha is what makes a streak a streak, and the blend state
    // turns it into a translucency for us
    outScene = vec4(lit * fade, base.a);
}
