#version 140
out vec2 vUV;

void main(){
  gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
  vUV = gl_MultiTexCoord0.xy;
}
