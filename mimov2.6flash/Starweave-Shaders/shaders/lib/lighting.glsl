#ifndef SW_LIGHTING
#define SW_LIGHTING

uniform vec4 lightningBoltPosition;

// 方块光暖色斜坡: 深橙到琥珀再到暖白
vec3 blockRamp(float b){
  b = saturate(b);
  vec3 c = mix(vec3(0.015, 0.004, 0.001), vec3(1.0, 0.42, 0.1), smoothstep(0.0, 0.4, b));
  c = mix(c, vec3(1.0, 0.72, 0.38), smoothstep(0.4, 0.75, b));
  c = mix(c, vec3(1.0, 0.93, 0.82), smoothstep(0.75, 1.0, b));
  return c * (0.15 + 1.85 * b * b);
}

// 把光照图原始坐标换算为 0 到 1 的光等级
vec2 lightLevels(vec2 lmRaw){
  return clamp(lmRaw / (30.0 / 32.0) - vec2(1.0 / 32.0), 0.0, 1.0);
}

// 世界空间太阳方向
vec3 sunWorldDir(){
  return normalize(mat3(gbufferModelViewInverse) * sunPosition);
}

vec3 moonWorldDir(){
  return normalize(mat3(gbufferModelViewInverse) * moonPosition);
}

vec3 shadowLightWorldDir(){
  return normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
}

// 月相亮度, 满月最亮
float moonIllumination(){
  float phase = cos(SW_TAU * float(moonPhase) / 8.0);
  return 0.3 + 0.7 * (phase * 0.5 + 0.5);
}

// 昼夜环境光色: 白昼偏暖白, 黄昏橙红, 夜晚深蓝
vec3 ambientSkyColor(){
  vec3 sunDir = sunWorldDir();
  float elevation = sunDir.y;
  float day = smoothstep(-0.06, 0.22, elevation);
  float horizon = 1.0 - saturate(abs(elevation) / 0.3);
  float duskness = horizon * smoothstep(-0.22, 0.02, elevation);

  vec3 nightC = vec3(0.045, 0.065, 0.16);
  vec3 dayC = vec3(0.38, 0.52, 0.86) * 0.45 + skyColor * 0.2;
  vec3 duskC = vec3(1.0, 0.42, 0.2) * 0.22;

  vec3 c = mix(nightC, dayC, day);
  c = mix(c, duskC, duskness * 0.75);
  c *= 1.0 - 0.55 * rainStrength;
  return c;
}

// 直射光颜色: 白昼太阳暖白, 夜晚月光冷蓝
vec3 directLightColor(){
  vec3 lightDir = shadowLightWorldDir();
  vec3 sunDir = sunWorldDir();
  float isSun = step(0.0, dot(lightDir, sunDir));
  float sunUp = smoothstep(-0.04, 0.14, sunDir.y);
  float moonUp = smoothstep(-0.04, 0.1, moonWorldDir().y);

  vec3 sunC = vec3(1.0, 0.93, 0.8) * 3.4 * sunUp;
  vec3 moonC = vec3(0.4, 0.5, 0.85) * 0.38 * moonUp * moonIllumination();
  vec3 c = mix(moonC, sunC, isSun);
  c *= 1.0 - 0.6 * rainStrength;
  return c;
}

// 简易 GGX 高光
vec3 ggxSpecular(vec3 N, vec3 V, vec3 L, vec3 radiance, float rough, vec3 F0){
  float a = max(rough * rough, 0.002);
  vec3 H = normalize(V + L);
  float NdotH = max(dot(N, H), 0.0);
  float NdotL = max(dot(N, L), 0.0);
  float NdotV = max(dot(N, V), 0.0);
  float d = a * a / (SW_PI * pow(NdotH * NdotH * (a * a - 1.0) + 1.0, 2.0));
  float k = a * 0.5;
  float gv = NdotV / (NdotV * (1.0 - k) + k);
  float gl = NdotL / (NdotL * (1.0 - k) + k);
  vec3 F = F0 + (1.0 - F0) * pow(1.0 - max(dot(H, V), 0.0), 5.0);
  return d * gv * gl * F * radiance * NdotL / max(SW_PI, 0.001);
}

// 自发光与半球环境光合成的基础光照(半透明物体自发光路径)
vec3 selfLight(vec3 albedo, vec2 lmRaw, float ao, vec3 worldN){
  vec2 lm = lightLevels(lmRaw);
  vec3 block = blockRamp(lm.x);
  vec3 sky = ambientSkyColor() * (0.25 + 0.9 * lm.y);
  float hemi = 0.6 + 0.4 * (worldN.y * 0.5 + 0.5);
  vec3 color = albedo * (block + sky * hemi) * mix(1.0, ao, 0.75);
  color += albedo * directLightColor() * max(dot(worldN, shadowLightWorldDir()), 0.0) * lm.y * 0.25;
  return color;
}

// 距离雾量
float fogAmount(float distance, float density){
  return 1.0 - exp(-distance * density);
}

vec3 applyFog(vec3 color, float distance, vec3 target, float density){
  return mix(color, target, saturate(fogAmount(distance, density)));
}

// 闪电的瞬间环境补光
vec3 lightningLight(vec3 worldN){
  if (thunderStrength <= 0.001) return vec3(0.0);
  float flick = 0.35 + 0.65 * step(0.55, hash12(vec2(float(frameCounter), 7.3)));
  flick *= 0.5 + 0.5 * hash12(vec2(float(frameCounter), 2.1));
  vec3 dir = normalize(mat3(gbufferModelViewInverse) * normalize(lightningBoltPosition.xyz + vec3(0.0001)));
  float facing = 0.35 + 0.65 * max(dot(worldN, dir), 0.0);
  return vec3(0.75, 0.82, 1.0) * (flick * 1.6 + 0.2) * thunderStrength * facing;
}

#endif
