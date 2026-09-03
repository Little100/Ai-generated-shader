#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/wind.glsl"

// ==============================================================================
// Aetheria: Shadow Pass Vertex Shader
// ==============================================================================

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

out vec2 texCoord;
out vec4 vertexColor;

void main() {
    texCoord = gl_MultiTexCoord0.st;
    vertexColor = gl_Color;

    vec4 position = gl_Vertex;
    vec3 worldPos = position.xyz + cameraPosition;

    // Apply wind motion in shadow pass to align shadow casting with moving geometry
    float blockId = mc_Entity.x;
    if (blockId == 10001.0 || blockId == 10004.0) {
        float isTop = float(gl_MultiTexCoord0.t < mc_midTexCoord.t);
        position.xyz += calculateGrassWave(worldPos, frameTimeCounter, isTop);
    } else if (blockId == 10002.0) {
        position.xyz += calculateLeavesWave(worldPos, frameTimeCounter);
    }

    gl_Position = gl_ModelViewProjectionMatrix * position;
}
