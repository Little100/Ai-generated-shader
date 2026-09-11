#version 330 compatibility

/*
    Everything translucent arrives here, not just water. The surface is parked in
    its own buffers so the composite pass can read the opaque scene behind it and
    do the refraction across the real depth gap, but glass and ice are marked so
    they only get a tint and a sheen instead of waves.
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
flat in float blockId;

/* RENDERTARGETS: 4,5 */
layout(location = 0) out vec4 outWaterColor;
layout(location = 1) out vec4 outWaterData;

void main() {
    vec4 base = texture(gtexture, texcoord) * tint;
    if (base.a < 0.02) {
        discard;
    }

    int id = int(blockId + 0.5);
    // anything the block list does not know about counts as water, so a missing
    // block.properties degrades to the expected behaviour
    float waterMask = isSolidTranslucentBlock(id) ? 0.0 : 1.0;

    vec3 absolutePos = worldPos + cameraPosition;
    vec3 geometric = normalize(worldNormal);
    vec3 normal = geometric;

    if (waterMask > 0.5) {
        // only a water surface gets waves, and only on its upward face so the
        // block silhouette keeps its shape
        vec3 waves = waterWaveNormal(absolutePos.xz, frameTimeCounter);
        float upness = saturate(geometric.y * 2.5 - 1.2);
        normal = normalize(mix(geometric, waves, upness));

        // rain roughens the surface and flattens the wave detail
        float wetAmount = wetness * rainStrength;
        normal = normalize(mix(normal, geometric, wetAmount * 0.35));
    }

    outWaterColor = vec4(srgbToLinear(base.rgb), base.a);
    outWaterData = vec4(encodeNormal(normal), waterMask);
}
