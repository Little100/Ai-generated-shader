#version 330 compatibility

/* RENDERTARGETS: 0 */

// ==============================================================================
// Aetheria: G-Buffers Weather (Rain & Snow) Fragment Shader
// ==============================================================================

uniform sampler2D texture;

in vec2 texCoord;
in vec4 vertexColor;

void main() {
    vec4 albedo = texture(texture, texCoord) * vertexColor;
    if (albedo.a < 0.05) {
        discard;
    }

    gl_FragData[0] = albedo;
}
