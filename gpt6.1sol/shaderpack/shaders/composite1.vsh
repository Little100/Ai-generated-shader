#version 330 compatibility

out vec2 awTexcoord;

void main() {
    gl_Position = ftransform();
    awTexcoord = gl_MultiTexCoord0.xy;
}
