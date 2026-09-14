#version 330 compatibility
// 描边线条直接输出
in vec4 vTint;
layout(location = 0) out vec4 oAlbedo;
layout(location = 1) out vec4 oData;
layout(location = 2) out vec4 oNormal;
/* RENDERTARGETS: 0,1,2 */
void main() {
  oAlbedo = vec4(vTint.rgb, vTint.a);
  oData = vec4(vec2(1.0, 0.0), 0.0, 6.0 / 9.0 + 0.001);
  oNormal = vec4(0.5, 0.5, 1.0, 1.0);
}
