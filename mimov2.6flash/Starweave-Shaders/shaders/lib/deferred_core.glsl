#ifndef SW_DEFERRED_CORE
#define SW_DEFERRED_CORE

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D depthtex2;

in vec2 vUV;

#ifdef DIM_END
uniform vec3 endFlashPosition;
uniform float endFlashIntensity;
#endif

// 屏幕空间环境遮挡
float computeSSAO(vec3 rawPos, vec3 wN){
  float radius = 0.55;
  float occ = 0.0;
  for (int i = 0; i < 8; i++){
    float fi = float(i);
    vec3 rnd = vec3(
      hash12(gl_FragCoord.xy + fi * 17.0),
      hash12(gl_FragCoord.xy + fi * 29.0 + 5.0),
      hash12(gl_FragCoord.xy + fi * 41.0 + 9.0));
    vec3 dir = normalize(rnd * 2.0 - 1.0);
    if (dot(dir, wN) < 0.0) dir = -dir;
    vec3 sampleRaw = rawPos + dir * radius * (0.35 + 0.65 * fract(fi * 0.618 + 0.13));
    vec4 sampleView = gbufferModelView * vec4(sampleRaw, 1.0);
    vec4 clip = gbufferProjection * sampleView;
    if (clip.w <= 0.0001) continue;
    vec2 suv = clip.xy / clip.w * 0.5 + 0.5;
    if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) continue;
    vec3 sceneView = reconstructView(suv, texture(depthtex0, suv).r);
    float diff = sceneView.z - sampleView.z;
    if (diff > 0.02){
      vec3 sceneRaw = viewToWorldRaw(sceneView);
      float range = saturate(radius / max(length(sceneRaw - rawPos), 0.001));
      occ += step(0.02, diff) * range;
    }
  }
  return 1.0 - (occ / 8.0) * 0.85;
}

// 自发光的轻微火焰抖动
float emissiveFlicker(vec3 absWorld){
  vec3 cell = floor(absWorld * 3.0);
  float t = floor(frameTimeCounter * 9.0);
  return 0.86 + 0.28 * hash13(cell + vec3(t, t * 0.5, 0.0));
}

void main(){
  vec3 hdr = vec3(0.0);
  float depth = texture(depthtex0, vUV).r;

  if (depth >= 0.999999){
    hdr = texture(colortex0, vUV).rgb;
#if defined(VOLUMETRICS) && defined(SHADOWS) && !defined(DIM_NETHER) && !defined(DIM_END)
    vec3 rayDir = screenRayDir(vUV);
    vec3 lightDir = shadowLightWorldDir();
    hdr += volumetricLight(rayDir, 500.0, lightDir, directLightColor(), fogColor);
#endif
    gl_FragData[0] = vec4(hdr, 1.0);
    gl_FragData[1] = vec4(hdr, 1.0);
    return;
  }

  vec3 viewPos = reconstructView(vUV, depth);
  vec3 rawPos = viewToWorldRaw(viewPos);
  vec3 absWorld = rawToWorld(rawPos);
  float viewDistance = length(viewPos);
  vec3 rayDir = screenRayDir(vUV);
  vec3 V = -rayDir;

  // 手部像素的世界重建不可靠, 跳过需要世界位置的效果
  float depthNoHand = texture(depthtex2, vUV).r;
  bool isHand = depthNoHand > depth + 1e-6;

  vec4 tex0 = texture(colortex0, vUV);
  vec4 tex1 = texture(colortex1, vUV);
  vec4 tex2 = texture(colortex2, vUV);

  vec3 albedo = tex0.rgb;
  float blockLevel = tex0.a;
  float skyLevel = tex1.a;
  vec3 N = tex1.xyz * 2.0 - 1.0;
  if (dot(N, N) < 0.01) N = vec3(0.0, 1.0, 0.0);
  N = normalize(N);
  float smoothness = tex2.r;
  float metalness = tex2.g;
  float emissive = tex2.b;
  float ao = tex2.a;

  // 雨天打湿顶面: 变暗并提升光泽
  float wetUp = saturate(N.y) * wetness;
  albedo *= 1.0 - 0.2 * wetUp;
  smoothness = mix(smoothness, 0.88, wetUp * 0.75);

#ifdef SSAO
  if (!isHand){
    float ssao = computeSSAO(rawPos, N);
    ao *= ssao;
  }
#endif

  vec3 lightDir = shadowLightWorldDir();
  float NdotL = max(dot(N, lightDir), 0.0);

  float shadow = 1.0;
#ifdef SHADOWS
#if !defined(DIM_NETHER) && !defined(DIM_END)
  if (NdotL > 0.0 && !isHand) shadow = softShadow(absWorld, N, lightDir);
#endif
#endif
#ifdef CLOUD_SHADOWS
#if !defined(DIM_NETHER) && !defined(DIM_END)
  if (!isHand) shadow *= cloudShadow(absWorld, lightDir);
#endif
#endif

  vec3 directRadiance = directLightColor();
  vec3 F0 = mix(vec3(0.04), albedo, metalness);
  float rough = 1.0 - smoothness;

  vec3 color = vec3(0.0);
#ifdef DIM_NETHER
  // 下界: 以暖红环境光与方块光为主
  float hemiN = 0.55 + 0.45 * (N.y * 0.5 + 0.5);
  vec3 ambient = vec3(0.14, 0.035, 0.018) * hemiN * mix(0.55, 1.0, ao);
  color += albedo * ambient;
  color += albedo * blockRamp(blockLevel) * mix(0.5, 1.0, ao);
#else
#ifdef DIM_END
  // 终界: 紫调虚空环境光与传送门闪光
  float hemiE = 0.5 + 0.5 * (N.y * 0.5 + 0.5);
  vec3 ambient = vec3(0.1, 0.05, 0.16) * hemiE * mix(0.5, 1.0, ao);
  ambient += vec3(0.65, 0.55, 1.0) * endFlashIntensity * 1.4;
  color += albedo * ambient;
  color += albedo * blockRamp(blockLevel) * mix(0.5, 1.0, ao);
#else
  float hemi = 0.55 + 0.45 * (N.y * 0.5 + 0.5);
  vec3 ambient = ambientSkyColor() * pow(skyLevel, 1.3) * hemi * mix(0.45, 1.0, ao);
  color += albedo * (1.0 - metalness * 0.65) * ambient;
  color += albedo * blockRamp(blockLevel) * mix(0.5, 1.0, ao);

  color += albedo * (1.0 - metalness) * directRadiance * NdotL * shadow;
  color += ggxSpecular(N, V, lightDir, directRadiance * shadow, max(rough, 0.06), F0);

  // 平滑表面反射程序化天空, 与背景共用同一套天空函数
  if (smoothness > 0.3){
    vec3 R = reflect(rayDir, N);
    if (R.y < 0.02) R.y = 0.02 + (0.02 - R.y) * 0.35;
    R = normalize(R);
    vec3 skyR = proceduralSky(R);
    float NdotV = max(dot(N, V), 0.0);
    vec3 F = F0 + (1.0 - F0) * pow(1.0 - NdotV, 5.0);
    color += skyR * F * smoothness * smoothness * 0.65;
  }

  color += lightningLight(N);
#endif
#endif

  // 自发光方块直接以原色推入 HDR
  float flick = (emissive > 0.85 && !isHand) ? emissiveFlicker(absWorld) : 1.0;
  color += albedo * emissive * 1.35 * flick;

  // 水下的动态光焦散
  if (isEyeInWater == 1 && !isHand){
    float sunUp = smoothstep(0.05, 0.3, shadowLightWorldDir().y);
    if (sunUp > 0.0 && NdotL > 0.0){
      vec2 cp = absWorld.xz * 0.55;
      float t = frameTimeCounter;
      float c1 = vnoise(cp + vec2(t * 0.5, t * 0.35));
      float c2 = vnoise(cp * 1.7 - vec2(t * 0.4, t * 0.55));
      float caustic = pow(saturate(1.0 - abs(c1 - c2) * 3.2), 3.0);
      color += directLightColor() * caustic * sunUp * 0.5 * saturate(N.y);
    }
  }

  // 体积光只在主世界且阴影开启时积分
#if defined(VOLUMETRICS) && defined(SHADOWS) && !defined(DIM_NETHER) && !defined(DIM_END)
  vec3 volColor = volumetricLight(rayDir, viewDistance, lightDir, directLightColor(), fogColor);
  color = color * exp(-viewDistance * 0.004) + volColor;
#endif

  // 距离雾: 主世界指数雾, 下界浓重红雾, 终界紫雾
  float density = 0.0032 + rainStrength * 0.004;
#ifdef DIM_NETHER
  density = 0.014;
#endif
#ifdef DIM_END
  density = 0.0045;
#endif
  vec3 fogTarget = fogColor;
#ifdef DIM_END
  fogTarget = mix(fogColor, vec3(0.16, 0.06, 0.22), 0.65);
#endif
#ifdef DIM_NETHER
  fogTarget = mix(fogColor, vec3(0.4, 0.08, 0.03), 0.35);
#endif
  // 雾底补一点环境光防止过黑
  fogTarget += ambientSkyColor() * 0.12;
  hdr = applyFog(color, viewDistance, fogTarget, density);

  gl_FragData[0] = vec4(hdr, 1.0);
  gl_FragData[1] = vec4(hdr, 1.0);
}

/* DRAWBUFFERS:03 */

#endif
