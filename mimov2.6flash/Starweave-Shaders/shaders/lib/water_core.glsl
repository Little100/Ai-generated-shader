#ifndef SW_WATER_CORE
#define SW_WATER_CORE

uniform sampler2D tex;
uniform sampler2D colortex3;
uniform sampler2D depthtex1;

in vec2 vUV;
in vec2 vLightmap;
in vec4 vColor;
in vec3 vWorldAbs;
in vec3 vWorldNormal;
in float vDist;
in vec4 vEntity;

// 半透明方块与水面的主流程
void main(){
  vec4 t = texture(tex, vUV);
  if (t.a < 0.1) discard;

  bool isWater = (vEntity.x == 10200.0);
  vec3 albedo = t.rgb * vColor.rgb;
  vec2 lm = lightLevels(vLightmap);
  float dist = max(vDist, 0.01);
  vec3 absW = vWorldAbs;
  vec3 rayDir = screenRayDir(vUV);
  vec3 V = -rayDir;

  vec3 N = normalize(vWorldNormal);
#ifdef WATER_WAVES
  if (isWater) N = waterNormal(absW, frameTimeCounter, dist);
#endif

  // 已点亮的不透明场景作为折射来源
  vec2 sceneUV = vUV;
  if (isWater){
    sceneUV += vec2(N.x, N.z) * 0.04 * (1.0 / (1.0 + dist * 0.2));
    sceneUV = clamp(sceneUV, vec2(0.001), vec2(0.999));
  }
  vec3 behind = texture(colortex3, sceneUV).rgb;
  vec3 viewScene = reconstructView(sceneUV, texture(depthtex1, sceneUV).r);
  float thickness = max(dist - length(viewScene), 0.0);

  vec3 lightDir = shadowLightWorldDir();
  float shadow = 1.0;
#ifdef SHADOWS
  if (isWater && dot(N, lightDir) > 0.0) shadow = softShadow(absW, N, lightDir);
#endif

  vec3 color;
  float alpha;

  if (isWater){
    float absorb = 1.0 - exp(-thickness * 0.1);
    vec3 deepTint = vec3(0.04, 0.2, 0.26) * (0.25 + 0.75 * lm.y) + fogColor * 0.08;
    vec3 refr = mix(behind, deepTint, absorb * 0.72);

    vec3 R = reflect(rayDir, N);
    if (R.y < 0.03) R.y = 0.03 + (0.03 - R.y) * 0.4;
    R = normalize(R);
    vec3 skyR = proceduralSky(R);

    float NdotV = max(dot(N, V), 0.0);
    float F = 0.02 + 0.98 * pow(1.0 - NdotV, 5.0);
    F = mix(0.04, 1.0, F);

    vec3 direct = directLightColor();
    vec3 spec = ggxSpecular(N, V, lightDir, direct * shadow, 0.07, vec3(0.035)) * 1.6;

    color = mix(refr, skyR, saturate(F) * 0.9);
    color += spec;
    color += albedo * blockRamp(lm.x) * 0.55;
    color += albedo * ambientSkyColor() * lm.y * 0.5;

    // 近岸白沫
    float shore = 1.0 - smoothstep(0.0, 2.6, thickness);
    float foamNoise = vnoise(absW.xz * 2.6 + vec2(frameTimeCounter * 0.7, -frameTimeCounter * 0.5));
    color += vec3(0.55, 0.65, 0.7) * shore * smoothstep(0.45, 0.9, foamNoise) * 0.3;

    alpha = t.a * mix(0.78, 0.96, saturate(F));
  } else {
    // 玻璃等半透明体: 透射场景加表面光
    vec3 R = reflect(rayDir, N);
    float NdotV = max(dot(N, V), 0.0);
    float F = pow(1.0 - NdotV, 5.0);
    vec3 skyR = proceduralSky(normalize(R + vec3(0.0, 0.02, 0.0)));
    vec3 lit = selfLight(albedo, vLightmap, 1.0, N);
    color = mix(lit, behind * albedo, t.a * 0.55);
    color += skyR * F * 0.25;
    color += albedo * directLightColor() * max(dot(N, lightDir), 0.0) * shadow * lm.y * 0.6;
    alpha = t.a;
  }

  vec3 fogTarget = fogColor + ambientSkyColor() * 0.12;
#ifdef DIM_END
  fogTarget = mix(fogTarget, vec3(0.16, 0.06, 0.22), 0.5);
#endif
  float density = 0.0032 + rainStrength * 0.004;
#ifdef DIM_NETHER
  density = 0.014;
#endif
#ifdef DIM_END
  density = 0.0045;
#endif
  color = applyFog(color, dist, fogTarget, density);

  gl_FragData[0] = vec4(color, alpha);
}

/* DRAWBUFFERS:0 */

#endif
