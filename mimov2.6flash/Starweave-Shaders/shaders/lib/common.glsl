#ifndef SW_COMMON
#define SW_COMMON

#define SW_PI 3.14159265
#define SW_TAU 6.2831853

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform int isEyeInWater;
uniform float rainStrength;
uniform float wetness;
uniform float thunderStrength;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;
uniform int moonPhase;

// 从深度重建视图空间坐标
vec3 reconstructView(vec2 uv, float depth){
  vec4 clip = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
  vec4 view = gbufferProjectionInverse * clip;
  return view.xyz / view.w;
}

// 视图空间回到渲染管线的原始顶点空间
vec3 viewToWorldRaw(vec4 viewPos){
  return (gbufferModelViewInverse * viewPos).xyz;
}

vec3 viewToWorldRaw(vec3 viewPos){
  return viewToWorldRaw(vec4(viewPos, 1.0));
}

// 原始空间转绝对世界坐标(受设置开关控制)
vec3 rawToWorld(vec3 raw){
#if RAW_SPACE_IS_ABSOLUTE
  return raw;
#else
  return raw + cameraPosition;
#endif
}

// 绝对世界坐标转回阴影矩阵所需输入
vec3 worldToShadowSpace(vec3 absWorld){
#if RAW_SPACE_IS_ABSOLUTE
  return absWorld;
#else
  return absWorld - cameraPosition;
#endif
}

// 深度重建绝对世界坐标
vec3 worldPosFromDepth(vec2 uv, float depth){
  return rawToWorld(viewToWorldRaw(reconstructView(uv, depth)));
}

// 屏幕像素的世界视线方向
vec3 screenRayDir(vec2 uv){
  vec3 view = reconstructView(uv, 1.0);
  return normalize(mat3(gbufferModelViewInverse) * view);
}

// 视线方向转世界朝向(旋转部分)
vec3 viewDirToWorld(vec3 viewDir){
  return normalize(mat3(gbufferModelViewInverse) * viewDir);
}

float saturate(float x){ return clamp(x, 0.0, 1.0); }
vec3 saturate3(vec3 x){ return clamp(x, 0.0, 1.0); }

float hash12(vec2 p){
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p3){
  p3 = fract(p3 * 0.1031);
  p3 += dot(p3, p3.zyx + 31.32);
  return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p){
  vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.xx + p3.yz) * p3.zy);
}

// 标准二维值噪声
float vnoise(vec2 p){
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = hash12(i);
  float b = hash12(i + vec2(1.0, 0.0));
  float c = hash12(i + vec2(0.0, 1.0));
  float d = hash12(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 周期性值噪声, 用于无缝平铺的风场与云
float vnoisePeriodic(vec2 p, float period){
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  vec2 wrap = vec2(period);
  float a = hash12(mod(i, wrap));
  float b = hash12(mod(i + vec2(1.0, 0.0), wrap));
  float c = hash12(mod(i + vec2(0.0, 1.0), wrap));
  float d = hash12(mod(i + vec2(1.0, 1.0), wrap));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p){
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 5; i++){
    v += a * vnoise(p);
    p = p * 2.03 + vec2(17.7, 9.2);
    a *= 0.5;
  }
  return v;
}

float fbmPeriodic(vec2 p, float period){
  float v = 0.0;
  float a = 0.5;
  float per = period;
  for (int i = 0; i < 5; i++){
    v += a * vnoisePeriodic(p, per);
    p *= 2.0;
    per *= 2.0;
    a *= 0.5;
  }
  return v;
}

float luma(vec3 c){ return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

#endif
