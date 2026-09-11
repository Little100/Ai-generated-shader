#version 330 compatibility

/*
    Textured geometry that carries no lightmap, such as the enchantment glint
    and spider eyes. It is treated as pure emission so it keeps its own colour
    instead of being shaded by the sun.
*/

#include "/lib/buffers.glsl"
#include "/lib/surface.glsl"

in vec2 texcoord;
in vec2 lmcoord;
in vec2 lightLevel;
in vec4 tint;
in vec3 worldNormal;
in vec3 worldPos;
in float viewDistance;

/* RENDERTARGETS: 0,1,2,3 */
layout(location = 0) out vec4 outScene;
layout(location = 1) out vec4 outAlbedo;
layout(location = 2) out vec4 outNormal;
layout(location = 3) out vec4 outLight;

void main() {
    vec4 base = texture(gtexture, texcoord) * tint;
    if (base.a < alphaTestRef) {
        discard;
    }

    vec3 albedo = srgbToLinear(base.rgb);
    vec3 normal = normalize(worldNormal);

    outScene = vec4(albedo * 1.35, 1.0);
    outAlbedo = vec4(albedo, MAT_EMISSIVE);
    outNormal = vec4(encodeNormal(normal), 0.5);
    outLight = vec4(lightLevel, 0.0, 1.0);
}
