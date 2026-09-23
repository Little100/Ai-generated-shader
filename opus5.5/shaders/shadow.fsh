#version 330 compatibility

#define KOMOREBI_GEOMETRY

#include "/lib/util.glsl"

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 tint;
in vec3 worldNormal;
in vec3 worldPos;
in float materialId;
in vec2 lmcoord;
in vec4 shadowColor;

/* RENDERTARGETS: 0 */

void main() {
    vec4 color = texture2D(gtexture, texcoord) * tint;
    // 落叶与草叶的镂空必须保留, 否则树冠会变成实心阴影
    if (color.a < 0.1) discard;
    gl_FragData[0] = shadowColor;
}
