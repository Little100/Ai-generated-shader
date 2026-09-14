// 光照与天空共用函数
// 昼夜太阳色
vec3 museSunTint(float sunH) {
  float d = clamp(sunH, -0.2, 1.0);
  vec3 low = vec3(1.0, 0.45, 0.22);
  vec3 mid = vec3(1.0, 0.85, 0.68);
  vec3 high = vec3(1.0, 0.97, 0.92);
  vec3 c = mix(low, mid, clamp(d * 2.2 + 0.35, 0.0, 1.0));
  c = mix(c, high, clamp(d * 1.4, 0.0, 1.0));
  return c;
}
// 天空渐变
vec3 museSkyGrad(vec3 dir, vec3 sunDir, vec3 moonDir, float dayF, float rainF) {
  float h = clamp(dir.y, -1.0, 1.0);
  vec3 dayTop = vec3(0.28, 0.52, 0.86);
  vec3 dayHor = vec3(0.72, 0.83, 0.92);
  vec3 setHor = vec3(0.98, 0.55, 0.38);
  vec3 nightTop = vec3(0.015, 0.03, 0.07);
  vec3 nightHor = vec3(0.06, 0.10, 0.16);
  float up = pow(clamp(h, 0.0, 1.0), 0.6);
  vec3 day = mix(dayHor, dayTop, up);
  vec3 night = mix(nightHor, nightTop, up);
  vec3 sky = mix(night, day, dayF);
  float sunAmt = max(dot(dir, sunDir), 0.0);
  float setBand = pow(1.0 - abs(h), 3.0) * (1.0 - abs(dayF - 0.5) * 2.0);
  setBand = clamp(setBand, 0.0, 1.0);
  sky = mix(sky, setHor, setBand * 0.45 * dayF);
  sky += vec3(1.0, 0.75, 0.5) * pow(sunAmt, 24.0) * 0.55 * dayF;
  sky += vec3(1.0, 0.9, 0.75) * pow(sunAmt, 350.0) * 2.2 * dayF;
  float moonAmt = max(dot(dir, moonDir), 0.0);
  sky += vec3(0.75, 0.85, 1.0) * pow(moonAmt, 800.0) * 1.6 * (1.0 - dayF);
  sky += vec3(0.45, 0.58, 0.85) * pow(moonAmt, 24.0) * 0.16 * (1.0 - dayF);
  sky = mix(sky, vec3(0.45, 0.5, 0.55) * (0.35 + 0.65 * dayF), rainF * 0.7);
  return sky;
}
// 星空闪烁
float museStars(vec3 dir, float nightF, vec2 seed) {
  if (dir.y < 0.02) {
    return 0.0;
  }
  vec2 sp = dir.xz / max(dir.y, 0.08) * 42.0 + seed;
  vec2 cell = floor(sp);
  vec2 pos = fract(sp) - 0.5;
  float h = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
  float star = smoothstep(0.08, 0.0, length(pos)) * step(0.92, h);
  float tw = 0.6 + 0.4 * sin(seed.x * 3.0 + h * 40.0);
  return star * tw * nightF * smoothstep(0.02, 0.25, dir.y);
}
// 高度雾混合因子
float museMistF(vec3 playerPos, float worldY, float amount) {
  float dist = length(playerPos);
  float hF = exp(-abs(worldY - MIST_CENTER) * MIST_FALLOFF);
  float dF = 1.0 - exp(-dist * 0.012 * (0.4 + amount));
  return clamp(dF * (0.35 + 0.65 * hF) * amount + dF * 0.25, 0.0, 1.0);
}
// 水面焦散亮斑
float museCaustic(vec3 wpos, float t) {
  float a = museFbm(wpos.xz * 0.55 + vec2(t * 0.25, t * 0.18));
  float b = museFbm(wpos.xz * 0.75 - vec2(t * 0.21, t * 0.26));
  float v = abs(a - b) * 2.0;
  v = pow(clamp(1.0 - v * 1.6, 0.0, 1.0), 3.0);
  return v;
}
