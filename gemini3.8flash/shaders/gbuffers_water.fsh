#version 330 compatibility

/* RENDERTARGETS: 0,1,2 */

#include "/lib/settings.glsl"
#include "/lib/water.glsl"

// ==============================================================================
// Aetheria: G-Buffers Water & Translucents Fragment Shader
// ==============================================================================

uniform sampler2D texture;
uniform mat4 gbufferModelView;
uniform float frameTimeCounter;

in vec2 texCoord;
in vec2 lmCoord;
in vec4 vertexColor;
in vec3 normal;
in vec3 worldPos;
in float isWater;

void main() {
    vec4 albedo = texture(texture, texCoord) * vertexColor;
    if (albedo.a < 0.05) {
        discard;
    }

    vec3 fragNormal = normal;
    float matId = 0.0;

    if (isWater > 0.5) {
        matId = 1.0; // Water material ID
        // Calculate dynamic normal in world space and transform to view space
        vec3 worldNormal = calculateWaterNormal(worldPos.xz, frameTimeCounter);
        fragNormal = mat3(gbufferModelView) * worldNormal;

        // Give water a soft translucent crystalline base color
        albedo = vec4(0.12, 0.45, 0.65, 0.60);
    }

    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(normalize(fragNormal) * 0.5 + 0.5, matId / 255.0);
    gl_FragData[2] = vec4(lmCoord, 0.0, 1.0);
}
