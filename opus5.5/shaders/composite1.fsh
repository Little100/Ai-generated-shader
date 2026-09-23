#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0,4 */

// 折射偏移, 由水面法线的切线分量推得, 换算到屏幕空间
vec2 refractionOffset(vec3 normal, float thickness) {
    float strength = clamp(thickness * 0.75, 0.0, 1.0) * 0.028;
    vec2 dir = normal.xz / max(1.0 - normal.y * 0.7, 0.4);
    return dir * strength * vec2(1.0, 1.0 / aspectRatio);
}

// 屏幕空间的反射, 沿反射向量前进并按深度判定命中
vec3 screenSpaceReflection(vec3 viewPos, vec3 reflectDir, vec2 uv) {
#ifdef WATER_REFLECTION
    const int STEPS = 14;
    vec3 rayPos = viewPos + reflectDir * 0.15;
    float stepLen = 0.3;
    for (int i = 0; i < STEPS; i++) {
        rayPos += reflectDir * stepLen;
        stepLen *= 1.32;
        vec4 projected = gbufferProjection * vec4(rayPos, 1.0);
        if (projected.w <= 0.0) break;
        vec2 sampleUV = (projected.xy / projected.w) * 0.5 + 0.5;
        if (any(lessThan(sampleUV, vec2(0.0))) || any(greaterThan(sampleUV, vec2(1.0)))) break;
        float sceneDepth = texture2D(depthtex0, sampleUV).r;
        if (sceneDepth >= 1.0) continue;
        vec3 sceneView = screenToViewPos(vec3(sampleUV, sceneDepth));
        // 射线落到实体之后即视为命中
        if (rayPos.z < sceneView.z) {
            vec2 d = abs(sampleUV - uv);
            float edgeFade = smoothstep(0.0, 0.07, min(d.x, d.y));
            float depthFade = 1.0 - smoothstep(28.0, 110.0, length(sceneView));
            return texture2D(colortex0, sampleUV).rgb * edgeFade * depthFade;
        }
    }
#endif
    return vec3(0.0);
}

// 水面的着色
vec3 shadeWater(vec3 viewPos, vec3 worldPos, vec3 viewDir, vec3 normal,
                float thicknessHint, float distance, LightInfo light) {
    vec3 lightDir = light.direction;
    vec3 lightColor = light.color;

    if (isEyeInWater == 1) {
        // 水下看到的是水面内表面, 以全反射与吸收为主
        vec4 scene = texture2D(colortex0, texcoord);
        float cosTheta = clamp(dot(normal, viewDir), 0.0, 1.0);
        float refl = fresnelUnderwater(cosTheta);
        vec3 totalReflect = renderSky(reflect(-viewDir, normal), false) * 0.35;
        vec3 result = mix(scene.rgb, totalReflect, refl * 0.6);
        result += waterSunGlitter(normal, viewDir, lightDir, lightColor, 1.0) * 0.3;
        return waterAbsorb(result, distance * 0.05);
    }

    // 水体厚度由水面深度与水下地形深度之差估计
    vec2 refrUV = clamp(texcoord + refractionOffset(normal, thicknessHint), vec2(0.001), vec2(0.999));
    vec3 behindView = screenToViewPos(vec3(refrUV, texture2D(depthtex0, refrUV).r));
    float thickness = max(length(behindView) - distance, 0.0);
    // 贴着地面时收窄偏移, 免得取到岸上的像素
    float shoreFade = smoothstep(0.0, 1.4, thickness);
    refrUV = mix(texcoord, refrUV, shoreFade);

    vec3 refracted = texture2D(colortex0, refrUV).rgb;
    // 焦散落在透过水面的光照上
    refracted *= 1.0 + caustics(worldPos.xz, frameTimeCounter, 0.34) * causticsStrength * light.shadowSoft * 0.14;

    vec3 refrColor = waterAbsorb(refracted, thickness * 0.3)
                   + waterScatter(lightColor) * (1.0 - exp(-thickness * 0.16)) * 1.4;

    // 反射, 屏幕空间命中优先, 未命中回落到天空
    vec3 reflectDir = reflect(-viewDir, normal);
    vec3 ssr = screenSpaceReflection(viewPos, reflectDir, texcoord);
    vec3 skyReflect = renderSky(reflectDir, false) * 0.9;
    vec3 reflection = mix(skyReflect, ssr, clamp(luminance(ssr) * 2.5, 0.0, 0.7));

    float cosTheta = clamp(dot(normal, viewDir), 0.0, 1.0);
    float refl = fresnelWater(cosTheta);
    // 远处视角更平, 反射因此更强
    refl = mix(refl, clamp(refl * 1.4, 0.0, 1.0), clamp(1.0 - distance / 200.0, 0.0, 1.0));

    return mix(refrColor, reflection, clamp(refl, 0.0, 0.98))
         + waterSunGlitter(normal, viewDir, lightDir, lightColor, light.shadowSoft);
}

void main() {
    vec4 aux = texture2D(colortex4, texcoord);
    int matId = int(aux.z * 255.0 + 0.5);
    int matSlot = decodeSlot(aux.z);

    // 不透明像素直接透传
    if (matSlot != SLOT_WATER && matSlot != SLOT_GLASS) {
        gl_FragData[0] = texture2D(colortex0, texcoord);
        gl_FragData[1] = aux;
        return;
    }

    float rawDepth = texture2D(depthtex0, texcoord).r;
    vec3 viewPos = screenToViewPos(vec3(texcoord, rawDepth));
    float distance = length(viewPos);
    vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;
    vec3 viewDir = normalize(-viewPos);
    vec3 normal = decodeNormal(texture2D(colortex1, texcoord).rg);
    vec4 matData = texture2D(colortex3, texcoord);

    LightInfo light = getLightInfo();
    vec3 result;

    if (matSlot == SLOT_GLASS) {
        // 玻璃取不透明场景作为背景, 按自身颜色与厚度混合
        vec3 tint = srgbToLinear(texture2D(colortex7, texcoord).rgb);
        float opacity = clamp(1.0 - sqrt(max(abs(matData.a), 0.0)), 0.0, 1.0);
        vec3 behind = texture2D(colortex0, texcoord).rgb;
        // 玻璃自身的镜面反射
        vec3 reflectDir = reflect(-viewDir, normal);
        float refl = fresnelSchlick(clamp(dot(normal, viewDir), 0.0, 1.0), 0.05);
        vec3 reflection = renderSky(reflectDir, false) * 0.55;
        vec3 glassColor = mix(behind, behind * tint * 1.2, 0.55)
                        + reflection * refl * 1.6;
        result = mix(glassColor, behind, opacity * 0.25);
        // 让玻璃本身也有一点亮度, 免得看起来像空框
        result += tint * 0.04 * light.intensity;
    } else {
        result = shadeWater(viewPos, worldPos, viewDir, normal, matData.a, distance, light);
    }

    gl_FragData[0] = vec4(max(result, 0.0), 1.0);
    gl_FragData[1] = aux;
}
