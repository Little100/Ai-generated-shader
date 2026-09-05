#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
uniform sampler2D colortex0;
in vec2 vUV;
/* RENDERTARGETS: 5 */
void main() {
    vec3 highlights = vec3(0.0);
#ifdef BLOOM
    for (int i=0;i<4;++i) {
        vec2 offset = vec2(float(i%2),float(i/2))-0.5;
        vec3 color = texture(colortex0,vUV+offset*pixelSize()).rgb;
        float luma = luminance(color);
        highlights += color*(max(luma-0.90,0.0)/max(luma,0.001))*0.25;
    }
#endif
    gl_FragData[0] = vec4(highlights,1.0);
}
