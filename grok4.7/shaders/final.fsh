#version 120
#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/post.glsl"

varying vec2 texcoord;

vec3 bloomGather(vec2 uv) {
    vec3 acc = vec3(0.0);
    float w = 0.0;
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    for (int y = -6; y <= 6; y++) {
        for (int x = -6; x <= 6; x++) {
            vec2 o = vec2(float(x), float(y));
            float d2 = dot(o, o);
            float weight = exp(-d2 * 0.045);
            vec3 s = texture2D(colortex0, uv + o * texel * 2.5).rgb;
            float bright = max(luma(s) - 0.85, 0.0);
            acc += s * bright * weight;
            w += weight;
        }
    }
    return acc / max(w, 0.001);
}

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    color += bloomGather(texcoord) * K_BLOOM * 0.85;

    float exposure = exp2(K_EXPOSURE_BIAS) * mix(1.15, 0.72, K_NIGHT);
    exposure *= mix(1.0, 0.8, rainStrength);
    color *= exposure;

    #if K_GRADE == 1
        color = grade(color);
        color = agx(color);
    #elif K_GRADE == 2
        color = mix(color, vec3(luma(color)), 0.18);
        color = acesFilm(color * vec3(0.85, 0.9, 1.05));
    #else
        color = acesFilm(color);
    #endif

    float sat = K_SATURATION;
    color = mix(vec3(luma(color)), color, sat);

    vec2 p = texcoord * 2.0 - 1.0;
    float vig = pow(saturate(dot(p, p)), 1.35);
    color *= 1.0 - vig * 0.28 * K_VIGNETTE;

    float grain = (hash12(gl_FragCoord.xy + float(frameCounter)) - 0.5) * 0.012;
    color += grain * (1.0 - luma(color));

    color = linearToSrgb(max(color, vec3(0.0)));
    gl_FragColor = vec4(color, 1.0);
}
