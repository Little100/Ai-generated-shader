#version 120
/* RENDERTARGETS: 0 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/post.glsl"
#include "/lib/space.glsl"
#include "/lib/sky.glsl"
#include "/lib/material.glsl"
#include "/lib/water.glsl"

varying vec2 texcoord;

float ao(vec2 uv) {
    float depth = texture2D(depthtex1, uv).r;
    if (depth >= 1.0) {
        return 1.0;
    }
    vec3 viewPos = viewFromScreen(uv, depth);
    Material m = materialFromGbuffer(uv);
    vec3 n = m.normal;
    float occ = 0.0;
    float rot = blueNoise(gl_FragCoord.xy) * TAU;
    int taps = 6 + K_QUALITY * 2;
    for (int i = 0; i < 12; i++) {
        if (i >= taps) {
            break;
        }
        vec2 o = vogelDisk(i, taps, rot) * 0.012;
        vec2 suv = uv + o;
        float sd = texture2D(depthtex1, suv).r;
        vec3 s = viewFromScreen(suv, sd);
        vec3 d = s - viewPos;
        float dist = length(d);
        float range = smoothstep(1.2, 0.05, dist);
        occ += saturate(dot(n, d / max(dist, 1e-4))) * range;
    }
    return saturate(1.0 - occ / float(taps) * 1.6 * K_AO);
}

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    vec3 gi = texture2D(colortex5, texcoord).rgb;
    vec3 refl = texture2D(colortex6, texcoord).rgb;
    vec3 shafts = texture2D(colortex4, texcoord).rgb;
    float depth = texture2D(depthtex0, texcoord).r;
    float waterMask = texture2D(colortex8, texcoord).r;

    color += gi;
    color += refl;
    color += shafts * 0.65;

    float shade = ao(texcoord);
    color *= mix(1.0, shade, 0.65);

    if (depth < 1.0) {
        vec3 viewPos = viewFromScreen(texcoord, depth);
        float dist = length(viewPos);
        vec3 viewDir = normalize(mat3(gbufferModelViewInverse) * viewPos);
        if (waterMask > 0.5 && isEyeInWater == 0) {
            vec3 absorb = beerLambert(vec3(0.45, 0.12, 0.08), dist * 0.15);
            color = color * absorb + waterScatterColor() * (1.0 - absorb) * 0.35;
        }
        float fogAmt = 1.0 - exp(-dist * (0.0015 + rainStrength * 0.004 + fogDensity * 0.002));
        fogAmt = saturate(fogAmt);
        vec3 fogCol = skyRadiance(viewDir) * 0.65;
        if (isEyeInWater == 1) {
            fogAmt = 1.0 - exp(-dist * 0.08);
            fogCol = waterScatterColor() * (0.4 + K_SUN_UP * 0.8);
        } else if (isEyeInWater == 2) {
            fogAmt = 1.0 - exp(-dist * 0.35);
            fogCol = vec3(0.85, 0.22, 0.02);
        }
        color = mix(color, fogCol, fogAmt * 0.85);
    }

    if (blindness > 0.0) {
        color *= 1.0 - blindness;
    }

    gl_FragData[0] = vec4(max(color, vec3(0.0)), 1.0);
}
