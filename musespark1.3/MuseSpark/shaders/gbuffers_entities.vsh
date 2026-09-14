#version 330 compatibility
// 实体顶点直通传递
uniform mat4 gbufferModelViewInverse;
out vec2 vTex;
out vec2 vLm;
out vec4 vTint;
out vec3 vNrm;
#include "lib/muse_vertex.glsl"
void main() {
  vTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  vLm = museFixLm((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy);
  vTint = gl_Color;
  vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
  vec3 vn = normalize(gl_NormalMatrix * gl_Normal);
  vNrm = normalize(mat3(gbufferModelViewInverse) * vn);
  gl_Position = gl_ProjectionMatrix * viewPos;
}
