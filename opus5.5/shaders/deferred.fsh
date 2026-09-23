#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0,4 */

// 屏幕空间环境遮蔽, 在法线半球内采样深度纹理
float computeSSAO(vec3 viewPos, vec3 viewNormal, float dither) {
#ifdef SSAO
    float radius = aoRadius;
    float occlusion = 0.0;
    const int RADIAL = 6;
    const int RINGS = 2;
    for (int s = 0; s < RINGS; s++) {
        float fi = float(s);
        for (int r = 0; r < RADIAL; r++) {
            float ri = float(r);
            float sampleRadius = radius * (fi + 0.4) / float(RINGS);
            float angle = dither * TAU + ri * 2.39996323 + fi * 1.7;
            vec2 offset = vec2(cos(angle), sin(angle)) * sampleRadius;
            vec4 projected = gbufferProjection * vec4(viewPos + vec3(offset, 0.0), 1.0);
            vec2 sampleUV = (projected.xy / projected.w) * 0.5 + 0.5;
            if (any(lessThan(sampleUV, vec2(0.0))) || any(greaterThan(sampleUV, vec2(1.0)))) continue;
            vec3 sampleView = screenToViewPos(vec3(sampleUV, texture2D(depthtex0, sampleUV).r));
            vec3 diff = sampleView - viewPos;
            float dist = length(diff);
            if (dist < 0.02) continue;
            // 只在同一深度层内比较, 避免前景轮廓把背景压黑
            float rangeCheck = smoothstep(0.0, 1.0, radius / max(dist, EPS));
            float dirDot = dot(diff / dist, viewNormal);
            occlusion += max(dirDot - 0.08, 0.0) * rangeCheck;
        }
    }
    float norm = float(RADIAL * RINGS) * 0.5;
    float ao = clamp(1.0 - occlusion / norm, 0.0, 1.0);
    return mix(1.0, ao, clamp(aoStrength, 0.0, 2.0));
#else
    return 1.0;
#endif
}

// 天空可见度, 由朝向与天光等级推测, 远处直接按全开处理
float estimateSkyOcclusion(vec3 worldNormal, float lightmapY, float depth) {
    float up = clamp(worldNormal.y * 0.5 + 0.5, 0.0, 1.0);
    float open = mix(0.34, 1.0, up);
    float near = smoothstep(0.99985, 0.99999, depth);
    return mix(open * clamp(lightmapY * 1.2, 0.0, 1.0), 1.0, near);
}

void main() {
    float rawDepth = texture2D(depthtex0, texcoord).r;
    vec3 worldDir = normalize(viewToWorldDir(screenToViewPos(vec3(texcoord, 1.0))));
    float dither = ign(gl_FragCoord.xy, frameCounter);

    LightInfo light = getLightInfo();
    vec3 lightDir = light.direction;

    // 天空像素直接出结果, 云的步进交给后续的后处理
    if (rawDepth >= 1.0) {
        vec3 skyColor = renderSky(worldDir, true) + renderCelestial(worldDir);
        gl_FragData[0] = vec4(skyColor, 1.0);
        // 第三通道标记天空像素, 第二通道给满遮蔽因为天空没有遮挡
        gl_FragData[1] = vec4(1.0, 1.0, 0.0, 0.0);
        return;
    }

    vec3 viewPos = screenToViewPos(vec3(texcoord, rawDepth));
    vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;
    float distance = length(viewPos);
    vec3 viewDir = normalize(-viewPos);

    vec2 uv = texcoord;
    vec4 normalData = texture2D(colortex1, uv);
    vec3 normal = decodeNormal(normalData.rg);
    float aoBias = normalData.b;
    int matId = int(normalData.a * 255.0 + 0.5);

    vec4 lightData = texture2D(colortex2, uv);
    float blockLight = lightData.r;
    float skyLight = lightData.g;
    float emissiveMask = lightData.b;

    vec4 matData = texture2D(colortex3, uv);
    float roughness = matData.r;
    float metalness = matData.g;
    float leafPass = matData.a;

    vec3 albedo = texture2D(colortex7, uv).rgb;

    // 遮蔽在视角空间计算, 因此法线也要转回视角空间
    // 遮蔽偏置让树叶与玻璃这类薄面片少受自遮蔽影响
    float ao = computeSSAO(viewPos, worldToViewDir(normal), dither);
    ao = mix(ao, 1.0, clamp(aoBias, 0.0, 1.0));
    float skyOcclusion = estimateSkyOcclusion(normal, skyLight, rawDepth);

    // 直射光可见度, 云影与树叶光斑依次削减
    float shadow = sampleShadow(worldPos, normal, lightDir, light.shadowSoft, ign(gl_FragCoord.xy, frameCounter));
#ifdef CLOUD_SHADOW
    shadow *= mix(1.0, cloudShadowAmount(worldPos), clamp(light.shadowSoft * 0.4 + 0.6, 0.0, 1.0));
#endif
    // 远处阴影平滑退出, 避免出现生硬边界
    shadow = mix(1.0, shadow, shadowDistanceFade(distance));
    float dapple = dappleMask(worldPos, normal, dappleDepth * shadowSoftness);
    // 光斑是被树冠挡住之后漏下来的亮斑, 只有遮挡处才生效
    shadow = mix(shadow, shadow * (0.35 + 0.65 * dapple), 1.0 - shadow);

    float ndl = clamp(dot(normal, lightDir), 0.0, 1.0);
    // 一点点环绕光, 让明暗交界不至于断裂
    float wrapped = clamp((dot(normal, lightDir) + 0.32) / 1.32, 0.0, 1.0);
    float diffuseTerm = mix(wrapped, ndl, 0.72);

    vec3 lightColor = light.color;
    vec3 direct = lightColor * diffuseTerm * shadow * ao;

    // 彩色阴影, 半透明遮挡物把自身颜色透过来
    vec4 shadowTint = sampleShadowColor(worldPos);
    float shadowAmount = clamp(1.0 - shadow, 0.0, 1.0);
    if (shadowAmount > 0.01 && shadowTint.a < 0.985) {
        vec3 bleed = lightColor * shadowTint.rgb * diffuseTerm * (1.0 - shadowTint.a) * 0.5;
        direct += bleed * shadowAmount;
    }

    vec3 ambient = skyAmbient(normal, skyOcclusion, skyLight, blockLight);
    vec3 blockLightColor = blockLightColor(blockLight, worldPos);
    vec3 emission = albedo * emissiveMask * 3.4;

    // 树叶透光与皮肤次表面
    vec3 scatter = translucentScatter(normal, lightDir, lightColor, leafPass * 0.9);
    if (matId == SLOT_ENTITY) scatter += translucentScatter(normal, lightDir, lightColor, 0.22);

    // 高光, 金属用反照率做反射色
    vec3 specColor = mix(vec3(0.04), albedo, metalness);
    float gloss = max(mix(roughness, roughness * 0.55, wetness * wetHighlight), 0.02);
    vec3 spec = sunSpecular(normal, viewDir, lightDir, lightColor, gloss, shadow * ao, 0.55);
    // 环境高光, 用天空色近似镜面反射
    vec3 reflectDir = reflect(-viewDir, normal);
    vec3 envColor = skyGradient(reflectDir) * 0.5;
    float envFresnel = fresnelSchlick(clamp(dot(normal, viewDir), 0.0, 1.0), max(specColor.r, 0.04));
    vec3 envSpec = envColor * envFresnel * mix(1.0, 2.2, metalness) * (1.0 - gloss) * ao;

    vec3 rim = rimHighlight(normal, viewDir, lightDir, lightColor, 1.0 - roughness);

    vec3 lit = albedo * (direct + ambient + blockLightColor) + emission + scatter + spec + envSpec + rim;

    gl_FragData[0] = vec4(max(lit, 0.0), 1.0);
    gl_FragData[1] = vec4(skyLight, skyOcclusion, float(matId) / 255.0, leafPass);
}
