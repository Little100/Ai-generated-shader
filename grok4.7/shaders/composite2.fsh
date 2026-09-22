#version 120
/* RENDERTARGETS: 6 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/post.glsl"
#include "/lib/space.glsl"
#include "/lib/material.glsl"
#include "/lib/sky.glsl"

varying vec2 texcoord;

vec3 reflectColor(vec2 uv) {
    float depth = texture2D(depthtex0, uv).r;
    if (depth >= 1.0 || K_SSR <= 0.001) {
        return vec3(0.0);
    }
    vec3 viewPos = viewFromScreen(uv, depth);
    Material m = materialFromGbuffer(uv);
    if (m.roughness > 0.55 && m.id != ID_WATER) {
        return vec3(0.0);
    }
    vec3 n = m.normal;
    vec3 v = normalize(-viewPos);
    vec3 r = reflect(-v, n);
    float ndotv = saturate(dot(n, v));
    vec3 f0 = mix(vec3(m.f0), m.albedo, m.metal);
    float fresnel = fresnelSchlick(ndotv, f0).r;
    if (m.id == ID_WATER) {
        fresnel = mix(0.02, 1.0, pow(1.0 - ndotv, 5.0));
    }

    vec3 pos = viewPos + n * 0.08;
    float stepLen = 0.15;
    vec3 hitCol = skyRadiance(normalize(mat3(gbufferModelViewInverse) * r));
    int steps = 8 + K_QUALITY * 6;
    for (int i = 0; i < 28; i++) {
        if (i >= steps) {
            break;
        }
        pos += r * stepLen;
        stepLen *= 1.12;
        vec2 suv = screenFromView(pos);
        if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) {
            break;
        }
        float sd = texture2D(depthtex1, suv).r;
        vec3 scene = viewFromScreen(suv, sd);
        if (scene.z > pos.z && abs(scene.z - pos.z) < stepLen * 1.5) {
            hitCol = texture2D(colortex0, suv).rgb;
            break;
        }
    }
    float roughFade = 1.0 - saturate(m.roughness * 1.4);
    return hitCol * fresnel * roughFade * K_SSR;
}

void main() {
    gl_FragData[0] = vec4(reflectColor(texcoord), 1.0);
}
