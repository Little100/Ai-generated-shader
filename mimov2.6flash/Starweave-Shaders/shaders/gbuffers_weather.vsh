#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"

out vec2 vUV;
out vec2 vLightmap;
out vec4 vColor;
out float vDist;

void main(){
  vUV = gl_MultiTexCoord0.xy;
  vLightmap = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  vColor = gl_Color;

  vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
  vDist = length(viewPos.xyz);
  gl_Position = gl_ProjectionMatrix * viewPos;
}
