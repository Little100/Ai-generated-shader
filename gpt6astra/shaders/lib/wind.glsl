#ifndef TIDELUME_WIND
#define TIDELUME_WIND
vec3 windOffset(vec3 world, float id, float topVertex, float skylight) {
    vec3 offset = vec3(0.0);
#ifdef WIND
#if WORLD_KIND == 0
    float anchor = 0.0;
    // Tall-plant join is .5 on BOTH halves: no tearing across block borders.
    if (id == 10010.0) anchor = topVertex;
    if (id == 10011.0) anchor = topVertex*0.5;
    if (id == 10012.0) anchor = 0.5 + topVertex*0.5;
    if (id == 10020.0) anchor = 0.22;
    if (anchor > 0.0) {
        float t = frameTimeCounter;
        float gust = sin(t*1.32 + world.x*0.31 + world.z*0.23);
        float flutter = sin(t*2.7 - world.z*0.68 + world.y*0.39);
        float amp = anchor*WIND_STRENGTH*mix(0.035,0.12,skylight)*(1.0+rainStrength*0.65);
        offset.xz = vec2(gust+0.32*flutter, 0.48*gust-0.22*flutter)*amp;
    }
#endif
#endif
    return offset;
}
#endif
