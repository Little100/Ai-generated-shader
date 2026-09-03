#ifndef MATERIALS_GLSL
#define MATERIALS_GLSL

// Block ids assigned in block.properties
#define BLOCK_WATER 10
#define BLOCK_PLANT_SHORT 20
#define BLOCK_PLANT_TALL_LOWER 21
#define BLOCK_LEAVES 22
#define BLOCK_HANGING 23
#define BLOCK_SEAGRASS 24
#define BLOCK_PLANT_TALL_UPPER 25
#define BLOCK_EMISSIVE 30
#define BLOCK_LAVA 31

// Surface material ids stored in the gbuffer
#define MAT_DEFAULT 0
#define MAT_EMISSIVE 1
#define MAT_LAVA 2
#define MAT_LEAVES 3
#define MAT_PLANT 4
#define MAT_HAND 5
#define MAT_PARTICLE 6
#define MAT_UNLIT 7
#define MAT_ENTITY 8
#define MAT_WATER 9

float encodeMat(int mat) { return float(mat) / 255.0; }
int decodeMat(float x) { return int(x * 255.0 + 0.5); }

int materialFromBlock(int id) {
    if (id == BLOCK_EMISSIVE) return MAT_EMISSIVE;
    if (id == BLOCK_LAVA) return MAT_LAVA;
    if (id == BLOCK_LEAVES || id == BLOCK_HANGING) return MAT_LEAVES;
    if (id == BLOCK_PLANT_SHORT || id == BLOCK_PLANT_TALL_LOWER || id == BLOCK_PLANT_TALL_UPPER || id == BLOCK_SEAGRASS) return MAT_PLANT;
    return MAT_DEFAULT;
}

#endif
