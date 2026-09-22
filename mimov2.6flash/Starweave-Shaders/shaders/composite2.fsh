#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D colortex5;

in vec2 vUV;

void main(){
  /* DRAWBUFFERS:4 */
  vec2 dy = vec2(0.0, 1.6 / viewHeight);
  vec3 sum = texture(colortex5, vUV).rgb * 0.227027;
  sum += texture(colortex5, vUV + dy).rgb * 0.194595;
  sum += texture(colortex5, vUV - dy).rgb * 0.194595;
  sum += texture(colortex5, vUV + dy * 2.0).rgb * 0.121622;
  sum += texture(colortex5, vUV - dy * 2.0).rgb * 0.121622;
  sum += texture(colortex5, vUV + dy * 3.0).rgb * 0.054054;
  sum += texture(colortex5, vUV - dy * 3.0).rgb * 0.054054;
  sum += texture(colortex5, vUV + dy * 4.0).rgb * 0.016216;
  sum += texture(colortex5, vUV - dy * 4.0).rgb * 0.016216;
  gl_FragData[0] = vec4(sum, 1.0);
}
