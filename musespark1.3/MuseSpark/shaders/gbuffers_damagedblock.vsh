#version 330 compatibility
// 破坏裂纹顶点直通传递
out vec2 vTex;
out vec4 vTint;
void main() {
  vTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  vTint = gl_Color;
  gl_Position = ftransform();
}
