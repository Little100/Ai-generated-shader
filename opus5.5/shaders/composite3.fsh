#version 330 compatibility

#include "/lib/util.glsl"
#include "/lib/lighting.glsl"
#include "/lib/shadow.glsl"

uniform sampler2D depthtex0;

in vec2 texcoord;

/* RENDERTARGETS: 0,4 */

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

// 单个采样点的介质散射, 需要处在阴影之外并且离相机足够远
float mediumScatter(vec3 worldPos, vec3 normalHint) {
    vec3 sPos = worldToShadow(worldPos);
    if (any(lessThan(sPos, vec3(0.0))) || any(greaterThan(sPos, vec3(1.0)))) return 1.0;
    float stored = texture2D(shadowtex1, sPos.xy).r;
    // 加一点抖动, 否则会出现台阶状条纹
    sPos.z += (ign(gl_FragCoord.xy * 0.5, frameCounter) - 0.5) * 0.0006;
    return step(sPos.z - 0.0004, stored);
}

void main() {
    vec4 scene = texture2D(colortex0, texcoord);
    vec4 aux = texture2D(colortex4, texcoord);
    float rawDepth = texture2D(depthtex0, texcoord).r;

    // 非天空像素在延迟阶段已经算过直射光, 只需天空与远景参与
    if (rawDepth < 0.9995) {
        gl_FragData[0] = scene;
        gl_FragData[1] = aux;
        return;
    }

#ifdef GOD_RAYS
    vec3 worldDir = normalize(viewToWorldDir(screenToViewPos(vec3(texcoord, 1.0))));
    LightInfo light = getLightInfo();
    vec3 lightDir = light.direction;

    // 只有朝着主光源看才有明显光柱
    float facing = max(dot(worldDir, lightDir), 0.0);
    float skyOcclusion = aux.g;

    float jitter = ign(gl_FragCoord.xy, frameCounter * 0.73);
    float marchLength = 190.0;
    float dt = marchLength / float(RAY_LOOP);
    float transmittance = 1.0;
    float accum = 0.0;

    for (int i = 0; i < RAY_LOOP; i++) {
        float t = (float(i) + jitter) * dt;
        vec3 samplePos = cameraPosition + worldDir * t;
        float medium = mediumScatter(samplePos, worldDir);
        // 空气散射随高度衰减, 低处更厚
        float heightTerm = exp(-max(samplePos.y - 62.0, 0.0) * 0.02);
        float density = (0.55 + heightTerm * 0.75) * (1.0 - clamp(skyOcclusion, 0.0, 1.0) * 0.35);
        float stepOptical = medium * density * dt * 0.012;
        accum += medium * density * transmittance * dt;
        transmittance *= exp(-stepOptical);
    }

    float phase = 0.35 + 0.65 * pow(facing, 4.0);
    vec3 ray = light.color * accum * phase * godrayStrength * 0.0009;
    // 夜里不出现光柱
    ray *= smoothstep(-0.05, 0.22, sunHeight());
    ray *= (1.0 - rainStrength * 0.7);

    scene.rgb += ray;
#endif

    gl_FragData[0] = scene;
    gl_FragData[1] = aux;
}
