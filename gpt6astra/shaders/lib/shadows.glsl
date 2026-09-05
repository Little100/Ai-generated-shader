#ifndef TIDELUME_SHADOWS
#define TIDELUME_SHADOWS
#include "/lib/shadow_space.glsl"
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
vec3 shadowTap(vec3 q) {
    float opaque = step(q.z, texture(shadowtex1,q.xy).r);
#ifdef COLORED_SHADOWS
    float allDepth = step(q.z, texture(shadowtex0,q.xy).r);
    vec4 tint = texture(shadowcolor0,q.xy);
    vec3 transmission = mix(vec3(1.0),toLinear(tint.rgb),sat(tint.a));
    return opaque * mix(transmission,vec3(1.0),allDepth);
#else
    return vec3(opaque);
#endif
}
vec3 surfaceShadow(vec3 p, vec3 normal, float skyLight) {
#if WORLD_KIND == 0
#ifdef SHADOWS
    vec3 light = lightDirection();
    float slope = 1.0-sat(dot(normal,light));
    float texelWorld = 2.0*shadowDistance/float(shadowMapResolution);
    vec3 q = shadowCoordinate(p + normal*texelWorld*(0.30+0.65*slope));
    q.z -= 0.00013 + 0.00022*slope;
    float fallback = smoothstep(0.73,0.98,skyLight);
    if (!insideShadow(q)) return vec3(fallback);
    vec3 sum = vec3(0.0);
    // Fixed low-discrepancy disk: no temporal grain in static shadows.
    for (int i=0;i<SHADOW_SAMPLES;++i) {
        float a = float(i)*2.39996323 + 0.37;
        float r = sqrt((float(i)+0.5)/float(SHADOW_SAMPLES));
        vec2 tap = vec2(cos(a),sin(a))*r*SHADOW_SOFTNESS/float(shadowMapResolution);
        sum += shadowTap(vec3(q.xy+tap,q.z));
    }
    float edge = smoothstep(shadowDistance*0.78,shadowDistance*0.98,length(p.xz));
    return mix(sum/float(SHADOW_SAMPLES),vec3(fallback),edge);
#else
    return vec3(smoothstep(0.73,0.98,skyLight));
#endif
#else
    return vec3(1.0);
#endif
}
float rayShadow(vec3 p) {
#if WORLD_KIND == 0
#ifdef SHADOWS
    vec3 q = shadowCoordinate(p);
    q.z -= 0.00022;
    if (!insideShadow(q)) return 0.0; // Unknown volume is not assumed sunlit.
    return step(q.z,texture(shadowtex1,q.xy).r);
#endif
#endif
    return 0.0;
}
#endif
