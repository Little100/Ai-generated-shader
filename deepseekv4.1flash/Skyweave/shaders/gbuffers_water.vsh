#version 330 compatibility

#include "/lib/gbuffer_vertex.glsl"
#include "/lib/materials.glsl"

// Iris replaces this with an integer attribute and hands back a converted alias
in vec2 mc_Entity;

flat out float blockId;

void main() {
    skyweaveVertex();
    blockId = mc_Entity.x;
}
