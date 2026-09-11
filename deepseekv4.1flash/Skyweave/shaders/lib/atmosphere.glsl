/*
    Skyweave - the single scattering atmosphere.

    One model drives the sky dome, the aerial perspective haze and the ambient
    light that lands on geometry. Because all three read the same integral the
    world and the sky can never drift apart: a red sunset automatically tints
    the fog and the shadows the same way.

    Everything is in SI units, one Minecraft block is one metre, and the planet
    centre sits at the world origin so the local up axis is +Y.
*/

#if !defined(SKYWEAVE_ATMOSPHERE_INCLUDED)
#define SKYWEAVE_ATMOSPHERE_INCLUDED

#include "/lib/math.glsl"
#include "/lib/config.glsl"

const float PLANET_RADIUS = 6360000.0;
const float ATMOSPHERE_RADIUS = 6420000.0;
const float RAYLEIGH_SCALE_HEIGHT = 8000.0;
const float MIE_SCALE_HEIGHT = 1200.0;
const float OZONE_CENTER = 25000.0;
const float OZONE_HALF_WIDTH = 15000.0;

// scattering and extinction coefficients per metre
const vec3 RAYLEIGH_SCATTERING = vec3(5.802, 13.558, 33.1) * 1e-6;
const vec3 MIE_SCATTERING = vec3(3.996) * 1e-6;
const vec3 MIE_EXTINCTION = vec3(4.40) * 1e-6;
const vec3 OZONE_ABSORPTION = vec3(0.650, 1.881, 0.085) * 1e-6;

const float MIE_ANISOTROPY = 0.8;
const float MIE_BACKSCATTER = -0.15;
const float MIE_BACKSCATTER_MIX = 0.25;

// how much energy the sun delivers, tuned so a clear noon lands near white
const float SUN_IRRADIANCE = 30.0;
const float MOON_IRRADIANCE = 0.42;

// the sun subtends about half a degree, the moon roughly the same
const float SUN_ANGULAR_RADIUS = 0.00475;
const float MOON_ANGULAR_RADIUS = 0.00455;

// optical depth toward the sun uses a fixed small quadrature, four samples is
// enough because the density profile is smooth along that short ray
const int SUN_TRANSMITTANCE_STEPS = 4;

const vec3 PLANET_UP = vec3(0.0, 1.0, 0.0);

bool raySphereIntersect(vec3 origin, vec3 dir, float radius, out float nearHit, out float farHit) {
    float b = dot(origin, dir);
    float c = dot(origin, origin) - radius * radius;
    float disc = b * b - c;
    if (disc < 0.0) {
        nearHit = 0.0;
        farHit = 0.0;
        return false;
    }
    float root = sqrt(disc);
    nearHit = -b - root;
    farHit = -b + root;
    return true;
}

// position of a camera at the given altitude, in the planet centred frame
vec3 atmosphereOrigin(float altitude) {
    return vec3(0.0, PLANET_RADIUS + max(altitude, -60.0), 0.0);
}

float rayleighDensity(float height) {
    return exp(-height / RAYLEIGH_SCALE_HEIGHT);
}

float mieDensity(float height) {
    return exp(-height / MIE_SCALE_HEIGHT);
}

// the ozone layer is a tent profile between the two altitude limits
float ozoneDensity(float height) {
    return max(0.0, 1.0 - abs(height - OZONE_CENTER) / OZONE_HALF_WIDTH);
}

float henyeyGreenstein(float cosTheta, float g) {
    float g2 = g * g;
    float denom = max(1.0 + g2 - 2.0 * g * cosTheta, 1e-4);
    return (1.0 - g2) / (4.0 * PI * pow(denom, 1.5));
}

// Rayleigh is almost symmetric, Mie is a strong forward lobe plus a soft halo
float rayleighPhase(float cosTheta) {
    return 3.0 / (16.0 * PI) * (1.0 + cosTheta * cosTheta);
}

float miePhase(float cosTheta) {
    return mix(henyeyGreenstein(cosTheta, MIE_ANISOTROPY),
               henyeyGreenstein(cosTheta, MIE_BACKSCATTER),
               MIE_BACKSCATTER_MIX);
}

// transmittance from an arbitrary point in the atmosphere toward the sun, zero
// when the planet itself blocks the ray
vec3 sunTransmittanceFrom(vec3 position, vec3 sunDir) {
    float nearHit;
    float farHit;
    if (raySphereIntersect(position, sunDir, PLANET_RADIUS, nearHit, farHit) && nearHit > 0.0) {
        return vec3(0.0);
    }
    if (!raySphereIntersect(position, sunDir, ATMOSPHERE_RADIUS, nearHit, farHit)) {
        return vec3(1.0);
    }

    float rayLength = max(farHit, 0.0);
    float dt = rayLength / float(SUN_TRANSMITTANCE_STEPS);

    vec3 depthR = vec3(0.0);
    vec3 depthM = vec3(0.0);
    vec3 depthO = vec3(0.0);

    for (int i = 0; i < SUN_TRANSMITTANCE_STEPS; i++) {
        vec3 p = position + sunDir * ((float(i) + 0.5) * dt);
        float h = max(length(p) - PLANET_RADIUS, 0.0);
        depthR += vec3(rayleighDensity(h) * dt);
        depthM += vec3(mieDensity(h) * dt);
        depthO += vec3(ozoneDensity(h) * dt);
    }

    vec3 tau = RAYLEIGH_SCATTERING * depthR + MIE_EXTINCTION * depthM + OZONE_ABSORPTION * depthO;
    return exp(-tau);
}

// sunlight reaching a surface at the given altitude, this is what reddens the
// sun as it drops toward the horizon
vec3 sunTransmittance(float altitude, vec3 sunDir) {
    return sunTransmittanceFrom(atmosphereOrigin(altitude), sunDir);
}

// the full single scattering integral, primarySteps controls how finely the
// view ray is subdivided. The cost is primarySteps * SUN_TRANSMITTANCE_STEPS
// density evaluations, so callers pick a budget to suit the pass.
vec3 atmosphereScattering(vec3 origin, vec3 dir, vec3 sunDir, float sunIrradiance, int primarySteps) {
    float nearHit;
    float farHit;
    if (!raySphereIntersect(origin, dir, ATMOSPHERE_RADIUS, nearHit, farHit)) {
        return vec3(0.0);
    }
    if (farHit <= 0.0) {
        return vec3(0.0);
    }

    float rayLength = farHit;
    float groundNear;
    float groundFar;
    if (raySphereIntersect(origin, dir, PLANET_RADIUS, groundNear, groundFar) && groundNear > 0.0) {
        rayLength = min(rayLength, groundNear);
    }

    float cosTheta = dot(dir, sunDir);
    float phaseR = rayleighPhase(cosTheta);
    float phaseM = miePhase(cosTheta);

    float dt = rayLength / float(primarySteps);

    vec3 scatteredR = vec3(0.0);
    vec3 scatteredM = vec3(0.0);
    vec3 depthR = vec3(0.0);
    vec3 depthM = vec3(0.0);
    vec3 depthO = vec3(0.0);

    for (int i = 0; i < primarySteps; i++) {
        vec3 p = origin + dir * ((float(i) + 0.5) * dt);
        float h = max(length(p) - PLANET_RADIUS, 0.0);

        float stepR = rayleighDensity(h) * dt;
        float stepM = mieDensity(h) * dt;
        float stepO = ozoneDensity(h) * dt;

        vec3 tau = RAYLEIGH_SCATTERING * depthR + MIE_EXTINCTION * depthM + OZONE_ABSORPTION * depthO;
        vec3 viewTransmittance = exp(-tau);
        vec3 sunTransmittanceHere = sunTransmittanceFrom(p, sunDir);

        scatteredR += stepR * viewTransmittance * sunTransmittanceHere;
        scatteredM += stepM * viewTransmittance * sunTransmittanceHere;

        depthR += vec3(stepR);
        depthM += vec3(stepM);
        depthO += vec3(stepO);
    }

    vec3 result = scatteredR * RAYLEIGH_SCATTERING * phaseR
                + scatteredM * MIE_SCATTERING * phaseM;

#ifdef SUN_GLOW
    result *= mix(1.0, SUN_GLOW, saturate(phaseM / max(henyeyGreenstein(1.0, MIE_ANISOTROPY), 1e-5)));
#endif

    return result * sunIrradiance;
}

int skyPrimarySteps() {
#if SKY_QUALITY == 1
    return 12;
#elif SKY_QUALITY == 3
    return 34;
#else
    return 22;
#endif
}

// budget version used wherever the result feeds a blur or an average, twenty
// four evaluations per pixel is affordable across a full screen
int ambientPrimarySteps() {
#if SKY_QUALITY == 1
    return 4;
#elif SKY_QUALITY == 3
    return 10;
#else
    return 6;
#endif
}

// sky radiance as seen from the camera, the direction is world space
vec3 skyRadiance(vec3 dir, vec3 sunDir, float altitude) {
    return atmosphereScattering(atmosphereOrigin(altitude), dir, sunDir,
                                SUN_IRRADIANCE, skyPrimarySteps());
}

vec3 skyRadianceCheap(vec3 dir, vec3 sunDir, float altitude) {
    return atmosphereScattering(atmosphereOrigin(altitude), dir, sunDir,
                                SUN_IRRADIANCE, ambientPrimarySteps());
}

// moon light is the sun colour reflected off a grey disc, so it inherits the
// same atmospheric reddening on the way in
vec3 moonTransmittance(float altitude, vec3 moonDir) {
    return sunTransmittance(altitude, moonDir);
}

// Two lookups are enough because the sky is the smoothest thing in the frame.
// One along the surface normal and one straight up, blended by how much of the
// hemisphere the surface can actually see. The ground bounce underneath is a
// fraction of the same value rather than a third integral.
vec3 skyIrradiance(vec3 normal, vec3 sunDir, float altitude) {
    vec3 origin = atmosphereOrigin(altitude);
    int steps = ambientPrimarySteps();

    float upness = saturate(dot(normal, PLANET_UP) * 0.5 + 0.5);

    vec3 upward = atmosphereScattering(origin, PLANET_UP, sunDir, SUN_IRRADIANCE, steps);
    vec3 around = atmosphereScattering(origin, normalize(mix(normal, PLANET_UP, 0.30)), sunDir, SUN_IRRADIANCE, steps);

    vec3 sky = mix(around, upward, upness * 0.55);

    // light bouncing off the terrain below, tinted like dry ground
    vec3 ground = sky * vec3(0.24, 0.21, 0.16) * (1.0 - upness) * 0.45;

    return (sky + ground) * PI * SKY_LIGHT_STRENGTH;
}

// the sky colour a distant surface fades into, reused by the fog pass so haze
// and sky always agree
vec3 atmosphericHaze(vec3 dir, vec3 sunDir, float altitude) {
    return skyRadianceCheap(dir, sunDir, altitude);
}

#endif
