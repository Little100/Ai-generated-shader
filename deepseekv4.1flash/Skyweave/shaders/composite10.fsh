#version 330 compatibility

/*
    Tone mapping and grading. Once the curve has run the image is encoded to
    sRGB, which is the point where the pipeline stops being physical light and
    starts being something to look at.
*/

#include "/lib/buffers.glsl"
#include "/lib/post.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outScene;

uniform sampler2D colortex0;

void main() {
    vec3 color = max(texture(colortex0, texcoord).rgb, vec3(0.0));
    color = toneMap(color);
    color = applyGrade(color);
    color = linearToSrgb(color);

    outScene = vec4(saturate(color), 1.0);
}
