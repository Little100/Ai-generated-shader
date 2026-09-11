/*
    Skyweave - the uniform block shared by every program.

    Iris supplies all of these; the file exists so that the declaration is
    written once and every include sees the same type. Samplers that only a
    single pass needs are declared next to the code that reads them, which keeps
    the texture unit count reasonable.

    Every name here was checked against the Iris uniform registry, so anything
    that would silently read back as zero was left out on purpose.
*/

#if !defined(SKYWEAVE_UNIFORMS_INCLUDED)
#define SKYWEAVE_UNIFORMS_INCLUDED

/*  matrices  */

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

/*  camera  */

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 eyePosition;
uniform vec3 relativeEyePosition;
uniform vec3 playerLookVector;
uniform vec3 playerBodyVector;
uniform vec3 upPosition;
uniform float eyeAltitude;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform float centerDepthSmooth;

/*  celestial  */

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;
uniform float sunAngle;
uniform float shadowAngle;
uniform int moonPhase;

/*  world and weather  */

uniform int worldTime;
uniform int worldDay;
uniform float frameTimeCounter;
uniform float frameTime;
uniform int frameCounter;
uniform float rainStrength;
uniform float wetness;
uniform float thunderStrength;
uniform vec4 lightningBoltPosition;
uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogStart;
uniform float fogEnd;
uniform int fogMode;
uniform float fogShape;

/*  biome and dimension  */

uniform int biome;
uniform int biome_category;
uniform int biome_precipitation;
uniform float temperature;
uniform float rainfall;
uniform bool hasSkylight;
uniform bool hasCeiling;
uniform int seaLevel;
uniform float cloudHeight;

/*  player state  */

uniform int isEyeInWater;
uniform float blindness;
uniform float darknessFactor;
uniform float darknessLightFactor;
uniform float nightVision;
uniform float playerMood;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform vec3 heldBlockLightColor;
uniform vec3 heldBlockLightColor2;
uniform vec4 entityColor;
uniform float alphaTestRef;
uniform int renderStage;

/*  screen  */

uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float screenBrightness;

/*  identifiers  */

uniform int entityId;
uniform int blockEntityId;
uniform int heldItemId;
uniform int heldItemId2;

/*  base textures, cheap enough to keep everywhere  */

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D noisetex;

#endif
