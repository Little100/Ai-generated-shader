#ifndef TIDELUME_FOG
#define TIDELUME_FOG
vec3 foggedSurface(vec3 color, vec3 player) {
    vec3 delta = player-cameraOrigin();
    float dist = length(delta);
    vec3 ray = safeNormalize(delta);
    vec3 haze;
    float optical;
#if WORLD_KIND == -1
    haze = atmosphere(ray);
    optical = dist*0.027*FOG_DENSITY;
#elif WORLD_KIND == 1
    haze = atmosphere(ray);
    optical = dist*0.005*FOG_DENSITY;
#else
    float worldY = (player.y+cameraOrigin().y)*0.5+cameraPosition.y;
    float lowMist = exp(-max(worldY-62.0,0.0)*0.027);
    float dusk = exp(-sq(sunDirection().y*5.0));
    float density = 0.00075+(0.0012+0.0014*dusk)*lowMist+rainStrength*0.0045;
    optical = dist*density*FOG_DENSITY;
    float openAir = mix(0.07,1.0,skyAccess());
    optical *= openAir;
    haze = atmosphere(ray)*mix(0.025,1.0,skyAccess());
#endif
    // Render-distance curtain hides cut-off chunks without fogging tall nearby builds.
    float horizontal = length(delta.xz);
    float curtain = smoothstep(far*0.70, max(far*0.98,1.0),horizontal);
    float amount = max(1.0-exp(-optical),curtain);
    return mix(color,haze,sat(amount));
}
vec3 mediumTransport(vec3 color, float dist) {
    if (isEyeInWater == 1) {
        vec3 absorption = exp(-dist*vec3(0.17,0.070,0.042)/WATER_CLARITY);
        vec3 scattering = vec3(0.012,0.095,0.13)*mix(0.18,1.0,skyAccess())*mix(0.35,1.0,daylight());
        color = color*absorption+scattering*(1.0-absorption);
    } else if (isEyeInWater == 2) {
        color = mix(color,vec3(1.4,0.19,0.015),1.0-exp(-dist*2.8));
    } else if (isEyeInWater == 3) {
        color = mix(color,vec3(0.55,0.69,0.81),1.0-exp(-dist*0.8));
    }
    return color;
}
vec3 applyStatus(vec3 color, float dist) {
    float lostSight = max(blindness,darknessFactor*0.7);
    color *= exp(-max(dist-2.0,0.0)*lostSight*0.30);
    color *= 1.0-darknessLightFactor*0.85;
    return color;
}
#endif
