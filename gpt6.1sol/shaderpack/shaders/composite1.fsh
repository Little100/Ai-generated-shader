#version 330 compatibility

uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float wetness;
uniform int worldTime;

in vec2 awTexcoord;

const float AW_CHROMATIC_EDGE = 0.36; //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]
const float AW_GRAIN = 0.34; //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

/* RENDERTARGETS: 0 */

vec3 awHashColor(vec2 p) {
    float a = fract(sin(dot(p, vec2(12.9898, 78.233)) + frameTimeCounter * 2.1) * 43758.5453);
    float b = fract(sin(dot(p, vec2(39.3468, 11.135)) - frameTimeCounter * 1.7) * 22578.1459);
    return vec3(a, b, fract(a + b * 0.73));
}

float awDayFactor() {
    float wave = sin(float(worldTime) * 6.2831853 / 24000.0);
    return smoothstep(-0.25, 0.35, wave);
}

void main() {
    vec2 uv = awTexcoord;
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec2 centered = uv * 2.0 - 1.0;
    float radius = clamp(length(centered), 0.0, 1.35);
    float chroma = AW_CHROMATIC_EDGE * radius * radius;
    vec2 offset = centered * px * chroma * 5.0;

    vec3 left = texture2D(colortex1, clamp(uv - offset, vec2(0.001), vec2(0.999))).rgb;
    vec3 center = texture2D(colortex1, clamp(uv, vec2(0.001), vec2(0.999))).rgb;
    vec3 right = texture2D(colortex1, clamp(uv + offset, vec2(0.001), vec2(0.999))).rgb;
    vec3 color = vec3(left.r, center.g, right.b);

    float depth = texture2D(depthtex0, uv).r;
    float rain = clamp(rainStrength + wetness * 0.25, 0.0, 1.0);
    float air = smoothstep(0.48, 1.0, depth) * (0.025 + rain * 0.08);
    vec3 airColor = mix(vec3(0.06, 0.12, 0.19), vec3(0.22, 0.45, 0.52), awDayFactor());
    color = mix(color, airColor, air);

    float vignette = smoothstep(0.42, 1.14, radius);
    color *= 1.0 - vignette * 0.11;
    color += (awHashColor(gl_FragCoord.xy) - vec3(0.5)) * (AW_GRAIN * 0.006);
    gl_FragColor = vec4(max(color, vec3(0.0)), 1.0);
}
