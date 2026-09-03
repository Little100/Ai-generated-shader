#version 330 compatibility

/* RENDERTARGETS: 0,3 */

// ==============================================================================
// Aetheria: G-Buffers Textured (Particles & Beams) Fragment Shader
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

    // Emissive glow for fire particles, torches, sparks
    float brightness = max(max(albedo.r, albedo.g), albedo.b);
    vec3 bloomContrib = (brightness > 0.8) ? albedo.rgb * 1.5 : vec3(0.0);
    gl_FragData[1] = vec4(bloomContrib, 1.0);
}
