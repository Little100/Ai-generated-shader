#ifndef TIDELUME_SHADOW_SPACE
#define TIDELUME_SHADOW_SPACE
// An original smooth center-biased projection. Applied identically on both sides.
vec3 warpShadow(vec3 ndc) {
    float stretch = 0.28 + 0.72*length(ndc.xy);
    return vec3(ndc.xy/stretch, ndc.z*0.5);
}
vec3 shadowCoordinate(vec3 player) {
    vec4 q = shadowProjection * shadowModelView * vec4(player,1.0);
    return warpShadow(q.xyz/q.w)*0.5+0.5;
}
bool insideShadow(vec3 q) {
    return all(greaterThan(q,vec3(0.002))) && all(lessThan(q,vec3(0.998)));
}
#endif
