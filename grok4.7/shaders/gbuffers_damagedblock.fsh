#version 120
/* RENDERTARGETS: 0 */
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
    gl_FragData[0] = vec4(srgbToLinear(tex.rgb * vColor.rgb), tex.a * vColor.a);
}
