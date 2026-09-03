#version 330 compatibility

/* RENDERTARGETS: 0,1,2 */

// ==============================================================================
// Aetheria: G-Buffers Entities Fragment Shader
// ==============================================================================

uniform sampler2D texture;
uniform vec4 entityColor;

in vec2 texCoord;
in vec2 lmCoord;
in vec4 vertexColor;
in vec3 normal;

void main() {
    vec4 albedo = texture(texture, texCoord) * vertexColor;
    if (albedo.a < 0.1) {
        discard;
    }

    // Blend hurt flash or creeper flashing overlay
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(normalize(normal) * 0.5 + 0.5, 0.0);
    gl_FragData[2] = vec4(lmCoord, 0.0, 1.0);
}
