#version 330 compatibility
#define DIM_NETHER

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/materials.glsl"

in vec2 texcoord;
in vec4 glcolor;
flat in int blockId;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 c = texture(gtexture, texcoord) * glcolor;
    if (c.a < 0.1) discard;
    // Water casts a pale caustic-tinted shadow instead of a hard one
    if (blockId == BLOCK_WATER) c = vec4(0.6, 0.85, 1.0, 0.25);
    outColor = c;
}
