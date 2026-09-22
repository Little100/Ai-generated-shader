#version 120
/* RENDERTARGETS: 0,1,2,3 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 vColor;
varying vec3 vNormal;

void main() {
    vec3 albedo = srgbToLinear(vColor.rgb);
    vec3 n = normalize(vNormal);
    int id = 12;
    #ifdef DH_BLOCK_GRASS
    #endif
    vec3 lit = albedo * (0.08 + 0.25 * skyLightColor() * K_SUN_UP);
    gl_FragData[0] = vec4(lit, 0.0);
    gl_FragData[1] = vec4(albedo, 0.0);
    gl_FragData[2] = vec4(encodeNormal(n), 0.8, 0.0);
    gl_FragData[3] = vec4(0.0, 0.05, 1.0, 1.0);
}
