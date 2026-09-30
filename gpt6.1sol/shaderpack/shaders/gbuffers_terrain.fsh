#version 330 compatibility

uniform sampler2D gtexture;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float rainStrength;
uniform float wetness;
uniform int worldTime;
uniform int isEyeInWater;
uniform sampler2D shadowtex0;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;

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

float awShadow(vec3 viewPosition) {
    vec4 shadowClip = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(viewPosition, 1.0);
    vec3 shadowCoord = shadowClip.xyz / max(abs(shadowClip.w), 0.0001);
    shadowCoord = shadowCoord * 0.5 + 0.5;
    if (shadowCoord.x <= 0.002 || shadowCoord.x >= 0.998 || shadowCoord.y <= 0.002 || shadowCoord.y >= 0.998 || shadowCoord.z <= 0.0 || shadowCoord.z >= 1.0) {
        return 1.0;
    }

    vec2 texel = vec2(1.0 / 2048.0);
    float visible = 0.0;
    float receiver = shadowCoord.z - 0.0018;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            float stored = texture2D(shadowtex0, shadowCoord.xy + vec2(x, y) * texel).r;
            visible += receiver <= stored ? 1.0 : 0.0;
        }
    }
    return visible / 9.0;
}

void main() {
    vec4 base = texture2D(gtexture, awTexcoord) * awVertexColor;
    if (base.a < 0.08) {
        discard;
    }

    vec2 lmcoord = clamp(awLightcoord, vec2(0.0), vec2(1.0));
    vec3 lightmapColor = vec3(lmcoord.x, lmcoord.y, lmcoord.y);
    vec3 normal = normalize(awNormal);
    vec3 keyDirection = awKeyDirection();
    float day = awDayFactor();
    float directional = 0.65 + 0.55 * max(dot(normal, keyDirection), 0.0);
    float shadow = mix(1.0, awShadow(awViewPosition), awDayFactor());
    float ambient = 0.22 + 0.34 * lightmapColor.r + 0.18 * lightmapColor.g;
    float rain = clamp(rainStrength + wetness * 0.35, 0.0, 1.0);
    float dusk = 1.0 - smoothstep(0.0, 0.82, abs(awDayWave()));

    vec3 warm = vec3(1.10, 0.96, 0.80);
    vec3 cool = vec3(0.68, 0.82, 1.12);
    vec3 keyColor = mix(cool, warm, day);
    vec3 lit = base.rgb * lightmapColor * (ambient + directional * 0.36 * shadow) * keyColor;
    lit = mix(lit, lit * vec3(0.83, 0.91, 1.08), rain * 0.28);
    lit += vec3(0.025, 0.035, 0.060) * dusk;

    if (isEyeInWater == 1) {
        lit = mix(lit, lit * vec3(0.62, 0.88, 0.96), 0.18);
    }

    gl_FragColor = vec4(max(lit, vec3(0.0)), base.a);
}
