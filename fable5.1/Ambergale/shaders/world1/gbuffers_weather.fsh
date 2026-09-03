#version 330 compatibility
#define DIM_END

// Rain streaks are thinned and lit by the sky so they read as a veil rather than white stripes

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/materials.glsl"
#include "/lib/sky.glsl"
#include "/lib/lighting.glsl"

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 playerPos;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 c = texture(gtexture, texcoord) * glcolor;
    if (c.a < 0.01) discard;
    vec3 sunDir = sunDirWorld();
    vec3 amb = skyAmbient(sunDir) * pow(lmcoord.y, 1.5) + blocklight(lmcoord.x, playerPos + cameraPosition) * 0.5;
    vec3 col = srgbToLinear(c.rgb) * amb * 1.2;
    float fade = 1.0 - smoothstep(6.0, 18.0, length(playerPos));
    outColor = vec4(col, c.a * 0.55 * (0.4 + 0.6 * fade));
}
