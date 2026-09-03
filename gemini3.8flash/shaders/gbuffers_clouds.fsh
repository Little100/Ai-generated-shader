#version 330 compatibility

/* RENDERTARGETS: 0 */

// ==============================================================================
// Aetheria: G-Buffers Clouds Fragment Shader
// ==============================================================================

uniform sampler2D texture;
uniform vec3 sunPosition;

in vec2 texCoord;
in vec4 vertexColor;

void main() {
    vec4 albedo = texture(texture, texCoord) * vertexColor;
    if (albedo.a < 0.1) {
        discard;
    }

    // Soft fluffy cloud shading tinted by atmospheric ambient light
    float sunElevation = normalize(sunPosition).y;
    float dayFactor = clamp(sunElevation * 2.0 + 0.2, 0.0, 1.0);
    vec3 cloudTint = mix(vec3(0.35, 0.40, 0.55), vec3(1.0, 0.98, 0.95), dayFactor);

    // Warm sunset tint on clouds
    float sunsetFactor = smoothstep(0.35, 0.0, abs(sunElevation));
    cloudTint = mix(cloudTint, vec3(1.05, 0.65, 0.55), sunsetFactor * 0.7);

    gl_FragData[0] = vec4(albedo.rgb * cloudTint, albedo.a * 0.85);
}
