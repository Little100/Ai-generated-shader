#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/sky.glsl"
#include "/lib/lighting.glsl"
#include "/lib/fog.glsl"
uniform sampler2D gtexture;
uniform float alphaTestRef;
#ifdef GEOM_ENTITY
uniform vec4 entityColor;
#endif
in vec2 vUV;
in vec2 vLightmap;
in vec4 vColor;
in vec3 vNormal;
in vec3 vPlayer;
flat in float vMaterial;
in float vChunkFade;
#ifdef GEOM_TRANSLUCENT
/* RENDERTARGETS: 0 */
#else
/* RENDERTARGETS: 0,1 */
#endif
void main() {
#ifdef GEOM_UNTEXTURED
    vec4 texel = vColor;
#else
    vec4 texel = texture(gtexture,vUV)*vColor;
#endif
    if (texel.a<max(alphaTestRef,0.001)) discard;
    if (hash21(gl_FragCoord.xy)>vChunkFade) discard;
#ifdef GEOM_ENTITY
    texel.rgb = mix(texel.rgb,entityColor.rgb,entityColor.a);
#endif
    vec3 normal = safeNormalize(vNormal);
    if (!gl_FrontFacing) normal = -normal;
    vec3 albedo = toLinear(texel.rgb);
#ifdef GEOM_EMISSIVE
    vec3 color = albedo*2.4;
#elif defined(GEOM_UNLIT)
    vec3 color = albedo;
#else
    vec3 color = shadeSurface(albedo,normal,vPlayer,vLightmap,vMaterial);
#endif
#ifdef GEOM_FORWARD
#ifndef GEOM_HAND
    if (isEyeInWater != 1) color = foggedSurface(color,vPlayer);
    color = mediumTransport(color,length(vPlayer-cameraOrigin()));
#else
    color = mediumTransport(color,0.7);
#endif
#endif
    gl_FragData[0] = vec4(color,texel.a);
#ifndef GEOM_TRANSLUCENT
#ifdef GEOM_HAND
    const float surfaceFlag = 0.25;
#else
    const float surfaceFlag = 1.0;
#endif
    gl_FragData[1] = vec4(normal*0.5+0.5,surfaceFlag);
#endif
}
