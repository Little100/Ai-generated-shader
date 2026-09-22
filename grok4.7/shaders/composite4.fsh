#version 120
/* RENDERTARGETS: 4 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/post.glsl"

varying vec2 texcoord;

void main() {
    vec3 acc = vec3(0.0);
    float w = 0.0;
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    for (int y = -4; y <= 4; y++) {
        for (int x = -4; x <= 4; x++) {
            vec2 o = vec2(float(x), float(y));
            float d = dot(o, o);
            float weight = exp(-d * 0.18);
            acc += texture2D(colortex4, texcoord + o * texel * 3.0).rgb * weight;
            w += weight;
        }
    }
    gl_FragData[0] = vec4(acc / max(w, 0.001), 1.0);
}
