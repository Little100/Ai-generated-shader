#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D colortex4;

in vec2 vUV;

void main(){
  /* DRAWBUFFERS:5 */
  vec2 dx = vec2(1.6 / viewWidth, 0.0);
  vec3 sum = texture(colortex4, vUV).rgb * 0.227027;
  sum += texture(colortex4, vUV + dx).rgb * 0.194595;
  sum += texture(colortex4, vUV - dx).rgb * 0.194595;
  sum += texture(colortex4, vUV + dx * 2.0).rgb * 0.121622;
  sum += texture(colortex4, vUV - dx * 2.0).rgb * 0.121622;
  sum += texture(colortex4, vUV + dx * 3.0).rgb * 0.054054;
  sum += texture(colortex4, vUV - dx * 3.0).rgb * 0.054054;
  sum += texture(colortex4, vUV + dx * 4.0).rgb * 0.016216;
  sum += texture(colortex4, vUV - dx * 4.0).rgb * 0.016216;
  gl_FragData[0] = vec4(sum, 1.0);
}
