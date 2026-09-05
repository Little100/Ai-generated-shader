#ifndef TIDELUME_LIGHTING
#define TIDELUME_LIGHTING
#include "/lib/shadows.glsl"
vec3 shadeSurface(vec3 albedo, vec3 normal, vec3 player, vec2 lm, float material) {
    float sky = sat((lm.y-0.03125)/0.9375);
    float block = sat((lm.x-0.03125)/0.9375);
    vec3 light = lightDirection();
    float up = sat(normal.y*0.5+0.5);
    vec3 ambient;
    vec3 direct = vec3(0.0);
#if WORLD_KIND == 0
    vec3 shade = mix(vec3(0.034,0.058,0.11)*NIGHT_BRIGHTNESS,vec3(0.19,0.30,0.42),daylight());
    ambient = shade*pow(sky,2.1)*mix(0.42,1.0,up);
    ambient += vec3(0.030,0.023,0.015)*sky*(1.0-up)*daylight();
    float diffuse = max(dot(normal,light),0.0);
    float foliage = (material>=10010.0 && material<=10020.0) ? 1.0 : 0.0;
    float transmission = foliage*pow(sat(dot(safeNormalize(player-cameraOrigin()),light)),5.0)*0.32;
    vec3 visibility = surfaceShadow(player,normal,sky);
    float horizon = smoothstep(0.015,0.10,abs(sunDirection().y));
    direct = sunlightColor()*visibility*(diffuse+transmission)*1.55*horizon*(1.0-rainStrength*0.87);
    direct *= smoothstep(0.02,0.30,sky); // suppress skylight leaks in sealed caves
#elif WORLD_KIND == -1
    ambient = vec3(0.105,0.054,0.038)*mix(0.75,1.15,up)+toLinear(fogColor)*0.12;
#elif WORLD_KIND == 1
    ambient = vec3(0.13,0.11,0.19)*mix(0.6,1.1,up);
    direct = vec3(0.16,0.28,0.25)*max(dot(normal,safeNormalize(vec3(0.4,0.8,-0.3))),0.0);
#endif
    // Very low floor; caves still require lights. Night vision remains functional.
    ambient += vec3(0.0035,0.0042,0.0060);
    ambient = mix(ambient,max(ambient,vec3(0.65)),nightVision);
    float local = pow(block,3.2)*2.5;
#ifdef HAND_LIGHT
    float held = float(max(heldBlockLightValue,heldBlockLightValue2))/15.0;
    float distanceToHand = length(player-cameraOrigin()+vec3(0.0,0.25,0.0));
    local = max(local,held*2.2*sq(sat(1.0-distanceToHand/13.0)));
#endif
    vec3 warm = vec3(1.0,0.53,0.23)*local*BLOCKLIGHT_BRIGHTNESS;
    vec3 color = albedo*(ambient+direct+warm);
    // Hand-selected emitter classes. Not a fabricated PBR/material texture reader.
    float emission = 0.0;
    if (material == 10040.0) emission = 1.6;
    if (material == 10041.0) emission = 3.2;
    if (material == 10042.0) emission = 0.7;
    float brightTexel = smoothstep(0.10,0.65,max(albedo.r,max(albedo.g,albedo.b)));
    color += albedo*emission*brightTexel;
#ifdef WET_SURFACES
#if WORLD_KIND == 0
    float patch = smoothstep(0.35,0.72,valueNoise2((player.xz+cameraPosition.xz)*0.19));
    float wet = wetness*pow(sky,10.0)*sat(normal.y)*patch;
    vec3 view = safeNormalize(cameraOrigin()-player);
    vec3 h = safeNormalize(view+light);
    float spec = pow(sat(dot(normal,h)),96.0)*wet;
    color *= 1.0-wet*0.15;
    color += sunlightColor()*spec*visibility*1.8;
#endif
#endif
    return max(color,vec3(0.0));
}
#endif
