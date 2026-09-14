#version 330 compatibility
// 阴影片元镂空裁剪与水面过滤
uniform sampler2D gtexture;
in vec2 vTex;
in vec4 vTint;
in vec2 vEnt;
void main() {
  if (vEnt.y > 0.5) {
    discard;
  }
  vec4 c = texture(gtexture, vTex) * vTint;
  if (c.a < 0.5) {
    discard;
  }
  gl_FragColor = vec4(1.0);
}
