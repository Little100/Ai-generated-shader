#version 330 compatibility

uniform sampler2D gtexture;

in vec2 awShadowTexcoord;

void main() {
    if (texture2D(gtexture, awShadowTexcoord).a < 0.08) {
        discard;
    }
    gl_FragColor = vec4(1.0);
}
