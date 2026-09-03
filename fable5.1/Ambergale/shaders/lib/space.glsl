#ifndef SPACE_GLSL
#define SPACE_GLSL

vec3 screenToView(vec3 screenPos) {
    vec4 ndc = vec4(screenPos * 2.0 - 1.0, 1.0);
    vec4 view = gbufferProjectionInverse * ndc;
    return view.xyz / view.w;
}

vec3 viewToScreen(vec3 viewPos) {
    vec4 clip = gbufferProjection * vec4(viewPos, 1.0);
    return clip.xyz / clip.w * 0.5 + 0.5;
}

vec3 viewToPlayer(vec3 viewPos) {
    return (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
}

vec3 playerToView(vec3 playerPos) {
    return (gbufferModelView * vec4(playerPos, 1.0)).xyz;
}

#endif
