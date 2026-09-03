#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/water.glsl"

// ==============================================================================
// Aetheria: G-Buffers Water & Translucents Vertex Shader
// ==============================================================================

attribute vec4 mc_Entity;

uniform vec3 cameraPosition;
uniform float frameTimeCounter;

out vec2 texCoord;
out vec2 lmCoord;
out vec4 vertexColor;
out vec3 normal;
out vec3 worldPos;
out float isWater;

void main() {
    texCoord = gl_MultiTexCoord0.st;
    lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;
    normal = gl_NormalMatrix * gl_Normal;

    vec4 position = gl_Vertex;
    worldPos = position.xyz + cameraPosition;

    isWater = (mc_Entity.x == 10003.0) ? 1.0 : 0.0;

#ifdef WATER_WAVES
    if (isWater > 0.5) {
        position.y += evaluateWaterHeight(worldPos.xz, frameTimeCounter);
    }
#endif

    gl_Position = gl_ModelViewProjectionMatrix * position;
}
