#version 330 compatibility

/*
    The last program in the chain and the only one that writes to the screen.
    Everything here works on display values rather than on light, which is the
    right space for a sharpening kernel and for grain.
*/

#include "/lib/buffers.glsl"
#include "/lib/post.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

uniform sampler2D colortex0;

// shifts the red and blue channels apart as they move away from the centre
vec3 applyChromaticAberration(vec3 color, vec2 uv) {
    if (CHROMATIC_ABERRATION <= 0.0) {
        return color;
    }

    vec2 centered = uv - 0.5;
    centered.x *= aspectRatio;
    float radius = length(centered);

    if (radius <= 0.05) {
        return color;
    }

    vec2 direction = centered / radius;
    vec2 offset = direction * (CHROMATIC_ABERRATION * 0.0025 * radius * radius);
    // the axis was scaled to keep the shift circular, so it is undone here
    offset.x /= aspectRatio;

    color.r = texture(colortex0, uv + offset).r;
    color.b = texture(colortex0, uv - offset).b;
    return color;
}

// unsharp mask against the four nearest neighbours
vec3 applySharpen(vec3 color, vec2 uv) {
    if (SHARPEN <= 0.0) {
        return color;
    }

    vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
    vec3 neighbours = texture(colortex0, uv + vec2(texel.x, 0.0)).rgb
                    + texture(colortex0, uv - vec2(texel.x, 0.0)).rgb
                    + texture(colortex0, uv + vec2(0.0, texel.y)).rgb
                    + texture(colortex0, uv - vec2(0.0, texel.y)).rgb;

    return clamp(color + (color - neighbours * 0.25) * SHARPEN, 0.0, 1.0);
}

void main() {
    vec3 color = texture(colortex0, texcoord).rgb;

    color = applyChromaticAberration(color, texcoord);
    color = applySharpen(color, texcoord);

    color *= vignetteFactor(texcoord, VIGNETTE);
    color *= filmGrain(texcoord, GRAIN);

    outColor = vec4(saturate(color), 1.0);
}
