#version 140
out vec2 vUV;
out vec2 vLightmap;
out vec4 vColor;

void main(){
  gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
  vUV = gl_MultiTexCoord0.xy;
  vLightmap = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  vColor = gl_Color;
}
