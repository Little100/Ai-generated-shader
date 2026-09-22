#ifndef SW_FINAL_CORE
#define SW_FINAL_CORE

uniform sampler2D colortex0;
#ifdef BLOOM
uniform sampler2D colortex4;
#endif
uniform sampler2D depthtex0;

in vec2 vUV;

// ACES 风格的电影感映射
vec3 tonemapACES(vec3 x){
  float a = 2.51;
  float b = 0.03;
  float c = 2.43;
  float d = 0.59;
  float e = 0.14;
  return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

vec3 sceneColorAt(vec2 uv){
  vec3 hdr = texture(colortex0, uv).rgb;
#ifdef BLOOM
  hdr += texture(colortex4, uv).rgb * BLOOM_STRENGTH;
#endif
  float depth = texture(depthtex0, uv).r;
  vec3 viewPos = reconstructView(uv, depth);
  float viewDistance = length(viewPos);
  if (isEyeInWater == 1){
    hdr *= exp(-viewDistance * vec3(0.3, 0.07, 0.05));
  } else if (isEyeInWater == 2){
    hdr *= exp(-viewDistance * vec3(0.06, 0.28, 0.7));
  }
  return hdr * EXPOSURE;
}

void main(){
  vec3 hdr = sceneColorAt(vUV);
  vec3 color = tonemapACES(hdr);

#ifdef FXAA
  // 轻量边缘抗锯齿: 依据亮度突变向邻域混合
  vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
  vec3 hdrL = sceneColorAt(vUV + vec2(-texel.x, 0.0));
  vec3 hdrR = sceneColorAt(vUV + vec2(texel.x, 0.0));
  vec3 hdrU = sceneColorAt(vUV + vec2(0.0, texel.y));
  vec3 hdrD = sceneColorAt(vUV + vec2(0.0, -texel.y));
  float lC = luma(hdr);
  float edge = abs(luma(hdrL) - lC) + abs(luma(hdrR) - lC)
             + abs(luma(hdrU) - lC) + abs(luma(hdrD) - lC);
  float blend = saturate((edge - 0.12) * 4.5) * 0.55;
  vec3 avg = (tonemapACES(hdrL) + tonemapACES(hdrR) + tonemapACES(hdrU) + tonemapACES(hdrD)) * 0.25;
  color = mix(color, avg, blend);
#endif

  // 冷阴影暖高光的轻微分调
  float l = luma(color);
  color += vec3(0.0, 0.004, 0.012) * (1.0 - l);
  color += vec3(0.014, 0.005, -0.006) * smoothstep(0.55, 1.0, l);
  color = mix(vec3(l), color, 1.06);

#ifdef VIGNETTE
  vec2 q = vUV - 0.5;
  float vig = 1.0 - smoothstep(0.42, 0.95, length(q) * 1.35);
  color *= mix(1.0, vig, 0.4);
#endif

  // 末端抖动消除色带
  color += (hash12(gl_FragCoord.xy + float(frameCounter)) - 0.5) / 255.0;

  gl_FragData[0] = vec4(saturate3(color), 1.0);
}

#endif
