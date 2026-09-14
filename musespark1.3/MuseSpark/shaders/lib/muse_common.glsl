// 通用噪声与色调函数库
float museHash(vec2 p) {
  vec3 q = fract(vec3(p.xyx) * 0.1031);
  q += dot(q, q.yzx + 33.33);
  return fract((q.x + q.y) * q.z);
}
// 值噪声
float museNoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = museHash(i);
  float b = museHash(i + vec2(1.0, 0.0));
  float c = museHash(i + vec2(0.0, 1.0));
  float d = museHash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
// 双层分形噪声
float museFbm(vec2 p) {
  float v = 0.0;
  float w = 0.5;
  for (int i = 0; i < 3; i++) {
    v += w * museNoise(p);
    p = p * 2.03 + 17.7;
    w *= 0.5;
  }
  return v;
}
// ACES 近似色调映射
vec3 museAces(vec3 x) {
  return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}
// 亮度
float museLuma(vec3 c) {
  return dot(c, vec3(0.299, 0.587, 0.114));
}
