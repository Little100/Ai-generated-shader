#version 140
#include "/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/wave.glsl"

in vec4 mc_Entity;

uniform mat4 shadowModelViewInverse;

out vec2 vUV;

void main(){
  vUV = gl_MultiTexCoord0.xy;
#ifdef WAVING
  vec3 shadowView = (gl_ModelViewMatrix * gl_Vertex).xyz;
  vec3 absWorld = (shadowModelViewInverse * vec4(shadowView, 1.0)).xyz;
  vec3 delta = terrainWave(mc_Entity.x, absWorld, frameTimeCounter);
  gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * (gl_Vertex + vec4(delta, 0.0)));
#else
  gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
#endif
}
