#ifndef KILN_MATERIAL
#define KILN_MATERIAL

struct Material {
    vec3 albedo;
    vec3 normal;
    float roughness;
    float f0;
    float metal;
    float emission;
    float porosity;
    float subsurface;
    float ao;
    int id;
};

#define ID_NONE 0
#define ID_GRASS 1
#define ID_LEAVES 2
#define ID_WATER 3
#define ID_LAVA 4
#define ID_EMISSIVE 5
#define ID_METAL 6
#define ID_GLASS 7
#define ID_ICE 8
#define ID_SAND 9
#define ID_SNOW 10
#define ID_PLANKS 11
#define ID_STONE 12
#define ID_ORE 13
#define ID_WOOL 14
#define ID_CROP 15
#define ID_LANTERN 16
#define ID_FIRE 17
#define ID_PORTAL 18
#define ID_AMETHYST 19
#define ID_COPPER 20
#define ID_DEEPSLATE 21

uniform sampler2D normals;
uniform sampler2D specular;

vec3 decodeNormalMap(vec4 ntex, vec3 geomN, vec3 tangent, vec3 bitangent) {
    vec3 n = ntex.xyz * 2.0 - 1.0;
    if (length(ntex.xyz - vec3(0.5, 0.5, 1.0)) < 0.02) {
        return geomN;
    }
    n.xy *= 1.0;
    return normalize(tangent * n.x + bitangent * n.y + geomN * n.z);
}

Material makeMaterial(vec3 albedo, vec3 geomN, vec2 uv, int id, float vanillaAo) {
    Material m;
    m.albedo = albedo;
    m.normal = geomN;
    m.roughness = 0.72;
    m.f0 = R0_DIELECTRIC;
    m.metal = 0.0;
    m.emission = 0.0;
    m.porosity = 0.4;
    m.subsurface = 0.0;
    m.ao = vanillaAo;
    m.id = id;

    vec4 spec = texture2D(specular, uv);
    bool hasSpec = spec.r + spec.g + spec.b + spec.a > 0.001;
    if (hasSpec) {
        float perceptual = spec.r;
        m.roughness = sqr(1.0 - perceptual);
        float g = spec.g * 255.0;
        if (g < 230.0) {
            m.f0 = spec.g;
            m.metal = 0.0;
        } else if (g < 255.0) {
            m.metal = 1.0;
            m.f0 = 0.9;
        } else {
            m.metal = 1.0;
            m.f0 = luma(albedo);
        }
        float b = spec.b * 255.0;
        if (b <= 64.0) {
            m.porosity = b / 64.0;
            m.subsurface = 0.0;
        } else {
            m.porosity = 0.0;
            m.subsurface = (b - 65.0) / 190.0;
        }
        m.emission = spec.a < 0.996 ? spec.a : 0.0;
    }

    if (id == ID_GRASS || id == ID_LEAVES || id == ID_CROP) {
        m.subsurface = max(m.subsurface, 0.45);
        m.roughness = min(m.roughness, 0.62);
        m.porosity = max(m.porosity, 0.55);
    } else if (id == ID_WATER) {
        m.roughness = 0.04;
        m.f0 = 0.02;
        m.porosity = 0.0;
    } else if (id == ID_LAVA || id == ID_FIRE) {
        m.emission = max(m.emission, id == ID_LAVA ? 1.0 : 0.85);
        m.roughness = 0.35;
    } else if (id == ID_EMISSIVE || id == ID_LANTERN) {
        m.emission = max(m.emission, id == ID_LANTERN ? 0.9 : 0.75);
    } else if (id == ID_METAL || id == ID_COPPER) {
        m.metal = max(m.metal, 0.85);
        m.roughness = min(m.roughness, 0.35);
        m.f0 = max(m.f0, 0.7);
    } else if (id == ID_GLASS) {
        m.roughness = min(m.roughness, 0.06);
        m.f0 = 0.04;
    } else if (id == ID_ICE) {
        m.roughness = 0.08;
        m.f0 = 0.03;
        m.subsurface = 0.3;
    } else if (id == ID_SAND) {
        m.roughness = 0.9;
        m.porosity = 0.7;
    } else if (id == ID_SNOW) {
        m.roughness = 0.78;
        m.f0 = 0.02;
        m.subsurface = 0.25;
    } else if (id == ID_PLANKS) {
        m.roughness = 0.68;
        m.porosity = 0.5;
    } else if (id == ID_STONE || id == ID_DEEPSLATE) {
        m.roughness = 0.84;
        m.porosity = 0.25;
    } else if (id == ID_ORE) {
        m.roughness = 0.55;
        m.metal = 0.25;
        m.emission = max(m.emission, 0.04);
    } else if (id == ID_WOOL) {
        m.roughness = 0.95;
        m.subsurface = 0.15;
    } else if (id == ID_PORTAL) {
        m.emission = 0.7;
        m.roughness = 0.2;
    } else if (id == ID_AMETHYST) {
        m.roughness = 0.12;
        m.subsurface = 0.4;
        m.f0 = 0.06;
        m.emission = 0.05;
    }

    m.albedo = mix(m.albedo, m.albedo * m.albedo, m.metal);
    return m;
}

vec3 fresnelSchlick(float cosTheta, vec3 f0) {
    return f0 + (1.0 - f0) * pow(saturate(1.0 - cosTheta), 5.0);
}

float distributionGGX(float ndoth, float rough) {
    float a = rough * rough;
    float a2 = a * a;
    float d = ndoth * ndoth * (a2 - 1.0) + 1.0;
    return a2 / max(PI * d * d, 1e-5);
}

float geometrySmith(float ndotv, float ndotl, float rough) {
    float r = rough + 1.0;
    float k = (r * r) / 8.0;
    float gv = ndotv / (ndotv * (1.0 - k) + k);
    float gl = ndotl / (ndotl * (1.0 - k) + k);
    return gv * gl;
}

vec3 evaluateSpecular(Material m, vec3 n, vec3 v, vec3 l, vec3 lightColor) {
    vec3 h = normalize(v + l);
    float ndotl = saturate(dot(n, l));
    float ndotv = saturate(dot(n, v));
    float ndoth = saturate(dot(n, h));
    float vdoth = saturate(dot(v, h));
    vec3 f0 = mix(vec3(m.f0), m.albedo, m.metal);
    float d = distributionGGX(ndoth, max(m.roughness, 0.045));
    float g = geometrySmith(ndotv, ndotl, m.roughness);
    vec3 f = fresnelSchlick(vdoth, f0);
    vec3 spec = (d * g * f) / max(4.0 * ndotv * ndotl, 1e-4);
    return spec * lightColor * ndotl;
}

vec3 evaluateDiffuse(Material m, vec3 n, vec3 v, vec3 l, vec3 lightColor) {
    float ndotl = saturate(dot(n, l));
    float wrap = saturate((dot(n, l) + m.subsurface) / (1.0 + m.subsurface));
    vec3 f0 = mix(vec3(m.f0), m.albedo, m.metal);
    vec3 kd = (1.0 - fresnelSchlick(saturate(dot(n, v)), f0)) * (1.0 - m.metal);
    vec3 diffuse = m.albedo * kd * lightColor * mix(ndotl, wrap, m.subsurface) / PI;
    return diffuse;
}

vec3 shadeDirect(Material m, vec3 n, vec3 v, vec3 l, vec3 lightColor, float shadow) {
    return (evaluateDiffuse(m, n, v, l, lightColor) + evaluateSpecular(m, n, v, l, lightColor)) * shadow * m.ao;
}

#endif
