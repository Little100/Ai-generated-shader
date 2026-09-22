#version 120
/* RENDERTARGETS: 4 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/post.glsl"
#include "/lib/space.glsl"
#include "/lib/sky.glsl"

varying vec2 texcoord;

float shaftMarch(vec2 uv) {
    float depth = texture2D(depthtex0, uv).r;
    if (depth >= 1.0) {
        return 0.0;
    }
    vec3 viewEnd = viewFromScreen(uv, depth);
    vec3 lightView = normalize(mat3(gbufferModelView) * K_LIGHT_DIR);
    int steps = 6 + K_QUALITY * 4;
    float acc = 0.0;
    float dither = blueNoise(gl_FragCoord.xy);
    for (int i = 0; i < 18; i++) {
        if (i >= steps) {
            break;
        }
        float t = (float(i) + dither) / float(steps);
        vec3 pos = viewEnd * t;
        vec2 suv = screenFromView(pos);
        if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) {
            continue;
        }
        float sd = texture2D(depthtex0, suv).r;
        vec3 scene = viewFromScreen(suv, sd);
        float lit = scene.z < pos.z - 0.05 ? 0.0 : 1.0;
        float height = saturate(1.0 - abs(pos.y) / 64.0);
        acc += lit * height;
    }
    float ndotl = saturate(lightView.z * -1.0 + 0.35);
    return acc / float(steps) * ndotl;
}

void main() {
    vec3 seed = texture2D(colortex4, texcoord).rgb;
    float shaft = shaftMarch(texcoord) * K_VOLUMETRIC;
    vec3 sun = sunLightColor() * K_SUN_INTENSITY;
    vec3 moon = vec3(0.35, 0.42, 0.7) * K_MOON_INTENSITY * K_NIGHT;
    vec3 col = seed + (sun + moon) * shaft * 0.35;
    col *= mix(1.0, 0.45, rainStrength);
    gl_FragData[0] = vec4(col, 1.0);
}
