#version 120
/* RENDERTARGETS: 0 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sky.glsl"

uniform sampler2D gtexture;

varying vec2 vUv;
varying vec4 vColor;

void main() {
    vec4 tex = texture2D(gtexture, vUv);
    if (tex.a < 0.05) {
        discard;
    }
    vec3 col = skyLightColor() * srgbToLinear(tex.rgb * vColor.rgb) * K_CLOUD;
    gl_FragData[0] = vec4(col, tex.a * 0.55);
}
