#version 330 compatibility

/*
    The sky dome. The vanilla sky geometry is ignored entirely: the view
    direction is rebuilt from the screen position and the inverse projection,
    which behaves the same for the dome, the horizon strip and the void plane
    and never leaves a seam where the vanilla boxes meet.
*/

#include "/lib/buffers.glsl"
#include "/lib/sky.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outScene;

void main() {
    vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);

    vec3 viewDir = normalize(screenToView(uv, 1.0, gbufferProjectionInverse));
    vec3 worldDir = mat3(gbufferModelViewInverse) * viewDir;

    vec3 sky = renderSkyForDimension(worldDir, normalize(sunPosition), normalize(moonPosition), eyeAltitude);

    outScene = vec4(sky, 1.0);
}
