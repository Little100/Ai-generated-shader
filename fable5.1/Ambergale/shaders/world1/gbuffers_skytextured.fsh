#version 330 compatibility
#define DIM_END

// Sun and moon textures are disabled in shaders.properties; this only handles custom sky textures

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/materials.glsl"

in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outAlbedo;

void main() {
    vec4 c = texture(gtexture, texcoord) * glcolor;
    if (c.a < 0.01) discard;
    outAlbedo = vec4(c.rgb * c.a * 0.4, 1.0);
}
