#version 330 compatibility

#include "/lib/util.glsl"

in vec2 texcoord;

// 以屏幕中心为基准的暗角, 保持四角压暗而不侵入画面中心
float vignette(vec2 uv) {
    vec2 p = (uv - 0.5) * vec2(aspectRatio, 1.0);
    float r = length(p) * 1.28;
    return 1.0 - smoothstep(0.42, 0.98, r) * 0.32;
}

// 冷暖分离的调色, 高光偏暖, 暗部偏冷
vec3 splitTone(vec3 color) {
    float l = luminance(color);
    vec3 warm = vec3(1.035, 1.0, 0.955);
    vec3 cool = vec3(0.955, 0.985, 1.045);
    vec3 tone = mix(cool, warm, smoothstep(0.08, 0.62, l));
    return color * tone;
}

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    vec3 bloom = texture2D(colortex6, texcoord).rgb;

    color += bloom;

    // 曝光与色调映射
    color *= exposure;
#ifdef TONEMAP_ACES
    color = acesFilm(color);
#else
    color = hableFilmic(color);
#endif

    // 夜色做一次去饱和, 避免夜间像加了蓝色滤镜
    color = desaturateForNight(color, nightFactor() * 0.6);
    color = saturateColor(color, colSat);
    color = splitTone(color);

    // 暗角与雨天的整体压暗
    color *= vignette(texcoord);
    color *= mix(1.0, 0.92, rainStrength);

    // 抖动, 消除暗部色带
    float noise = ign(gl_FragCoord.xy, frameCounter) - 0.5;
    color += noise * (1.0 / 255.0) * 0.9;

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
