#version 330 compatibility

/*
    Untextured geometry. The colour arrives entirely through gl_Color, which is
    how the selection outline, leash lines and similar overlays are drawn.
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
    if (tint.a < alphaTestRef) {
        discard;
    }

    vec3 albedo = srgbToLinear(tint.rgb);
    vec3 normal = normalize(worldNormal);
    vec3 viewDir = normalize(worldPos + vec3(0.0, 0.0, 1e-5));
    vec3 lightmapColor = texture(lightmap, lmcoord).rgb;

    SurfaceResult lit = shadeSurface(albedo, normal, worldPos, viewDir, lightLevel, lightmapColor,
                                    0, viewDistance, lightLevel.y, 0.42, 1.0, 0.0, 0.0);

    outScene = vec4(lit.color, 1.0);
    outAlbedo = vec4(albedo, MAT_OPAQUE);
    outNormal = vec4(encodeNormal(normal), 0.42);
    outLight = vec4(lightLevel, lit.directVisibility, 1.0);
}
