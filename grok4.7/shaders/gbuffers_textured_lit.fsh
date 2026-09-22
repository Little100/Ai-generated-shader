#version 120
/* RENDERTARGETS: 0,1,2,3 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D gtexture;

varying vec2 vUv;
varying vec2 vLm;
varying vec4 vColor;
varying vec3 vNormal;

void main() {
    vec4 tex = texture2D(gtexture, vUv);
    if (tex.a < 0.1) {
        discard;
    }
    vec3 albedo = srgbToLinear(tex.rgb * vColor.rgb);
    vec3 lit = albedo * (0.05 + vLm.y * 0.15 * skyLightColor() + vLm.x * vLm.x * blockLightColor() * 0.5 * K_TORCH_INTENSITY);
    gl_FragData[0] = vec4(lit, tex.a);
    gl_FragData[1] = vec4(albedo, 0.0);
    gl_FragData[2] = vec4(encodeNormal(normalize(vNormal)), 0.6, 0.0);
    gl_FragData[3] = vec4(0.0, 0.05, vColor.a, vLm.y);
}
