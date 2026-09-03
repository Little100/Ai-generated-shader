#version 330 compatibility
#define DIM_NETHER

// Composites translucent surfaces onto the lit opaque scene with refraction, then applies underwater fog

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/materials.glsl"
#include "/lib/space.glsl"
#include "/lib/sky.glsl"
#include "/lib/dimension.glsl"
#include "/lib/water.glsl"
#include "/lib/fog.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 tdata = texture(colortex3, texcoord);
    bool hasTranslucent = tdata.a > 0.5;
    float depthAll = texture(depthtex0, texcoord).r;
    float depthOpaque = texture(depthtex1, texcoord).r;

    vec2 sampleUv = texcoord;
    #ifdef WATER_REFRACTION
    if (hasTranslucent && depthOpaque > depthAll) {
        vec2 offset = (tdata.xy * 2.0 - 1.0);
        float thickness = saturate((depthOpaque - depthAll) * 400.0);
        vec2 candidate = texcoord + offset * 0.02 * thickness * (tdata.z > 0.75 ? 1.0 : 0.4);
        // Only accept refracted samples that still lie behind the translucent layer
        if (texture(depthtex1, candidate).r > depthAll) sampleUv = candidate;
    }
    #endif

    vec3 behind = texture(colortex0, sampleUv).rgb;
    vec3 sunDir = sunDirWorld();
    vec3 skyAmb;
    #if defined DIM_NETHER || defined DIM_END
    skyAmb = dimAmbient();
    #else
    skyAmb = skyAmbient(sunDir);
    #endif

    float refractedDepth = texture(depthtex1, sampleUv).r;
    vec3 viewOpaque = screenToView(vec3(sampleUv, refractedDepth));
    vec3 viewFront = screenToView(vec3(texcoord, depthAll));

    if (hasTranslucent && tdata.z > 0.75 && isEyeInWater == 0) {
        // Water seen from above: tint what lies below by the distance the ray travels through it
        float travel = distance(viewOpaque, viewFront);
        vec4 lightData = texture(colortex1, sampleUv);
        behind = applyWaterFog(behind, travel, skyAmb * pow(lightData.y, 1.5) + 0.02);
    }

    vec4 front = texture(colortex4, texcoord);
    vec3 color = hasTranslucent ? behind * (1.0 - front.a) + front.rgb : behind;

    float dist = length(viewFront);
    if (depthAll >= 1.0) dist = far;
    if (isEyeInWater == 1) {
        float eyeSky = float(eyeBrightnessSmooth.y) / 240.0;
        color = applyWaterFog(color, dist, skyAmb * pow(eyeSky, 1.5) + 0.02);
    } else if (isEyeInWater == 2) {
        color = applyLavaFog(color, dist);
    } else if (isEyeInWater == 3) {
        color = applySnowFog(color, dist);
    }

    outColor = vec4(color, 1.0);
}
