#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/pipeline.glsl"
#include "/lib/sky.glsl"
#include "/lib/shadows.glsl"
uniform sampler2D depthtex0;
in vec2 vUV;
/* RENDERTARGETS: 7 */
void main() {
    float depth = texture(depthtex0,vUV).r;
    vec3 view = screenToView(vUV,depth);
    vec3 ray = viewRay(vUV);
    float limit = depth>=0.999999 ? min(far,160.0) : min(length(view),160.0);
    vec3 beams = vec3(0.0);
#if defined(VOLUMETRIC_LIGHT) && defined(SHADOWS) && WORLD_KIND == 0
    if (isEyeInWater != 2 && isEyeInWater != 3) {
        float stepLength = limit/float(VOLUMETRIC_STEPS);
        float jitter = hash21(gl_FragCoord.xy);
        float integral = 0.0;
        for (int i=0;i<VOLUMETRIC_STEPS;++i) {
            float t = (float(i)+0.15+jitter*0.7)*stepLength;
            vec3 p = cameraOrigin()+ray*t;
            float height = cameraPosition.y+p.y;
            float density = exp(-max(height-64.0,0.0)*0.025);
            float transmittance = exp(-t*(isEyeInWater == 1 ? 0.028 : 0.007));
            integral += rayShadow(p)*density*transmittance*stepLength;
        }
        float phase = 0.20+1.6*pow(sat(dot(ray,lightDirection())),10.0);
        float horizon = smoothstep(0.025,0.12,abs(sunDirection().y));
        beams = sunlightColor()*integral*0.0040*phase*FOG_DENSITY*horizon*(1.0-rainStrength*0.82);
    }
#endif
    gl_FragData[0] = vec4(beams,min(length(view),65000.0));
}
