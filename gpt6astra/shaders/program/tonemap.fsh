#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/sky.glsl"
#include "/lib/fog.glsl"
uniform sampler2D colortex0;
uniform sampler2D colortex5;
in vec2 vUV;
/* RENDERTARGETS: 0 */
vec3 tidelumeCurve(vec3 hdr) {
    // Authored rational shoulder, luminance-preserving with gentle highlight whitening.
    float luma = max(luminance(hdr),0.00001);
    float mapped = luma*(1.0+0.10*luma)/(0.82+1.16*luma+0.10*luma*luma);
    vec3 chromatic = hdr*(mapped/luma);
    float brightest = max(chromatic.r,max(chromatic.g,chromatic.b));
    chromatic /= max(1.0,brightest*0.97);
    float white = smoothstep(1.8,10.0,luma)*0.35;
    return mix(chromatic,vec3(mapped),white);
}
void main() {
    vec3 color = texture(colortex0,vUV).rgb;
#ifdef BLOOM
    color += texture(colortex5,vUV).rgb*BLOOM_STRENGTH;
#endif
    float adaptation = mix(1.20,0.95,skyAccess()*daylight());
    color = tidelumeCurve(max(color,vec3(0.0))*EXPOSURE*adaptation);
    float grey = luminance(color);
    color = mix(vec3(grey),color,SATURATION);
    vec2 centered = vUV*2.0-1.0;
    color *= 1.0-VIGNETTE_STRENGTH*pow(sat(dot(centered,centered)*0.5),1.4);
    gl_FragData[0] = vec4(sat(toDisplay(color)),1.0);
}
