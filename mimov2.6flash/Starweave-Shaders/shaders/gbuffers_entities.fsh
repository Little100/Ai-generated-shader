#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/lighting.glsl"
#include "/lib/material.glsl"
#include "/lib/write_gbuffer.glsl"

in vec2 vUV;
in vec2 vLightmap;
in vec4 vColor;
in vec3 vWorldNormal;
in float vDist;

uniform sampler2D tex;

void main(){
  /* DRAWBUFFERS:012 */
  vec4 t = texture(tex, vUV);
  if (t.a < 0.1) discard;
  vec3 albedo = t.rgb * vColor.rgb;
  vec2 lm = lightLevels(vLightmap);
  MatData m = readMaterial(vUV, 0.0);
  writeGbuffer(albedo, lm.x, lm.y, vWorldNormal, m.smoothness, m.metalness, m.emissive, 1.0);
}
