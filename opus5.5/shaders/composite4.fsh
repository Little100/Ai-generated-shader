#version 330 compatibility

#include "/lib/util.glsl"
#include "/lib/lighting.glsl"
#include "/lib/clouds.glsl"

uniform sampler2D depthtex0;

in vec2 texcoord;

/* RENDERTARGETS: 0,4 */

void main() {
    vec4 scene = texture2D(colortex0, texcoord);
    vec4 aux = texture2D(colortex4, texcoord);
    vec4 clouds = texture2D(colortex5, texcoord);

    // 仅天空像素接受云的合成, 地形保持原样
    if (aux.g > 0.5 && clouds.a > 0.001) {
        scene.rgb = mix(scene.rgb, clouds.rgb / max(clouds.a, EPS), clouds.a);
    }

    gl_FragData[0] = scene;
    gl_FragData[1] = aux;
}
