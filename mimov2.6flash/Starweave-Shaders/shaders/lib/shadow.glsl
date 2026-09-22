#ifndef SW_SHADOW
#define SW_SHADOW

uniform sampler2D shadowtex0;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

// 中心加密的阴影扭曲, 渲染与采样两侧必须一致
vec2 shadowWarp(vec2 ndc){
  vec2 c = ndc;
  float l = max(abs(c.x), abs(c.y));
  if (l > 0.0001){
    c *= 1.0 / (1.0 + 1.35 * l);
  }
  return c;
}

// 世界坐标到阴影UV与深度
vec4 shadowClip(vec3 shadowSpacePos){
  vec4 clip = shadowProjection * shadowModelView * vec4(shadowSpacePos, 1.0);
  clip.xy = shadowWarp(clip.xy);
  return clip;
}

bool insideShadowMap(vec2 uv){
  return uv.x > 0.001 && uv.x < 0.999 && uv.y > 0.001 && uv.y < 0.999;
}

// 单点采样阴影可见度
float shadowAt(vec3 shadowSpacePos, float compareDepth, float bias){
  vec4 clip = shadowClip(shadowSpacePos);
  vec2 uv = clip.xy * 0.5 + 0.5;
  float depth = clip.z * 0.5 + 0.5;
  if (!insideShadowMap(uv)) return 1.0;
  float d = texture(shadowtex0, uv).r;
  return step(depth - bias, d);
}

// 旋转核PCF软阴影
float softShadow(vec3 absWorld, vec3 normal, vec3 lightDir){
  vec3 shadowSpace = worldToShadowSpace(absWorld);
  vec4 clip = shadowClip(shadowSpace);
  vec2 uv = clip.xy * 0.5 + 0.5;
  float depth = clip.z * 0.5 + 0.5;
  if (!insideShadowMap(uv)) return 1.0;

  float NdotL = max(dot(normal, lightDir), 0.0);
  float bias = 0.0006 + 0.0035 * (1.0 - NdotL);
  vec2 texel = vec2(1.0) / float(shadowMapResolution);
  float angle = hash12(gl_FragCoord.xy + float(frameCounter)) * SW_TAU;
  float ca = cos(angle);
  float sa = sin(angle);
  mat2 rot = mat2(ca, -sa, sa, ca);

  float lit = 0.0;
  for (int x = -1; x <= 1; x++){
    for (int y = -1; y <= 1; y++){
      vec2 offset = rot * (vec2(float(x), float(y)) * 1.35 * texel);
      float d = texture(shadowtex0, uv + offset).r;
      lit += step(depth - bias, d);
    }
  }
  return lit / 9.0;
}

// 体积光: 沿视线向光源方向的遮挡积分
vec3 volumetricLight(vec3 rayDir, float viewDistance, vec3 lightDir, vec3 lightColor, vec3 fogTint){
  float steps = float(VOLUMETRIC_STEPS);
  float maxDist = min(viewDistance, shadowDistance * 0.9);
  if (maxDist <= 1.0) return vec3(0.0);

  float g = 0.55;
  float mu = dot(rayDir, lightDir);
  float phase = (1.0 - g * g) / (4.0 * SW_PI * pow(1.0 + g * g - 2.0 * g * mu, 1.5));
  phase *= 4.0;

  float jitter = hash12(gl_FragCoord.xy + float(frameCounter) * 0.37);
  float stepLen = maxDist / steps;
  float transmittance = 1.0;
  vec3 scatter = vec3(0.0);

  for (int i = 0; i < 64; i++){
    if (float(i) >= steps) break;
    float t = (float(i) + jitter) * stepLen;
    vec3 absWorld = cameraPosition + rayDir * t;
    vec3 shadowSpace = worldToShadowSpace(absWorld);
    vec4 clip = shadowClip(shadowSpace);
    vec2 uv = clip.xy * 0.5 + 0.5;
    float lit = 1.0;
    if (insideShadowMap(uv)){
      float depth = clip.z * 0.5 + 0.5;
      lit = step(depth - 0.0015, texture(shadowtex0, uv).r);
    }
    float falloff = exp(-t * 0.012);
    scatter += lit * transmittance * falloff * stepLen * 0.02;
    transmittance *= 0.995;
  }

  vec3 c = lightColor * scatter * phase;
  return c + fogTint * scatter * 0.08;
}

// 云影: 天空云平面对地面的实时遮蔽
float cloudShadow(vec3 absWorld, vec3 lightDir){
  if (lightDir.y < 0.08) return 1.0;
  if (absWorld.y < -60.0 || absWorld.y > 320.0) return 1.0;
  float dist = length(absWorld - cameraPosition);
  if (dist > 240.0) return 1.0;

  float t = (160.0 - absWorld.y) / lightDir.y;
  if (t < 0.0 || t > 700.0) return 1.0;
  vec2 hit = absWorld.xz + lightDir.xz * t;
  float time = frameTimeCounter;
  vec2 drift = vec2(time * 1.6, time * 0.7);
  float cover = fbmPeriodic((hit + drift) * 0.004, 64.0);
  float density = saturate((cover - 0.48) * 3.0);
  return 1.0 - density * 0.78 * (1.0 - rainStrength * 0.5);
}

#endif
