#version 330 compatibility

// ==============================================================================
// Aetheria: G-Buffers Sky Basic Vertex Shader
// ==============================================================================

out vec3 vertexPos;
out vec4 vertexColor;

void main() {
    vertexPos = gl_Vertex.xyz;
    vertexColor = gl_Color;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}
