#version 120
/* RENDERTARGETS: 0 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sky.glsl"

uniform mat4 gbufferModelViewInverse;

varying vec4 vColor;
varying vec3 vViewPos;

void main() {
    vec3 viewDir = normalize((gbufferModelViewInverse * vec4(vViewPos, 0.0)).xyz);
    vec3 sky = skyRadiance(viewDir) * K_CLOUD;
    sky = mix(sky, sky * 0.35, K_CLOUD_COVER * 0.5);
    sky += cloudColor(viewDir, 0.0) * K_CLOUD;
    gl_FragData[0] = vec4(sky, 1.0);
}
