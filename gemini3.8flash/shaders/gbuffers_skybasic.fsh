#version 330 compatibility

/* RENDERTARGETS: 0 */

#include "/lib/settings.glsl"
#include "/lib/atmosphere.glsl"

// ==============================================================================
// Aetheria: G-Buffers Sky Basic Fragment Shader
// ==============================================================================

uniform vec3 sunPosition;
uniform float frameTimeCounter;
uniform float rainStrength;

in vec3 vertexPos;
in vec4 vertexColor;

void main() {
    vec3 viewDir = normalize(vertexPos);
    vec3 sunDir = normalize(sunPosition);

    vec3 sky = calculateSkyColor(viewDir, sunDir, frameTimeCounter, rainStrength);

    gl_FragData[0] = vec4(sky, 1.0);
}
