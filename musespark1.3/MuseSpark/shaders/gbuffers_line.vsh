#version 330 compatibility
// 线条顶点直通传递
out vec4 vTint;
void main() {
  vTint = gl_Color;
  gl_Position = ftransform();
}
