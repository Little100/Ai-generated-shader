#version 120
/* RENDERTARGETS: 0,4 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/space.glsl"
#include "/lib/sky.glsl"
#include "/lib/material.glsl"
#include "/lib/shadow.glsl"
#include "/lib/post.glsl"

varying vec2 texcoord;

void main() {
    float depth = texture2D(depthtex1, texcoord).r;
    vec3 scene = texture2D(colortex0, texcoord).rgb;
    if (depth >= 1.0) {
        gl_FragData[0] = vec4(scene, 1.0);
        gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec3 viewPos = viewFromScreen(texcoord, depth);
    vec3 playerPos = playerFromView(viewPos);
    Material m = materialFromGbuffer(texcoord);
    vec3 n = m.normal;
    vec3 v = normalize(-viewPos);
    vec3 lightDir = K_LIGHT_DIR;
    vec3 viewL = normalize(mat3(gbufferModelView) * lightDir);

    float shadow = sampleShadow(playerPos, n);
    float contact = contactShadow(viewPos, n, viewL, depthtex1);
    shadow *= mix(1.0, contact, 0.45);

    vec3 sun = sunLightColor() * K_SUN_INTENSITY;
    vec3 moon = vec3(0.45, 0.55, 0.85) * (0.35 + K_MOON_LIGHT) * K_MOON_INTENSITY * K_NIGHT;
    vec3 key = sun + moon;
    vec3 direct = shadeDirect(m, n, v, lightDir, key, shadow);

    float skyVis = texture2D(colortex3, texcoord).a;
    vec3 indirect = m.albedo * skyLightColor() * skyVis * 0.22 * (1.0 - m.metal);
    indirect += m.albedo * vec3(0.03, 0.025, 0.02) * m.ao;

    vec3 emission = m.albedo * m.emission * 4.0 * K_TORCH_INTENSITY;
    vec3 color = scene * 0.15 + direct + indirect + emission;

    float ndotl = saturate(dot(n, lightDir));
    vec3 shaftSeed = key * shadow * ndotl * skyVis * 0.15;

    gl_FragData[0] = vec4(color, 1.0);
    gl_FragData[1] = vec4(shaftSeed, 1.0);
}
