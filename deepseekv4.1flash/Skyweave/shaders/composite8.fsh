#version 330 compatibility

/*
    Puts the frame together. Bloom and light shafts are added over the scene and
    the measured exposure is folded in here, so everything downstream works in
    display referred units.
*/

#include "/lib/buffers.glsl"
#include "/lib/post.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outScene;

uniform sampler2D colortex0;
uniform sampler2D colortex6;
uniform sampler2D colortex8;
uniform sampler2D colortex9;

void main() {
    vec3 color = texture(colortex0, texcoord).rgb;
    vec3 bloom = texture(colortex6, texcoord).rgb;
    vec3 shafts = texture(colortex8, texcoord).rgb;

    if (texture(depthtex1, texcoord).r < 1.0) {
        color += bloom * BLOOM_STRENGTH + shafts;
    } else {
        // the sky still catches the shafts and a share of the glow, just less
        color += bloom * BLOOM_STRENGTH * 0.6 + shafts * 0.35;
    }

    float exposure = texture(colortex9, vec2(0.5)).r;
    outScene = vec4(color * exposure * EXPOSURE, 1.0);
}
