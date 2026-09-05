#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/wind.glsl"
#if defined(GEOM_TERRAIN) || defined(GEOM_WATER)
in vec4 mc_Entity;
in vec4 mc_midTexCoord;
#endif
out vec2 vUV;
out vec2 vLightmap;
out vec4 vColor;
out vec3 vNormal;
out vec3 vPlayer;
flat out float vMaterial;
out float vChunkFade;
void main() {
    vUV = (gl_TextureMatrix[0]*gl_MultiTexCoord0).xy;
    vLightmap = (gl_TextureMatrix[1]*gl_MultiTexCoord1).xy;
    vColor = gl_Color;
    vec4 view = gl_ModelViewMatrix*gl_Vertex;
    vec3 player = (gbufferModelViewInverse*view).xyz;
    vNormal = safeNormalize(mat3(gbufferModelViewInverse)*(gl_NormalMatrix*gl_Normal));
    if (dot(vNormal,vNormal)<0.1) vNormal = vec3(0.0,1.0,0.0);
    vMaterial = 0.0;
    vec3 offset = vec3(0.0);
#if defined(GEOM_TERRAIN) || defined(GEOM_WATER)
    vMaterial = mc_Entity.x;
    float top = 1.0-step(mc_midTexCoord.y,gl_MultiTexCoord0.y);
    offset = windOffset(player+cameraPosition,vMaterial,top,sat(vLightmap.y));
#endif
    vPlayer = player+offset;
    // Keep ftransform() intact for Iris line expansion / vertex format patching.
    gl_Position = ftransform()+gl_ProjectionMatrix*gbufferModelView*vec4(offset,0.0);
    vChunkFade = 1.0;
#ifdef IRIS_FEATURE_FADE_VARIABLE
#if defined(GEOM_TERRAIN) || defined(GEOM_WATER)
    if (mc_chunkFade >= 0.0) vChunkFade = mc_chunkFade;
#endif
#endif
}
