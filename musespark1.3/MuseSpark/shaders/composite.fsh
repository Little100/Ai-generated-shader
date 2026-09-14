#version 330 compatibility
// 合成阶段做棱镜色散辉光暗角
#include "lib/muse_settings.glsl"
#include "lib/muse_common.glsl"
uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;
in vec2 vUv;
layout(location = 0) out vec4 oOut;
/* RENDERTARGETS: 0 */
void main() {
  vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight);
  vec2 toC = vUv - 0.5;
  float r2 = dot(toC, toC);
  float spread = (0.0015 + r2 * 0.012) * PRISM_AMOUNT;
  vec2 dir = toC / max(length(toC), 0.0001);
  vec3 c;
  c.r = texture(colortex0, vUv + dir * spread).r;
  c.g = texture(colortex0, vUv).g;
  c.b = texture(colortex0, vUv - dir * spread).b;
  vec3 acc = vec3(0.0);
  float wsum = 0.0;
  for (int ix = -2; ix <= 2; ix++) {
    for (int iy = -2; iy <= 2; iy++) {
      vec2 o = vec2(float(ix), float(iy)) * px * 1.6;
      float w = 1.0 / (1.0 + float(ix * ix + iy * iy));
      vec3 s = texture(colortex0, vUv + o).rgb;
      float l = museLuma(s);
      acc += s * smoothstep(0.75, 1.6, l) * w;
      wsum += w;
    }
  }
  vec3 bloom = acc / max(wsum, 0.001);
  float vig = 1.0 - r2 * 0.55;
  vec3 col = (c + bloom * 0.45 * (0.4 + 0.6 * PRISM_AMOUNT)) * vig;
  oOut = vec4(col, 1.0);
}
