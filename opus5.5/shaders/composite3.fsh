#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 5 */

#if godraySteps == 8
#define RAY_LOOP 8
#elif godraySteps == 16
#define RAY_LOOP 16
#elif godraySteps == 40
#define RAY_LOOP 40
#elif godraySteps == 64
#define RAY_LOOP 64
#else
#define RAY_LOOP 24
#endif

// 采样点是否处在直射光里, 用阴影贴图逐点判断, 这样树冠之间会自然出现光柱
float lightVisibility(vec3 worldPos, float dither) {
    vec3 sPos = worldToShadow(worldPos);
    if (any(lessThan(sPos, vec3(0.0))) || any(greaterThan(sPos, vec3(1.0)))) return 1.0;
    // 抖动一点深度, 否则会出现台阶状的条纹
    float stored = texture2D(shadowtex1, sPos.xy + vec2(dither - 0.5) * 0.0018).r;
    return step(sPos.z - 0.0016, stored);
}

void main() {
    float rawDepth = texture2D(depthtex0, texcoord).r;
    vec3 worldDir = normalize(viewToWorldDir(screenToViewPos(vec3(texcoord, 1.0))));

#ifdef GOD_RAYS
    // 天空方向按最远距离推进, 有几何体时缩短到该处
    float sceneDistance = 512.0;
    if (rawDepth < 1.0) {
        sceneDistance = length(screenToViewPos(vec3(texcoord, rawDepth)));
    }
    float marchLength = min(sceneDistance, 320.0);

    LightInfo light = getLightInfo();
    vec3 lightDir = light.direction;
    // 朝着主光源看时光柱最明显, 背对时几乎不可见
    float facing = max(dot(worldDir, lightDir), 0.0);
    float phase = 0.30 + 0.70 * pow(facing, 4.0);

    float dither = ign(gl_FragCoord.xy, frameCounter);
    float dt = marchLength / float(RAY_LOOP);
    float transmittance = 1.0;
    float accum = 0.0;

    for (int i = 0; i < RAY_LOOP; i++) {
        float t = (float(i) + dither) * dt;
        vec3 samplePos = cameraPosition + worldDir * t;
        float visible = lightVisibility(samplePos, dither);
        // 空气散射随高度衰减, 低处更厚
        float density = 0.55 + exp(-max(samplePos.y - 62.0, 0.0) * 0.02) * 0.75;
        accum += visible * density * transmittance * dt;
        transmittance *= exp(-density * dt * 0.004);
    }

    vec3 ray = light.color * accum * phase * godrayStrength * 0.0007;
    // 夜间与雨天不出现光柱
    ray *= smoothstep(-0.05, 0.22, sunHeight()) * (1.0 - rainStrength * 0.7);

    gl_FragData[0] = vec4(max(ray, 0.0), 1.0);
#else
    gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
#endif
}
