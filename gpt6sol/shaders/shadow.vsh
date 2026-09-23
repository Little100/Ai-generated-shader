#version 330 compatibility

#include "/lib/wind.glsl"

uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

in vec2 mc_Entity;
out vec2 vUv;
out float vBlockId;

void main() {
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    vec3 playerPos = (shadowModelViewInverse * view).xyz;
    vec3 worldPos = playerPos + cameraPosition;
    vec3 offset = foliageOffset(worldPos, mc_Entity.x, frameTimeCounter);
    view.xyz += mat3(gl_ModelViewMatrix) * offset;
    gl_Position = gl_ProjectionMatrix * view;
    vUv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vBlockId = mc_Entity.x;
}

