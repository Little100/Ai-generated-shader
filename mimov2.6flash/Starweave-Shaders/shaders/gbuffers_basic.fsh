#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/write_gbuffer.glsl"

in vec4 vColor;

void main(){
  /* DRAWBUFFERS:012 */
  writeGbuffer(vColor.rgb, 0.0, 1.0, vec3(0.0, 1.0, 0.0), 0.05, 0.0, 0.0, 1.0);
}
