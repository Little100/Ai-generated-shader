#version 330 compatibility
// 天空基础片元输出雾蓝色便于延迟阶段重建天空
uniform vec3 fogColor;
in vec3 vDir;
layout(location = 0) out vec4 oAlbedo;
layout(location = 1) out vec4 oData;
layout(location = 2) out vec4 oNormal;
/* RENDERTARGETS: 0,1,2 */
void main() {
  vec3 d = normalize(vDir);
  if (d.y < -0.02) {
    discard;
  }
  oAlbedo = vec4(fogColor, 1.0);
  oData = vec4(vec2(1.0, 0.0), 0.0, 7.0 / 9.0 + 0.001);
  oNormal = vec4(0.5, 0.5, 1.0, 1.0);
}
