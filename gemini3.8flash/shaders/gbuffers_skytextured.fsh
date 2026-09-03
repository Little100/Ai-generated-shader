#version 330 compatibility

/* RENDERTARGETS: 0,3 */

// ==============================================================================
// Aetheria: G-Buffers Sky Textured (Sun & Moon) Fragment Shader
// ==============================================================================

uniform sampler2D texture;

in vec2 texCoord;
in vec4 vertexColor;

void main() {
    vec4 albedo = texture(texture, texCoord) * vertexColor;
    if (albedo.a < 0.05) {
        discard;
    }

    // Enhance radiant core of sun/moon
    vec3 celestialColor = albedo.rgb * 2.5;

    gl_FragData[0] = vec4(celestialColor, albedo.a);
    gl_FragData[1] = vec4(celestialColor * albedo.a, 1.0); // Bloom target
}
