/*
    The vertex stage shared by every program that draws world geometry.

    Iris swaps the model view and projection matrices for whichever pass is
    running, so the model view times the projection always lands in the right
    clip space. The world position is recovered relative to the camera, which is
    the space the shadow matrices expect.
*/

#if !defined(SKYWEAVE_GBUFFER_VERTEX_INCLUDED)
#define SKYWEAVE_GBUFFER_VERTEX_INCLUDED

#include "/lib/math.glsl"
#include "/lib/config.glsl"

out vec2 texcoord;
out vec2 lmcoord;
out vec2 lightLevel;
out vec4 tint;
out vec3 worldNormal;
out vec3 worldPos;
out float viewDistance;

// waveAmount is zero for everything except the foliage that sways
void skyweaveVertex(float waveAmount) {
    vec4 position = gl_Vertex;

#ifdef WAVING_PLANTS
    if (waveAmount > 0.0) {
        // the base of the plant stays planted and the tip does the moving
        float localHeight = clamp(fract(position.y), 0.0, 1.0);
        float bend = localHeight * localHeight * waveAmount;

        vec3 baseWorld = (gbufferModelViewInverse * (gl_ModelViewMatrix * position)).xyz;
        float phase = baseWorld.x * 0.31 + baseWorld.z * 0.26;
        float time = frameTimeCounter;

        float sway = sin(time * 1.55 + phase) * 0.6 + sin(time * 2.61 + phase * 1.7) * 0.25;
        float wind = 0.35 + rainStrength * 1.1;

        position.xyz += vec3(sway, 0.0, sway * 0.55) * (bend * wind * 0.11);
    }
#else
    waveAmount = 0.0;
#endif

    vec4 viewPos = gl_ModelViewMatrix * position;
    gl_Position = gl_ProjectionMatrix * viewPos;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lightLevel = clamp(gl_MultiTexCoord1.xy / 240.0, 0.0, 1.0);
    tint = gl_Color;

    viewDistance = length(viewPos.xyz);
    worldPos = (gbufferModelViewInverse * viewPos).xyz;
    worldNormal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal);
}

void skyweaveVertex() {
    skyweaveVertex(0.0);
}

#endif
