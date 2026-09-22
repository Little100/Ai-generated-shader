#version 120
/* RENDERTARGETS: 0 */
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/post.glsl"
#include "/lib/space.glsl"

uniform sampler2D colortex7;

varying vec2 texcoord;

void main() {
    vec3 current = texture2D(colortex0, texcoord).rgb;
    #if K_TA == 0
        gl_FragData[0] = vec4(current, 1.0);
        return;
    #endif
    float depth = texture2D(depthtex0, texcoord).r;
    vec3 currentView = viewFromScreen(texcoord, depth);
    vec3 player = playerFromView(currentView);
    vec2 prevUv = previousScreen(player);
    vec2 delta = texcoord - prevUv;
    float move = length(delta * vec2(viewWidth, viewHeight));
    bool valid = prevUv.x > 0.0 && prevUv.x < 1.0 && prevUv.y > 0.0 && prevUv.y < 1.0 && move < 24.0;
    vec3 history = texture2D(colortex7, prevUv).rgb;
    float blend = valid ? 0.12 : 1.0;
    vec3 outc = mix(history, current, blend);
    gl_FragData[0] = vec4(outc, 1.0);
}
