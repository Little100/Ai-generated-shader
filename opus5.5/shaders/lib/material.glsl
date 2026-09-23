#ifndef KOMOREBI_MATERIAL
#define KOMOREBI_MATERIAL

#include "/lib/common.glsl"
#include "/lib/noise.glsl"

// 由 mc_Entity.x 得到材质号, 方块清单在 block.properties 中维护
struct MaterialInfo {
    int id;
    float roughness;
    float metalness;
    float emissive;
    float subsurface;
    float waveAmount;
    vec3 specularTint;
    float aoBias;
    float normalStrength;
};

// mc_Entity.x 的取值来自 block.properties, 编号与材质语义一一对应
MaterialInfo materialFromBlock(float blockId, float renderType, vec2 lightmap, vec3 albedo) {
    MaterialInfo m;
    m.id = MATERIAL_DEFAULT;
    m.roughness = 0.82;
    m.metalness = 0.0;
    m.emissive = 0.0;
    m.subsurface = 0.0;
    m.waveAmount = 0.0;
    m.specularTint = vec3(1.0);
    m.aoBias = 0.0;
    m.normalStrength = 1.0;

    // 流体渲染类型单独处理, 即使方块表缺失也能识别出水
    if (renderType > 0.5 && renderType < 1.5) {
        m.id = MATERIAL_WATER;
        m.roughness = 0.03;
        m.specularTint = vec3(0.92, 0.97, 1.0);
        return m;
    }

    int id = int(blockId + 0.5);
    if (id == 1) {
        m.id = MATERIAL_FOLIAGE;
        m.roughness = 0.66;
        m.subsurface = 0.9;
        m.waveAmount = 1.0;
        m.aoBias = 0.25;
        m.normalStrength = 1.4;
    } else if (id == 2) {
        m.id = MATERIAL_WATER;
        m.roughness = 0.03;
        m.specularTint = vec3(0.92, 0.97, 1.0);
    } else if (id == 3) {
        m.id = MATERIAL_GLASS;
        m.roughness = 0.06;
        m.aoBias = 0.35;
    } else if (id == 4) {
        m.id = MATERIAL_METAL;
        m.roughness = 0.26;
        m.metalness = 0.85;
        m.specularTint = albedo * 0.85 + 0.15;
        m.aoBias = 0.15;
    } else if (id == 5) {
        m.id = MATERIAL_EMISSIVE;
        m.roughness = 0.5;
        m.emissive = 1.0;
    } else if (id == 6) {
        m.id = MATERIAL_SAND;
        m.roughness = 0.93;
        m.normalStrength = 0.65;
    } else if (id == 7) {
        m.id = MATERIAL_SNOW;
        m.roughness = 0.6;
        m.subsurface = 0.6;
        m.normalStrength = 0.5;
    } else if (id == 8) {
        m.id = MATERIAL_WOOD;
        m.roughness = 0.78;
    } else if (id == 9) {
        m.id = MATERIAL_FOLIAGE;
        m.roughness = 0.7;
        m.subsurface = 0.62;
        m.waveAmount = 1.0;
        m.aoBias = 0.2;
        m.normalStrength = 1.2;
    }

    // 方块表缺失时按光照贴图推断自发光
    if (m.emissive < 0.5 && lightmap.x > 0.62 && lightmap.y < 0.12) {
        m.emissive = clamp((lightmap.x - 0.62) * 2.2, 0.0, 1.0);
    }
    // 被雨淋湿的表面降低粗糙度
    if (rainStrength > 0.01 && m.id != MATERIAL_EMISSIVE) {
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
vec3 surfaceDetailNormal(vec3 normal, vec3 worldPos, float strength, int material) {
    if (strength <= 0.001) return normal;
    vec3 t, b;
    buildTangentBasis(normal, t, b);
    float scale = material == MATERIAL_SAND ? 6.0 : (material == MATERIAL_SNOW ? 9.0 : 4.0);
    float h = valueNoise3(worldPos * scale, 2);
    float hx = valueNoise3(worldPos * scale + t * 0.12, 2);
    float hy = valueNoise3(worldPos * scale + b * 0.12, 2);
    vec2 grad = vec2(hx - h, hy - h) * 6.0 * strength * 0.35;
    return normalize(normal - t * grad.x - b * grad.y);
}

#endif
