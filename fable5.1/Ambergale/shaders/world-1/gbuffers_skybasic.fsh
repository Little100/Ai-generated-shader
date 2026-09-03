#version 330 compatibility
#define DIM_NETHER

// Vanilla sky geometry is only used as a mask; the real sky is painted in deferred

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/materials.glsl"

in vec4 glcolor;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 outAlbedo;
layout(location = 1) out vec4 outLightData;
layout(location = 2) out vec4 outNormal;

void main() {
    outAlbedo = vec4(0.0, 0.0, 0.0, 1.0);
    outLightData = vec4(0.0, 1.0, encodeMat(MAT_UNLIT), 1.0);
    outNormal = vec4(0.5, 1.0, 0.5, 1.0);
}
