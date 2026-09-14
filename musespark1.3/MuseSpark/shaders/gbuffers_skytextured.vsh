#version 330 compatibility
// 日月贴片顶点仅传位置
void main() {
  gl_Position = ftransform();
}
