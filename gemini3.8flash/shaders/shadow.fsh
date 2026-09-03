#version 330 compatibility

// ==============================================================================
// Aetheria: Shadow Pass Fragment Shader
// ==============================================================================

uniform sampler2D texture;

in vec2 texCoord;
in vec4 vertexColor;

void main() {
    vec4 albedo = texture(texture, texCoord) * vertexColor;
    if (albedo.a < 0.1) {
        discard;
    }
}
