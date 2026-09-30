#version 330 compatibility

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float rainStrength;
uniform float wetness;
uniform int worldTime;
uniform int isEyeInWater;

in vec2 awTexcoord;
in vec2 awLightcoord;
in vec4 awVertexColor;
in vec3 awNormal;
in vec3 awViewPosition;

/* RENDERTARGETS: 0 */

float awDayWave() {
    return sin(float(worldTime) * 6.2831853 / 24000.0);
}

float awDayFactor() {
    return smoothstep(-0.25, 0.35, awDayWave());
}

vec3 awKeyDirection() {
    vec3 sun = normalize(sunPosition + vec3(0.0001));
    vec3 moon = normalize(moonPosition + vec3(0.0001));
    return normalize(mix(moon, sun, awDayFactor()));
}

void main() {
    vec4 base = texture2D(gtexture, awTexcoord) * awVertexColor;
    if (base.a < 0.08) {
        discard;
    }

    vec3 lightmapColor = texture2D(lightmap, awLightcoord).rgb;
    vec3 normal = normalize(awNormal);
    vec3 keyDirection = awKeyDirection();
    float day = awDayFactor();
    float directional = 0.65 + 0.55 * max(dot(normal, keyDirection), 0.0);
    float ambient = 0.22 + 0.34 * lightmapColor.r + 0.18 * lightmapColor.g;
    float rain = clamp(rainStrength + wetness * 0.35, 0.0, 1.0);
    float dusk = 1.0 - smoothstep(0.0, 0.82, abs(awDayWave()));

    vec3 warm = vec3(1.10, 0.96, 0.80);
    vec3 cool = vec3(0.68, 0.82, 1.12);
    vec3 keyColor = mix(cool, warm, day);
    vec3 lit = base.rgb * lightmapColor * (ambient + directional * 0.36) * keyColor;
    lit = mix(lit, lit * vec3(0.83, 0.91, 1.08), rain * 0.28);
    lit += vec3(0.025, 0.035, 0.060) * dusk;

    if (isEyeInWater == 1) {
        lit = mix(lit, lit * vec3(0.62, 0.88, 0.96), 0.18);
    }

    gl_FragColor = vec4(max(lit, vec3(0.0)), base.a);
}
