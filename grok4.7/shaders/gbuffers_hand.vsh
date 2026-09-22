#version 120
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/material.glsl"
#include "/lib/vertex.glsl"

void main() {
    kilnVertex(false);
    if (firstPersonCamera) {
        gl_Position.z *= 0.5;
    }
}
