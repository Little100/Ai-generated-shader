#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */

// 十三点采样降采样, 抑制闪烁并保住体积
vec3 downsample13(sampler2D src, vec2 uv, vec2 texel) {
    vec3 a = texture2D(src, uv + texel * vec2(-1.0, -1.0)).rgb;
    vec3 b = texture2D(src, uv + texel * vec2(1.0, -1.0)).rgb;
    vec3 c = texture2D(src, uv + texel * vec2(-1.0, 1.0)).rgb;
    vec3 d = texture2D(src, uv + texel * vec2(1.0, 1.0)).rgb;
    vec3 e = texture2D(src, uv).rgb;
    vec3 f = texture2D(src, uv + texel * vec2(-2.0, 0.0)).rgb;
    vec3 g = texture2D(src, uv + texel * vec2(2.0, 0.0)).rgb;
    vec3 h = texture2D(src, uv + texel * vec2(0.0, -2.0)).rgb;
    vec3 i = texture2D(src, uv + texel * vec2(0.0, 2.0)).rgb;
    vec3 j = texture2D(src, uv + texel * vec2(-2.0, -2.0)).rgb;
    vec3 k = texture2D(src, uv + texel * vec2(2.0, -2.0)).rgb;
    vec3 l = texture2D(src, uv + texel * vec2(-2.0, 2.0)).rgb;
    vec3 m = texture2D(src, uv + texel * vec2(2.0, 2.0)).rgb;

    vec3 result = e * 0.125;
    result += (a + b + c + d) * 0.125;
    result += (f + g + h + i) * 0.0625;
    result += (j + k + l + m) * 0.03125;
    return result;
}

// 帐篷滤波上采样, 双线性合并九个点
vec3 upsampleTent(sampler2D src, vec2 uv, vec2 texel) {
    vec3 a = texture2D(src, uv + texel * vec2(-1.0, -1.0)).rgb;
    vec3 b = texture2D(src, uv + texel * vec2(1.0, -1.0)).rgb;
    vec3 c = texture2D(src, uv + texel * vec2(-1.0, 1.0)).rgb;
    vec3 d = texture2D(src, uv + texel * vec2(1.0, 1.0)).rgb;
    vec3 e = texture2D(src, uv).rgb;
    vec3 f = texture2D(src, uv + texel * vec2(-1.0, 0.0)).rgb;
    vec3 g = texture2D(src, uv + texel * vec2(1.0, 0.0)).rgb;
    vec3 h = texture2D(src, uv + texel * vec2(0.0, -1.0)).rgb;
    vec3 i = texture2D(src, uv + texel * vec2(0.0, 1.0)).rgb;
    return (a + b + c + d) * 0.0625 + (f + g + h + i) * 0.125 + e * 0.25;
}

void main() {
    vec4 scene = texture2D(colortex0, texcoord);
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);

#ifdef BLOOM
    // 五级金字塔, 每级跨度翻倍, 合计覆盖约六十四像素半径
    vec3 bloom = downsample13(colortex6, texcoord, texel);
    bloom += downsample13(colortex6, texcoord, texel * 2.0) * 0.85;
    bloom += downsample13(colortex6, texcoord, texel * 4.0) * 0.7;
    bloom += downsample13(colortex6, texcoord, texel * 8.0) * 0.55;
    bloom += downsample13(colortex6, texcoord, texel * 16.0) * 0.4;
    // 再叠一层大范围帐篷做柔和铺底
    bloom = bloom * 0.62 + upsampleTent(colortex6, texcoord, texel * 14.0) * 0.16;

    float norm = 1.0 + 0.85 + 0.7 + 0.55 + 0.4;
    scene.rgb += bloom / norm * bloomStrength * 2.4;
#endif

    gl_FragData[0] = scene;
}
