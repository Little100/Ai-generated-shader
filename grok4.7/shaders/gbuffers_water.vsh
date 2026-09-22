#version 120
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/material.glsl"
#include "/lib/vertex.glsl"
#include "/lib/water.glsl"

void main() {
    kilnVertex(true);
    if (vId == ID_WATER) {
        vec3 displaced;
        vec3 wn;
        waterSurface(vWorldPos, displaced, wn);
        vec3 delta = (displaced - vWorldPos) * K_WATER_WAVES;
        vec4 local = gl_Vertex;
        local.xyz += (gl_ModelViewMatrixInverse * vec4(delta, 0.0)).xyz;
        vec4 view = gl_ModelViewMatrix * local;
        vViewPos = view.xyz;
        vPlayerPos = (gbufferModelViewInverse * vec4(vViewPos, 1.0)).xyz;
        vWorldPos = vPlayerPos + cameraPosition;
        gl_Position = gl_ProjectionMatrix * view;
        vNormal = wn;
    }
}
