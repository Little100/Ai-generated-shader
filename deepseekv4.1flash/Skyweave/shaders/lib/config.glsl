/*
    Skyweave - user facing options.

    Every option is declared here exactly once and always with the same macro
    name, because Iris requires a macro to be defined identically in every
    translation unit that reads it. Programs pull this file in before doing
    anything else.

    The bracket list in the trailing comment is what turns a numeric macro into
    a slider in the shader settings screen, and the text after it becomes the
    hover tooltip.
*/

#if !defined(SKYWEAVE_CONFIG_INCLUDED)
#define SKYWEAVE_CONFIG_INCLUDED

/*  quality  */

// shadow map resolution is a fixed const below, this picks the frustum size
#define SHADOW_DISTANCE 2 // [0 1 2 3] 0 = 64, 1 = 128, 2 = 192, 3 = 256 blocks

// shadow filtering effort
#define SHADOW_FILTER 1 // [0 1 2] 0 = hard, 1 = soft, 2 = very soft

// penumbra growth with blocker distance for the soft shadow filters
#define SHADOW_SOFTNESS 1.0 // [0.0 0.25 0.5 1.0 1.5 2.0 3.0]

// screen space ambient occlusion effort, 0 disables it
#define SSAO_QUALITY 2 // [0 1 2 3]

// strength of the ambient occlusion term
#define SSAO_STRENGTH 1.0 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0]

// volumetric light shaft effort, 0 disables them
#define VOLUMETRIC_QUALITY 2 // [0 1 2 3]

// light shaft brightness multiplier
#define VOLUMETRIC_STRENGTH 1.0 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0 3.0]

// ray sample count used by the atmosphere model for the sky dome
#define SKY_QUALITY 2 // [1 2 3] 1 = fast, 2 = balanced, 3 = precise

// how many steps the cloud lighting integrates through the cloud volume
#define CLOUD_QUALITY 2 // [0 1 2 3]

// bloom glow strength
#define BLOOM_STRENGTH 0.85 // [0.0 0.25 0.5 0.75 0.85 1.0 1.5 2.0]

// depth of field, blurring everything away from the focal plane
// #define DEPTH_OF_FIELD // enable the depth of field pass

// depth of field blur radius
#define DOF_STRENGTH 0.35 // [0.1 0.25 0.35 0.5 0.75 1.0]

/*  sky  */

// render the atmosphere scattering model instead of the vanilla sky
#define SKY_ATMOSPHERE // draw the sky with a physical scattering model

// render the sun as a physical disc with limb darkening
#define SKY_SUN // draw a physical sun disc

// render the moon with phase and earthshine
#define SKY_MOON // draw the moon

// procedural star field
#define SKY_STARS // draw stars

// the galactic band across the night sky
#define SKY_GALAXY // draw the milky way band

// aurora curtains on cold night skies
#define SKY_AURORA // draw aurora

// aurora brightness
#define AURORA_STRENGTH 1.0 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0 3.0]

// how often aurora appears, 0 never and 1 every clear night
#define AURORA_FREQUENCY 0.5 // [0.0 0.15 0.35 0.5 0.75 1.0]

// horizontal sun glow spread around the horizon
#define SUN_GLOW 1.0 // [0.0 0.5 1.0 1.5 2.0 3.0]

// how strongly the sky dome colours bleed onto surfaces
#define SKY_LIGHT_STRENGTH 1.0 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0]

/*  world  */

// direct sun and moon light brightness
#define DIRECT_LIGHT_STRENGTH 1.0 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0 3.0]

// torch and lantern light brightness
#define BLOCK_LIGHT_STRENGTH 1.0 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0 3.0]

// tint block light with the colour of the emitting block
#define COLORED_LIGHTS // derive light colour from the light source block

// saturation boost applied to the coloured light tint
#define COLORED_LIGHT_SATURATION 1.0 // [0.0 0.5 1.0 1.5 2.0]

// strength of the aerial perspective haze
#define FOG_STRENGTH 1.0 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0]

// vertical extent of the ground haze layer in blocks
#define FOG_HEIGHT 24.0 // [8.0 16.0 24.0 40.0 64.0 96.0]

// how far the fog reaches in clear weather
#define FOG_DISTANCE 256.0 // [64.0 128.0 192.0 256.0 384.0 512.0]

// extra fog thickness while it rains
#define RAIN_FOG_BOOST 1.0 // [0.0 0.5 1.0 1.5 2.0 3.0]

// specular highlights on glossy surfaces
#define SPECULAR_STRENGTH 1.0 // [0.0 0.25 0.5 0.75 1.0 1.5 2.0]

// offsets the smoothness guessed for a surface
#define SMOOTHNESS_BIAS 0.0 // [-0.5 -0.25 0.0 0.25 0.5]

// strength of the sun glint on the water surface
#define WATER_SPECULAR 1.0 // [0.0 0.5 1.0 1.5 2.0 3.0]

// wave amplitude
#define WATER_WAVE_HEIGHT 1.0 // [0.0 0.5 1.0 1.5 2.0]

// wave animation speed
#define WATER_WAVE_SPEED 1.0 // [0.0 0.5 1.0 1.5 2.0]

// how much the scene behind the water surface bends
#define WATER_REFRACTION 0.5 // [0.0 0.25 0.5 0.75 1.0]

// how quickly light is absorbed by water
#define WATER_ABSORPTION 1.0 // [0.25 0.5 0.75 1.0 1.5 2.0 3.0]

// wet surfaces and rain ripples
#define WET_SURFACES // darken and gloss surfaces while it rains

// strength of the rain wetness effect
#define WET_SURFACE_STRENGTH 1.0 // [0.25 0.5 0.75 1.0 1.5 2.0]

// leaves and grass sway in the wind
#define WAVING_PLANTS // animate plant geometry

// how far plants bend
#define WAVING_STRENGTH 1.0 // [0.0 0.5 1.0 1.5 2.0]

// lorentz style colour shift at the screen edges
#define CHROMATIC_ABERRATION 0.5 // [0.0 0.25 0.5 0.75 1.0]

/*  post  */

// tone mapping curve
#define TONEMAP 1 // [0 1 2 3] 0 = aces, 1 = agx, 2 = filmic, 3 = linear

// overall image brightness
#define EXPOSURE 1.0 // [0.25 0.5 0.75 1.0 1.25 1.5 2.0 3.0]

// adapt exposure to the average screen brightness
#define AUTO_EXPOSURE // measure the frame and adjust exposure

// how quickly the measured exposure settles
#define AUTO_EXPOSURE_SPEED 1.0 // [0.25 0.5 1.0 2.0 4.0]

// colour saturation
#define SATURATION 1.0 // [0.0 0.5 0.75 1.0 1.25 1.5 2.0]

// contrast around mid grey
#define CONTRAST 1.0 // [0.5 0.75 1.0 1.25 1.5 2.0]

// dark corner shading
#define VIGNETTE 0.35 // [0.0 0.15 0.25 0.35 0.5 0.75 1.0]

// unsharp mask amount applied at the very end
#define SHARPEN 0.35 // [0.0 0.15 0.25 0.35 0.5 0.75 1.0]

// film grain amount
#define GRAIN 0.15 // [0.0 0.05 0.1 0.15 0.25 0.4]

#endif
