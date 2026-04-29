local function copy_color(color)
	if #color >= 3 then
		return {r=color[1], g=color[2], b=color[3]}
	else
		return {r=color.r, g=color.g, b=color.b}
	end
end

local function copy_current_settings()
	return {
		agricultural_stage = settings.startup["functional-gleba-map-colors-agricultural-stage"].value,
		agricultural_stage_contrast = settings.startup["functional-gleba-map-colors-agricultural-stage-contrast"].value,

		high_fertility_yumako_game_color = copy_color(settings.startup["functional-gleba-map-colors-high-fertility-yumako-color"].value),
		low_fertility_yumako_game_color = copy_color(settings.startup["functional-gleba-map-colors-low-fertility-yumako-color"].value),
		artificial_yumako_game_color = copy_color(settings.startup["functional-gleba-map-colors-artificial-yumako-color"].value),
		high_fertility_jellynut_game_color = copy_color(settings.startup["functional-gleba-map-colors-high-fertility-jellynut-color"].value),
		low_fertility_jellynut_game_color = copy_color(settings.startup["functional-gleba-map-colors-low-fertility-jellynut-color"].value),
		artificial_jellynut_game_color = copy_color(settings.startup["functional-gleba-map-colors-artificial-jellynut-color"].value),

		highland_game_color = copy_color(settings.startup["functional-gleba-map-colors-highland-color"].value),
		midland_game_color = copy_color(settings.startup["functional-gleba-map-colors-midland-color"].value),
		lowland_game_color = copy_color(settings.startup["functional-gleba-map-colors-lowland-color"].value),
		shallow_water_game_color = copy_color(settings.startup["functional-gleba-map-colors-shallow-water-color"].value),
		deep_water_game_color = copy_color(settings.startup["functional-gleba-map-colors-deep-water-color"].value),
		other_game_color = copy_color(settings.startup["functional-gleba-map-colors-other-color"].value),
	}
end

local function compare_colors(lhs, rhs)
	if lhs.r ~= rhs.r then return false end
	if lhs.g ~= rhs.g then return false end
	if lhs.b ~= rhs.b then return false end
	return true
end

local function compare_settings(lhs, rhs)
	if lhs.agricultural_stage ~= rhs.agricultural_stage then return false end
	if lhs.agricultural_stage_contrast ~= rhs.agricultural_stage_contrast then return false end

	if compare_colors(lhs.high_fertility_yumako_game_color, rhs.high_fertility_yumako_game_color) == false then return false end
	if compare_colors(lhs.low_fertility_yumako_game_color, rhs.low_fertility_yumako_game_color) == false then return false end
	if compare_colors(lhs.artificial_yumako_game_color, rhs.artificial_yumako_game_color) == false then return false end
	if compare_colors(lhs.high_fertility_jellynut_game_color, rhs.high_fertility_jellynut_game_color) == false then return false end
	if compare_colors(lhs.low_fertility_jellynut_game_color, rhs.low_fertility_jellynut_game_color) == false then return false end
	if compare_colors(lhs.artificial_jellynut_game_color, rhs.artificial_jellynut_game_color) == false then return false end

	if compare_colors(lhs.highland_game_color, rhs.highland_game_color) == false then return false end
	if compare_colors(lhs.midland_game_color, rhs.midland_game_color) == false then return false end
	if compare_colors(lhs.lowland_game_color, rhs.lowland_game_color) == false then return false end
	if compare_colors(lhs.shallow_water_game_color, rhs.shallow_water_game_color) == false then return false end
	if compare_colors(lhs.deep_water_game_color, rhs.deep_water_game_color) == false then return false end
	if compare_colors(lhs.other_game_color, rhs.other_game_color) == false then return false end
	return true
end

local function rechart_on_first_tick()
	script.on_event(defines.events.on_tick, function(event)
		local gleba_surface = game.surfaces["gleba"]
		if gleba_surface and gleba_surface.is_chunk_generated({0, 0}) then
			for force_name, force in pairs(game.forces) do
				if #force.players >= 1 then
					force.rechart("gleba")
					force.print({ "functional-gleba-map-colors-messages.recharting-gleba-map" }, { game_state = false })
				end
			end
		end
		script.on_event(defines.events.on_tick, nil)
	end)
end

script.on_init(function()
	storage.settings = copy_current_settings()
	rechart_on_first_tick()
end)

script.on_configuration_changed(function(change_data)
	if change_data.mod_startup_settings_changed then
		local current_settings = copy_current_settings()
		if storage.settings and compare_settings(storage.settings, current_settings) == false then
			storage.settings = current_settings
			rechart_on_first_tick()
		end
	end
end)
