#version 120
/* RENDERTARGETS: 7 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/post.glsl"

varying vec2 texcoord;

void main() {
    gl_FragData[0] = vec4(texture2D(colortex0, texcoord).rgb, 1.0);
}
