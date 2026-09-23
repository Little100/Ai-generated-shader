#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0,6 */

// 亮部阈值与软膝, 避免阈值处出现硬边
const float BLOOM_THRESHOLD = 0.92;
const float BLOOM_KNEE = 0.55;

vec3 prefilter(vec3 color) {
    float brightness = max(max(color.r, color.g), color.b);
    float soft = clamp(brightness - BLOOM_THRESHOLD + BLOOM_KNEE, 0.0, 2.0 * BLOOM_KNEE);
    soft = soft * soft / (4.0 * BLOOM_KNEE + EPS);
    float contribution = max(soft, brightness - BLOOM_THRESHOLD) / max(brightness, EPS);
    return color * clamp(contribution, 0.0, 1.0);
}

void main() {
    vec4 scene = texture2D(colortex0, texcoord);
    vec4 rays = texture2D(colortex5, texcoord);

    // 体积光在雾之后叠加, 这样光柱会被雾略微削弱
    scene.rgb += rays.rgb * 0.85;

#ifdef BLOOM
    vec3 bright = prefilter(scene.rgb);
    // 太阳与火把这类极亮处额外保留, 让泛光有明确来源
    bright = max(bright, scene.rgb * smoothstep(1.6, 5.0, luminance(scene.rgb)) * 0.6);
    gl_FragData[0] = scene;
    gl_FragData[1] = vec4(bright, 1.0);
#else
    gl_FragData[0] = scene;
    gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
#endif
}
