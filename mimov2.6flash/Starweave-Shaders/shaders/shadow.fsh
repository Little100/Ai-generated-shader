#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D tex;

in vec2 vUV;

void main(){
  /* DRAWBUFFERS:0 */
  if (texture(tex, vUV).a < 0.1) discard;
  gl_FragData[0] = vec4(1.0);
}
