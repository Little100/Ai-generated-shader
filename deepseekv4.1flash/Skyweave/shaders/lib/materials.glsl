/*
    Skyweave - block identifiers used for material classification.

    These numbers are meaningless on their own; they map to the names declared
    in block.properties. If that file is missing every lookup returns zero and
    the shader quietly falls back to its default material, so nothing breaks.
*/

#if !defined(SKYWEAVE_MATERIALS_INCLUDED)
#define SKYWEAVE_MATERIALS_INCLUDED

#include "/lib/uniforms.glsl"

/*  material identifiers, stored in the alpha channel of the albedo buffer  */

const float MAT_OPAQUE = 0.0;
const float MAT_SKY = 0.1;
const float MAT_FOLIAGE = 0.2;
const float MAT_METAL = 0.3;
const float MAT_EMISSIVE = 0.4;
const float MAT_ENTITY = 0.5;
const float MAT_HAND = 0.6;
const float MAT_CLOUD = 0.7;
const float MAT_WEATHER = 0.8;

bool isMaterial(float stored, float expected) {
    return abs(stored - expected) < 0.025;
}

/*  dimension, derived from the world flags rather than a dimension id  */

// a roof over the world and no sky above it is the nether
bool inNetherDimension() {
    return hasCeiling;
}

// neither sky nor a roof is the end
bool inEndDimension() {
    return !hasSkylight && !hasCeiling;
}

/*  light sources  */

const int BLOCK_TORCH = 10000;
const int BLOCK_WALL_TORCH = 10001;
const int BLOCK_SOUL_TORCH = 10002;
const int BLOCK_SOUL_WALL_TORCH = 10003;
const int BLOCK_LANTERN = 10004;
const int BLOCK_SOUL_LANTERN = 10005;
const int BLOCK_GLOWSTONE = 10006;
const int BLOCK_SEA_LANTERN = 10007;
const int BLOCK_SHROOMLIGHT = 10008;
const int BLOCK_LAVA = 10009;
const int BLOCK_CAMPFIRE = 10010;
const int BLOCK_SOUL_CAMPFIRE = 10011;
const int BLOCK_REDSTONE_LAMP = 10012;
const int BLOCK_END_ROD = 10013;
const int BLOCK_BEACON = 10014;
const int BLOCK_CONDUIT = 10015;
const int BLOCK_JACK_O_LANTERN = 10016;
const int BLOCK_MAGMA = 10017;
const int BLOCK_CRYING_OBSIDIAN = 10018;
const int BLOCK_RESPAWN_ANCHOR = 10019;
const int BLOCK_AMETHYST = 10020;
const int BLOCK_OCHRE_FROGLIGHT = 10021;
const int BLOCK_VERDANT_FROGLIGHT = 10022;
const int BLOCK_PEARLESCENT_FROGLIGHT = 10023;
const int BLOCK_FIRE = 10024;
const int BLOCK_SOUL_FIRE = 10025;
const int BLOCK_NETHER_PORTAL = 10026;
const int BLOCK_END_PORTAL_FRAME = 10027;
const int BLOCK_ENCHANTING_TABLE = 10028;
const int BLOCK_BREWING_STAND = 10029;
const int BLOCK_COPPER_BULB = 10030;

/*  classification, kept here so vertex programs can reach it too  */

bool isLightSourceBlock(int blockId) {
    return blockId >= 10000 && blockId < 10100;
}

bool isFoliageBlock(int blockId) {
    return blockId >= 10200 && blockId < 10300;
}

// translucent but not water: refractive waves would look wrong on a window
bool isSolidTranslucentBlock(int blockId) {
    return blockId >= 10300 && blockId < 10400;
}

/*  polished metals  */

const int BLOCK_IRON_BLOCK = 10100;
const int BLOCK_GOLD_BLOCK = 10101;
const int BLOCK_COPPER_BLOCK = 10102;
const int BLOCK_DIAMOND_BLOCK = 10103;
const int BLOCK_NETHERITE_BLOCK = 10104;
const int BLOCK_EMERALD_BLOCK = 10105;

/*  foliage, which scatters light through rather than stopping it  */

const int BLOCK_LEAVES = 10200;
const int BLOCK_GRASS = 10201;
const int BLOCK_VINES = 10202;
const int BLOCK_FLOWERS = 10203;
const int BLOCK_CROPS = 10204;
const int BLOCK_MUSHROOM = 10205;

#endif
