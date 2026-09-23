#ifndef KOMOREBI_CLOUDS
#define KOMOREBI_CLOUDS

#include "/lib/sky.glsl"

// 体积云, 光线步进加上前方遮蔽估计

// 云在缓冲里的编码, rgb 为散射色, a 为不透明度
const vec3 CLOUD_EXTINCTION = vec3(0.86, 0.88, 0.94);

#if cloudSteps == 12
#define CLOUD_LOOP 12
#elif cloudSteps == 18
#define CLOUD_LOOP 18
#elif cloudSteps == 36
#define CLOUD_LOOP 36
#elif cloudSteps == 56
#define CLOUD_LOOP 56
#else
#define CLOUD_LOOP 24
// 沿光线前方取几个点估计遮蔽, 近似自投影
float cloudLightMarch(vec3 pos, vec3 lightDir, float lod) {
    float density = 0.0;
    float stepLen = cloudThickness * 0.22;
    float weight = 1.0;
    for (int i = 0; i < 5; i++) {
        pos += lightDir * stepLen;
        stepLen *= 1.42;
        density += cloudDensity(pos, cloudCoverage, cloudThickness, lod) * weight;
        weight *= 0.72;
    }
    return density;
}

// 体积云主体, 在天空方向上前进, 返回预乘颜色
vec4 marchClouds(vec3 rayOrigin, vec3 rayDir, float maxDistance, float lod, float jitter) {
    float top = cloudAltitude + cloudThickness;
    float bottom = cloudAltitude - cloudThickness * 0.25;

    // 求与云层的两个交点, 层在相机下方时直接跳过
    float t0, t1;
    if (abs(rayDir.y) < 1e-4) {
        if (rayOrigin.y < bottom || rayOrigin.y > top) return vec4(0.0);
        t0 = 0.0;
        t1 = maxDistance;
    } else {
        float ta = (bottom - rayOrigin.y) / rayDir.y;
        float tb = (top - rayOrigin.y) / rayDir.y;
        t0 = max(min(ta, tb), 0.0);
        t1 = min(max(ta, tb), maxDistance);
    }
    if (t1 <= t0) return vec4(0.0);

    float dt = (t1 - t0) / float(CLOUD_LOOP);
    float t = t0 + dt * jitter;

    vec3 lightDir = normalize(sunPosition);
    vec3 sunCol = sunLightColor() * SUN_LUMINANCE * 0.15;
    vec3 ambientCol = (skyZenithColor() + skyHorizonColor()) * 0.5;
    // 月亮在夜间同样照亮云底
    ambientCol = mix(ambientCol, moonLightColor() * 0.35, nightFactor() * 0.7);

    vec3 scatter = vec3(0.0);
    float transmittance = 1.0;

    for (int i = 0; i < CLOUD_LOOP; i++) {
        vec3 pos = rayOrigin + rayDir * t;
        float density = cloudDensity(pos, cloudCoverage, cloudThickness, lod);
        if (density > 0.002) {
            float lightTransmit = exp(-cloudLightMarch(pos, lightDir, lod * 0.5) * 1.6);
            // 粉末效应, 云团朝向观察者的边缘更亮
            float powder = 1.0 - exp(-density * 7.0);
            float sunAmount = lightTransmit * mix(1.0, powder, 0.65);
            float phase = 0.6 + 0.4 * pow(max(dot(rayDir, lightDir), 0.0), 8.0);
            vec3 lit = sunCol * sunAmount * phase + ambientCol * 0.55;
            float stepExtinction = exp(-density * dt * 0.016);
            scatter += lit * density * (1.0 - stepExtinction) * transmittance * 5.0;
            transmittance *= stepExtinction;
            if (transmittance < 0.02) break;
        }
        t += dt;
        if (t > t1) break;
    }

    return vec4(scatter * CLOUD_EXTINCTION, clamp(1.0 - transmittance, 0.0, 1.0));
}

#endif

#endif
