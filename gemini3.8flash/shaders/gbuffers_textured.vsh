#version 330 compatibility

// ==============================================================================
// Aetheria: G-Buffers Textured (Particles & Beams) Vertex Shader
// ==============================================================================

out vec2 texCoord;
out vec4 vertexColor;

void main() {
    texCoord = gl_MultiTexCoord0.st;
    vertexColor = gl_Color;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}
