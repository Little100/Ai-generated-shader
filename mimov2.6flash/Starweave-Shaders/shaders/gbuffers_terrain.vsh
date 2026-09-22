#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/wave.glsl"

in vec4 mc_Entity;

out vec2 vUV;
out vec2 vLightmap;
out vec4 vColor;
out vec3 vWorldNormal;
out vec4 vEntity;
out float vDist;

void main(){
  vUV = gl_MultiTexCoord0.xy;
  vLightmap = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  vColor = gl_Color;
  vEntity = mc_Entity;

  vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
  vDist = length(viewPos.xyz);
#ifdef WAVING
  vec3 absWorld = rawToWorld(viewToWorldRaw(viewPos));
  vec3 delta = terrainWave(mc_Entity.x, absWorld, frameTimeCounter);
  gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * (gl_Vertex + vec4(delta, 0.0)));
#else
  gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
#endif
  vWorldNormal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
}
