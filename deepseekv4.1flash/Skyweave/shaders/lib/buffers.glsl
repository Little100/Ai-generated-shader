/*
    Skyweave - render target declarations.

    Iris reads these directives from the fragment source, so this file is pulled
    into every .fsh. The values are identical everywhere on purpose: a
    conflicting declaration across files would make the option ambiguous.

    Layout

      colortex0   linear hdr scene colour, opaque geometry only
      colortex1   albedo in rgb, material identifier in alpha
      colortex2   world normal in rgb, smoothness in alpha
      colortex3   block light, sky light, direct light visibility, occlusion
      colortex4   water surface colour and coverage
      colortex5   water surface normal and roughness
      colortex6   bloom ping
      colortex7   bloom pong
      colortex8   bright pass and light shafts
      colortex9   measured exposure, one texel, survives the frame
      colortex10  previous exposure, one texel, survives the frame
      colortex11  depth of field scratch
*/

#if !defined(SKYWEAVE_BUFFERS_INCLUDED)
#define SKYWEAVE_BUFFERS_INCLUDED

// Iris reads the format names as strings, but glsl needs them to be values
#define RGBA 0
#define RGB8 1
#define RGBA8 2
#define RGB16F 3
#define RGBA16F 4
#define RGB32F 5
#define RGBA32F 6
#define R11F_G11F_B10F 7
#define RGB10_A2 8

const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16F;
const int colortex2Format = RGBA16F;
const int colortex3Format = RGBA16F;
const int colortex4Format = RGBA16F;
const int colortex5Format = RGBA16F;
const int colortex6Format = RGBA16F;
const int colortex7Format = RGBA16F;
const int colortex8Format = RGBA16F;
const int colortex9Format = RGBA16F;
const int colortex10Format = RGBA16F;
const int colortex11Format = RGBA16F;

const bool colortex0Clear = true;
const bool colortex1Clear = true;
const bool colortex2Clear = true;
const bool colortex3Clear = true;
const bool colortex4Clear = true;
const bool colortex5Clear = true;
const bool colortex6Clear = false;
const bool colortex7Clear = false;
const bool colortex8Clear = false;
const bool colortex9Clear = false;
const bool colortex10Clear = false;
const bool colortex11Clear = false;

const vec4 colortex0ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex2ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const vec4 colortex3ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex4ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex5ClearColor = vec4(0.0, 0.0, 0.0, 0.0);

#endif
