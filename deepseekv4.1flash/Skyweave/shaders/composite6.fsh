#version 330 compatibility

/*
    Exposure measurement. The destination is a single texel, so this runs one
    fragment. The samples come from a fixed grid, which means the result does
    not depend on which fragment happens to execute.
*/

#include "/lib/buffers.glsl"
#include "/lib/post.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 outExposure;

uniform sampler2D colortex0;
uniform sampler2D colortex10;

void main() {
#ifdef AUTO_EXPOSURE
    // the buffer is only written from the second frame on, so whatever the
    // driver left there is clamped into the range the measurement can produce
    float previous = clamp(texture(colortex10, vec2(0.5)).r, 0.05, 12.0);

    float sum = 0.0;
    float count = 0.0;

    for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
            vec2 sampleUV = (vec2(float(x), float(y)) + 0.5) / 4.0;
            // the sky is skipped so a wide open horizon does not drag the whole
            // frame down with it
            if (texture(depthtex1, sampleUV).r >= 1.0) {
                continue;
            }
            sum += log2(max(luminance(texture(colortex0, sampleUV).rgb), 1e-4));
            count += 1.0;
        }
    }

    float average = count > 0.5 ? exp2(sum / count) : 0.18;
    float target = clamp(0.16 / max(average, 1e-3), 0.05, 12.0);

    outExposure = vec4(mix(previous, target, saturate(frameTime * AUTO_EXPOSURE_SPEED)), 0.0, 0.0, 1.0);
#else
    outExposure = vec4(1.0, 0.0, 0.0, 1.0);
#endif
}
