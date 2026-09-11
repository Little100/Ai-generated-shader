#version 330 compatibility

/*
    Depth of field. The circle of confusion comes straight from the depth
    buffer, so everything away from the focal plane softens while the subject
    stays sharp. The pass is disabled outright in shaders.properties when the
    option is off, so it costs nothing then.
*/

#include "/lib/buffers.glsl"
#include "/lib/post.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outScene;

uniform sampler2D colortex0;

// the view space distance along the view axis, which is what a circle of
// confusion actually depends on
float viewDepthAt(vec2 uv) {
    float depth = texture(depthtex0, uv).r;
    if (depth >= 1.0) {
        return 1e6;
    }
    return -screenToView(uv, depth, gbufferProjectionInverse).z;
}

void main() {
#ifdef DEPTH_OF_FIELD
    vec3 center = texture(colortex0, texcoord).rgb;

    float centerLinear = viewDepthAt(texcoord);
    if (centerLinear > 1e5) {
        outScene = vec4(center, 1.0);
        return;
    }

    // focus rides the centre of the frame, which keeps the usual minecraft
    // framing sharp unless the player is clearly looking at something close
    float focusDistance = clamp(centerLinear * 0.85, 3.0, 48.0);
    float coc = abs(centerLinear - focusDistance) / max(focusDistance, 1.0);
    coc = saturate(coc - 0.12) * DOF_STRENGTH * 3.0;

    if (coc <= 0.001) {
        outScene = vec4(center, 1.0);
        return;
    }

    float radius = coc * 14.0;
    vec3 accumulated = center;
    float weightSum = 1.0;

    const int taps = 12;
    for (int i = 0; i < taps; i++) {
        vec2 offset = discSample(i, taps) * radius / vec2(viewWidth, viewHeight);
        vec2 sampleUV = clamp(texcoord + offset, vec2(0.001), vec2(0.999));
        float sampleLinear = viewDepthAt(sampleUV);

        // near geometry bleeds outward and far geometry does not, which stops
        // a sharp foreground from dissolving into the background
        float weight = (sampleLinear < centerLinear || sampleLinear > 1e5) ? 0.35 : 1.0;
        accumulated += texture(colortex0, sampleUV).rgb * weight;
        weightSum += weight;
    }

    outScene = vec4(accumulated / weightSum, 1.0);
#else
    outScene = vec4(texture(colortex0, texcoord).rgb, 1.0);
#endif
}
