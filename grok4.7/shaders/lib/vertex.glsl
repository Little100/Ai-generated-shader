#ifndef KILN_VERTEX
#define KILN_VERTEX

uniform mat4 gbufferModelViewInverse;

out vec2 vUv;
out vec2 vLm;
out vec4 vColor;
out vec3 vViewPos;
out vec3 vPlayerPos;
out vec3 vNormal;
out vec3 vTangent;
out vec3 vWorldPos;
out float vAo;
flat out int vId;

attribute vec4 mc_Entity;
attribute vec4 at_tangent;
attribute vec4 mc_midTexCoord;
attribute vec3 at_midBlock;

uniform vec3 chunkOffset;

void kilnVertex(bool terrain) {
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    vViewPos = view.xyz;
    vPlayerPos = (gbufferModelViewInverse * vec4(vViewPos, 1.0)).xyz;
    vWorldPos = vPlayerPos + cameraPosition;
    gl_Position = gl_ProjectionMatrix * view;

    vUv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vLm = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
    vNormal = normalize(gl_NormalMatrix * gl_Normal);
    vTangent = normalize(gl_NormalMatrix * at_tangent.xyz);
    vAo = vColor.a;
    vId = terrain ? int(mc_Entity.x + 0.5) : 0;
}

vec3 windOffset(vec3 world, vec3 mid, int id) {
    bool plant = id == ID_GRASS || id == ID_LEAVES || id == ID_CROP;
    if (!plant) {
        return vec3(0.0);
    }
    float h = saturate(mid.y * 0.5 + 0.5);
    if (id == ID_LEAVES) {
        h = 1.0;
    }
    float gust = sin(K_TIME * 1.6 + world.x * 0.18 + world.z * 0.13);
    float flutter = sin(K_TIME * 4.2 + world.y * 1.7) * 0.35;
    vec2 dir = vec2(0.8, 0.35);
    float amp = (0.06 + rainStrength * 0.08) * h * (id == ID_LEAVES ? 0.55 : 1.0);
    return vec3(dir * (gust + flutter) * amp, flutter * amp * 0.25);
}

#endif
