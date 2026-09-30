#version 330 compatibility

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float rainStrength;
uniform float wetness;
uniform int worldTime;
uniform sampler2D shadowtex0;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;

in vec4 awVertexColor;
in vec3 awNormal;
in vec3 awViewPosition;
in vec2 awLightcoord;

/* RENDERTARGETS: 0 */

float awDayFactor() {
    float wave = sin(float(worldTime) * 6.2831853 / 24000.0);
    return smoothstep(-0.25, 0.35, wave);
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
    vec2 lmcoord = clamp(awLightcoord, vec2(0.0), vec2(1.0));
    vec3 lightmapColor = vec3(lmcoord.x, lmcoord.y, lmcoord.y);
    vec3 sun = normalize(sunPosition + vec3(0.0001));
    vec3 moon = normalize(moonPosition + vec3(0.0001));
    vec3 key = normalize(mix(moon, sun, awDayFactor()));
    float directional = 0.72 + 0.45 * max(dot(normalize(awNormal), key), 0.0);
    float shadow = mix(1.0, awShadow(awViewPosition), awDayFactor());
    float rain = clamp(rainStrength + wetness * 0.35, 0.0, 1.0);
    vec3 lightColor = mix(vec3(0.72, 0.84, 1.08), vec3(1.10, 0.98, 0.82), awDayFactor());
    vec3 color = awVertexColor.rgb * lightmapColor * directional * shadow * lightColor;
    color = mix(color, color * vec3(0.83, 0.91, 1.08), rain * 0.22);
    gl_FragColor = vec4(max(color, vec3(0.0)), awVertexColor.a);
}
