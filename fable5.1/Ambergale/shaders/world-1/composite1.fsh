#version 330 compatibility
#define DIM_NETHER

// Screen-space light shafts from the sun, rendered into the lower-left quarter of colortex5

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/space.glsl"
#include "/lib/sky.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 outColor;

void main() {
    if (texcoord.x > 0.25 || texcoord.y > 0.25) discard;
    vec2 uv = texcoord * 4.0;

    #if !defined GODRAYS || defined DIM_NETHER || defined DIM_END
    outColor = vec4(0.0);
    return;
    #else
    vec3 sunDir = sunDirWorld();
    float dayGate = dayFactor(sunDir) * (1.0 - rainStrength * 0.8);
    if (isEyeInWater != 0 || dayGate <= 0.001) { outColor = vec4(0.0); return; }

    vec4 sunClip = gbufferProjection * vec4(sunPosition, 1.0);
    if (sunClip.w <= 0.0) { outColor = vec4(0.0); return; }
    vec2 sunScreen = sunClip.xy / sunClip.w * 0.5 + 0.5;

    vec3 viewDirWorld = normalize(viewToPlayer(screenToView(vec3(uv, 1.0))));
    float facing = pow(saturate(dot(viewDirWorld, sunDir)), 3.0);
    if (facing <= 0.001) { outColor = vec4(0.0); return; }

    const int steps = 20;
    float jitter = hash12(gl_FragCoord.xy + float(frameCounter % 4) * 7.3);
    vec2 delta = (sunScreen - uv) / float(steps);
    // Limit the ray so distant sun positions do not sample far outside the screen
    float maxLen = 0.6;
    float rayLen = length(sunScreen - uv);
    if (rayLen > maxLen) delta *= maxLen / rayLen;

    float accum = 0.0;
    float weight = 1.0;
    float total = 0.0;
    vec2 p = uv + delta * jitter;
    for (int i = 0; i < steps; i++) {
        vec2 sp = saturate(p);
        float d = texture(depthtex1, sp).r;
        accum += step(1.0, d) * weight;
        total += weight;
        weight *= 0.94;
        p += delta;
    }
    float rays = accum / total;
    vec3 col = sunColor(sunDir) * rays * facing * dayGate * GODRAYS_STRENGTH * 0.18;
    outColor = vec4(col, 1.0);
    #endif
}
