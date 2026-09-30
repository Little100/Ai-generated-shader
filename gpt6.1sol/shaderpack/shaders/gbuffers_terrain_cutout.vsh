#version 330 compatibility

out vec2 awTexcoord;
out vec2 awLightcoord;
out vec4 awVertexColor;
out vec3 awNormal;
out vec3 awViewPosition;

void main() {
    vec4 awView = gl_ModelViewMatrix * gl_Vertex;
    gl_Position = gl_ProjectionMatrix * awView;
    awTexcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    awLightcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    awVertexColor = gl_Color;
    awNormal = normalize(gl_NormalMatrix * gl_Normal);
    awViewPosition = awView.xyz;
}
