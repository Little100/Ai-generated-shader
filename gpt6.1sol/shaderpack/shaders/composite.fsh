#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float wetness;
uniform int worldTime;

in vec2 awTexcoord;

const float AW_BLOOM_STRENGTH = 0.62; //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
const float AW_ATMOSPHERE = 0.78; //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

/* RENDERTARGETS: 1 */

vec3 awScene(vec2 uv) {
    return texture2D(colortex0, clamp(uv, vec2(0.001), vec2(0.999))).rgb;
}

vec3 awHot(vec2 uv) {
    return max(awScene(uv) - vec3(0.70), vec3(0.0));
}

vec3 awBloom(vec2 uv, vec2 px) {
    vec3 glow = vec3(0.0);
    glow += awHot(uv + px * vec2(-3.0, -2.0)) * 0.06;
    glow += awHot(uv + px * vec2(-2.0,  0.0)) * 0.10;
    glow += awHot(uv + px * vec2(-1.0,  2.0)) * 0.12;
    glow += awHot(uv + px * vec2( 0.0, -3.0)) * 0.10;
    glow += awHot(uv + px * vec2( 0.0,  0.0)) * 0.22;
    glow += awHot(uv + px * vec2( 0.0,  3.0)) * 0.10;
    glow += awHot(uv + px * vec2( 1.0, -2.0)) * 0.12;
    glow += awHot(uv + px * vec2( 2.0,  0.0)) * 0.10;
    glow += awHot(uv + px * vec2( 3.0,  2.0)) * 0.06;
    glow += awHot(uv + px * vec2(-6.0, 0.0)) * 0.04;
    glow += awHot(uv + px * vec2( 6.0, 0.0)) * 0.04;
    return glow;
}

float awDayFactor() {
    float wave = sin(float(worldTime) * 6.2831853 / 24000.0);
    return smoothstep(-0.25, 0.35, wave);
}

float awHash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7)) + frameTimeCounter * 3.7) * 43758.5453);
}

vec3 awSoftTone(vec3 color) {
    vec3 mapped = color / (color + vec3(0.78));
    return mix(color, mapped, 0.38);
}

void main() {
    vec2 uv = awTexcoord;
    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec3 scene = awScene(uv);
    vec3 bloom = awBloom(uv, px);
    float depth = texture2D(depthtex0, uv).r;
    float day = awDayFactor();
    float wave = sin(float(worldTime) * 6.2831853 / 24000.0);
    float dusk = 1.0 - smoothstep(0.0, 0.82, abs(wave));
    float rain = clamp(rainStrength + wetness * 0.25, 0.0, 1.0);
    float distant = smoothstep(0.55, 1.0, depth);

    vec3 color = scene + bloom * AW_BLOOM_STRENGTH;
    color = awSoftTone(max(color, vec3(0.0)));
    color = mix(color, color * vec3(1.04, 0.95, 0.88) + vec3(0.014, 0.004, 0.0), dusk * 0.12);
    color = mix(color, color * vec3(0.86, 0.93, 1.08), rain * 0.14);

    vec3 atmosphericColor = mix(vec3(0.045, 0.11, 0.18), vec3(0.30, 0.56, 0.64), day);
    float haze = distant * AW_ATMOSPHERE * (0.035 + rain * 0.10);
    color = mix(color, atmosphericColor, haze);

    float edge = clamp(length(uv * 2.0 - 1.0), 0.0, 1.25);
    float vignette = smoothstep(0.36, 1.12, edge);
    color *= 1.0 - vignette * 0.16;

    float grain = awHash(gl_FragCoord.xy) - 0.5;
    color += grain * (0.0035 + 0.0015 * rain);
    gl_FragColor = vec4(max(color, vec3(0.0)), 1.0);
}
