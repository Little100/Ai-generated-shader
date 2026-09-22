#ifndef SW_WAVE
#define SW_WAVE

// 依方块类别返回摆动幅度, 10100 段为分类摇曳区
float waveAmplitude(float entityId){
  if (entityId == 10100) return 0.035;
  if (entityId == 10101) return 0.06;
  if (entityId == 10102) return 0.018;
  if (entityId == 10103) return 0.03;
  if (entityId == 10104) return 0.028;
  return 0.0;
}

// 地形顶点的风场位移, 距离越远摆动越弱
vec3 terrainWave(float entityId, vec3 absWorld, float time){
  float amp = waveAmplitude(entityId);
  if (amp <= 0.0) return vec3(0.0);
  float dist = length(absWorld - cameraPosition);
  amp *= 1.0 - saturate((dist - 56.0) / 48.0);
  if (amp <= 0.0005) return vec3(0.0);

  vec2 cell = absWorld.xz * 0.15;
  float gust = vnoise(cell * 0.35 + vec2(time * 0.35, time * 0.22));
  float swayX = sin(absWorld.x * 0.9 + time * 2.1 + gust * 4.0);
  float swayZ = cos(absWorld.z * 0.8 - time * 1.7 + gust * 3.0);
  float flutter = sin(time * 5.0 + absWorld.x * 2.0 + absWorld.z * 2.0);

  if (entityId == 10102){
    return vec3(swayX, flutter * 0.35, swayZ) * amp * (0.5 + gust);
  }
  float topWeight = 1.0;
  return vec3(swayX, -0.15 * abs(swayX), swayZ * 0.7) * amp * topWeight * (0.4 + gust);
}

// 水面高度场
float waterHeight(vec3 absWorld, float time){
  float h = 0.0;
  h += sin(absWorld.x * 0.19 + time * 1.15) * 0.04;
  h += sin(absWorld.z * 0.24 - time * 1.4) * 0.032;
  h += sin((absWorld.x * 0.7 + absWorld.z * 0.55) + time * 2.3) * 0.016;
  h += (vnoise(absWorld.xz * 0.35 + vec2(time * 0.4, -time * 0.3)) - 0.5) * 0.03;
  return h;
}

// 水面法线扰动(有限差分)
vec3 waterNormal(vec3 absWorld, float time, float distance){
  float fade = 1.0 - saturate((distance - 48.0) / 96.0);
  if (fade <= 0.001) return vec3(0.0, 1.0, 0.0);
  float e = 0.06;
  float h0 = waterHeight(absWorld, time);
  float hx = waterHeight(absWorld + vec3(e, 0.0, 0.0), time);
  float hz = waterHeight(absWorld + vec3(0.0, 0.0, e), time);
  vec3 n = normalize(vec3(-(hx - h0) * fade / e, 1.0, -(hz - h0) * fade / e));
  return n;
}

#endif
