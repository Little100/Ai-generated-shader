#version 330 compatibility
#define DIM_END

// Lights every opaque surface and paints the sky where nothing was drawn

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/materials.glsl"
#include "/lib/space.glsl"
#include "/lib/sky.glsl"
#include "/lib/dimension.glsl"
#include "/lib/shadow.glsl"
#include "/lib/lighting.glsl"
#include "/lib/water.glsl"
#include "/lib/fog.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    float depth = texture(depthtex0, texcoord).r;
    vec3 viewPos = screenToView(vec3(texcoord, depth));
    vec3 playerPos = viewToPlayer(viewPos);
    vec3 viewDirWorld = normalize(playerPos);
    vec3 sunDir = sunDirWorld();

    if (depth >= 1.0) {
        #if defined DIM_NETHER || defined DIM_END
        vec3 sky = dimSky(viewDirWorld);
        #else
        vec3 sky = renderSky(viewDirWorld, sunDir, true);
        sky = applyFog(sky, playerPos, viewDirWorld, sunDir, true);
        #endif
        outColor = vec4(sky, 1.0);
        return;
    }

    vec3 albedo = srgbToLinear(texture(colortex0, texcoord).rgb);
    vec4 lightData = texture(colortex1, texcoord);
    vec3 normalWorld = normalize(texture(colortex2, texcoord).rgb * 2.0 - 1.0);
    vec2 lm = lightData.xy;
    int mat = decodeMat(lightData.z);
    float ao = lightData.w;
    vec3 worldPos = playerPos + cameraPosition;

    vec3 color;
    if (mat == MAT_UNLIT) {
        color = albedo;
    } else if (mat == MAT_EMISSIVE || mat == MAT_LAVA) {
        float glow = mat == MAT_LAVA ? 2.4 : 1.6;
        float lumaBoost = pow(luminance(albedo), 0.6);
        color = albedo * (0.25 + glow * lumaBoost);
    } else {
        #if defined DIM_NETHER || defined DIM_END
        vec3 ambient = dimAmbient() * mix(0.6, 1.0, normalWorld.y * 0.5 + 0.5) * ao;
        vec3 direct = vec3(0.0);
        #else
        vec3 skyAmb = skyAmbient(sunDir);
        vec3 lightDir = shadowLightDirWorld();
        vec3 lightCol = sunColor(sunDir) + moonColor(sunDir);
        lightCol *= 1.0 - rainStrength * 0.85;

        float noise = hash12(gl_FragCoord.xy);
        vec3 shadow;
        if (mat == MAT_HAND) {
            // The hand never lands in the shadow map, so it inherits the sky exposure of the eye
            shadow = vec3(smoothstep(0.5, 1.0, float(eyeBrightnessSmooth.y) / 240.0));
        } else {
            shadow = sampleShadow(playerPos, normalWorld, lightDir, noise);
            float shadowFade = smoothstep(shadowDistance * 0.9, shadowDistance * 0.6, length(playerPos));
            shadow = mix(vec3(saturate(dot(normalWorld, lightDir)) * smoothstep(0.55, 0.95, lm.y)), shadow, shadowFade);
        }

        vec3 ambient = ambientLight(skyAmb, normalWorld, lm.y, ao);
        vec3 direct = directLight(lightCol, normalWorld, lightDir, shadow, lm.y, mat);

        float wetGloss = wetness * smoothstep(0.7, 1.0, lm.y) * saturate(normalWorld.y);
        vec3 viewDirW = -viewDirWorld;
        direct += specularHighlight(lightCol, normalWorld, lightDir, viewDirW, wetGloss * 0.8, shadow);
        albedo *= 1.0 - wetGloss * 0.25;
        #endif

        vec3 block = blocklight(lm.x, worldPos);
        block += blocklightColor(1.0) * handLightLevel(viewPos) * 1.2;

        float nv = nightVision * 0.35;
        color = albedo * (ambient + direct + block + nv);
        color *= 1.0 - darknessFactor * 0.85;
    }

    // Distance fog and dimension fog
    float dist = length(playerPos);
    #if defined DIM_NETHER
    color = mix(color, dimAmbient() * 0.9, 1.0 - exp(-dist * 0.012));
    #elif defined DIM_END
    color = mix(color, vec3(0.05, 0.03, 0.09), 1.0 - exp(-dist * 0.006));
    #else
    if (isEyeInWater == 0) color = applyFog(color, playerPos, viewDirWorld, sunDir, false);
    #endif

    color *= 1.0 - blindness * 0.95;
    outColor = vec4(color, 1.0);
}
