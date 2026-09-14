#version 330 compatibility
// 地形片元打包反照率与材质标记
#include "lib/muse_settings.glsl"
#include "lib/muse_common.glsl"
uniform sampler2D gtexture;
in vec2 vTex;
in vec2 vLm;
in vec4 vTint;
in vec3 vNrm;
in vec2 vEnt;
layout(location = 0) out vec4 oAlbedo;
layout(location = 1) out vec4 oData;
layout(location = 2) out vec4 oNormal;
/* RENDERTARGETS: 0,1,2 */
void main() {
  vec4 c = texture(gtexture, vTex) * vTint;
  float leaf = 1.0 - clamp(abs(vEnt.x - 100.0), 0.0, 1.0);
  float herb = 1.0 - clamp(abs(vEnt.x - 101.0), 0.0, 1.0);
  float glow = 1.0 - clamp(abs(vEnt.x - 102.0), 0.0, 1.0);
  float cut = mix(0.1, CUTOUT_REF, max(leaf, herb));
  if (c.a < cut) {
    discard;
  }
  float flag = mix(0.0, 1.0, step(0.5, leaf));
  flag = mix(flag, 2.0, step(0.5, herb));
  flag = mix(flag, 3.0, step(0.5, glow));
  float emi = glow * clamp(museLuma(c.rgb) * 1.4 + 0.35, 0.0, 1.0);
  oAlbedo = vec4(c.rgb, c.a);
  oData = vec4(vLm, emi, flag / 9.0 + 0.001);
  oNormal = vec4(normalize(vNrm) * 0.5 + 0.5, 1.0);
}
