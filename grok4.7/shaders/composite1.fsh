#version 120
/* RENDERTARGETS: 5 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/post.glsl"
#include "/lib/space.glsl"
#include "/lib/material.glsl"
#include "/lib/sky.glsl"

varying vec2 texcoord;

vec3 bounce(vec2 uv) {
    float depth = texture2D(depthtex1, uv).r;
    if (depth >= 1.0 || K_SSGI <= 0.001) {
        return vec3(0.0);
    }
    vec3 viewPos = viewFromScreen(uv, depth);
    Material m = materialFromGbuffer(uv);
    vec3 n = m.normal;
    int steps = 4 + K_QUALITY * 3;
    vec3 acc = vec3(0.0);
    float w = 0.0;
    float rot = blueNoise(gl_FragCoord.xy) * TAU;
    for (int i = 0; i < 16; i++) {
        if (i >= steps) {
            break;
        }
        vec2 xi = hash22(uv * viewWidth + float(i) * 17.1 + float(frameCounter));
        vec3 dir = hemisphereSample(xi, n);
        vec3 pos = viewPos + dir * 0.35;
        float dist = 0.4;
        bool hit = false;
        vec2 hitUv = uv;
        for (int s = 0; s < 8; s++) {
            pos += dir * dist;
            dist *= 1.35;
            vec2 suv = screenFromView(pos);
            if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) {
                break;
            }
            float sd = texture2D(depthtex1, suv).r;
            vec3 scene = viewFromScreen(suv, sd);
            if (scene.z > pos.z && scene.z - pos.z < dist) {
                hit = true;
                hitUv = suv;
                break;
            }
        }
        if (hit) {
            vec3 incoming = texture2D(colortex0, hitUv).rgb;
            float nd = saturate(dot(n, dir));
            acc += incoming * nd;
            w += 1.0;
        } else {
            vec3 sky = skyLightColor() * saturate(dir.y * 0.5 + 0.5);
            acc += sky * 0.35;
            w += 0.35;
        }
    }
    vec3 gi = acc / max(w, 0.001);
    return gi * m.albedo * (1.0 - m.metal) * K_SSGI * 0.55;
}

void main() {
    gl_FragData[0] = vec4(bounce(texcoord), 1.0);
}
