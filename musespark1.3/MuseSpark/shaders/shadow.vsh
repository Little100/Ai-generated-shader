#version 330 compatibility
// 阴影顶点摆动与坐标传递
in vec2 mc_Entity;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;
out vec2 vTex;
out vec4 vTint;
out vec2 vEnt;
#include "lib/muse_vertex.glsl"
void main() {
  vTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  vTint = gl_Color;
  vEnt = mc_Entity;
  vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
  vec3 playerPos = (shadowModelViewInverse * viewPos).xyz;
  vec3 worldPos = playerPos + cameraPosition;
  playerPos += museWave(mc_Entity, worldPos, vTex);
  gl_Position = gl_ProjectionMatrix * (shadowModelView * vec4(playerPos, 1.0));
}
