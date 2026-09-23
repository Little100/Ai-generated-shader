#version 330 compatibility

#define KOMOREBI_GEOMETRY

#include "/lib/common.glsl"

in vec2 texcoord;
in vec4 tint;
in vec3 worldNormal;
in vec3 worldPos;
in float slot;

/* RENDERTARGETS: 0 */

void main() {
    vec4 color = texture2D(gtexture, texcoord) * tint;
    // 树叶与草的镂空必须保留, 否则树冠会变成实心阴影
    if (color.a < 0.1) discard;
    // 彩色阴影, 玻璃把自身颜色透到地面上, 树叶偏绿
    vec3 tintColor = vec3(1.0);
    float occlusiveness = 1.0;
    if (slot == SLOT_GLASS) {
        tintColor = srgbToLinear(color.rgb) + 0.08;
        occlusiveness = 0.35;
    } else if (slot == SLOT_FOLIAGE || slot == SLOT_PLANT) {
        tintColor = vec3(0.72, 1.0, 0.62);
        occlusiveness = 0.62;
    } else if (slot == SLOT_WATER) {
        tintColor = vec3(0.55, 0.82, 0.92);
        occlusiveness = 0.25;
    }
    gl_FragData[0] = vec4(tintColor, occlusiveness);
}
