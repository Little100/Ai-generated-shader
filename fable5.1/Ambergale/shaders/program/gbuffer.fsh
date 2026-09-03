// Shared fragment stage for opaque gbuffer programs.
// Writes albedo, light levels, material id, ambient occlusion and a world-space normal.

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/materials.glsl"

uniform float alphaTestRef;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normalWorld;
in vec3 playerPos;
flat in int material;

layout(location = 0) out vec4 outAlbedo;
layout(location = 1) out vec4 outLightData;
layout(location = 2) out vec4 outNormal;

void main() {
    #ifdef GB_BASIC
    vec4 albedo = glcolor;
    #else
    vec4 albedo = texture(gtexture, texcoord);
    albedo.rgb *= glcolor.rgb;
    #endif

    float ao = 1.0;
    #if defined GB_TERRAIN || defined GB_BLOCK
    // separateAo puts vanilla ambient occlusion into the alpha channel of the vertex color
    ao = glcolor.a;
    #else
    albedo.a *= glcolor.a;
    #endif

    #ifdef GB_ENTITY
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
    #endif

    #ifdef GB_OVERLAY
    if (albedo.a < 0.004) discard;
    #else
    if (albedo.a < alphaTestRef) discard;
    #endif
    #if (defined GB_TERRAIN || defined GB_BLOCK) && !defined GB_OVERLAY
    if (albedo.a < 0.1) discard;
    #endif

    // Backfaces still need a normal that points toward the viewer for lighting
    vec3 n = normalWorld;
    vec3 viewDirWorld = normalize(-playerPos);
    if (dot(n, viewDirWorld) < 0.0 && material != MAT_PLANT) n = -n;

    outAlbedo = vec4(albedo.rgb, 1.0);
    #ifdef GB_OVERLAY
    // Cracks and enchantment glint blend over the surface they decorate, leaving its gbuffer data intact
    outAlbedo.a = albedo.a;
    #else
    outLightData = vec4(lmcoord, encodeMat(material), ao);
    outNormal = vec4(n * 0.5 + 0.5, 1.0);
    #endif
}
