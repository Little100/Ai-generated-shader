#version 330 compatibility

out vec2 awShadowTexcoord;

void main() {
    gl_Position = ftransform();
    awShadowTexcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
