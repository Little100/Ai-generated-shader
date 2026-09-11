#version 330 compatibility

/*
    Runs once the opaque world has been drawn and the depth buffer is complete.
    Ambient occlusion and the aerial perspective haze are applied here; the
    translucent pass has not happened yet, so water is handled by the next pass.
*/

#include "/lib/buffers.glsl"
#include "/lib/post.glsl"
#include "/lib/sky.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outScene;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;

void main() {
    vec2 uv = texcoord;
    vec3 color = texture(colortex0, uv).rgb;

    // depthtex1 leaves out every translucent surface, so anything still at the
    // far plane here is genuinely background and needs neither occlusion nor
    // haze. The sky pass has already written the colour for those pixels.
    float depth = texture(depthtex1, uv).r;

    if (depth < 1.0) {
        vec3 viewPos = screenToView(uv, depth, gbufferProjectionInverse);
        vec3 cameraRelative = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
        vec3 viewDir = normalize(cameraRelative + vec3(0.0, 1e-5, 0.0));

        vec3 normal = decodeNormal(texture(colortex2, uv).rgb);
        vec4 lightData = texture(colortex3, uv);

        // occlusion only hides ambient light, so a surface standing in full sun
        // keeps nearly all of its brightness
        float occlusion = computeOcclusion(uv, viewPos, mat3(gbufferModelView) * normal);
        color *= mix(1.0, occlusion, 1.0 - lightData.b * 0.8);

        color = aerialPerspective(color, cameraRelative, viewDir, length(viewPos));
    }

    outScene = vec4(max(color, vec3(0.0)), 1.0);
}
