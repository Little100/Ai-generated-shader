#version 330 compatibility
// 全屏合成顶点传递纹理坐标
out vec2 vUv;
void main() {
  vUv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  gl_Position = ftransform();
}
