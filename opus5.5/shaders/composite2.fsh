#version 330 compatibility

#include "/lib/util.glsl"
#include "/lib/lighting.glsl"
#include "/lib/clouds.glsl"

uniform sampler2D depthtex0;

in vec2 texcoord;

/* RENDERTARGETS: 0,4 */

void main() {
    vec4 scene = texture2D(colortex0, texcoord);
    vec4 aux = texture2D(colortex4, texcoord);
    float rawDepth = texture2D(depthtex0, texcoord).r;
    bool isSky = rawDepth >= 1.0;

    vec3 worldDir = normalize(viewToWorldDir(screenToViewPos(vec3(texcoord, 1.0))));
    vec3 cameraWorldPos = cameraPosition;

    // 天空像素额外做一次体积云的步进
    if (isSky) {
        float jitter = ign(gl_FragCoord.xy, frameCounter * 1.37);
#ifdef SP_CLOUDS
        vec4 clouds = marchClouds(cameraWorldPos, worldDir, 4200.0, 1.0, jitter);
#else
        vec4 clouds = vec4(0.0);
#endif
        gl_FragData[0] = scene;
        gl_FragData[1] = clouds;
        return;
    }

    // 地形像素做高度雾与空气透视
    vec3 viewPos = screenToViewPos(vec3(texcoord, rawDepth));
    vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;
    vec3 viewDir = normalize(-viewPos);
    float distance = length(viewPos);

#ifdef VOLUMETRIC_FOG
    // 雾的颜色随视线方向在天空色与地面色之间渐变
    vec3 fogColor = mix(skyHorizonColor(), skyZenithColor(), clamp(worldDir.y * 1.4, 0.0, 1.0));
    fogColor *= mix(0.85, 1.0, dayFactor());
    // 阴天时雾色被压向灰蓝
    fogColor = mix(fogColor, vec3(0.30, 0.33, 0.38) * dayFactor(), rainStrength * 0.6);
    fogColor = mix(fogColor, fogColor * 0.12, nightFactor() * 0.55);

    FogResult fog = applyFog(worldPos, viewDir, scene.rgb, fogColor, distance, 1.0);
    scene.rgb = fog.color;
#else
    // 简化路径, 只保留近处的距离雾
    float fogFactor = 1.0 - exp(-distance * 0.0016 * fogDensity);
    vec3 fogColor = mix(skyHorizonColor(), skyZenithColor(), clamp(worldDir.y * 1.4, 0.0, 1.0));
    scene.rgb = mix(scene.rgb, fogColor, fogFactor);
#endif

    // 水下再叠一层吸收
    if (isEyeInWater == 1) {
        scene.rgb = underwaterFog(scene.rgb, getLightInfo().color, distance, 1.0 + float(isEyeInWater == 1) * 0.4);
    }

    gl_FragData[0] = scene;
    gl_FragData[1] = aux;
}
