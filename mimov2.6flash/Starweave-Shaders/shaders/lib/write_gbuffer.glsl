#ifndef SW_WRITE_GBUFFER
#define SW_WRITE_GBUFFER

// G缓冲布局: 原色+方块光等级, 世界法线+天空光等级, 板质参数+AO
void writeGbuffer(vec3 albedo, float blockLevel, float skyLevel, vec3 worldN, float smoothness, float metalness, float emissive, float ao){
  gl_FragData[0] = vec4(albedo, blockLevel);
  gl_FragData[1] = vec4(normalize(worldN) * 0.5 + 0.5, skyLevel);
  gl_FragData[2] = vec4(smoothness, metalness, emissive, clamp(ao, 0.0, 1.0));
}

#endif
