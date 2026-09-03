// Forward-lit translucent surfaces. Water gets procedural waves, reflections of the sky and a transmission tint.

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
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normalWorld;
in vec3 playerPos;
flat in int material;

// Color lands in colortex4 with premultiplied alpha blending so composite can refract what lies behind it
/* RENDERTARGETS: 4,3 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outTranslucentData;

vec3 reflectSky(vec3 dir, vec3 sunDir, float skyLevel) {
    #if defined DIM_NETHER || defined DIM_END
    return dimSky(dir) * skyLevel;
    #else
    dir.y = abs(dir.y);
    return renderSky(dir, sunDir, false) * pow(skyLevel, 2.0);
    #endif
}

void main() {
    vec3 sunDir = sunDirWorld();
    vec3 worldPos = playerPos + cameraPosition;
    vec3 viewDirWorld = normalize(-playerPos);
    vec3 n = normalWorld;
    if (dot(n, viewDirWorld) < 0.0) n = -n;

    #if defined DIM_NETHER || defined DIM_END
    vec3 skyAmb = dimAmbient();
    vec3 lightCol = vec3(0.0);
    vec3 lightDir = vec3(0.0, 1.0, 0.0);
    vec3 shadow = vec3(0.0);
    #else
    vec3 skyAmb = skyAmbient(sunDir);
    vec3 lightDir = shadowLightDirWorld();
    vec3 lightCol = (sunColor(sunDir) + moonColor(sunDir)) * (1.0 - rainStrength * 0.85);
    float noise = hash12(gl_FragCoord.xy);
    vec3 shadow = sampleShadow(playerPos, n, lightDir, noise);
    #endif

    vec4 albedo = texture(gtexture, texcoord) * glcolor;
    #ifdef GB_ENTITY
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
    #endif
    if (albedo.a < 0.004) discard;
    vec3 color;
    float alpha = albedo.a;
    vec2 refractOffset = vec2(0.0);

    if (material == MAT_WATER) {
        bool horizontal = abs(normalWorld.y) > 0.5;
        float waveStrength = 0.22 + rainStrength * 0.25;
        vec3 wn = horizontal ? waterNormal(worldPos.xz, frameTimeCounter, waveStrength) : n;
        if (horizontal && normalWorld.y < 0.0) wn.y = -wn.y;
        if (!horizontal) wn = normalize(n + 0.08 * (waterNormal(worldPos.xy + worldPos.zz, frameTimeCounter, 0.4) - vec3(0.0, 1.0, 0.0)));

        float fresnel = pow(1.0 - saturate(dot(wn, viewDirWorld)), 5.0);
        fresnel = mix(0.03, 1.0, fresnel);
        if (isEyeInWater == 1) fresnel *= 0.35;

        vec3 refl = reflectSky(reflect(-viewDirWorld, wn), sunDir, lmcoord.y);
        vec3 sunSpec = specularHighlight(lightCol, wn, lightDir, viewDirWorld, 0.92, shadow) * 6.0;

        // Water body tint uses the biome color from the vertex color, deepened toward absorption
        vec3 body = srgbToLinear(glcolor.rgb) * vec3(0.55, 0.75, 0.85);
        vec3 bodyLit = body * (skyAmb * pow(lmcoord.y, 1.5) * 0.7 + lightCol * shadow * 0.25 + blocklight(lmcoord.x, worldPos) * 0.6);

        color = mix(bodyLit, refl, fresnel) + sunSpec;
        alpha = mix(0.35, 0.9, fresnel);
        if (isEyeInWater == 1) alpha = 0.25;
        refractOffset = (wn.xz - (horizontal ? vec2(0.0) : n.xz)) * 0.9;
    } else {
        vec3 lin = srgbToLinear(albedo.rgb);
        vec3 ambient = ambientLight(skyAmb, n, lmcoord.y, 1.0);
        vec3 direct = directLight(lightCol, n, lightDir, shadow, lmcoord.y, MAT_DEFAULT);
        vec3 block = blocklight(lmcoord.x, worldPos);
        vec3 refl = reflectSky(reflect(-viewDirWorld, n), sunDir, lmcoord.y);
        float fresnel = pow(1.0 - saturate(dot(n, viewDirWorld)), 5.0);
        color = lin * (ambient + direct + block) + refl * fresnel * 0.35 * saturate(1.0 - albedo.a * 0.5);
        color += specularHighlight(lightCol, n, lightDir, viewDirWorld, 0.7, shadow) * 0.8;
        if (material == MAT_HAND) color = lin * (skyAmb * 0.8 + lightCol * 0.5 + block);
        if (material == MAT_PARTICLE) color = lin * (skyAmb * pow(lmcoord.y, 1.5) * 1.1 + lightCol * shadow * 0.45 + block);
        refractOffset = material == MAT_DEFAULT ? n.xz * 0.15 * (1.0 - albedo.a) : vec2(0.0);
    }

    #if !defined DIM_NETHER && !defined DIM_END
    if (isEyeInWater == 0) color = applyFog(color, playerPos, normalize(playerPos), sunDir, false);
    #endif

    alpha = saturate(alpha);
    outColor = vec4(color * alpha, alpha);
    // Refraction offset and water mask for composite; alpha channel drives the blend of this buffer
    outTranslucentData = vec4(refractOffset * 0.5 + 0.5, material == MAT_WATER ? 1.0 : 0.5, 1.0);
}
