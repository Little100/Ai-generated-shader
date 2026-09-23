import json, os

TEMP = os.environ['TEMP']
allb = json.load(open(os.path.join(TEMP, 'blk_1.21.11-registries.json')))
S = set(allb)

leaves = sorted(x for x in allb if x.endswith('_leaves'))
leaves = sorted(set(leaves) | {'mangrove_roots'})

glass = sorted(x for x in allb if ('_glass' in x) or x.startswith('glass'))

water = sorted(x for x in allb if x == 'water' or x == 'bubble_column' or x == 'water_cauldron'
               or x.endswith('_coral') or x.endswith('_coral_fan') or x.endswith('_coral_wall_fan')
               or x in ('sponge', 'wet_sponge'))

PLANT_EXTRA = {
 'grass_block','short_grass','tall_grass','fern','large_fern','short_dry_grass','tall_dry_grass',
 'dandelion','poppy','blue_orchid','allium','azure_bluet','red_tulip','orange_tulip','white_tulip',
 'pink_tulip','oxeye_daisy','cornflower','lily_of_the_valley','wither_rose','sunflower','lilac',
 'rose_bush','peony','torchflower','torchflower_crop','pitcher_plant','pitcher_crop',
 'sugar_cane','bamboo','bamboo_sapling','cactus','cactus_flower','bush','firefly_bush','wildflowers',
 'melon_stem','pumpkin_stem','attached_melon_stem','attached_pumpkin_stem',
 'sweet_berry_bush','cave_vines','cave_vines_plant','weeping_vines','weeping_vines_plant',
 'twisting_vines','twisting_vines_plant','seagrass','tall_seagrass','kelp','kelp_plant','dried_kelp_block',
 'nether_sprouts','warped_roots','crimson_roots','hanging_roots','mangrove_roots','muddy_mangrove_roots',
 'big_dripleaf','big_dripleaf_stem','small_dripleaf','spore_blossom','moss_block','moss_carpet',
 'pale_moss_block','pale_moss_carpet','pale_hanging_moss','pink_petals','chorus_flower','chorus_plant',
 'brown_mushroom','red_mushroom','mushroom_stem','brown_mushroom_block','red_mushroom_block',
 'lily_pad','dead_bush','crimson_fungus','warped_fungus','nether_wart','nether_wart_block',
 'warped_wart_block','cocoa','frogspawn','sculk_vein','azalea','flowering_azalea',
 'glow_lichen','vine','wheat','carrots','potatoes','beetroots','leaf_litter','sea_pickle',
 'closed_eyeblossom','open_eyeblossom','sculk','resin_clump',
 'melon','pumpkin','carved_pumpkin','hay_block','mangrove_propagule',
}
plants = PLANT_EXTRA | set(x for x in allb if x.endswith('_sapling') or x.endswith('_flower'))
plants |= set(x for x in allb if x.startswith('potted_'))
plants = sorted(p for p in plants if p in S)

metal = set(x for x in allb if x.endswith('_ore') or x.startswith('raw_') or 'copper' in x
            or x.endswith('_lightning_rod'))
metal |= {'iron_block','gold_block','diamond_block','netherite_block','emerald_block','lapis_block',
          'redstone_block','coal_block','quartz_block','amethyst_block','iron_bars','chain','hopper',
          'lightning_rod','rail','detector_rail','activator_rail','powered_rail','anvil','chipped_anvil',
          'damaged_anvil','cauldron','water_cauldron','lava_cauldron','powder_snow_cauldron',
          'lantern','soul_lantern','beacon','conduit'}
metal = sorted(m for m in metal if m in S)

SAND_SET = {
 'sand','red_sand','sandstone','chiseled_sandstone','cut_sandstone','smooth_sandstone',
 'sandstone_slab','sandstone_stairs','sandstone_wall','cut_sandstone_slab','smooth_sandstone_slab',
 'smooth_sandstone_stairs','red_sandstone','chiseled_red_sandstone','cut_red_sandstone',
 'smooth_red_sandstone','red_sandstone_slab','red_sandstone_stairs','red_sandstone_wall',
 'cut_red_sandstone_slab','smooth_red_sandstone_slab','smooth_red_sandstone_stairs',
 'gravel','suspicious_sand','suspicious_gravel','dirt','coarse_dirt','rooted_dirt','dirt_path',
 'podzol','mycelium','mud','packed_mud','muddy_mangrove_roots','clay','soul_sand','soul_soil'}
sand = sorted(x for x in allb if x in SAND_SET)

snowice = sorted(x for x in allb if x in {'snow','snow_block','powder_snow','ice','packed_ice',
                                          'blue_ice','frosted_ice'})

WOODFAM = ['oak','spruce','birch','jungle','acacia','dark_oak','mangrove','cherry','pale_oak',
           'bamboo','crimson','warped']
SUF = ['_planks','_door','_trapdoor','_fence','_fence_gate','_stairs','_slab','_sign','_wall_sign',
       '_hanging_sign','_wall_hanging_sign','_button','_pressure_plate','_shelf',
       '_log','_wood','_stem','_hyphae']
wood = set()
for f in WOODFAM:
    for s in SUF:
        if f + s in S:
            wood.add(f + s)
wood |= set(x for x in allb if x.startswith('stripped_'))
wood |= {'bookshelf','chiseled_bookshelf','crafting_table','cartography_table','fletching_table',
         'smithing_table','loom','barrel','chest','trapped_chest','ender_chest','lectern','composter',
         'beehive','bee_nest','note_block','jukebox','ladder','scaffolding'}
wood |= set(x for x in allb if 'mosaic' in x)
wood = sorted(w for w in wood if w in S)

CANDLE_COLORS = ['white_','orange_','magenta_','light_blue_','yellow_','lime_','pink_','gray_',
                 'light_gray_','cyan_','purple_','blue_','brown_','green_','red_','black_']
light = {
 'torch','wall_torch','soul_torch','soul_wall_torch','redstone_torch','redstone_wall_torch',
 'copper_torch','copper_wall_torch','lantern','soul_lantern','copper_lantern','glowstone','shroomlight',
 'sea_lantern','ochre_froglight','verdant_froglight','pearlescent_froglight','magma_block','campfire',
 'soul_campfire','end_rod','crying_obsidian','respawn_anchor','beacon','conduit','jack_o_lantern',
 'redstone_lamp','sculk_catalyst','sculk_shrieker','sculk_sensor','calibrated_sculk_sensor',
 'amethyst_cluster','budding_amethyst','small_amethyst_bud','medium_amethyst_bud','large_amethyst_bud',
 'lava','fire','soul_fire','furnace','blast_furnace','smoker','brewing_stand','enchanting_table',
 'end_portal_frame','end_gateway','light','candle','candle_cake','sea_pickle','magma_block',
 'sculk','lightning_rod','cave_vines','cave_vines_plant'}
for c in CANDLE_COLORS:
    light.add(c + 'candle')
    light.add(c + 'candle_cake')
light = sorted(l for l in light if l in S)

CATS = [('1) leaves', leaves), ('2) glass', glass), ('3) water', water), ('4) plants', plants),
        ('5) metal', metal), ('6) sand', sand), ('7) snowice', snowice), ('8) wood', wood),
        ('9) light', light)]

out = []
seen = set()
for name, lst in CATS:
    out.append('=== %s ===' % name)
    out.extend(lst)
    out.append('')
    seen |= set(lst)
open(os.path.join(TEMP, 'blocklist.txt'), 'w', encoding='utf-8').write('\n'.join(out))

for name, lst in CATS:
    print(name, len(lst))

uncat = sorted(S - seen)
print('\n=== UNCATEGORIZED (%d) ===' % len(uncat))
print('\n'.join(uncat))
