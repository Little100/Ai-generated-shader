#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D colortex0;

in vec2 vUV;

void main(){
  /* DRAWBUFFERS:4 */
  vec3 hdr = texture(colortex0, vUV).rgb;
  float w = smoothstep(0.8, 1.7, luma(hdr));
  gl_FragData[0] = vec4(hdr * w, 1.0);
}
