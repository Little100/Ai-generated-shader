/*
    The vertex stage every post processing pass shares.

    Iris maps Position to a unit quad and UV0 to its texture coordinates, so
    this reduces to a straight copy of the quad corner.
*/

#if !defined(SKYWEAVE_FULLSCREEN_INCLUDED)
#define SKYWEAVE_FULLSCREEN_INCLUDED

out vec2 texcoord;

void main() {
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0.xy;
}

#endif
