#version 330 compatibility

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform int worldTime;
uniform vec3 sunPosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

/* RENDERTARGETS: 0 */

float awDayWave() {
    return sin(float(worldTime) * 6.2831853 / 24000.0);
}

float awDayFactor() {
    return smoothstep(-0.25, 0.35, awDayWave());
}

vec3 awViewRay() {
    vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    vec4 clip = vec4(uv * 2.0 - 1.0, 1.0, 1.0);
    vec4 view = gbufferProjectionInverse * clip;
    return normalize(view.xyz / max(abs(view.w), 0.0001));
}

void main() {
    vec3 ray = awViewRay();
    float up = clamp(ray.y * 0.5 + 0.5, 0.0, 1.0);
    float day = awDayFactor();
    float dusk = 1.0 - smoothstep(0.0, 0.82, abs(awDayWave()));
    float rain = clamp(rainStrength, 0.0, 1.0);

    vec3 dayHorizon = vec3(0.40, 0.66, 0.78);
    vec3 dayZenith = vec3(0.075, 0.19, 0.38);
    vec3 nightHorizon = vec3(0.045, 0.10, 0.20);
    vec3 nightZenith = vec3(0.008, 0.018, 0.055);
    vec3 horizon = mix(nightHorizon, dayHorizon, day);
    vec3 zenith = mix(nightZenith, dayZenith, day);
    vec3 sky = mix(horizon, zenith, pow(up, 0.72));

    vec3 duskColor = vec3(0.46, 0.16, 0.28);
    sky += duskColor * dusk * pow(1.0 - up, 1.7) * 0.58;
    sky = mix(sky, vec3(dot(sky, vec3(0.30, 0.59, 0.11))), rain * 0.28);

    vec3 sunDir = normalize(sunPosition + vec3(0.0001));
    float sunDot = max(dot(ray, sunDir), 0.0);
    float sunDisc = smoothstep(0.9984, 0.9997, sunDot) * day;
    float sunHalo = pow(sunDot, 44.0) * (0.09 + 0.18 * day);
    sky += vec3(1.00, 0.54, 0.22) * sunDisc;
    sky += vec3(1.00, 0.27, 0.10) * sunHalo;

    float ribbon = sin(ray.x * 8.0 + ray.z * 5.0 + frameTimeCounter * 0.018);
    ribbon += 0.55 * sin(ray.x * 19.0 - ray.z * 7.0 - frameTimeCounter * 0.011);
    float ribbonBand = smoothstep(0.33, 0.86, ray.y) * (1.0 - smoothstep(0.72, 0.98, ray.y));
    float ribbonGlow = smoothstep(0.52, 0.96, ribbon * 0.5 + 0.5) * ribbonBand;
    sky += vec3(0.06, 0.22, 0.25) * ribbonGlow * (0.22 + 0.78 * (1.0 - day));

    float starField = sin(ray.x * 181.0 + ray.y * 97.0) * sin(ray.z * 137.0 - ray.x * 61.0);
    float stars = smoothstep(0.93, 0.995, starField) * (1.0 - day) * smoothstep(0.0, 0.35, up);
    sky += vec3(0.44, 0.68, 0.92) * stars * 0.48;

    gl_FragColor = vec4(max(sky, vec3(0.0)), 1.0);
}
