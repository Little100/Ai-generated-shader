#version 330 compatibility

/* RENDERTARGETS: 0,3 */

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/color.glsl"
#include "/lib/atmosphere.glsl"
#include "/lib/lighting.glsl"
#include "/lib/water.glsl"

// ==============================================================================
// Aetheria: Deferred Composite Pass Fragment Shader
// Handles soft shadow sampling, diffuse illumination, indirect lighting,
// Beer-Lambert water optics, atmospheric height fog, and bloom extraction.
// ==============================================================================

uniform sampler2D colortex0; // Albedo / Scene color
uniform sampler2D colortex1; // View-space normal (xyz) & Material ID (w)
uniform sampler2D colortex2; // Lightmap UV (x=blocklight, y=skylight)
uniform sampler2D depthtex0; // Full depth buffer (including translucents)
uniform sampler2D depthtex1; // Solid depth buffer (excluding translucents)
uniform sampler2D shadowtex0; // Directional sun/moon shadow map

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float near;
uniform float far;

in vec2 texCoord;

void main() {
    float depth0 = texture(depthtex0, texCoord).r;
    vec4 albedo = texture(colortex0, texCoord);

    // If sampling empty sky background (depth = 1.0), preserve sky and emit subtle bloom if bright
    if (depth0 >= 1.0) {
        gl_FragData[0] = albedo;
        vec3 skyBloom = max(albedo.rgb - vec3(1.0), vec3(0.0));
        gl_FragData[1] = vec4(skyBloom, 1.0);
        return;
    }

    // 1. Reconstruct coordinate spaces
    vec3 viewPos = screenToView(texCoord, depth0, gbufferProjectionInverse);
    vec3 playerPos = viewToPlayer(viewPos, gbufferModelViewInverse);
    vec3 worldPos = playerToWorld(playerPos, cameraPosition);
    vec3 viewDir = normalize(viewPos);

    // 2. Unpack surface normal and material tags
    vec4 normalData = texture(colortex1, texCoord);
    vec3 normal = normalize(normalData.xyz * 2.0 - 1.0);
    float materialId = normalData.w * 255.0;
    bool isWater = (abs(materialId - 1.0) < 0.2);
    bool isFoliage = (abs(materialId - 2.0) < 0.2);

    // 3. Unpack lightmap (normalized to 0..1 range)
    vec4 lmData = texture(colortex2, texCoord);
    float blockLightUV = clamp((lmData.x - 0.03125) / 0.9375, 0.0, 1.0);
    float skyLightUV = clamp((lmData.y - 0.03125) / 0.9375, 0.0, 1.0);

    // 4. Directional Sun/Moon Lighting Setup
    vec3 sunDir = normalize(sunPosition);
    float sunElevation = sunDir.y;
    float dayFactor = smoothstep(-0.12, 0.22, sunElevation);
    float sunsetFactor = smoothstep(0.35, 0.0, abs(sunElevation)) * (1.0 - rainStrength);

    vec3 mainLightDir = (sunElevation >= -0.05) ? sunDir : -sunDir;

    // Sunlight color transition: crisp daylight, fiery amber sunset, or cool silver moonlight
    vec3 daySun = vec3(1.15, 1.08, 0.98);
    vec3 sunsetSun = vec3(1.25, 0.58, 0.22);
    vec3 nightMoon = vec3(0.18, 0.25, 0.45);
    vec3 sunColor = mix(nightMoon, daySun, dayFactor);
#ifdef VIBRANT_SUNSET
    sunColor = mix(sunColor, sunsetSun, sunsetFactor * 0.85);
#endif

    // 5. Shadow Calculation with Poisson Disk Filtering
    float shadow = calculateShadow(shadowtex0, playerPos, normal, mainLightDir, shadowModelView, shadowProjection);
    // Smoothly fade out shadow in areas not open to sky
    shadow *= smoothstep(0.04, 0.25, skyLightUV);

    // Direct Lambertian diffuse term with gentle roll-off
    float NdotL = clamp(dot(normal, mainLightDir), 0.0, 1.0);
    float directLighting = mix(NdotL, NdotL * 0.5 + 0.5, 0.12);

    // 6. Blocklight & Torchlight (with organic micro-flicker)
    vec3 blockLight = calculateBlockLight(blockLightUV, worldPos, frameTimeCounter);

    // 7. Ambient Skylight
    vec3 skyAmbientColor = calculateSkyColor(vec3(0.0, 1.0, 0.0), sunDir, frameTimeCounter, rainStrength);
    vec3 ambientLight = calculateAmbientLight(skyLightUV, normal, skyAmbientColor, dayFactor);

    // 8. Foliage Subsurface Glow (Backlighting SSS)
    vec3 sss = calculateSubsurfaceGlow(normal, viewDir, mainLightDir, sunColor, shadow, isFoliage ? 1.0 : 0.0);

    // 9. Water Optics (Beer-Lambert Absorption & Reflections)
    vec3 sceneAlbedo = albedo.rgb;
    if (isWater) {
        float depth1 = texture(depthtex1, texCoord).r;
        float linDepth0 = linearizeDepth(depth0, near, far);
        float linDepth1 = linearizeDepth(depth1, near, far);
        float waterOpticalDepth = max(linDepth1 - linDepth0, 0.0);

        // Optical light absorption through water column
        sceneAlbedo = applyWaterExtinction(sceneAlbedo, waterOpticalDepth);

        // Surface Fresnel reflection
#ifdef WATER_REFLECTIONS
        float fresnel = calculateFresnel(normal, viewDir);
        vec3 reflectedDir = reflect(viewDir, normal);
        vec3 reflectedWorldDir = mat3(gbufferModelViewInverse) * reflectedDir;
        vec3 reflectedSky = calculateSkyColor(reflectedWorldDir, sunDir, frameTimeCounter, rainStrength);
        sceneAlbedo = mix(sceneAlbedo, reflectedSky, fresnel * 0.85);
#endif
    } else {
        // Underwater caustics on submerged floors
#ifdef WATER_CAUSTICS
        float depth1 = texture(depthtex1, texCoord).r;
        if (depth1 > depth0 + 0.0001 && skyLightUV > 0.4) {
            sceneAlbedo *= calculateWaterCaustics(worldPos.xz, frameTimeCounter);
        }
#endif
    }

    // 10. Assemble illumination
    vec3 totalIllumination = sunColor * (directLighting * shadow) + ambientLight + blockLight + sss;
    vec3 litColor = sceneAlbedo * totalIllumination;

    // 11. Volumetric Height Fog with Solar Forward Scattering
    litColor = calculateAtmosphericFog(litColor, worldPos, cameraPosition, viewDir, sunDir, frameTimeCounter, rainStrength);

    // 12. Write Output Buffers
    gl_FragData[0] = vec4(litColor, albedo.a);

    // Extract HDR bloom luminance for composite1
    vec3 bloomExtract = max(litColor - vec3(1.0), vec3(0.0));
    gl_FragData[1] = vec4(bloomExtract, 1.0);
}
