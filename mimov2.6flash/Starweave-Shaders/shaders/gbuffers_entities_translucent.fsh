#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/lighting.glsl"
#include "/lib/sky.glsl"

in vec2 vUV;
in vec2 vLightmap;
in vec4 vColor;
in vec3 vWorldNormal;
in float vDist;
in vec4 vEntity;

uniform sampler2D tex;

void main(){
  /* DRAWBUFFERS:0 */
  vec4 t = texture(tex, vUV);
  if (t.a < 0.1) discard;
  vec3 albedo = t.rgb * vColor.rgb;
  vec3 N = normalize(vWorldNormal);
  vec3 color = selfLight(albedo, vLightmap, 1.0, N);

  vec3 rayDir = screenRayDir(gl_FragCoord.xy / vec2(viewWidth, viewHeight));
  float F = pow(1.0 - max(dot(N, -rayDir), 0.0), 5.0);
  vec3 R = reflect(rayDir, N);
  color += proceduralSky(R) * F * 0.2;

  color = applyFog(color, max(vDist, 0.01), fogColor + ambientSkyColor() * 0.12, 0.0032 + rainStrength * 0.004);
  gl_FragData[0] = vec4(color, t.a);
}
