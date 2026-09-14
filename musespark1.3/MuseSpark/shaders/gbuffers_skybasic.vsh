#version 330 compatibility
// 天空基础顶点只传方向
out vec3 vDir;
void main() {
  vDir = gl_Vertex.xyz;
  gl_Position = ftransform();
}
