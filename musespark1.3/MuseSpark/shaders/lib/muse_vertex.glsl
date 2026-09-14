// 植被摆动与光照坐标修正共用函数
uniform float frameTimeCounter;
// 叶与草摆动偏移
vec3 museWave(vec2 entityMark, vec3 anchor, vec2 uv) {
  float leaf = 1.0 - clamp(abs(entityMark.x - 100.0), 0.0, 1.0);
  float herb = 1.0 - clamp(abs(entityMark.x - 101.0), 0.0, 1.0);
  float kind = max(leaf, herb);
  float topW = mix(0.35, 1.0, clamp(uv.y, 0.0, 1.0));
  float sway = sin(frameTimeCounter * 1.6 + anchor.x * 0.35 + anchor.z * 0.27);
  float gust = sin(frameTimeCounter * 0.6 + anchor.x * 0.05 - anchor.z * 0.07);
  float amp = (leaf * 0.045 + herb * 0.075) * topW * (0.65 + 0.35 * gust);
  return vec3(sway * amp, sway * amp * 0.25 * herb, sway * amp * 0.7) * step(0.001, kind);
}
// 水面起伏偏移
vec3 museRipple(vec3 anchor) {
  float w = sin(frameTimeCounter * 1.2 + anchor.x * 0.5 + anchor.z * 0.4);
  return vec3(0.0, w * 0.03, 0.0);
}
// 光照贴图坐标去边距修正
vec2 museFixLm(vec2 lm) {
  return clamp((lm - 0.03125) * 1.0667, 0.0, 1.0);
}
