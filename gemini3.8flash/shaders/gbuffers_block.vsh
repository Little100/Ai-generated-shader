#version 330 compatibility

// ==============================================================================
// Aetheria: G-Buffers Block Entities Vertex Shader
// ==============================================================================

out vec2 texCoord;
out vec2 lmCoord;
out vec4 vertexColor;
out vec3 normal;

void main() {
    texCoord = gl_MultiTexCoord0.st;
    lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vertexColor = gl_Color;
    normal = gl_NormalMatrix * gl_Normal;

    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}
