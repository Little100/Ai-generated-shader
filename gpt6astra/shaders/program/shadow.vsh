#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/wind.glsl"
#include "/lib/shadow_space.glsl"
in vec4 mc_Entity;
in vec4 mc_midTexCoord;
out vec2 vUV;
out vec4 vColor;
flat out float vMaterial;
void main() {
    vUV = (gl_TextureMatrix[0]*gl_MultiTexCoord0).xy;
    vColor = gl_Color;
    vMaterial = mc_Entity.x;
    vec3 p = (shadowModelViewInverse*gl_ModelViewMatrix*gl_Vertex).xyz;
    float top = 1.0-step(mc_midTexCoord.y,gl_MultiTexCoord0.y);
    float skylight = sat((gl_TextureMatrix[1]*gl_MultiTexCoord1).y);
    p += windOffset(p+cameraPosition,vMaterial,top,skylight);
    vec4 clip = shadowProjection*shadowModelView*vec4(p,1.0);
    gl_Position = vec4(warpShadow(clip.xyz/clip.w),1.0);
}
