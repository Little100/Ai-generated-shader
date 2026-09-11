/*
    Skyweave - everything drawn above the horizon.

    The scattering integral supplies the base colour; the discs, stars, galactic
    band and aurora are layered on top in physical order so the brighter bodies
    correctly occlude the fainter ones.
*/

#if !defined(SKYWEAVE_SKY_INCLUDED)
#define SKYWEAVE_SKY_INCLUDED

#include "/lib/math.glsl"
#include "/lib/config.glsl"
#include "/lib/atmosphere.glsl"
#include "/lib/materials.glsl"

// the vanilla sky spins about the north south axis once per minecraft day
const vec3 CELESTIAL_POLE = vec3(0.0, 0.0, 1.0);

// the galactic band sits at an angle to the celestial equator, this keeps it
// from lining up with the horizon and reading as a flat stripe
const float GALAXY_INCLINATION = 1.05;

// radiance of the solar disc, past the top of the tone curve so it blooms
const float SUN_DISC_RADIANCE = 260.0;
const float MOON_DISC_RADIANCE = 3.2;

float celestialRotation() {
    return -float(worldTime) / 24000.0 * TAU;
}

// world direction expressed in the frame that spins with the sky
vec3 toCelestial(vec3 worldDir) {
    return rotateAboutAxis(worldDir, CELESTIAL_POLE, celestialRotation());
}

float sunDiscMask(vec3 dir, vec3 sunDir) {
    float cosAngle = dot(dir, sunDir);
    float cosRadius = cos(SUN_ANGULAR_RADIUS);
    if (cosAngle < cosRadius) {
        return 0.0;
    }
    float angle = acos(clamp(cosAngle, -1.0, 1.0));
    return 1.0 - smoothstep(SUN_ANGULAR_RADIUS * 0.86, SUN_ANGULAR_RADIUS, angle);
}

// limb darkening follows the eddington approximation, the disc centre is
// noticeably brighter than the rim
float sunDiscIntensity(vec3 dir, vec3 sunDir) {
    float mask = sunDiscMask(dir, sunDir);
    if (mask <= 0.0) {
        return 0.0;
    }
    float angle = acos(clamp(dot(dir, sunDir), -1.0, 1.0));
    float radius = angle / SUN_ANGULAR_RADIUS;
    float mu = sqrt(max(1.0 - radius * radius, 0.0));
    return mask * (1.0 - 0.62 * (1.0 - mu));
}

// the moon is shaded as a sphere lit by the sun, which produces the correct
// crescent and gibbous shapes for every phase without a lookup table
float moonDiscIntensity(vec3 dir, vec3 moonDir, vec3 sunDir, out vec2 discCoord) {
    discCoord = vec2(0.0);
    float cosAngle = dot(dir, moonDir);
    float cosRadius = cos(MOON_ANGULAR_RADIUS);
    if (cosAngle < cosRadius) {
        return 0.0;
    }

    float angle = acos(clamp(cosAngle, -1.0, 1.0));
    float radius = angle / MOON_ANGULAR_RADIUS;
    float mask = 1.0 - smoothstep(0.9, 1.0, radius);

    vec3 offsetDir = normalize(dir - moonDir * cosAngle);
    vec3 surfaceNormal = normalize(moonDir * sqrt(max(1.0 - radius * radius, 0.0)) + offsetDir * radius);

    // the sun is far enough away that its direction at the moon is the same
    float lambert = dot(surfaceNormal, sunDir);
    float lit = smoothstep(-0.02, 0.06, lambert);

    // maria and highlands, keyed off the disc coordinates
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), moonDir));
    vec3 upLocal = cross(moonDir, right);
    discCoord = vec2(dot(offsetDir, right), dot(offsetDir, upLocal)) * radius;
    float maria = fbm3D(vec3(discCoord * 7.0, 3.7), 4, 2.2, 0.5) * 0.5 + 0.5;
    float surface = mix(0.78, 1.0, maria);

    // a touch of earthshine so the dark limb is not pure black
    float earthshine = 0.035 * (1.0 - lit);

    return mask * (lit * surface + earthshine);
}

// a two layer cell based star field, the second layer holds the faint dust
vec3 starField(vec3 celestialDir, float nightFactor) {
    vec3 total = vec3(0.0);

    for (int layer = 0; layer < 2; layer++) {
        float scale = layer == 0 ? 90.0 : 190.0;
        float threshold = layer == 0 ? 0.985 : 0.955;
        float size = layer == 0 ? 0.055 : 0.035;

        vec3 p = celestialDir * scale;
        vec3 cell = floor(p);
        vec3 local = fract(p) - 0.5;

        vec3 star = hash33Stable(cell);
        if (star.z > threshold) {
            float brightness = (star.z - threshold) / max(1.0 - threshold, 1e-5);
            vec3 offset = vec3((star.xy * 2.0 - 1.0) * 0.32, 0.0);
            float d = length(local - offset);
            float core = exp(-pow(d / size, 2.0));
            // scintillation is stronger near the horizon where the air is thick
            float twinkle = 0.72 + 0.28 * sin(frameTimeCounter * (2.0 + brightness * 6.0) + brightness * 40.0);
            // colour runs from cool blue giants to warm red dwarfs
            vec3 tint = mix(vec3(0.72, 0.82, 1.0), vec3(1.0, 0.82, 0.65), hash11(star.x + star.y * 7.0));
            total += tint * (core * brightness * twinkle * (layer == 0 ? 1.0 : 0.55));
        }
    }

    return total * nightFactor;
}

// fractal clouds of stars forming the galactic band
vec3 galaxyBand(vec3 celestialDir, float nightFactor) {
    vec3 axis = normalize(vec3(sin(GALAXY_INCLINATION), 0.0, cos(GALAXY_INCLINATION)));
    vec3 bandAxis = normalize(cross(axis, vec3(1.0, 0.0, 0.0)));

    float latitude = dot(celestialDir, bandAxis);
    float band = exp(-pow(abs(latitude) * 4.2, 2.0));

    // the bulge toward the galactic centre is brighter and warmer
    float longitude = dot(celestialDir, axis);
    float centreBoost = smoothstep(-0.4, 0.9, longitude);

    float structure = fbm3D(celestialDir * 5.5 + 11.0, 5, 2.15, 0.52);
    float dust = ridgedFbm3D(celestialDir * 9.0 + 3.0, 4, 2.4, 0.5);
    float density = saturate(structure * 0.5 + 0.5) * (0.35 + 0.65 * dust);

    vec3 cool = vec3(0.42, 0.52, 0.78);
    vec3 warm = vec3(0.85, 0.72, 0.55);
    vec3 tint = mix(cool, warm, saturate(centreBoost * 0.7 + structure * 0.3));

    return tint * (band * density * (0.35 + 0.65 * centreBoost) * 0.30 * nightFactor);
}

// vertical curtains hanging in the upper atmosphere, driven by ridged noise so
// the filaments stay sharp instead of blowing out into fog
vec3 auroraCurtains(vec3 dir, float strength) {
    if (strength <= 0.001 || dir.y < 0.012) {
        return vec3(0.0);
    }

    float shellHeight = 340.0;
    float t = shellHeight / max(dir.y, 0.012);
    vec2 ground = dir.xz * t * 0.0022;

    float flow = frameTimeCounter * 0.018;
    float body = ridgedFbm3D(vec3(ground * 1.1, flow), 4, 2.15, 0.55);
    float filament = ridgedFbm3D(vec3(ground * vec2(7.0, 1.4), flow * 1.9 + 5.0), 3, 2.5, 0.5);
    float curtain = body * (0.5 + 0.5 * filament);

    // the curtain fades out at the top and has a ragged lower edge
    float vertical = smoothstep(0.012, 0.16, dir.y) * (1.0 - smoothstep(0.42, 0.95, dir.y));
    float intensity = pow(saturate(curtain), 2.6) * vertical;

    float bandFade = 0.55 + 0.45 * sin(ground.x * 0.35 + flow * 3.0);
    intensity *= saturate(bandFade);

    vec3 low = vec3(0.16, 1.0, 0.48);
    vec3 mid = vec3(0.30, 0.85, 0.72);
    vec3 high = vec3(0.78, 0.28, 1.0);
    float heightMix = saturate(dir.y * 1.9);
    vec3 tint = mix(mix(low, mid, saturate(heightMix * 2.0)), high, saturate(heightMix * 1.6 - 0.6));

    return tint * intensity * strength;
}

// how likely aurora is tonight, a slow daily hash keeps it from being random
float auroraVisibility() {
#ifndef SKY_AURORA
    return 0.0;
#else
    if (AURORA_FREQUENCY <= 0.0) {
        return 0.0;
    }

    float daily = hash11(float(worldDay) * 1.37 + 0.5);
    if (daily > AURORA_FREQUENCY) {
        return 0.0;
    }

    // cold biomes see it far more often, warm ones almost never
    float cold = saturate((0.55 - temperature) * 2.4);
    float weather = 1.0 - rainStrength * 0.65;

    // it only shows while that night actually lasts, and never under a roof
    float night = 1.0 - saturate(sunPosition.y * 6.0);
    float openSky = hasSkylight ? 1.0 : 0.0;

    return saturate(0.30 + cold * 1.1) * weather * night * openSky * AURORA_STRENGTH;
#endif
}

// the complete sky for one view direction, world space
vec3 renderSky(vec3 dir, vec3 sunDir, vec3 moonDir, float altitude) {
    vec3 color = skyRadiance(dir, sunDir, altitude);

    float nightFactor = saturate(1.0 - sunPosition.y * 8.0);
    float sunUp = saturate(sunPosition.y * 6.0);

    vec3 celestialDir = toCelestial(dir);

#ifdef SKY_GALAXY
    color += galaxyBand(celestialDir, nightFactor);
#endif

#ifdef SKY_STARS
    color += starField(celestialDir, nightFactor);
#endif

    color += auroraCurtains(dir, auroraVisibility());

    // the moon is drawn before the sun so a sunrise correctly swallows it
    float moonIntensity = 0.0;
    vec2 moonCoord;
#ifdef SKY_MOON
    moonIntensity = moonDiscIntensity(dir, moonDir, sunDir, moonCoord);
    vec3 moonTint = vec3(0.92, 0.94, 1.0);
    color = mix(color, vec3(0.0), saturate(moonIntensity * 1.6));
    color += moonTint * (moonIntensity * MOON_DISC_RADIANCE * moonTransmittance(altitude, moonDir)) * (1.0 - sunUp * 0.85);
#endif

    float sunIntensity = 0.0;
#ifdef SKY_SUN
    sunIntensity = sunDiscIntensity(dir, sunDir);
    vec3 sunColor = sunTransmittance(altitude, sunDir);
    color = mix(color, vec3(0.0), saturate(sunIntensity * 1.6));
    color += sunColor * (sunIntensity * SUN_DISC_RADIANCE);
#endif

    return color;
}

// sky colour used by the passes that only need the background, cheaper and
// without any of the small scale detail
vec3 renderSkyBackground(vec3 dir, vec3 sunDir, float altitude) {
    return skyRadiance(dir, sunDir, altitude);
}

/*  dimensions without an atmosphere  */

// the nether has a roof, so there is no scattering to do, only the glow of the
// lava below bleeding into the haze
vec3 netherSky(vec3 dir) {
    float up = saturate(dir.y * 0.5 + 0.5);
    vec3 below = vec3(0.085, 0.012, 0.006);
    vec3 above = vec3(0.20, 0.040, 0.014);
    return mix(below, above, up) * 1.7;
}

// the end is a void with a fixed field of faint stars and a violet cast
vec3 endSky(vec3 dir) {
    vec3 celestial = toCelestial(dir);
    vec3 base = vec3(0.010, 0.009, 0.020);
    vec3 stars = starField(celestial, 0.55) * vec3(0.75, 0.70, 1.0);
    float glow = 0.35 + 0.65 * saturate(dir.y * 0.5 + 0.5);
    return base * glow + stars * 0.7;
}

// picks the right sky for the dimension the player is standing in
vec3 renderSkyForDimension(vec3 dir, vec3 sunDir, vec3 moonDir, float altitude) {
    if (inNetherDimension()) {
        return netherSky(dir);
    }
    if (inEndDimension()) {
        return endSky(dir);
    }

#ifndef SKY_ATMOSPHERE
    // a plain gradient, for when the scattering integral is more than the frame
    // budget can spare. It still dims with the sun so night reads as night.
    float up = saturate(dir.y * 0.5 + 0.5);
    vec3 sky = mix(vec3(0.55, 0.62, 0.78), vec3(0.20, 0.38, 0.75), pow(up, 0.7));
    sky *= mix(vec3(0.05, 0.06, 0.11), vec3(1.0), saturate(sunDir.y * 4.0 + 0.5));
    return sky;
#else
    return renderSky(dir, sunDir, moonDir, altitude);
#endif
}

#endif
