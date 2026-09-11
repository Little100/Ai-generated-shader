#version 330 compatibility

#include "/lib/gbuffer_vertex.glsl"
#include "/lib/materials.glsl"

// Iris replaces this with an integer attribute and hands back a converted alias
in vec2 mc_Entity;

flat out float blockId;

void main() {
    float waveAmount = 0.0;
    if (isFoliageBlock(int(mc_Entity.x + 0.5))) {
        waveAmount = WAVING_STRENGTH;
    }

    skyweaveVertex(waveAmount);
    blockId = mc_Entity.x;
}
