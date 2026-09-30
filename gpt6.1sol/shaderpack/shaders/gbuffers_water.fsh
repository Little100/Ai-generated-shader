#version 330 compatibility

uniform sampler2D gtexture;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float wetness;
uniform int worldTime;
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
    vec4 base = texture2D(gtexture, awTexcoord) * awVertexColor;
    vec2 lmcoord = clamp(awLightcoord, vec2(0.0), vec2(1.0));
    vec3 lightmapColor = vec3(lmcoord.x, lmcoord.y, lmcoord.y);
    vec3 sun = normalize(sunPosition + vec3(0.0001));
    vec3 moon = normalize(moonPosition + vec3(0.0001));
    vec3 key = normalize(mix(moon, sun, awDayFactor()));
    float directional = 0.72 + 0.42 * max(dot(normalize(awNormal), key), 0.0);
    float shadow = mix(1.0, awShadow(awViewPosition), awDayFactor());
    vec2 flow = awViewPosition.xz * 0.045 + vec2(frameTimeCounter * 0.018, -frameTimeCounter * 0.012);
    float waveA = sin(flow.x * 8.0 + sin(flow.y * 3.0));
    float waveB = cos(flow.y * 7.0 + sin(flow.x * 2.0));
    float ripple = 0.5 + 0.5 * waveA * waveB;
    vec3 waterTint = mix(vec3(0.035, 0.18, 0.24), vec3(0.055, 0.32, 0.38), awDayFactor());
    vec3 color = mix(base.rgb, waterTint, 0.38) * lightmapColor * directional * shadow;
    color += vec3(0.02, 0.08, 0.10) * pow(max(ripple, 0.0), 3.0);
    color = mix(color, color * vec3(0.80, 0.92, 1.12), clamp(rainStrength + wetness * 0.2, 0.0, 1.0) * 0.22);
    gl_FragColor = vec4(max(color, vec3(0.0)), clamp(base.a * 0.78, 0.05, 0.86));
}
