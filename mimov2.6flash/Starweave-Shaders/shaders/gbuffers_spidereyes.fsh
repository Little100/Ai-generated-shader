#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/lighting.glsl"
#include "/lib/write_gbuffer.glsl"

in vec2 vUV;
in vec2 vLightmap;
in vec4 vColor;

uniform sampler2D tex;

void main(){
  /* DRAWBUFFERS:012 */
  vec4 t = texture(tex, vUV);
  if (t.a < 0.1) discard;
  vec3 albedo = t.rgb * vColor.rgb;
  vec2 lm = lightLevels(vLightmap);
  writeGbuffer(albedo, lm.x, lm.y, vec3(0.0, 1.0, 0.0), 0.3, 0.0, 1.5, 1.0);
}
