#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/wave.glsl"

in vec4 mc_Entity;

out vec2 vUV;
out vec2 vLightmap;
out vec4 vColor;
out vec3 vWorldAbs;
out vec3 vWorldNormal;
out float vDist;
out vec4 vEntity;

void main(){
  vUV = gl_MultiTexCoord0.xy;
  vLightmap = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  vColor = gl_Color;
  vEntity = mc_Entity;

  vec4 displaced = gl_Vertex;
#ifdef WATER_WAVES
  if (mc_Entity.x == 10200.0){
    vec4 view0 = gl_ModelViewMatrix * gl_Vertex;
    vec3 absW = rawToWorld(viewToWorldRaw(view0));
    displaced.y += waterHeight(absW, frameTimeCounter);
  }
#endif

  vec4 viewPos = gl_ModelViewMatrix * displaced;
  vDist = length(viewPos.xyz);
  vWorldAbs = rawToWorld(viewToWorldRaw(viewPos));
  gl_Position = gl_ProjectionMatrix * viewPos;
  vWorldNormal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
}
