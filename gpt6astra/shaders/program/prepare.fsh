#include "/lib/settings.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/pipeline.glsl"
#include "/lib/sky.glsl"
in vec2 vUV;
/* RENDERTARGETS: 0 */
void main() {
    // Initialize the sky before opaque/depthless forward draws, not over them.
    gl_FragData[0] = vec4(renderSky(viewRay(vUV),cameraPosition+cameraOrigin()),1.0);
}
