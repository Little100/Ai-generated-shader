#version 330 compatibility

/*
    The underwater overlay draws through the same buffers as water so a
    submerged first person view still gets the absorption treatment.
*/

#include "/lib/buffers.glsl"
#include "/lib/surface.glsl"
#include "/lib/water.glsl"

in vec2 texcoord;
in vec2 lmcoord;
in vec2 lightLevel;
in vec4 tint;
in vec3 worldNormal;
in vec3 worldPos;
in float viewDistance;

/* RENDERTARGETS: 4,5 */
layout(location = 0) out vec4 outWaterColor;
layout(location = 1) out vec4 outWaterData;

void main() {
    vec4 base = texture(gtexture, texcoord) * tint;
    if (base.a < 0.02) {
        discard;
    }

    vec3 absolutePos = worldPos + cameraPosition;
    vec3 geometric = normalize(worldNormal);
    vec3 waves = waterWaveNormal(absolutePos.xz, frameTimeCounter);
    float upness = saturate(geometric.y * 2.5 - 1.2);
    vec3 normal = normalize(mix(geometric, waves, upness));

    outWaterColor = vec4(srgbToLinear(base.rgb), base.a);
    outWaterData = vec4(encodeNormal(normal), 1.0);
}
