#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/pipeline.glsl"
#include "/lib/sky.glsl"
#include "/lib/fog.glsl"
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
#include "/lib/ao.glsl"
in vec2 vUV;
/* RENDERTARGETS: 0,4 */
void main() {
    float depth = texture(depthtex0,vUV).r;
    vec3 color = texture(colortex0,vUV).rgb;
    vec4 surfaceData = texture(colortex1,vUV);
    bool hand = surfaceData.a>0.1 && surfaceData.a<0.4;
    vec3 view = screenToView(vUV,depth);
    if (depth<0.999999 && !hand) {
        vec3 normal = safeNormalize(mat3(gbufferModelView)*(surfaceData.xyz*2.0-1.0));
        color *= contactOcclusion(vUV,view,normal);
        if (isEyeInWater != 1) color = foggedSurface(color,viewToPlayer(view));
    }
    // Snapshot is pre-medium, so a water/air boundary can resolve its own path.
    gl_FragData[1] = vec4(color,surfaceData.a);
    // Resolve opaque transport at its OWN depth, before translucent layering.
    gl_FragData[0] = vec4(mediumTransport(color,hand ? 0.7 : length(view)),1.0);
}
