#version 140
#define DIM_END
#include "/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/lighting.glsl"
#include "/lib/sky.glsl"

void main(){
  /* DRAWBUFFERS:0 */
  vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
  vec3 dir = screenRayDir(uv);
  gl_FragData[0] = vec4(proceduralSky(dir), 1.0);
}
