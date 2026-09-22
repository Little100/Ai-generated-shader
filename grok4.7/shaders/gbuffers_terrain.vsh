#version 120
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/material.glsl"
#include "/lib/vertex.glsl"

void main() {
    kilnVertex(true);
    vec3 mid = at_midBlock.xyz / 64.0;
    vec3 wind = windOffset(vWorldPos, mid, vId) * K_WATER_WAVES;
    if (vId == ID_GRASS || vId == ID_LEAVES || vId == ID_CROP) {
        vec4 shifted = gl_Vertex;
        shifted.xyz += (gl_ModelViewMatrixInverse * vec4(wind, 0.0)).xyz;
        vec4 view = gl_ModelViewMatrix * shifted;
        vViewPos = view.xyz;
        vPlayerPos = (gbufferModelViewInverse * vec4(vViewPos, 1.0)).xyz;
        gl_Position = gl_ProjectionMatrix * view;
    }
}
