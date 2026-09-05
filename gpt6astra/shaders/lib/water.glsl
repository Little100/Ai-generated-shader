#ifndef TIDELUME_WATER
#define TIDELUME_WATER
uniform sampler2D colortex4;
uniform sampler2D depthtex1;
vec3 waterNormal(vec3 world, vec3 baseNormal) {
    float t = frameTimeCounter;
    vec2 p = world.xz;
    // Analytic gradients of four authored crossing wave trains. No noise textures.
    vec2 gradient = vec2(0.0);
    gradient += vec2(0.83,0.55)*0.052*cos(dot(p,vec2(0.83,0.55))*1.55+t*1.38);
    gradient += vec2(-0.44,0.90)*0.035*cos(dot(p,vec2(-0.44,0.90))*2.75-t*1.92);
    gradient += vec2(0.24,0.97)*0.016*cos(dot(p,vec2(0.24,0.97))*5.10+t*2.34);
    gradient += vec2(0.97,-0.23)*0.009*cos(dot(p,vec2(0.97,-0.23))*9.30-t*2.90);
    gradient *= WATER_WAVE_STRENGTH*(1.0+rainStrength*0.40);
    vec3 n = safeNormalize(vec3(-gradient.x,1.0,-gradient.y));
    if (baseNormal.y<0.0) n = -n;
    return safeNormalize(mix(baseNormal,n,pow(abs(baseNormal.y),6.0)));
}
vec3 reflectionColor(vec3 player, vec3 normal, vec3 incoming) {
    vec3 reflected = reflect(incoming,normal);
    vec3 fallback = skyRadiance(reflected)*mix(0.015,1.0,skyAccess());
    fallback = mix(fallback,atmosphere(reflected)*0.08,(1.0-smoothstep(-0.35,0.0,reflected.y)));
#ifdef WATER_REFLECTIONS
    vec3 start = (gbufferModelView*vec4(player+normal*0.075,1.0)).xyz;
    vec3 direction = mat3(gbufferModelView)*reflected;
    float travel = 0.40;
    for (int i=0;i<SSR_STEPS;++i) {
        vec3 probe = start+direction*travel;
        if (probe.z>-near) break;
        vec4 projected = gbufferProjection*vec4(probe,1.0);
        vec2 uv = projected.xy/projected.w*0.5+0.5;
        if (any(lessThan(uv,vec2(0.002))) || any(greaterThan(uv,vec2(0.998)))) break;
        float flag = texelFetch(colortex4,ivec2(uv*vec2(textureSize(colortex4,0))),0).a;
        if (flag>0.1 && flag<0.4) { travel += 0.32+travel*0.20; continue; }
        float depth = texture(depthtex1,uv).r;
        vec3 target = screenToView(uv,depth);
        float separation = target.z-probe.z;
        float tolerance = 0.25+travel*0.055;
        if (depth<0.999999 && separation>0.0 && separation<tolerance && travel>0.6) {
            float edge = smoothstep(0.0,0.10,min(min(uv.x,uv.y),min(1.0-uv.x,1.0-uv.y)));
            float confidence = edge*(1.0-float(i)/float(SSR_STEPS)*0.45);
            return mix(fallback,texture(colortex4,uv).rgb,confidence);
        }
        travel += 0.32+travel*0.20;
    }
#endif
    return fallback;
}
#endif
