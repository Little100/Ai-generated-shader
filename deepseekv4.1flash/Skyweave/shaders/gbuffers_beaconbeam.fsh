#version 330 compatibility

/*
    A beacon beam glows rather than sitting on a surface, so it is added on top
    of whatever it passes in front of instead of replacing it.
*/

#include "/lib/buffers.glsl"
#include "/lib/surface.glsl"

in vec2 texcoord;
in vec2 lmcoord;
in vec2 lightLevel;
in vec4 tint;
in vec3 worldNormal;
in vec3 worldPos;
in float viewDistance;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outScene;

void main() {
    vec4 base = texture(gtexture, texcoord) * tint;
    if (base.a < 0.02) {
        discard;
    }

    // gbuffers programs are not allowed to sample colortex0, so the beam is
    // added to the frame by the blend state instead of being composited here.
    // Only the part facing the camera contributes, which gives the cylinder a
    // soft falloff toward its silhouette.
    vec3 viewDir = normalize(worldPos + vec3(0.0, 0.0, 1e-5));
    float edge = 1.0 - abs(dot(normalize(worldNormal), viewDir));

    // the blend state multiplies by the alpha we output, so the falloff belongs
    // there and not here as well
    vec3 glow = srgbToLinear(base.rgb) * 1.8 * (0.35 + 0.65 * edge);

    outScene = vec4(glow, saturate(base.a));
}
