#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/noise.glsl"

uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;

in vec2 vUv;

vec3 brightColor(vec2 uv) {
    vec3 sampleColor = texture2D(colortex0, uv).rgb;
    float luminance = dot(sampleColor, vec3(0.2126, 0.7152, 0.0722));
    return sampleColor * smoothstep(0.78, 1.75, luminance);
}

void main() {
    vec3 color = texture2D(colortex0, vUv).rgb;
    if (BLOOM_STRENGTH > 0.0) {
    vec2 pixel = vec2(1.0 / viewWidth, 1.0 / viewHeight);
    vec3 glow = vec3(0.0);
    for (int i = 0; i < 12; ++i) {
        float angle = float(i) * 2.399963;
        float radius = sqrt(float(i) + 0.5) * 2.4;
        vec2 offset = vec2(cos(angle), sin(angle)) * radius * pixel;
        glow += brightColor(clamp(vUv + offset, pixel, 1.0 - pixel));
    }
    color += glow * (BLOOM_STRENGTH / 12.0);
    }
    color = color / (1.0 + color * 0.31);
    float gray = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(vec3(gray), color, SATURATION);
    color = pow(max(color, vec3(0.0)), vec3(0.94));
    color += (hash12(vUv * vec2(viewWidth, viewHeight)) - 0.5) / 255.0;
    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}

