#version 330 compatibility
// 最终输出曝光色调映射与抖动抗带状
#include "lib/muse_settings.glsl"
#include "lib/muse_common.glsl"
uniform sampler2D colortex0;
in vec2 vUv;
void main() {
  vec3 c = texture(colortex0, vUv).rgb * EXPOSURE;
  c = museAces(c);
  c = pow(c, vec3(1.0 / 2.2));
  float g = museHash(vUv * 913.7) - 0.5;
  c += g * (1.5 / 255.0);
  gl_FragColor = vec4(clamp(c, 0.0, 1.0), 1.0);
}
