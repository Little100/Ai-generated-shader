#version 330 compatibility

uniform sampler2D colortex0;

in vec2 awTexcoord;

void main() {
    gl_FragColor = texture2D(colortex0, awTexcoord);
}
