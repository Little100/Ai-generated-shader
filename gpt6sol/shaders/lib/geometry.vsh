#ifndef LOOMLIGHT_GEOMETRY_VERTEX
#define LOOMLIGHT_GEOMETRY_VERTEX

#include "/lib/wind.glsl"

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

#if defined(PASS_TERRAIN) || defined(PASS_WATER)
in vec2 mc_Entity;
#endif

out vec2 vUv;
out vec2 vLm;
out vec4 vColor;
out vec3 vNormal;
out vec3 vPlayerPos;
out vec3 vViewPos;
out float vBlockId;

void main() {
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    vec3 playerPos = (gbufferModelViewInverse * view).xyz;
    float blockId = 0.0;
#if defined(PASS_TERRAIN) || defined(PASS_WATER)
    blockId = mc_Entity.x;
    vec3 worldPos = playerPos + cameraPosition;
#ifdef PASS_TERRAIN
    vec3 offset = foliageOffset(worldPos, blockId, frameTimeCounter);
    view.xyz += mat3(gl_ModelViewMatrix) * offset;
    playerPos += offset;
#endif
#ifdef PASS_WATER
    if (abs(blockId - 10020.0) < 0.5 && gl_Normal.y > 0.6) {
        float wave = sin(worldPos.x * 1.41 + frameTimeCounter * 1.8) * cos(worldPos.z * 1.73 - frameTimeCounter * 1.2);
        vec3 offset = vec3(0.0, wave * 0.055, 0.0);
        view.xyz += mat3(gl_ModelViewMatrix) * offset;
        playerPos += offset;
    }
#endif
#endif
    gl_Position = gl_ProjectionMatrix * view;
    vUv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vLm = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
    vNormal = normalize(gl_NormalMatrix * gl_Normal);
    vPlayerPos = playerPos;
    vViewPos = view.xyz;
    vBlockId = blockId;
}

#endif

