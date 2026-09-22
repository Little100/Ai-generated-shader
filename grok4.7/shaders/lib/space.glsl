#ifndef KILN_SPACE
#define KILN_SPACE

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

vec3 viewFromScreen(vec2 uv, float depth) {
    vec4 clip = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 view = gbufferProjectionInverse * clip;
    return view.xyz / view.w;
}

vec3 playerFromView(vec3 viewPos) {
    return (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
}

vec3 viewFromPlayer(vec3 playerPos) {
    return (gbufferModelView * vec4(playerPos, 1.0)).xyz;
}

vec3 worldFromPlayer(vec3 playerPos) {
    return playerPos + cameraPosition;
}

vec2 screenFromView(vec3 viewPos) {
    vec4 clip = gbufferProjection * vec4(viewPos, 1.0);
    return clip.xy / clip.w * 0.5 + 0.5;
}

float linearizeDepth(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec3 shadowFromPlayer(vec3 playerPos) {
    vec4 shadowView = shadowModelView * vec4(playerPos, 1.0);
    vec4 shadowClip = shadowProjection * shadowView;
    shadowClip.xyz /= shadowClip.w;
    shadowClip.xy = shadowClip.xy * 0.5 + 0.5;
    return shadowClip.xyz;
}

vec3 previousView(vec3 playerPos) {
    return (gbufferPreviousModelView * vec4(playerPos, 1.0)).xyz;
}

vec2 previousScreen(vec3 playerPos) {
    vec3 prevView = previousView(playerPos);
    vec4 clip = gbufferPreviousProjection * vec4(prevView, 1.0);
    return clip.xy / clip.w * 0.5 + 0.5;
}

float viewDepthMeters(vec3 viewPos) {
    return length(viewPos);
}

#endif
