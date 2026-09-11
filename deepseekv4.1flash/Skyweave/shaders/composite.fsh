#version 330 compatibility

/*
    The translucent surfaces are composited here rather than in the deferred
    pass, because the translucent batch is drawn after deferred runs. By this
    point colortex0 holds the complete opaque scene, which is exactly what a
    refraction lookup needs.

    Water and solid translucents share one pass but not one treatment: water
    refracts and absorbs, glass and ice only tint and catch a highlight.
*/

#include "/lib/buffers.glsl"
#include "/lib/post.glsl"
#include "/lib/sky.glsl"
#include "/lib/water.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outScene;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex5;

vec3 viewPosAt(vec2 uv, float depth) {
    return screenToView(uv, depth, gbufferProjectionInverse);
}

void main() {
    vec2 uv = texcoord;
    vec3 color = texture(colortex0, uv).rgb;

    float surfaceDepth = texture(depthtex0, uv).r;
    vec4 surface = texture(colortex4, uv);
    vec4 data = texture(colortex5, uv);
    vec3 sunDir = normalize(sunPosition);

    bool hasSurface = surface.a > 0.01 && surfaceDepth < 1.0;

    if (hasSurface && data.a > 0.5) {
        /*  water  */

        vec3 surfaceViewPos = viewPosAt(uv, surfaceDepth);
        vec3 surfaceWorld = (gbufferModelViewInverse * vec4(surfaceViewPos, 1.0)).xyz;
        vec3 surfaceNormal = decodeNormal(data.rgb);
        vec3 surfaceViewDir = normalize(surfaceWorld + vec3(0.0, 1e-5, 0.0));

        // offset the lookup along the refracted ray
        vec3 viewNormal = mat3(gbufferModelView) * surfaceNormal;
        vec2 offset = viewNormal.xy * WATER_REFRACTION * 0.06 / max(-surfaceViewPos.z, 0.5);
        vec2 refractedUV = clamp(uv + offset, vec2(0.0015), vec2(0.9985));

        float behindDepth = texture(depthtex1, refractedUV).r;
        vec3 behindViewPos = viewPosAt(refractedUV, behindDepth);

        // a sample that lands in front of the surface would punch through a
        // foreground object, so fall back to the unrefracted pixel
        if (behindDepth >= 1.0 || (-behindViewPos.z) < (-surfaceViewPos.z) + 0.08) {
            refractedUV = uv;
            behindViewPos = viewPosAt(uv, texture(depthtex1, uv).r);
        }

        vec3 behind = texture(colortex0, refractedUV).rgb;

        // path length through the water column, corrected for the viewing angle
        float verticalGap = max((-behindViewPos.z) - (-surfaceViewPos.z), 0.0);
        float pathLength = verticalGap / max(abs(surfaceViewDir.z), 0.12);

        vec3 transmittance = waterAbsorption(pathLength);
        vec3 scattering = waterTint(pathLength) * (vec3(1.0) - transmittance) * 1.8;
        vec3 refracted = behind * transmittance + scattering;

        // the reflected ray is traced straight through the atmosphere, so the
        // surface mirrors the actual sky rather than an approximation of it
        vec3 reflected = renderSkyBackground(reflect(surfaceViewDir, surfaceNormal), sunDir, eyeAltitude);
        float fresnel = 0.02 + 0.98 * pow(saturate(1.0 - dot(surfaceNormal, surfaceViewDir)), 5.0);

        vec3 shaded = mix(refracted, reflected, fresnel);

        float visibility = shadowVisibility(surfaceWorld, surfaceNormal, length(surfaceViewPos), dot(surfaceNormal, sunDir));
        vec3 sunlight = sunTransmittance(eyeAltitude, sunDir) * SUN_IRRADIANCE;
        shaded += specularBRDF(surfaceNormal, surfaceViewDir, sunDir, 0.055, vec3(0.02))
                * sunlight * visibility * WATER_SPECULAR;

        color = mix(color, shaded, saturate(surface.a));
    } else if (hasSurface) {
        /*  glass and ice  */

        vec3 surfaceViewPos = viewPosAt(uv, surfaceDepth);
        vec3 surfaceWorld = (gbufferModelViewInverse * vec4(surfaceViewPos, 1.0)).xyz;
        vec3 surfaceNormal = decodeNormal(data.rgb);
        vec3 surfaceViewDir = normalize(surfaceWorld + vec3(0.0, 1e-5, 0.0));

        float visibility = shadowVisibility(surfaceWorld, surfaceNormal, length(surfaceViewPos), dot(surfaceNormal, sunDir));
        vec3 sheen = specularBRDF(surfaceNormal, surfaceViewDir, sunDir, 0.18, vec3(0.05))
                   * sunTransmittance(eyeAltitude, sunDir) * SUN_IRRADIANCE * visibility * 1.4;

        vec3 tinted = color * mix(vec3(1.0), surface.rgb, 0.6) + sheen;
        color = mix(color, tinted, saturate(surface.a));
    }

    /*  submerged  */

    if (isEyeInWater == 1) {
        vec3 viewDir = normalize(mat3(gbufferModelViewInverse) * screenToView(uv, 1.0, gbufferProjectionInverse));
        float distance = min(depthToViewDistance(surfaceDepth, gbufferProjectionInverse), 48.0);
        vec3 transmittance = waterAbsorption(distance * 0.85);
        vec3 scattering = waterTint(10.0) * (vec3(1.0) - transmittance) * 1.4;
        color = color * transmittance + scattering;
        color += sunTransmittance(eyeAltitude, sunDir) * miePhase(dot(viewDir, sunDir)) * 0.02;
    } else if (isEyeInWater == 2) {
        // lava is not tinted water, it is opaque
        float distance = min(depthToViewDistance(surfaceDepth, gbufferProjectionInverse), 6.0);
        color = mix(color, vec3(0.85, 0.18, 0.02) * 0.25, saturate(distance / 6.0) * 0.9);
    } else if (isEyeInWater == 3) {
        float distance = min(depthToViewDistance(surfaceDepth, gbufferProjectionInverse), 12.0);
        color = mix(color, vec3(0.35, 0.06, 0.55) * 0.4, saturate(distance / 12.0) * 0.8);
    }

    outScene = vec4(max(color, vec3(0.0)), 1.0);
}
