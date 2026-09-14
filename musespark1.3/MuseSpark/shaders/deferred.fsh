#version 330 compatibility
// 延迟光照计算阴影天空雾水体
#include "lib/muse_settings.glsl"
#include "lib/muse_common.glsl"
#include "lib/muse_light.glsl"
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float sunAngle;
uniform float rainStrength;
uniform float frameTimeCounter;
in vec2 vUv;
layout(location = 0) out vec4 oLit;
/* RENDERTARGETS: 0 */
// 屏幕转玩家空间坐标
vec3 museViewPos(vec2 uv, float depth) {
  vec4 ndc = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
  vec4 view = gbufferProjectionInverse * ndc;
  return view.xyz / view.w;
}
// 九宫格柔和阴影采样
float museShadow(vec3 playerPos, vec3 nrm, vec3 sunDir) {
  vec4 sp = shadowProjection * (shadowModelView * vec4(playerPos, 1.0));
  sp.xyz /= sp.w;
  vec3 suv = sp.xyz * 0.5 + 0.5;
  if (suv.x < 0.001 || suv.x > 0.999 || suv.y < 0.001 || suv.y > 0.999) {
    return 1.0;
  }
  float bias = mix(0.0016, 0.004, clamp(1.0 - abs(dot(nrm, sunDir)), 0.0, 1.0));
  float acc = 0.0;
  float wsum = 0.0;
  float stepPx = SHADOW_RES_INV * SHADOW_SOFT;
  for (int ix = -1; ix <= 1; ix++) {
    for (int iy = -1; iy <= 1; iy++) {
      vec2 off = vec2(float(ix), float(iy)) * stepPx;
      float w = (ix == 0 && iy == 0) ? 4.0 : 1.0;
      vec2 suvOff = suv.xy + off;
      float opaqueDepth = texture(shadowtex1, suvOff).x;
      float allDepth = texture(shadowtex0, suvOff).x;
      float litOpaque = step(suv.z - bias, opaqueDepth);
      float litAll = step(suv.z - bias, allDepth);
      vec4 tintCol = texture(shadowcolor0, suvOff);
      float tinted = clamp(litOpaque - litAll, 0.0, 1.0);
      float tintLuma = clamp(dot(tintCol.rgb, vec3(0.333)) * 0.7 + tintCol.a * 0.3, 0.15, 1.0);
      float sampleLit = mix(litAll, litOpaque * tintLuma, tinted);
      acc += sampleLit * w;
      wsum += w;
    }
  }
  return clamp(acc / max(wsum, 1.0), 0.0, 1.0);
}
void main() {
  vec4 albedo = texture(colortex0, vUv);
  vec4 data = texture(colortex1, vUv);
  vec4 encN = texture(colortex2, vUv);
  float depth = texture(depthtex0, vUv).x;
  if (depth >= 1.0) {
    float rainF = clamp(rainStrength, 0.0, 1.0);
    float dayF = clamp(sin(sunAngle * 6.2831853) * 0.5 + 0.5, 0.0, 1.0);
    dayF = smoothstep(0.02, 0.25, dayF);
    vec3 viewDir = normalize(museViewPos(vUv, 1.0));
    vec3 playerDir = normalize((gbufferModelViewInverse * vec4(viewDir, 0.0)).xyz);
    vec3 sunDir = normalize((gbufferModelViewInverse * vec4(normalize(sunPosition), 0.0)).xyz);
    vec3 moonDir = normalize((gbufferModelViewInverse * vec4(normalize(moonPosition), 0.0)).xyz);
    vec3 sky = museSkyGrad(playerDir, sunDir, moonDir, dayF, rainF);
    float nightF = 1.0 - dayF;
    sky += vec3(0.9, 0.95, 1.0) * museStars(playerDir, nightF * (1.0 - rainF), vec2(frameTimeCounter * 0.05, frameTimeCounter * 0.03));
    float cover = clamp(CLOUD_COVER + rainF * 0.35, 0.0, 1.0);
    if (playerDir.y > 0.01 && cover > 0.01) {
      vec2 cuv = playerDir.xz / max(playerDir.y, 0.12);
      float t = frameTimeCounter * 0.008;
      float cl = museFbm(cuv * 1.4 + vec2(t, t * 0.6));
      float cmask = smoothstep(1.0 - cover * 0.85, 1.05 - cover * 0.55, cl);
      float shade = museFbm(cuv * 2.6 - vec2(t * 1.4, 0.0));
      vec3 cloudCol = mix(vec3(0.62, 0.66, 0.74), vec3(1.02, 1.0, 0.98), dayF);
      cloudCol *= 0.75 + 0.5 * shade;
      cloudCol = mix(cloudCol, vec3(0.4, 0.43, 0.48), rainF * 0.55);
      float edge = smoothstep(0.0, 0.25, playerDir.y);
      sky = mix(sky, cloudCol, cmask * edge * 0.9);
    }
    oLit = vec4(sky, 1.0);
    return;
  }
  vec3 viewPos = museViewPos(vUv, depth);
  vec3 playerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 nrm = normalize(encN.rgb * 2.0 - 1.0);
  float flag = floor(data.a * 9.0 + 0.5);
  float skyLm = clamp(data.x, 0.0, 1.0);
  float blkLm = clamp(data.y, 0.0, 1.0);
  float emi = clamp(data.z, 0.0, 1.0);
  float rainF = clamp(rainStrength, 0.0, 1.0);
  float dayRaw = sin(sunAngle * 6.2831853) * 0.5 + 0.5;
  float dayF = smoothstep(0.02, 0.25, dayRaw);
  float nightF = 1.0 - dayF;
  vec3 sunDir = normalize((gbufferModelViewInverse * vec4(normalize(sunPosition), 0.0)).xyz);
  float sunH = clamp(sunDir.y, -1.0, 1.0);
  vec3 sunTint = museSunTint(sunH);
  float ndl = clamp(dot(nrm, sunDir), 0.0, 1.0);
  float shade = museShadow(playerPos, nrm, sunDir);
  float skyDiff = clamp(nrm.y * 0.5 + 0.5, 0.0, 1.0);
  vec3 skyAmb = mix(vec3(0.10, 0.14, 0.22), vec3(0.55, 0.68, 0.85), dayF);
  skyAmb = mix(skyAmb, vec3(0.35, 0.38, 0.42), rainF * 0.6);
  float torch = blkLm * blkLm * 2.1;
  vec3 torchCol = vec3(1.0, 0.55, 0.25) * torch;
  float skyL = skyLm * skyLm;
  vec3 dayLight = sunTint * (ndl * shade * 2.4 + skyDiff * 0.35) * skyL * dayF;
  vec3 moonLight = vec3(0.35, 0.5, 0.8) * (ndl * shade * 0.35 + skyDiff * 0.08) * skyL * nightF;
  vec3 amb = skyAmb * (0.25 + 0.75 * skyL) * (0.35 + 0.65 * dayF + 0.25 * nightF);
  vec3 col = albedo.rgb * (dayLight + moonLight + amb + torchCol);
  col += albedo.rgb * emi * 1.6;
  if (abs(flag - 7.0) < 0.5 || abs(flag - 8.0) < 0.5) {
    col = albedo.rgb;
  }
  if (abs(flag - 4.0) < 0.5) {
    vec3 worldPos = playerPos + cameraPosition;
    float ca = museCaustic(worldPos, frameTimeCounter);
    vec3 vDir = normalize(playerPos);
    vec3 rDir = reflect(vDir, normalize(nrm + vec3(ca * 0.25 - 0.125, 0.0, ca * 0.2 - 0.1)));
    float dayMix = clamp(dayF, 0.0, 1.0);
    vec3 sunR = normalize((gbufferModelViewInverse * vec4(normalize(sunPosition), 0.0)).xyz);
    vec3 moonR = normalize((gbufferModelViewInverse * vec4(normalize(moonPosition), 0.0)).xyz);
    vec3 rSky = museSkyGrad(normalize(rDir), sunR, moonR, dayMix, rainF);
    float fres = pow(1.0 - clamp(dot(-vDir, nrm), 0.0, 1.0), 3.0) * 0.85 + 0.15;
    vec3 waterBody = albedo.rgb * (0.35 + 0.65 * (dayLight + moonLight + amb + torchCol));
    col = mix(waterBody, rSky, clamp(fres, 0.0, 1.0) * 0.85);
    col += vec3(0.5, 0.75, 0.9) * ca * (0.25 + 0.75 * dayMix) * skyL;
    col += albedo.rgb * emi;
  }
  vec3 mistCol = mix(vec3(0.10, 0.13, 0.20), mix(vec3(0.72, 0.80, 0.88), vec3(0.95, 0.68, 0.52), clamp(1.0 - abs(sunH) * 2.2, 0.0, 1.0) * dayF), dayF);
  mistCol = mix(mistCol, vec3(0.45, 0.48, 0.52), rainF * 0.6);
  float mistF = museMistF(playerPos, playerPos.y + cameraPosition.y, MIST_AMOUNT);
  if (abs(flag - 7.0) < 0.5 || abs(flag - 8.0) < 0.5) {
    mistF *= 0.15;
  }
  col = mix(col, mistCol, mistF);
  oLit = vec4(col, albedo.a);
}
