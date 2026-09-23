#ifndef KOMOREBI_MATERIAL
#define KOMOREBI_MATERIAL

#include "/lib/atmosphere.glsl"

// 材质分类, 把方块归类为若干槽位, 每个槽位对应一组表面参数

struct MaterialInfo {
    int slot;
    float roughness;
    float metalness;
    float emissive;
    float subsurface;
    float waveAmount;
    float aoBias;
    float normalStrength;
};

MaterialInfo materialDefaults() {
    MaterialInfo m;
    m.slot = SLOT_NONE;
    m.roughness = 0.82;
    m.metalness = 0.0;
    m.emissive = 0.0;
    m.subsurface = 0.0;
    m.waveAmount = 0.0;
    m.aoBias = 0.0;
    m.normalStrength = 0.7;
    return m;
}

// mc_Entity.x 的取值来自 block.properties, 渲染类型用于识别流体
MaterialInfo materialFromBlock(float blockId, float renderType, vec2 lightmap, vec3 albedo) {
    MaterialInfo m = materialDefaults();
    float albedoLuma = luminance(albedo);

    // 流体优先判定, 这样即使方块表缺失水依然正确
    if (renderType > 0.5 && renderType < 1.5) {
        m.slot = SLOT_WATER;
        m.roughness = 0.03;
        return m;
    }

    int slot = int(blockId + 0.5);
    if (slot == SLOT_FOLIAGE) {
        m.slot = SLOT_FOLIAGE;
        m.roughness = 0.66;
        m.subsurface = 0.9;
        m.waveAmount = 1.0;
        m.aoBias = 0.25;
        m.normalStrength = 1.1;
    } else if (slot == SLOT_WATER) {
        m.slot = SLOT_WATER;
        m.roughness = 0.03;
    } else if (slot == SLOT_GLASS) {
        m.slot = SLOT_GLASS;
        m.roughness = 0.06;
        m.aoBias = 0.35;
        m.normalStrength = 0.0;
    } else if (slot == SLOT_METAL) {
        m.slot = SLOT_METAL;
        m.roughness = 0.26;
        m.metalness = 0.85;
        m.aoBias = 0.15;
        m.normalStrength = 0.4;
    } else if (slot == SLOT_EMISSIVE) {
        m.slot = SLOT_EMISSIVE;
        m.roughness = 0.5;
        m.emissive = 1.0;
        m.normalStrength = 0.0;
    } else if (slot == SLOT_SAND) {
        m.slot = SLOT_SAND;
        m.roughness = 0.93;
        m.normalStrength = 0.45;
    } else if (slot == SLOT_SNOW) {
        m.slot = SLOT_SNOW;
        m.roughness = 0.6;
        m.subsurface = 0.6;
        m.normalStrength = 0.35;
    } else if (slot == SLOT_WOOD) {
        m.slot = SLOT_WOOD;
        m.roughness = 0.78;
    } else if (slot == SLOT_PLANT) {
        m.slot = SLOT_PLANT;
        m.roughness = 0.7;
        m.subsurface = 0.62;
        m.waveAmount = 1.0;
        m.aoBias = 0.2;
        m.normalStrength = 0.9;
    } else if (slot == SLOT_ENTITY) {
        m.slot = SLOT_ENTITY;
        m.roughness = 0.62;
        m.subsurface = 0.4;
        m.normalStrength = 0.4;
    }

    // 浅色金属更接近自身颜色, 深色金属反射环境更多
    m.metalness = clamp(m.metalness + albedoLuma * 0.05, 0.0, 1.0);

    // 方块表缺失时按光照贴图推断自发光
    if (m.emissive < 0.5 && lightmap.x > 0.62 && lightmap.y < 0.12) {
        m.emissive = clamp((lightmap.x - 0.62) * 2.2, 0.0, 1.0);
    }
    // 被雨淋湿的表面降低粗糙度
    if (rainStrength > 0.01 && m.slot != SLOT_EMISSIVE) {
        m.roughness = mix(m.roughness, m.roughness * 0.45, wetness * 0.5);
    }
    return m;
}

// 由几何法线推断切线基, 供细节法线使用
void buildTangentBasis(vec3 normal, out vec3 tangent, out vec3 bitangent) {
    vec3 up = abs(normal.y) < 0.92 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    tangent = normalize(cross(up, normal));
    bitangent = cross(normal, tangent);
}

// 用世界坐标做一层细微的凹凸扰动, 让平面不至于死板
vec3 surfaceDetailNormal(vec3 normal, vec3 worldPos, float strength, int slot) {
    if (strength <= 0.001) return normal;
    vec3 t, b;
    buildTangentBasis(normal, t, b);
    float scale = slot == SLOT_SAND ? 6.0 : (slot == SLOT_SNOW ? 9.0 : 4.0);
    float h = valueNoise3(worldPos * scale);
    float hx = valueNoise3(worldPos * scale + t * 0.12);
    float hy = valueNoise3(worldPos * scale + b * 0.12);
    vec2 grad = vec2(hx - h, hy - h) * 6.0 * strength * 0.3;
    return normalize(normal - t * grad.x - b * grad.y);
}

#endif
