#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/sky.glsl"
#include "/lib/fog.glsl"
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;
in vec2 vUV;
/* RENDERTARGETS: 0 */
vec3 upsampleRays(float distanceToEye) {
    vec2 size = vec2(textureSize(colortex7,0));
    vec2 coord = vUV*size-0.5;
    vec2 base = floor(coord), fraction = fract(coord);
    vec3 sum = vec3(0.0);
    float weights = 0.0;
    for (int i=0;i<4;++i) {
        vec2 corner = vec2(float(i%2),float(i/2));
        vec2 uv = clamp((base+corner+0.5)/size,0.5/size,1.0-0.5/size);
        vec4 sampleRay = texture(colortex7,uv);
        float depthWeight = exp(-abs(sampleRay.a-distanceToEye)/max(0.75,distanceToEye*0.04));
        vec2 bilinear = mix(1.0-fraction,fraction,corner);
        float w = depthWeight*bilinear.x*bilinear.y;
        sum += sampleRay.rgb*w;
        weights += w;
    }
    return weights>0.001 ? sum/weights : vec3(0.0);
}
void main() {
    float depth = texture(depthtex0,vUV).r;
    float distanceToEye = min(length(screenToView(vUV,depth)),65000.0);
    vec3 color = texture(colortex0,vUV).rgb;
    float flag = texture(colortex1,vUV).a;
    bool hand = flag>0.1 && flag<0.4;
#ifdef VOLUMETRIC_LIGHT
    if (!hand) color += upsampleRays(distanceToEye);
#endif
    color = applyStatus(color,hand ? 0.7 : distanceToEye);
    gl_FragData[0] = vec4(max(color,vec3(0.0)),1.0);
}
