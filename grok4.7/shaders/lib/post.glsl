#ifndef KILN_POST
#define KILN_POST

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

vec3 decodeNormal(vec2 e) {
    vec2 f = e * 2.0 - 1.0;
    vec3 n = vec3(f, 1.0 - abs(f.x) - abs(f.y));
    if (n.z < 0.0) {
        n.xy = (1.0 - abs(n.yx)) * vec2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
    }
    return normalize(n);
}

vec2 encodeNormal(vec3 n) {
    float l1 = abs(n.x) + abs(n.y) + abs(n.z);
    vec2 e = n.xy / max(l1, 1e-5);
    if (n.z < 0.0) {
        e = (1.0 - abs(e.yx)) * vec2(e.x >= 0.0 ? 1.0 : -1.0, e.y >= 0.0 ? 1.0 : -1.0);
    }
    return e * 0.5 + 0.5;
}

Material materialFromGbuffer(vec2 uv) {
    vec4 g1 = texture2D(colortex1, uv);
    vec4 g2 = texture2D(colortex2, uv);
    vec4 g3 = texture2D(colortex3, uv);
    Material m;
    m.albedo = g1.rgb;
    m.normal = decodeNormal(g2.xy);
    m.roughness = g2.z;
    m.metal = g2.w;
    m.f0 = mix(R0_DIELECTRIC, luma(m.albedo), m.metal);
    m.emission = g3.r;
    m.subsurface = g3.g;
    m.ao = g3.b;
    m.porosity = g3.a;
    m.id = int(g1.a * 255.0 + 0.5);
    return m;
}

float blueNoise(vec2 pix) {
    return interleavedGradient(pix + float(frameCounter) * vec2(5.588238, 2.0));
}

vec3 bilateralFog(vec3 scene, vec3 fog, float depth, float centerDepth) {
    float w = smoothstep(centerDepth * 0.85, centerDepth * 1.4, depth);
    return mix(scene, fog, w);
}

#endif
