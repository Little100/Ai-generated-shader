#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/lighting.glsl"

in vec2 vUV;
in vec2 vLightmap;
in vec4 vColor;
in float vDist;

uniform sampler2D tex;

void main(){
  /* DRAWBUFFERS:0 */
  vec4 t = texture(tex, vUV);
  if (t.a < 0.1) discard;
  vec3 albedo = t.rgb * vColor.rgb;
  vec3 rayDir = screenRayDir(gl_FragCoord.xy / vec2(viewWidth, viewHeight));
  vec3 color = selfLight(albedo, vLightmap, 1.0, -rayDir);
  color = applyFog(color, max(vDist, 0.01), fogColor + ambientSkyColor() * 0.1, 0.004 + rainStrength * 0.005);
  gl_FragData[0] = vec4(color, t.a);
}
