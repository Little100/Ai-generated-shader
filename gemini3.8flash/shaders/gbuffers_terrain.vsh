#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/wind.glsl"

// ==============================================================================
// Aetheria: G-Buffers Terrain Vertex Shader
// ==============================================================================

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform vec3 cameraPosition;
uniform float frameTimeCounter;

out vec2 texCoord;
out vec2 lmCoord;
out vec4 vertexColor;
out vec3 normal;
out float materialId;

void main() {
    texCoord = gl_MultiTexCoord0.st;
    lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;
    normal = gl_NormalMatrix * gl_Normal;

    vec4 position = gl_Vertex;
    vec3 worldPos = position.xyz + cameraPosition;

    materialId = 0.0;
    float blockId = mc_Entity.x;

    if (blockId == 10001.0 || blockId == 10004.0) {
        float isTop = float(gl_MultiTexCoord0.t < mc_midTexCoord.t);
        position.xyz += calculateGrassWave(worldPos, frameTimeCounter, isTop);
        materialId = 2.0; // Foliage flag
    } else if (blockId == 10002.0) {
        position.xyz += calculateLeavesWave(worldPos, frameTimeCounter);
        materialId = 2.0; // Leaves flag
    }

    gl_Position = gl_ModelViewProjectionMatrix * position;
}
