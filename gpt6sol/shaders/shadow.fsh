#version 330 compatibility

uniform sampler2D texture;
in vec2 vUv;
in float vBlockId;

void main() {
    if (abs(vBlockId - 10020.0) < 0.5) discard;
    vec4 albedo = texture2D(texture, vUv);
    if (albedo.a < 0.5) discard;
    gl_FragColor = vec4(1.0);
}
