#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#ifdef BLUR_HORIZONTAL
uniform sampler2D colortex5;
/* RENDERTARGETS: 6 */
#define BLOOM_SOURCE colortex5
#else
uniform sampler2D colortex6;
/* RENDERTARGETS: 5 */
#define BLOOM_SOURCE colortex6
#endif
in vec2 vUV;
void main() {
    vec3 sum = vec3(0.0);
#ifdef BLOOM
    vec2 texel = 1.0/vec2(textureSize(BLOOM_SOURCE,0));
#ifdef BLUR_HORIZONTAL
    vec2 axis = vec2(texel.x,0.0);
#else
    vec2 axis = vec2(0.0,texel.y);
#endif
    float weights = 0.0;
    for (int i=-7;i<=7;++i) {
        float w = exp(-float(i*i)/19.0);
        sum += texture(BLOOM_SOURCE,clamp(vUV+axis*float(i),texel*0.5,1.0-texel*0.5)).rgb*w;
        weights += w;
    }
    sum /= weights;
#endif
    gl_FragData[0] = vec4(sum,1.0);
}
