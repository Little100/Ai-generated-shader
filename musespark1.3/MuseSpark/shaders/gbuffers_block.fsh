#version 330 compatibility
// 方块实体片元打包
uniform sampler2D gtexture;
in vec2 vTex;
in vec2 vLm;
in vec4 vTint;
in vec3 vNrm;
layout(location = 0) out vec4 oAlbedo;
layout(location = 1) out vec4 oData;
layout(location = 2) out vec4 oNormal;
/* RENDERTARGETS: 0,1,2 */
void main() {
  vec4 c = texture(gtexture, vTex) * vTint;
  if (c.a < 0.08) {
    discard;
  }
  oAlbedo = vec4(c.rgb, c.a);
  oData = vec4(vLm, 0.0, 5.0 / 9.0 + 0.001);
  oNormal = vec4(normalize(vNrm) * 0.5 + 0.5, 1.0);
}
