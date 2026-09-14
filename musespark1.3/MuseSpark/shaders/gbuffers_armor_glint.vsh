#version 330 compatibility
// 附魔辉光顶点直通传递
out vec2 vTex;
void main() {
  vTex = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  gl_Position = ftransform();
}
