#version 330 compatibility

/*
    Volumetric light shafts at half resolution. The result is soft enough that
    the lower resolution is never visible on screen.
*/

#include "/lib/buffers.glsl"
#include "/lib/post.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 8 */
layout(location = 0) out vec4 outShafts;


void main() {
    float depth = texture(depthtex0, texcoord).r;
    vec3 viewDir = normalize(mat3(gbufferModelViewInverse) * screenToView(texcoord, depth, gbufferProjectionInverse));
    float viewDistance = depthToViewDistance(depth, gbufferProjectionInverse);

    outShafts = vec4(lightShafts(viewDir, viewDistance), 1.0);
}
