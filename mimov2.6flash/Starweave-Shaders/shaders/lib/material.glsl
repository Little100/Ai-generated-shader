#ifndef SW_MATERIAL
#define SW_MATERIAL

// 材质约定: R 平滑度 G 金属度 B 自发光强度
struct MatData {
  float smoothness;
  float metalness;
  float emissive;
};

uniform sampler2D specular;

MatData readMaterial(vec2 uv, float entityId){
  vec4 s = texture(specular, uv);
  MatData m;
  m.smoothness = s.r;
  m.metalness = s.g;
  m.emissive = s.b;
  if (entityId == 10000){
    m.emissive = max(m.emissive, 1.35);
  } else if (entityId == 10001){
    m.emissive = max(m.emissive, 0.95);
  } else if (entityId == 10201){
    m.smoothness = max(m.smoothness, 0.88);
    m.metalness = 0.0;
  } else if (entityId == 10202){
    m.smoothness = max(m.smoothness, 0.8);
    m.metalness = 0.0;
  }
  m.smoothness = saturate(m.smoothness);
  m.metalness = saturate(m.metalness);
  m.emissive = max(m.emissive, 0.0);
  return m;
}

#endif
