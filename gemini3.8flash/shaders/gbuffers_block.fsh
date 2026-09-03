#version 330 compatibility

/* RENDERTARGETS: 0,1,2 */

// ==============================================================================
// Aetheria: G-Buffers Block Entities Fragment Shader
// ==============================================================================

uniform sampler2D texture;

in vec2 texCoord;
in vec2 lmCoord;
in vec4 vertexColor;
in vec3 normal;

void main() {
    vec4 albedo = texture(texture, texCoord) * vertexColor;
    if (albedo.a < 0.1) {
        discard;
    }

    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(normalize(normal) * 0.5 + 0.5, 0.0);
    gl_FragData[2] = vec4(lmCoord, 0.0, 1.0);
}
