#version 330 compatibility
#define DIM_NETHER

out vec4 glcolor;

void main() {
    gl_Position = ftransform();
    glcolor = gl_Color;
}
