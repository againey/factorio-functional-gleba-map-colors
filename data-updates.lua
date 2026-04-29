local ColorOklch = require("__hndy-color__.oklch")
local Arithmetic = require("__hndy-color__.util.arithmetic")
local modulo = Arithmetic.modulo

local contrast_value_map = {
	["very-high"] = 3.2,
	["high"] = 1.6,
	["moderate"] = 0.8,
	["low"] = 0.4,
	["very-low"] = 0.2,
}

local function collect_subgroup_tiles(subgroup)
	local gleba_tiles = {}
	for tile_name, tile_prototype in pairs(data.raw.tile) do
		if tile_prototype.subgroup == subgroup then
			gleba_tiles[tile_name] = true
		end
	end
	return gleba_tiles
end

local function find_terrain_item_prototype(tile_name)
	for item_name, item_prototype in pairs(data.raw.item) do
		if item_prototype.place_as_tile and item_prototype.place_as_tile.result == tile_name then
			return item_prototype
		end
	end

	return nil
 end

local function collect_plant_tile_tiers(natural_tile_name, artificial_tile_name, overgrowth_tile_name)
	local high_fertility = { [natural_tile_name] = true }
	local medium_fertility = {}
	local low_fertility = {}
	local artificial = { [artificial_tile_name] = true, [overgrowth_tile_name] = true }

	local artificial_item_prototype = find_terrain_item_prototype(artificial_tile_name)
	if artificial_item_prototype and artificial_item_prototype.place_as_tile and artificial_item_prototype.place_as_tile.tile_condition then
		for _, tile_name in ipairs(artificial_item_prototype.place_as_tile.tile_condition) do
			medium_fertility[tile_name] = true
		end
	end

	local overgrowth_item_prototype = find_terrain_item_prototype(overgrowth_tile_name)
	if overgrowth_item_prototype and overgrowth_item_prototype.place_as_tile and overgrowth_item_prototype.place_as_tile.tile_condition then
		for i, tile_name in ipairs(overgrowth_item_prototype.place_as_tile.tile_condition) do
			if medium_fertility[tile_name] ~= true then
				low_fertility[tile_name] = true
			end
		end
	end

	return {
		high_fertility = high_fertility,
		medium_fertility = medium_fertility,
		low_fertility = low_fertility,
		artificial = artificial,
	}
end

local function union_into_table(source, target)
	for key, value in pairs(source) do
		if target[key] == nil then
			target[key] = value
		end
	end
	return target
end

local function diff_tables(source, remove)
	local diff = {}
	for key, value in pairs(source) do
		if remove[key] == nil then
			diff[key] = value
		end
	end
	return diff
end

local function collect_nonagricultural_tile_tiers(nonagricultural_tiles)
	local tiers = {
		deep_water = {},
		shallow_water = {},
		lowland = {},
		midland = {},
		highland = {},
		other = {},
	}
	for tile_name, _ in pairs(nonagricultural_tiles) do
		local collision_mask = data.raw.tile[tile_name].collision_mask
		if collision_mask and collision_mask.layers and collision_mask.layers.water_tile == true then
			if collision_mask.layers.player == true then
				tiers.deep_water[tile_name] = true
			else
				tiers.shallow_water[tile_name] = true
			end
		else
			if string.match(tile_name, "^lowland%-") then
				tiers.lowland[tile_name] = true
			elseif string.match(tile_name, "^midland%-") then
				tiers.midland[tile_name] = true
			elseif string.match(tile_name, "^highland%-") then
				tiers.highland[tile_name] = true
			else
				tiers.other[tile_name] = true
			end
		end
	end
	return tiers
end

local function set_map_color_for_tiles(tile_names, color)
	for tile_name, _ in pairs(tile_names) do
		local tile_prototype = data.raw.tile[tile_name]
		if tile_prototype then
			tile_prototype.map_color = color
		end
	end
end

local function set_map_color_for_trees(tree_names, color)
	for tree_name, _ in pairs(tree_names) do
		local tree_prototype = data.raw.tree[tree_name]
		if tree_prototype then
			tree_prototype.map_color = color
		end
	end
end

-- Collect Gleba tile and tree information from prototypes.

local gleba_tiles = {}
union_into_table(collect_subgroup_tiles("gleba-tiles"), gleba_tiles)
union_into_table(collect_subgroup_tiles("gleba-water-tiles"), gleba_tiles)

local yumako_tile_tiers = collect_plant_tile_tiers("natural-yumako-soil", "artificial-yumako-soil", "overgrowth-yumako-soil")
local jellynut_tile_tiers = collect_plant_tile_tiers("natural-jellynut-soil", "artificial-jellynut-soil", "overgrowth-jellynut-soil")

local yumako_tiles = {}
union_into_table(yumako_tile_tiers.high_fertility, yumako_tiles)
union_into_table(yumako_tile_tiers.medium_fertility, yumako_tiles)
union_into_table(yumako_tile_tiers.low_fertility, yumako_tiles)
union_into_table(yumako_tile_tiers.artificial, yumako_tiles)

local jellynut_tiles = {}
union_into_table(jellynut_tile_tiers.high_fertility, jellynut_tiles)
union_into_table(jellynut_tile_tiers.medium_fertility, jellynut_tiles)
union_into_table(jellynut_tile_tiers.low_fertility, jellynut_tiles)
union_into_table(jellynut_tile_tiers.artificial, jellynut_tiles)

local agricultural_tiles = {}
union_into_table(yumako_tiles, agricultural_tiles)
union_into_table(jellynut_tiles, agricultural_tiles)

local nonagricultural_tiles = diff_tables(gleba_tiles, agricultural_tiles)
local nonagricultural_tile_tiers = collect_nonagricultural_tile_tiers(nonagricultural_tiles)

local yumako_neighbor_trees = {
	["funneltrunk"] = true,
	["hairyclubnub"] = true,
}

local jellynut_neighbor_trees = {
	["slipstack"] = true,
	["lickmaw"] = true,
}

local shared_neighbor_trees = {
	["water-cane"] = true,
	["teflilly"] = true,
	["cuttlepop"] = true,
}

local trees_with_special_handling = {}
union_into_table(yumako_neighbor_trees, trees_with_special_handling)
union_into_table(jellynut_neighbor_trees, trees_with_special_handling)
union_into_table(shared_neighbor_trees, trees_with_special_handling)

local other_trees = {}
for tree_name, tree_prototype in pairs(data.raw.tree) do
	if trees_with_special_handling[tree_name] ~= true then
		if tree_prototype.autoplace and tree_prototype.autoplace.control == "gleba_plants" then
			other_trees[tree_name] = true
		end
	end
end

-- Grab mod settings.

local agricultural_stage = settings.startup["functional-gleba-map-colors-agricultural-stage"].value
local agricultural_stage_contrast = contrast_value_map[settings.startup["functional-gleba-map-colors-agricultural-stage-contrast"].value]

local high_fertility_yumako_game_color = settings.startup["functional-gleba-map-colors-high-fertility-yumako-color"].value
local medium_fertility_yumako_game_color
local low_fertility_yumako_game_color = settings.startup["functional-gleba-map-colors-low-fertility-yumako-color"].value
local artificial_yumako_game_color = settings.startup["functional-gleba-map-colors-artificial-yumako-color"].value
local high_fertility_jellynut_game_color = settings.startup["functional-gleba-map-colors-high-fertility-jellynut-color"].value
local medium_fertility_jellynut_game_color
local low_fertility_jellynut_game_color = settings.startup["functional-gleba-map-colors-low-fertility-jellynut-color"].value
local artificial_jellynut_game_color = settings.startup["functional-gleba-map-colors-artificial-jellynut-color"].value

local highland_game_color = settings.startup["functional-gleba-map-colors-highland-color"].value
local midland_game_color = settings.startup["functional-gleba-map-colors-midland-color"].value
local lowland_game_color = settings.startup["functional-gleba-map-colors-lowland-color"].value
local shallow_water_game_color = settings.startup["functional-gleba-map-colors-shallow-water-color"].value
local deep_water_game_color = settings.startup["functional-gleba-map-colors-deep-water-color"].value
local other_game_color = settings.startup["functional-gleba-map-colors-other-color"].value

local high_fertility_yumako_color = ColorOklch.from_game_color(high_fertility_yumako_game_color):with_alpha(1.0):self_safe_normalize()
local medium_fertility_yumako_color
local low_fertility_yumako_color = ColorOklch.from_game_color(low_fertility_yumako_game_color):with_alpha(1.0):self_safe_normalize()
local high_fertility_jellynut_color = ColorOklch.from_game_color(high_fertility_jellynut_game_color):with_alpha(1.0):self_safe_normalize()
local medium_fertility_jellynut_color
local low_fertility_jellynut_color = ColorOklch.from_game_color(low_fertility_jellynut_game_color):with_alpha(1.0):self_safe_normalize()

local highland_color = ColorOklch.from_game_color(highland_game_color):with_alpha(1.0):self_safe_normalize()
local midland_color = ColorOklch.from_game_color(midland_game_color):with_alpha(1.0):self_safe_normalize()
local lowland_color = ColorOklch.from_game_color(lowland_game_color):with_alpha(1.0):self_safe_normalize()

-- Calculate interpolation values for low, medium, and high fertility tiles.

local low_fertility_lerp = 0.0
local medium_fertility_lerp = 0.5
local high_fertility_lerp = 1.0
local neighbor_tree_lerp = 0.25
local lerp_scale = 2 + agricultural_stage_contrast
if agricultural_stage == "natural" then
	medium_fertility_lerp = (0.0 + 1) / lerp_scale
	neighbor_tree_lerp = (medium_fertility_lerp + high_fertility_lerp) / 2
elseif agricultural_stage == "artificial" then
	medium_fertility_lerp = (lerp_scale - 1) / lerp_scale
	neighbor_tree_lerp = (low_fertility_lerp + medium_fertility_lerp) / 2
elseif agricultural_stage == "overgrowth" then
	low_fertility_lerp = (lerp_scale - 2) / lerp_scale
	medium_fertility_lerp = (lerp_scale - 1) / lerp_scale
	neighbor_tree_lerp = low_fertility_lerp / 2
end

-- Select reasonable colors for trees that grow on various tiles.

local yumako_neighbor_tree_color = low_fertility_yumako_color:interpolate_shorter_hue(high_fertility_yumako_color, neighbor_tree_lerp)
local jellynut_neighbor_tree_color = low_fertility_jellynut_color:interpolate_shorter_hue(high_fertility_jellynut_color, neighbor_tree_lerp)
local shared_neighbor_tree_color = yumako_neighbor_tree_color:interpolate_decreasing_hue(jellynut_neighbor_tree_color, 0.5)

yumako_neighbor_tree_color.h = modulo(yumako_neighbor_tree_color.h - 0.05, 1.0)
yumako_neighbor_tree_color.c = yumako_neighbor_tree_color.c * 0.4

jellynut_neighbor_tree_color.h = modulo(jellynut_neighbor_tree_color.h + 0.05, 1.0)
jellynut_neighbor_tree_color.c = jellynut_neighbor_tree_color.c * 0.4

shared_neighbor_tree_color.c = shared_neighbor_tree_color.c * 0.2

local other_tree_color = highland_color:interpolate_shorter_hue(midland_color, 0.5):interpolate_shorter_hue(midland_color:interpolate_shorter_hue(lowland_color, 0.5), 0.5)
other_tree_color.h = modulo(other_tree_color.h + 0.2, 1.0)
other_tree_color.c = other_tree_color.l * 0.8
other_tree_color.c = other_tree_color.c * 0.5

-- Calculate interpolated colors for fertile soil tiles.

medium_fertility_yumako_color = low_fertility_yumako_color:interpolate_shorter_hue(high_fertility_yumako_color, medium_fertility_lerp)
medium_fertility_jellynut_color = low_fertility_jellynut_color:interpolate_shorter_hue(high_fertility_jellynut_color, medium_fertility_lerp)
if low_fertility_lerp > 0.0 then
	low_fertility_yumako_color = low_fertility_yumako_color:interpolate_shorter_hue(high_fertility_yumako_color, low_fertility_lerp)
	low_fertility_jellynut_color = low_fertility_jellynut_color:interpolate_shorter_hue(high_fertility_jellynut_color, low_fertility_lerp)
end

medium_fertility_yumako_game_color = medium_fertility_yumako_color:to_game_color()
low_fertility_yumako_game_color = low_fertility_yumako_color:to_game_color()
medium_fertility_jellynut_game_color = medium_fertility_jellynut_color:to_game_color()
low_fertility_jellynut_game_color = low_fertility_jellynut_color:to_game_color()

-- Apply new colors to tile and tree prototypes.

set_map_color_for_tiles(yumako_tile_tiers.high_fertility, high_fertility_yumako_game_color)
set_map_color_for_tiles(yumako_tile_tiers.medium_fertility, medium_fertility_yumako_game_color)
set_map_color_for_tiles(yumako_tile_tiers.low_fertility, low_fertility_yumako_game_color)
set_map_color_for_tiles(yumako_tile_tiers.artificial, artificial_yumako_game_color)

set_map_color_for_tiles(jellynut_tile_tiers.high_fertility, high_fertility_jellynut_game_color)
set_map_color_for_tiles(jellynut_tile_tiers.medium_fertility, medium_fertility_jellynut_game_color)
set_map_color_for_tiles(jellynut_tile_tiers.low_fertility, low_fertility_jellynut_game_color)
set_map_color_for_tiles(jellynut_tile_tiers.artificial, artificial_jellynut_game_color)

set_map_color_for_tiles(nonagricultural_tile_tiers.deep_water, deep_water_game_color)
set_map_color_for_tiles(nonagricultural_tile_tiers.shallow_water, shallow_water_game_color)
set_map_color_for_tiles(nonagricultural_tile_tiers.lowland, lowland_game_color)
set_map_color_for_tiles(nonagricultural_tile_tiers.midland, midland_game_color)
set_map_color_for_tiles(nonagricultural_tile_tiers.highland, highland_game_color)
set_map_color_for_tiles(nonagricultural_tile_tiers.other, other_game_color)

set_map_color_for_trees(yumako_neighbor_trees, yumako_neighbor_tree_color:to_game_color())
set_map_color_for_trees(jellynut_neighbor_trees, jellynut_neighbor_tree_color:to_game_color())
set_map_color_for_trees(shared_neighbor_trees, shared_neighbor_tree_color:to_game_color())
set_map_color_for_trees(other_trees, other_tree_color:to_game_color())
