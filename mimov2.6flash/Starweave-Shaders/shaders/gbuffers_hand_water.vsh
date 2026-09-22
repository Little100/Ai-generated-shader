#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"

out vec2 vUV;
out vec2 vLightmap;
out vec4 vColor;
out vec3 vWorldNormal;
out float vDist;
out vec4 vEntity;

void main(){
  vUV = gl_MultiTexCoord0.xy;
  vLightmap = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  vColor = gl_Color;
  vEntity = vec4(0.0);

  vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
  vDist = length(viewPos.xyz);
  gl_Position = gl_ProjectionMatrix * viewPos;
  vWorldNormal = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
}
