#version 330 compatibility

#include "/lib/common.glsl"

in vec2 texcoord;

// 十三点采样, 在降采样时抑制闪烁并保持体积
vec3 downsample13(vec2 uv, vec2 texel) {
    vec3 a = texture2D(colortex5, uv + texel * vec2(-1.0, -1.0)).rgb;
    vec3 b = texture2D(colortex5, uv + texel * vec2(1.0, -1.0)).rgb;
    vec3 c = texture2D(colortex5, uv + texel * vec2(-1.0, 1.0)).rgb;
    vec3 d = texture2D(colortex5, uv + texel * vec2(1.0, 1.0)).rgb;
    vec3 e = texture2D(colortex5, uv).rgb;
    vec3 f = texture2D(colortex5, uv + texel * vec2(-2.0, 0.0)).rgb;
    vec3 g = texture2D(colortex5, uv + texel * vec2(2.0, 0.0)).rgb;
    vec3 h = texture2D(colortex5, uv + texel * vec2(0.0, -2.0)).rgb;
    vec3 i = texture2D(colortex5, uv + texel * vec2(0.0, 2.0)).rgb;
    vec3 j = texture2D(colortex5, uv + texel * vec2(-1.0, -1.0) * 2.0).rgb;
    vec3 k = texture2D(colortex5, uv + texel * vec2(1.0, -1.0) * 2.0).rgb;
    vec3 l = texture2D(colortex5, uv + texel * vec2(-1.0, 1.0) * 2.0).rgb;
    vec3 m = texture2D(colortex5, uv + texel * vec2(1.0, 1.0) * 2.0).rgb;

    vec3 result = e * 0.125;
    result += (a + b + c + d) * 0.125;
    result += (f + g + h + i) * 0.0625;
    result += (j + k + l + m) * 0.03125;
    return result;
}

// 帐篷滤波上采样, 用周边四点做双线性合并
vec3 upsampleTent(vec2 uv, vec2 texel) {
    vec3 a = texture2D(colortex5, uv + texel * vec2(-1.0, -1.0)).rgb;
    vec3 b = texture2D(colortex5, uv + texel * vec2(1.0, -1.0)).rgb;
    vec3 c = texture2D(colortex5, uv + texel * vec2(-1.0, 1.0)).rgb;
    vec3 d = texture2D(colortex5, uv + texel * vec2(1.0, 1.0)).rgb;
    vec3 e = texture2D(colortex5, uv).rgb;
    vec3 f = texture2D(colortex5, uv + texel * vec2(-1.0, 0.0)).rgb;
    vec3 g = texture2D(colortex5, uv + texel * vec2(1.0, 0.0)).rgb;
    vec3 h = texture2D(colortex5, uv + texel * vec2(0.0, -1.0)).rgb;
    vec3 i = texture2D(colortex5, uv + texel * vec2(0.0, 1.0)).rgb;
    return (a + b + c + d) * 0.0625 + (f + g + h + i) * 0.125 + e * 0.25;
}

void main() {
    vec2 texel = 1.0 / vec2(viewWidth, viewHeight) * 2.0;
    // 先按半分辨率降采样, 再做一次宽范围的帐篷上采样, 等效于大半径模糊
    vec3 down = downsample13(texcoord, texel * 0.5);
    vec3 up = upsampleTent(texcoord, texel * 2.0);
    gl_FragColor = vec4(mix(down, up, 0.45), 1.0);
}
