#version 330 compatibility

// 全屏四边形, 只负责把纹理坐标传给片元
out vec2 texcoord;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
