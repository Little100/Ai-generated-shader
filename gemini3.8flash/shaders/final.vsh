#version 330 compatibility

// ==============================================================================
// Aetheria: Final Post-Processing Pass Vertex Shader
// ==============================================================================

out vec2 texCoord;

void main() {
    texCoord = gl_MultiTexCoord0.st;
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}
