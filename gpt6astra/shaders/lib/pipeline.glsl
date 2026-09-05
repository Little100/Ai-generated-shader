#ifndef TIDELUME_PIPELINE
#define TIDELUME_PIPELINE
// 0: linear HDR scene, later display color; 1: world normal + surface flag.
// 4: immutable, fogged opaque snapshot for translucent refraction / SSR.
// 5,6: half-resolution bloom ping-pong; 7: half-resolution rays + view depth.
// Iris metadata: symbolic format names are NOT GLSL identifiers.
// Keep each directive on its own line inside this block comment.
/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16F;
const int colortex4Format = RGBA16F;
const int colortex5Format = RGBA16F;
const int colortex6Format = RGBA16F;
const int colortex7Format = RGBA16F;
*/
const bool colortex0Clear = true;
const bool colortex1Clear = true;
const bool colortex4Clear = true;
const bool colortex5Clear = true;
const bool colortex6Clear = true;
const bool colortex7Clear = true;
// Iris parses ClearColor directives, not arbitrary GLSL constructors.
// Spell all four components out even when they are identical.
const vec4 colortex0ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex1ClearColor = vec4(0.5,0.5,0.5,0.0);
const vec4 colortex4ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex7ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
#endif
