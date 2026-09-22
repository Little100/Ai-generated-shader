#version 120
/* RENDERTARGETS: 0,1,2,3 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D gtexture;

varying vec2 vUv;
varying vec4 vColor;

void main() {
    vec4 tex = texture2D(gtexture, vUv);
    if (tex.a < 0.1) {
        discard;
    }
    vec3 albedo = srgbToLinear(tex.rgb * vColor.rgb);
    gl_FragData[0] = vec4(albedo, tex.a);
    gl_FragData[1] = vec4(albedo, 0.0);
    gl_FragData[2] = vec4(0.5, 0.5, 0.8, 0.0);
    gl_FragData[3] = vec4(0.0, 0.0, 1.0, 1.0);
}
