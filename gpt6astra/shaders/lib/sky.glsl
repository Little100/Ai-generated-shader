#ifndef TIDELUME_SKY
#define TIDELUME_SKY
vec3 sunlightColor() {
    float elevation = sat(sunDirection().y);
    vec3 sun = mix(vec3(1.32,0.52,0.22),vec3(1.12,0.98,0.80),smoothstep(0.0,0.45,elevation));
    return mix(vec3(0.065,0.105,0.20)*NIGHT_BRIGHTNESS,sun*SUN_BRIGHTNESS,daylight());
}
vec3 atmosphere(vec3 ray) {
#if WORLD_KIND == -1
    vec3 base = toLinear(fogColor);
    return mix(vec3(0.07,0.012,0.006),base*0.8+vec3(0.055,0.012,0.005),0.65+0.2*ray.y);
#elif WORLD_KIND == 1
    float belt = exp(-abs(ray.y+0.03)*5.0);
    return vec3(0.009,0.009,0.023) + vec3(0.031,0.021,0.047)*belt;
#else
    float day = daylight();
    float height = pow(sat(ray.y),0.45);
    float dusk = exp(-sq(sunDirection().y*4.8));
    float facing = pow(sat(dot(ray,sunDirection())*0.5+0.5),5.0);
    vec3 zenith = mix(vec3(0.006,0.012,0.033)*NIGHT_BRIGHTNESS,vec3(0.105,0.32,0.57),day);
    vec3 horizon = mix(vec3(0.025,0.042,0.078)*NIGHT_BRIGHTNESS,vec3(0.53,0.72,0.78),day);
    horizon = mix(horizon,vec3(0.95,0.34,0.16),dusk*facing*0.76);
    vec3 col = mix(horizon,zenith,height);
    col += sunlightColor()*pow(sat(dot(ray,lightDirection())),24.0)*0.10;
    col = mix(col,vec3(luminance(col))*vec3(0.82,0.91,1.0),rainStrength*0.78);
    return col*mix(1.0,0.63,rainStrength);
#endif
}
float starField(vec3 ray) {
    // Octahedron-like direction chart avoids a singularity at the zenith.
    vec2 chart = ray.xz / (abs(ray.x)+abs(ray.y)+abs(ray.z)+0.001);
    vec2 p = chart*620.0;
    vec2 cell = floor(p), f = fract(p);
    float seed = hash21(cell+vec2(891.0,127.0));
    vec2 center = vec2(hash21(cell+vec2(17,41)),hash21(cell+vec2(53,9)))*0.6+0.2;
    float size = mix(0.035,0.14,hash21(cell+vec2(11,87)));
    float s = exp(-dot(f-center,f-center)/(size*size));
    return s*step(0.985,seed)*smoothstep(0.02,0.20,ray.y);
}
vec3 endHalo(vec3 ray) {
    vec3 axis = safeNormalize(vec3(0.35,0.89,-0.27));
    float ring = dot(ray,axis);
    float phi = atan(ray.z,ray.x);
    float drift = frameTimeCounter*0.022;
    float fold = sin(phi*5.0+drift)*0.012 + sin(phi*11.0-drift*0.7)*0.004;
    float strand = exp(-sq((ring-0.30-fold)*125.0));
    float echo = exp(-sq((ring-0.345-fold*0.6)*75.0));
    float veil = exp(-sq((ring-0.32)*19.0));
    float segments = 0.55+0.45*sin(phi*3.0-drift);
    vec3 col = mix(vec3(0.08,0.36,0.33),vec3(0.31,0.16,0.47),sin(phi*2.0+drift)*0.5+0.5);
    return col*(strand*0.7+echo*0.22+veil*0.065)*segments;
}
vec3 skyRadiance(vec3 ray) {
    vec3 col = atmosphere(ray);
#if WORLD_KIND == 0
    float day = daylight();
    float sunDot = dot(ray,sunDirection());
    float sunDisc = smoothstep(0.99970,0.99982,sunDot);
    float moonDot = dot(ray,safeNormalize(mat3(gbufferModelViewInverse)*moonPosition));
    float moonDisc = smoothstep(0.99962,0.99976,moonDot);
    float lunar = 0.30 + 0.70*(0.5+0.5*cos(float(moonPhase)*TL_TAU/8.0));
    col += sunDisc*vec3(7.0,5.3,3.1)*day*(1.0-rainStrength*0.95);
    col += moonDisc*vec3(0.52,0.72,1.05)*lunar*(1.0-day)*(1.0-rainStrength);
#ifdef STARS
    col += starField(ray)*vec3(0.80,0.88,1.12)*(1.0-day)*(1.0-rainStrength);
#endif
#elif WORLD_KIND == 1
#ifdef END_HALO
    col += endHalo(ray);
#endif
#ifdef STARS
    col += starField(ray)*vec3(0.32,0.51,0.54);
#endif
#endif
    return col;
}
// Density-defined slabs, marched in world units. Handles cameras above/in clouds.
float cloudDensity(vec3 world) {
    float slab = (world.y-CLOUD_HEIGHT)/34.0;
    float shape = smoothstep(0.0,0.16,slab)*(1.0-smoothstep(0.64,1.0,slab));
    vec2 drift = vec2(frameTimeCounter*0.70,frameTimeCounter*0.23);
    vec2 p = (world.xz+drift)*0.006;
    p += vec2(valueNoise2(p*0.45),valueNoise2(p*0.45+vec2(17.0)))*0.7;
    float field = cloudNoise(p+slab*0.13);
    float threshold = 0.79-CLOUD_COVERAGE*0.44-rainStrength*0.10;
    return smoothstep(threshold,threshold+0.20,field)*shape;
}
vec3 renderSky(vec3 ray, vec3 origin) {
    vec3 col = skyRadiance(ray);
#if WORLD_KIND == 0
#ifdef CLOUDS
    if (abs(ray.y)>0.008) {
        float a = (CLOUD_HEIGHT-origin.y)/ray.y;
        float b = (CLOUD_HEIGHT+34.0-origin.y)/ray.y;
        float entry = max(min(a,b),0.0);
        float exitT = min(max(a,b),3500.0);
        if (exitT>entry) {
            float stepLength = (exitT-entry)/float(CLOUD_STEPS);
            float trans = 1.0;
            vec3 glow = vec3(0.0);
            float day = daylight();
            vec3 cloudAmbient = mix(vec3(0.018,0.029,0.057)*NIGHT_BRIGHTNESS,vec3(0.39,0.53,0.65),day);
            for (int i=0;i<CLOUD_STEPS;++i) {
                vec3 p = origin+ray*(entry+(float(i)+0.5)*stepLength);
                float density = cloudDensity(p);
                float above = cloudDensity(p+lightDirection()*24.0+vec3(0.0,9.0,0.0));
                float rim = pow(sat(dot(ray,lightDirection())),10.0)*(1.0-density);
                vec3 lit = cloudAmbient + sunlightColor()*(0.35+0.9*exp(-above*2.6)+rim*0.7)*(1.0-rainStrength*0.65);
                float alpha = 1.0-exp(-density*stepLength*0.055);
                glow += lit*alpha*trans;
                trans *= 1.0-alpha;
                if (trans<0.025) break;
            }
            float fade = 1.0-smoothstep(2000.0,3500.0,entry);
            col = mix(col,col*trans+glow,fade);
        }
    }
#endif
#endif
    return max(col,vec3(0.0));
}
#endif
