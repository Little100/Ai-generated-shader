#version 330 compatibility
// 地形顶点摆动与数据传递
in vec2 mc_Entity;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
out vec2 vTex;
out vec2 vLm;
out vec4 vTint;
out vec3 vNrm;
out vec2 vEnt;
#include "lib/muse_vertex.glsl"
void main() {
  vTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  vLm = museFixLm((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy);
  vTint = gl_Color;
  vEnt = mc_Entity;
  vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
  vec3 origPlayer = (gbufferModelViewInverse * viewPos).xyz;
  vec3 worldPos = origPlayer + cameraPosition;
  vec3 playerPos = origPlayer + museWave(mc_Entity, worldPos, vTex);
  vec3 vn = normalize(gl_NormalMatrix * gl_Normal);
  vNrm = normalize(mat3(gbufferModelViewInverse) * vn);
  vec4 viewFixed = viewPos + gbufferModelView * vec4(playerPos - origPlayer, 0.0);
  gl_Position = gl_ProjectionMatrix * viewFixed;
}
