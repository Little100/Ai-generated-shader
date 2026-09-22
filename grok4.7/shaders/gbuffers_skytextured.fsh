#version 120
/* RENDERTARGETS: 0 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sky.glsl"

uniform sampler2D gtexture;
uniform mat4 gbufferModelViewInverse;

varying vec2 vUv;
varying vec4 vColor;
varying vec3 vViewPos;

void main() {
    vec4 tex = texture2D(gtexture, vUv);
    if (tex.a < 0.05) {
        discard;
    }
    vec3 viewDir = normalize((gbufferModelViewInverse * vec4(vViewPos, 0.0)).xyz);
    float sunish = saturate(dot(viewDir, K_SUN_DIR));
    vec3 col = srgbToLinear(tex.rgb) * vColor.rgb;
    col *= mix(moonDiskColor() * 0.35, sunDiskColor() * 0.15, sunish);
    gl_FragData[0] = vec4(col, tex.a);
}
