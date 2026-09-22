#version 140
out vec4 vColor;

void main(){
  gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
  vColor = gl_Color;
}
