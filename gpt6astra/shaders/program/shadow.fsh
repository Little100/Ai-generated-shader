#include "/lib/settings.glsl"
uniform sampler2D gtexture;
in vec2 vUV;
in vec4 vColor;
flat in float vMaterial;
/* RENDERTARGETS: 0 */
// Iris-only metadata, not executable GLSL.
/*
const int shadowcolor0Format = RGBA8;
*/
const bool shadowcolor0Clear = true;
const vec4 shadowcolor0ClearColor = vec4(1.0,1.0,1.0,0.0);
void main() {
    vec4 color = texture(gtexture,vUV)*vColor;
    // Let sun enter water. Receiver absorption is computed from actual scene depth.
    if (vMaterial == 10000.0) discard;
    if (color.a<0.10) discard;
    if (vMaterial == 10030.0) {
        // Preserve the stained texture's hue, not its very small vanilla opacity.
        float peak = max(max(color.r,color.g),max(color.b,0.001));
        gl_FragData[0] = vec4(mix(vec3(1.0),color.rgb/peak,0.80),0.78);
    } else {
        gl_FragData[0] = vec4(color.rgb,color.a);
    }
}
