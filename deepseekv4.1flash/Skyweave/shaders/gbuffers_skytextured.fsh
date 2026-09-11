#version 330 compatibility

/*
    The vanilla sun and moon quads are dropped. Both bodies are drawn
    analytically by the sky shader instead, with real limb darkening and a real
    terminator, so anything drawn here would land on top of them.
*/

void main() {
    discard;
}
