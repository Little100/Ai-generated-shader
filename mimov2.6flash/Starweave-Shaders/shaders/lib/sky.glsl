#ifndef SW_SKY
#define SW_SKY

// 星野: 基于方向的哈希网格, 带轻微闪烁
vec3 starField(vec3 dir, float time){
  vec3 col = vec3(0.0);
  vec3 d = dir * 90.0;
  vec3 id = floor(d);
  vec3 f = fract(d) - 0.5;
  float h = hash13(mod(id, vec3(90.0)));
  if (h > 0.982){
    vec3 off = (vec3(hash13(mod(id + 1.0, vec3(90.0))), hash13(mod(id + 2.0, vec3(90.0))), hash13(mod(id + 3.0, vec3(90.0)))) - 0.5) * 0.6;
    float star = 1.0 - saturate(length(f - off) * 9.0);
    float twinkle = 0.7 + 0.3 * sin(time * (2.0 + h * 6.0) + h * 40.0);
    vec3 tint = mix(vec3(0.7, 0.8, 1.0), vec3(1.0, 0.85, 0.7), hash13(mod(id + 7.0, vec3(90.0))));
    col += tint * star * star * twinkle * (0.6 + h);
  }
  return col;
}

// 极光带: 夜空中的飘动光幕
vec3 auroraBand(vec3 dir, float time){
  if (dir.y < 0.18) return vec3(0.0);
  float band = smoothstep(0.18, 0.4, dir.y) * (1.0 - smoothstep(0.55, 0.95, dir.y));
  float wave = sin(atan(dir.z, dir.x) * 3.0 + time * 0.35) * 0.16;
  float curtain = fbm(vec2(atan(dir.z, dir.x) * 2.5 + time * 0.22, dir.y * 6.0 + wave * 4.0));
  float mask = smoothstep(0.45, 0.85, curtain) * band;
  float hue = fbm(vec2(atan(dir.z, dir.x) * 1.5 - time * 0.1, dir.y * 3.0));
  vec3 c = mix(vec3(0.1, 1.0, 0.5), vec3(0.6, 0.2, 0.95), hue);
  c = mix(c, vec3(0.15, 0.5, 1.0), smoothstep(0.5, 0.9, dir.y));
  return c * mask * 0.85;
}

// 太阳与月亮圆盘
vec3 celestialDiscs(vec3 dir, float time){
  vec3 sunDir = sunWorldDir();
  vec3 moonDir = moonWorldDir();
  float sunDot = max(dot(dir, sunDir), 0.0);
  float moonDot = max(dot(dir, moonDir), 0.0);

  float sunUp = smoothstep(-0.12, 0.02, sunDir.y);
  float sunCore = smoothstep(0.9996, 0.99985, sunDot);
  float sunGlow = pow(sunDot, 900.0) * 4.0 + pow(sunDot, 90.0) * 0.55 + pow(sunDot, 18.0) * 0.16;
  vec3 sunC = (vec3(1.0, 0.92, 0.78) * sunCore * 36.0 + vec3(1.0, 0.7, 0.4) * sunGlow) * sunUp;

  float moonUp = smoothstep(-0.1, 0.03, moonDir.y);
  float moonCore = smoothstep(0.9997, 0.99992, moonDot);
  float moonGlow = pow(moonDot, 700.0) * 1.4 + pow(moonDot, 120.0) * 0.2;
  float ill = moonIllumination();
  vec3 moonC = (vec3(0.85, 0.9, 1.0) * moonCore * 6.0 * ill + vec3(0.5, 0.6, 0.9) * moonGlow * ill) * moonUp;
  return sunC + moonC;
}

// 云层: 云平面求交后的分形噪声, 雨天转为阴云
vec3 cloudLayer(vec3 dir, float time){
  if (dir.y < 0.015){
    return vec3(0.0);
  }
  float cloudAltitude = 160.0;
  float t = (cloudAltitude - cameraPosition.y) / dir.y;
  if (t < 0.0 || t > 4000.0) return vec3(0.0);
  vec3 hit = cameraPosition + dir * t;

  vec2 drift = vec2(time * 1.6, time * 0.7);
  float cover = fbmPeriodic((hit.xz + drift) * 0.004, 64.0);
  float detail = fbmPeriodic((hit.xz - drift * 1.4) * 0.014, 64.0);
  float density = saturate((cover * 0.72 + detail * 0.38 - 0.42) * 2.4);
  density = mix(density, saturate(density + 0.5), rainStrength);
  if (density <= 0.003) return vec3(0.0);

  float sunAmount = smoothstep(-0.05, 0.25, sunWorldDir().y);
  vec2 sunFlat = normalize(sunWorldDir().xz + vec2(0.0001));
  vec2 rayFlat = normalize(dir.xz + vec2(0.0001));
  float sideLight = 0.5 + 0.5 * dot(rayFlat, sunFlat);
  vec3 lit = mix(vec3(0.42, 0.46, 0.58), vec3(1.02, 0.99, 0.94), sideLight) * (0.25 + 0.95 * sunAmount);
  vec3 shaded = mix(lit, vec3(0.28, 0.3, 0.38) * (0.4 + 0.6 * sunAmount), density * 0.75);
  shaded = mix(shaded, vec3(0.32, 0.33, 0.36), rainStrength * 0.65);
  float edge = smoothstep(0.0, 0.35, density) * (1.0 - smoothstep(0.75, 1.0, density) * 0.25);
  return shaded * edge * 1.15;
}

#ifdef DIM_NETHER
// 下界: 暗红穹顶与飘散的火星
vec3 dimensionSky(vec3 dir, float time){
  float h = saturate(dir.y * 0.5 + 0.5);
  vec3 base = mix(vec3(0.16, 0.03, 0.015), vec3(0.03, 0.008, 0.01), h);
  float horizonGlow = pow(1.0 - abs(dir.y), 6.0);
  base += vec3(0.5, 0.12, 0.03) * horizonGlow * 0.55;

  vec3 cell = dir * 40.0 + vec3(0.0, time * 0.6, 0.0);
  vec3 id = floor(cell);
  float spark = hash13(id);
  if (spark > 0.97){
    vec3 f = fract(cell) - 0.5;
    float core = 1.0 - saturate(length(f) * 7.0);
    float pulse = 0.6 + 0.4 * sin(time * 6.0 + spark * 50.0);
    base += vec3(1.0, 0.45, 0.1) * core * core * pulse * 0.9;
  }
  return base;
}
#else
#ifdef DIM_END
// 终界: 紫色虚空与密织星尘
vec3 dimensionSky(vec3 dir, float time){
  float h = saturate(dir.y * 0.5 + 0.5);
  vec3 base = mix(vec3(0.05, 0.015, 0.07), vec3(0.01, 0.003, 0.02), h);
  float nebula = fbm(vec2(atan(dir.z, dir.x) * 2.0, dir.y * 3.0));
  base += vec3(0.16, 0.05, 0.24) * smoothstep(0.4, 0.8, nebula) * 0.5;
  base += starField(dir, time) * 1.4;
  float horizon = pow(1.0 - abs(dir.y), 8.0);
  base += vec3(0.3, 0.1, 0.45) * horizon * 0.35;
  return base;
}
#else
// 主世界: 渐变天穹, 阴阳两面配合晨昏染色
vec3 dimensionSky(vec3 dir, float time){
  vec3 sunDir = sunWorldDir();
  float upness = saturate(dir.y);
  float elevation = sunDir.y;
  float day = smoothstep(-0.1, 0.25, elevation);
  float duskiness = (1.0 - saturate(abs(elevation) / 0.35)) * smoothstep(-0.25, 0.0, elevation);

  vec3 zenithNight = vec3(0.012, 0.02, 0.06);
  vec3 zenithDay = vec3(0.18, 0.38, 0.82);
  vec3 horizonNight = vec3(0.04, 0.05, 0.11);
  vec3 horizonDay = vec3(0.62, 0.78, 0.98);

  vec3 zenith = mix(zenithNight, zenithDay, day);
  vec3 horizon = mix(horizonNight, horizonDay, day);
  vec3 grad = mix(horizon, zenith, pow(upness, 0.65));

  vec3 sunward = normalize(vec3(sunDir.x, 0.0, sunDir.z) + vec3(0.0001));
  vec3 rayward = normalize(vec3(dir.x, 0.0, dir.z) + vec3(0.0001));
  float toSun = max(dot(rayward, sunward), 0.0);
  vec3 duskWarm = mix(vec3(1.0, 0.32, 0.12), vec3(1.0, 0.6, 0.25), toSun);
  grad = mix(grad, duskWarm, duskiness * pow(1.0 - upness, 2.2) * (0.35 + 0.65 * pow(toSun, 2.0)));

  float nightness = 1.0 - day;
  grad += starField(dir, time) * nightness * (1.0 - rainStrength);
#ifdef AURORA
  grad += auroraBand(dir, time) * nightness * (1.0 - rainStrength) * 0.9;
#endif
  grad = mix(grad, vec3(0.42, 0.45, 0.5), rainStrength * 0.7);
  grad += celestialDiscs(dir, time);
  grad += cloudLayer(dir, time);
  if (dir.y < 0.0){
    grad = mix(grad, fogColor, saturate(-dir.y * 3.0));
  }
  return grad;
}
#endif
#endif

// 统一天空入口
vec3 proceduralSky(vec3 dir){
  float time = frameTimeCounter;
  return dimensionSky(normalize(dir), time);
}

#endif
