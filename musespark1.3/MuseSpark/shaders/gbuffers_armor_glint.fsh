#version 330 compatibility
// 附魔辉光标记自发光避免被压暗
uniform sampler2D gtexture;
in vec2 vTex;
layout(location = 0) out vec4 oAlbedo;
layout(location = 1) out vec4 oData;
layout(location = 2) out vec4 oNormal;
/* RENDERTARGETS: 0,1,2 */
void main() {
  vec4 c = texture(gtexture, vTex);
  if (c.a < 0.02) {
    discard;
  }
  oAlbedo = vec4(c.rgb * 1.4, c.a);
  oData = vec4(vec2(1.0, 1.0), 0.7, 3.0 / 9.0 + 0.001);
  oNormal = vec4(0.5, 0.5, 1.0, 1.0);
}
