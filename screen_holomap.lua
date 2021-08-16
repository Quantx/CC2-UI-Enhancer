g_colors = {
    backlight_default = color8(0, 2, 10, 255),
    glow_default = color8(64, 204, 255, 255),
    island_low_default = color8(0, 32, 64, 255),
    island_high_default = color8(0, 255, 255, 255),
    base_layer_default = color8(0, 5, 5, 255),
    grid_1_default = color8(0, 123, 201, 255),
    grid_2_default = color8(0, 26, 52, 128),
    holo = color8(0, 255, 255, 255),
    good = color8(0, 128, 255, 255),
    bad = color_status_bad
}

g_map_x = 0
g_map_z = 0
g_map_size = 2000
g_map_x_offset = 0
g_map_z_offset = 0
g_map_size_offset = 0

g_ui = nil

g_button_mode = 0
g_is_map_pos_initialised = false
g_is_render_holomap = true
g_is_render_holomap_tiles = true
g_is_render_holomap_vehicles = true
g_is_render_holomap_missiles = true
g_is_render_holomap_grids = true
g_is_render_holomap_backlight = true
g_is_render_team_capture = true
g_is_override_holomap_island_color = false

g_holomap_override_island_color_low = g_colors.island_low_default
g_holomap_override_island_color_high = g_colors.island_high_default
g_holomap_override_base_layer_color = g_colors.base_layer_default
g_holomap_backlight_color = g_colors.backlight_default
g_holomap_glow_color = g_colors.glow_default
g_holomap_grid_1_color = g_colors.grid_1_default
g_holomap_grid_2_color = g_colors.grid_2_default

g_blend_tick = 0
g_prev_pos_x = 0
g_prev_pos_y = 0
g_prev_size = (64 * 1024)
g_next_pos_x = 0
g_next_pos_y = 0
g_next_size = (64 * 1024)

g_is_pointer_hovered = false
g_pointer_pos_x = 0
g_pointer_pos_y = 0
g_pointer_pos_x_prev = 0
g_pointer_pos_y_prev = 0
g_is_pointer_pressed = false
g_is_mouse_mode = false
g_pointer_inbounds = false

g_startup_op_num = 0
g_startup_phase = 0
g_startup_phase_anim = 0

holomap_startup_phases = {
	memchk = 0,
	bios = 1,
	sys = 2,
	manual = 3,
	finish = 4
}

g_is_ruler = false
g_is_ruler_set = false
g_ruler_beg_x = 0
g_ruler_beg_y = 0
g_ruler_end_x = 0
g_ruler_end_y = 0

g_highlighted_vehicle_id = 0

g_color_waypoint = color8(0, 255, 255, 8)

g_is_dismiss_pressed = false
g_animation_time = 0
g_dismiss_counter = 0
g_dismiss_duration = 20
g_notification_time = 0

g_focus_mode = 0

function parse()
    g_prev_pos_x = g_next_pos_x
    g_prev_pos_y = g_next_pos_y
    g_prev_size = g_next_size
    g_blend_tick = 0
    
    g_next_pos_x = parse_f32(g_next_pos_x)
    g_next_pos_y = parse_f32(g_next_pos_y)
    g_next_size = parse_f32(g_next_size)
end

function begin()
    begin_load()
    begin_load_inventory_data()
	g_ui = lib_imgui:create_ui()
	
	g_startup_op_num = math.random(9999999999)
end

function update(screen_w, screen_h)
    g_is_mouse_mode = update_get_active_input_type() == e_active_input.keyboard
    g_animation_time = g_animation_time + 1

    local screen_vehicle = update_get_screen_vehicle()
	local world_x, world_y = get_world_from_holomap(g_pointer_pos_x, g_pointer_pos_y, screen_w, screen_h)
	local is_local = update_get_is_focus_local()

    if g_focus_mode ~= 0 then
        if g_focus_mode == 1 then
            focus_carrier()
        elseif g_focus_mode == 2 then
            focus_world()
        end

		g_startup_phase = holomap_startup_phases.finish
        g_focus_mode = 0
    end

    local function step(a, b, c)
        return a + clamp(b - a, -c, c)
    end

    if g_map_size_offset > 0 then
        g_map_x_offset = lerp(g_map_x_offset, 0, 0.15)
        g_map_z_offset = lerp(g_map_z_offset, 0, 0.15)
        
        if math.abs(g_map_x_offset) < 1000 then
            g_map_size_offset = step(g_map_size_offset, 0, 4000)
        end
    else
        g_map_size_offset = step(g_map_size_offset, 0, 4000)

        if math.abs(g_map_size_offset) < 1000 then
            g_map_x_offset = lerp(g_map_x_offset, 0, 0.15)
            g_map_z_offset = lerp(g_map_z_offset, 0, 0.15)
        end
    end

    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_pan), e_ui_interaction_special.map_pan)
    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_zoom), e_ui_interaction_special.map_zoom)
	update_add_ui_interaction("map tool", e_game_input.interact_a)
	if screen_vehicle:get() and screen_vehicle:get_dock_state() ~= e_vehicle_dock_state.docked then
		if g_startup_phase ~= holomap_startup_phases.finish then focus_world() end
		g_startup_phase = holomap_startup_phases.finish
		
		update_add_ui_interaction("set carrier waypoint", e_game_input.interact_b)
	end
	
    if g_is_map_pos_initialised == false then
        g_is_map_pos_initialised = true
        focus_world()
    end

    if is_local then
        g_next_pos_x = g_map_x
        g_next_pos_y = g_map_z
        g_next_size = g_map_size
    else
        g_blend_tick = g_blend_tick + 1
        local blend_factor = clamp(g_blend_tick / 10.0, 0.0, 1.0)
        g_map_x = lerp(g_prev_pos_x, g_next_pos_x, blend_factor)
        g_map_z = lerp(g_prev_pos_y, g_next_pos_y, blend_factor)
        g_map_size = lerp(g_prev_size, g_next_size, blend_factor)
    end
    
    if g_is_mouse_mode and g_pointer_inbounds and update_get_is_notification_holomap_set() == false then
        local pointer_dx = g_pointer_pos_x - g_pointer_pos_x_prev
        local pointer_dy = g_pointer_pos_y - g_pointer_pos_y_prev

        if g_is_pointer_pressed then
            g_map_x = g_map_x - pointer_dx * g_map_size * 0.005
            g_map_z = g_map_z + pointer_dy * g_map_size * 0.005
        end
    end

	update_set_screen_background_type(g_button_mode + 1)
	update_set_screen_background_is_render_islands(false)
	update_set_screen_map_position_scale(g_map_x + g_map_x_offset, g_map_z + g_map_z_offset, g_map_size + g_map_size_offset)
	g_is_render_holomap_tiles = true
	g_is_render_holomap_vehicles = true
	g_is_render_holomap_missiles = true
	g_is_render_holomap_grids = true
	g_is_render_holomap_backlight = true
	g_is_render_team_capture = true
	g_is_override_holomap_island_color = false
	g_holomap_override_island_color_low = g_colors.island_low_default
	g_holomap_override_island_color_high = g_colors.island_high_default
	g_holomap_override_base_layer_color = g_colors.base_layer_default
	g_holomap_backlight_color = g_colors.backlight_default
	g_holomap_glow_color = g_colors.glow_default
	g_holomap_grid_1_color = g_colors.grid_1_default
	g_holomap_grid_2_color = g_colors.grid_2_default

	update_ui_rectangle(0, 0, screen_w, screen_h, color8(0, 0, 0, 220))

	g_ui:begin_ui()

	if g_startup_phase ~= holomap_startup_phases.finish then
		update_set_screen_background_type(0)
		update_set_screen_background_is_render_islands(false)
		update_set_screen_map_position_scale(-10000, -10000, 500)
	
		if screen_vehicle:get() then
			local veh = update_get_vehicle_by_id(screen_vehicle:get_id())
			local target_desired, target_allocated = veh:get_power_system_state(4) -- Radar
			if target_desired == 0 then	g_startup_phase_anim = g_startup_phase_anim + 1	end
		end
	
		if g_startup_phase == holomap_startup_phases.memchk then
			render_startup_memchk( screen_w, screen_h )
		elseif g_startup_phase == holomap_startup_phases.bios then
			render_startup_bios( screen_w, screen_h )
		elseif g_startup_phase == holomap_startup_phases.sys then
			render_startup_sys( screen_w, screen_h )
		elseif g_startup_phase == holomap_startup_phases.manual then
			render_startup_manual( screen_w, screen_h )
		end
		
		if g_startup_phase == holomap_startup_phases.finish then
			focus_world()
		end
    elseif update_get_is_notification_holomap_set() then
        g_notification_time = g_notification_time + 1

        update_set_screen_background_type(0)
        update_set_screen_background_is_render_islands(false)
        
        local notification = update_get_notification_holomap()
        local notification_col = get_notification_color(notification)

        g_holomap_backlight_color = color8(notification_col:r(), notification_col:g(), notification_col:b(), 10)
        g_holomap_glow_color = notification_col

        local border_col = notification_col
        local border_padding = 8
        local border_thickness = 4
        local border_w = 32
        local border_h = 24

        update_ui_rectangle(border_padding, border_padding, border_w, border_thickness, border_col)
        update_ui_rectangle(border_padding, border_padding, border_thickness, border_h, border_col)
        update_ui_rectangle(screen_w - border_padding - border_w, border_padding, border_w, border_thickness, border_col)
        update_ui_rectangle(screen_w - border_padding - border_thickness, border_padding, border_thickness, border_h, border_col)
        update_ui_rectangle(border_padding, screen_h - border_padding - border_thickness, border_w, border_thickness, border_col)
        update_ui_rectangle(border_padding, screen_h - border_padding - border_h, border_thickness, border_h, border_col)
        update_ui_rectangle(screen_w - border_padding - border_w, screen_h - border_padding - border_thickness, border_w, border_thickness, border_col)
        update_ui_rectangle(screen_w - border_padding - border_thickness, screen_h - border_padding - border_h, border_thickness, border_h, border_col)

        if notification:get() then
            render_notification_display(screen_w, screen_h, notification)
        end

        local is_dismiss = g_is_dismiss_pressed or (g_is_pointer_pressed and g_is_pointer_hovered and g_is_mouse_mode)
        
        if g_notification_time >= 30 then
            local color_dismiss = color_white
            update_ui_push_offset(screen_w / 2, screen_h - 34)

            if is_dismiss then
                local dismiss_factor = clamp(g_dismiss_counter / g_dismiss_duration, 0, 1)
                update_ui_rectangle(-30, -2, 60 * dismiss_factor, 13, color_dismiss)
            end

            update_ui_rectangle_outline(-30, -2, 60, 13, iff(is_dismiss, color_dismiss, iff(g_animation_time % 20 > 10, color_white, color_black)))
            update_ui_text(-30, 0, update_get_loc(e_loc.upp_dismiss), 60, 1, iff(is_dismiss, color_dismiss, color_white), 0)
            update_ui_pop_offset()
        end

        if is_dismiss then
            g_dismiss_counter = g_dismiss_counter + 1
        else
            g_dismiss_counter = 0
        end

        if g_dismiss_counter > g_dismiss_duration then
            g_dismiss_counter = 0
            g_is_dismiss_pressed = false
            g_is_pointer_pressed = false
            update_map_dismiss_notification()
        end
    else
		local map_zoom = g_map_size + g_map_size_offset

		if map_zoom < 70000 then
			local island_count = update_get_tile_count()
			for i = 0, island_count - 1, 1 do 
				local island = update_get_tile_by_index(i)

				if island ~= nil and island:get() then
					local island_color = update_get_team_color(island:get_team_control())
					local island_pos = island:get_position_xz()
					local island_size = island:get_size()

					local screen_pos_x = 0
					local screen_pos_y = 0
					
					if map_zoom < 16000 then
						screen_pos_x, screen_pos_y = get_holomap_from_world(island_pos:x(), island_pos:y() + (island_size:y() / 2), screen_w, screen_h)
					else
						screen_pos_x, screen_pos_y = get_holomap_from_world(island_pos:x(), island_pos:y(), screen_w, screen_h)
						screen_pos_y = screen_pos_y - 27
					end

					local command_center_count = island:get_command_center_count()
					if command_center_count > 0 then
						--local command_center_position = island:get_command_center_position(0)
						--local cmd_pos_x, cmd_pos_y = get_holomap_from_world(command_center_position:x(), command_center_position:y(), screen_w, screen_h)

						local island_capture = island:get_team_capture()
						local island_team = island:get_team_control()
						local island_capture_progress = island:get_team_capture_progress()
						local team_color = update_get_team_color(island_capture)

						if island_capture ~= island_team and island_capture ~= -1 and island_capture_progress > 0 then
							update_ui_rectangle(screen_pos_x - 13, screen_pos_y - 16, 26, 5, color_black)
							update_ui_rectangle(screen_pos_x - 12, screen_pos_y - 15, 24 * island_capture_progress, 3, team_color)
						end
					end

					update_ui_text(screen_pos_x - 64, screen_pos_y - 10, island:get_name(), 128, 1, island_color, 0)
					
					local category_data = g_item_categories[island:get_facility_category()]
					
					update_ui_image(screen_pos_x - 4, screen_pos_y, category_data.icon, island_color, 0)
					
					if island:get_team_control() ~= update_get_screen_team_id() then
						local difficulty_level = island:get_difficulty_level()
						local icon_w = 6
						local icon_spacing = 2
						local total_w = icon_w * difficulty_level + icon_spacing * (difficulty_level - 1)

						for i = 0, difficulty_level - 1 do
							update_ui_image(screen_pos_x - total_w / 2 + (icon_w + icon_spacing) * i, screen_pos_y + 9, atlas_icons.column_difficulty, island_color, 0)
						end
					end
				end
			end
		end

		if screen_vehicle:get() then
			local waypoint_count = screen_vehicle:get_waypoint_count()
			
			local screen_vehicle_pos = screen_vehicle:get_position_xz()
			local waypoint_prev_x, waypoint_prev_y = get_holomap_from_world(screen_vehicle_pos:x(), screen_vehicle_pos:y(), screen_w, screen_h)
			
			local waypoint_remove = -1
			
			for i = 0, waypoint_count - 1, 1 do
				local waypoint = screen_vehicle:get_waypoint(i)
				local waypoint_pos = waypoint:get_position_xz()
				
				local waypoint_distance = vec2_dist( screen_vehicle_pos, waypoint_pos )
				
				if waypoint_distance < 500 then
					waypoint_remove = i
				end
				
				local waypoint_screen_pos_x, waypoint_screen_pos_y = get_holomap_from_world(waypoint_pos:x(), waypoint_pos:y(), screen_w, screen_h)
				
				update_ui_line(waypoint_prev_x, waypoint_prev_y, waypoint_screen_pos_x, waypoint_screen_pos_y, g_color_waypoint)
				update_ui_image(waypoint_screen_pos_x - 3, waypoint_screen_pos_y - 3, atlas_icons.map_icon_waypoint, g_color_waypoint, 0)
				
				waypoint_prev_x = waypoint_screen_pos_x
				waypoint_prev_y = waypoint_screen_pos_y
			end
			
			if waypoint_remove > -1 then
				local waypoint_path = {}
				
				for i = waypoint_remove + 1, waypoint_count - 1, 1 do
					local waypoint = screen_vehicle:get_waypoint(i)
					
					waypoint_path[#waypoint_path + 1] = waypoint:get_position_xz()
				end
				
				screen_vehicle:clear_waypoints()
				
				for i = 1, #waypoint_path, 1 do
					screen_vehicle:add_waypoint(waypoint_path[i]:x(), waypoint_path[i]:y())
				end
			end
		end

		g_highlighted_vehicle_id = 0
		if not g_is_pointer_pressed and is_local then
			local highlighted_distance_best = 4 * math.max( 1, 2000 / map_zoom )
			
			local vehicle_count = update_get_map_vehicle_count()
			for i = 0, vehicle_count - 1, 1 do 
				local vehicle = update_get_map_vehicle_by_index(i)

				if vehicle:get() then
					local vehicle_definition_index = vehicle:get_definition_index()

					if vehicle_definition_index ~= e_game_object_type.chassis_spaceship and vehicle_definition_index ~= e_game_object_type.drydock and vehicle_definition_index ~= e_game_object_type.carrier then
						local vehicle_team = vehicle:get_team()
						local vehicle_attached_parent_id = vehicle:get_attached_parent_id()

						if vehicle_attached_parent_id == 0 and vehicle:get_is_visible() and vehicle:get_is_observation_revealed() then
							local vehicle_pos_xz = vehicle:get_position_xz()
							local screen_pos_x, screen_pos_y = get_holomap_from_world(vehicle_pos_xz:x(), vehicle_pos_xz:y(), screen_w, screen_h)

							local vehicle_distance_to_cursor = vec2_dist( vec2( screen_pos_x, screen_pos_y ), vec2( g_pointer_pos_x, g_pointer_pos_y ) )

							if vehicle_distance_to_cursor < highlighted_distance_best then
								g_highlighted_vehicle_id = vehicle:get_id()
--									g_highlighted_waypoint_id = 0
								highlighted_distance_best = vehicle_distance_to_cursor
							end
						end
--[[
						if vehicle_team == update_get_screen_team_id() then
							local waypoint_count = vehicle:get_waypoint_count()
							
							if g_drag_vehicle_id == 0 or g_drag_vehicle_id == vehicle:get_id() then
								for j = 0, waypoint_count - 1, 1 do
									local waypoint = vehicle:get_waypoint(j)
									local waypoint_type = waypoint:get_type()

									if waypoint_type == e_waypoint_type.move or waypoint_type == e_waypoint_type.deploy then
										local waypoint_pos = waypoint:get_position_xz(j)
										local waypoint_screen_pos_x, waypoint_screen_pos_y = get_screen_from_world(waypoint_pos:x(), waypoint_pos:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
										local waypoint_distance_to_cursor = math.abs(waypoint_screen_pos_x - g_pointer_pos_x) + math.abs(waypoint_screen_pos_y - g_pointer_pos_y)

										if waypoint_distance_to_cursor < highlighted_distance_best then
											g_highlighted_vehicle_id = vehicle:get_id()
											g_highlighted_waypoint_id = waypoint:get_id()
											highlighted_distance_best = waypoint_distance_to_cursor
										end
									end
								end
							end
						end
--]]
					end
				end
			end
		end
		
		if g_is_ruler then
			if g_pointer_inbounds then
				g_ruler_end_x = world_x
				g_ruler_end_y = world_y
			end
			
			if not g_is_ruler_set and g_pointer_inbounds then
				g_ruler_beg_x = g_ruler_end_x
				g_ruler_beg_y = g_ruler_end_y
				
				g_is_ruler_set = true
			end
		
			if g_is_ruler_set then
				local cy = screen_h - 45
				local cx = 15
				
				local icon_col = color_grey_mid
				local text_col = color_grey_dark
				
				local screen_beg_x, screen_beg_y = get_holomap_from_world(g_ruler_beg_x, g_ruler_beg_y, screen_w, screen_h)
				local screen_end_x, screen_end_y = get_holomap_from_world(g_ruler_end_x, g_ruler_end_y, screen_w, screen_h)
				
				update_ui_line(screen_beg_x, screen_beg_y, screen_end_x, screen_end_y, color_grey_dark)
				
				update_ui_text(cx, cy, "X", 100, 0, icon_col, 0)
				update_ui_text(cx + 15, cy, string.format("%.0f", g_ruler_end_x), 100, 0, text_col, 0)
				cy = cy + 10
				
				update_ui_text(cx, cy, "Y", 100, 0, icon_col, 0)
				update_ui_text(cx + 15, cy, string.format("%.0f", g_ruler_end_y), 100, 0, text_col, 0)
				cy = cy + 10
				
				local dist = vec2_dist(vec2(g_ruler_beg_x, g_ruler_beg_y), vec2(g_ruler_end_x, g_ruler_end_y))

				if dist < 10000 then
					update_ui_image(cx, cy, atlas_icons.column_distance, icon_col, 0)
					update_ui_text(cx + 15, cy, string.format("%.0f ", dist) .. update_get_loc(e_loc.acronym_meters), 100, 0, text_col, 0)
				else
					update_ui_image(cx, cy, atlas_icons.column_distance, icon_col, 0)
					update_ui_text(cx + 15, cy, string.format("%.2f ", dist / 1000) .. update_get_loc(e_loc.acronym_kilometers), 100, 0, text_col, 0)
				end

				cy = cy + 10

				local bearing = 90 - math.atan(g_ruler_end_y - g_ruler_beg_y, g_ruler_end_x - g_ruler_beg_x) / math.pi * 180

				if bearing < 0 then bearing = bearing + 360 end

				update_ui_image(cx, cy, atlas_icons.column_angle, icon_col, 0)
				update_ui_text(cx + 15, cy, string.format("%.0f deg", bearing), 100, 0, text_col, 0)
				cy = cy + 10
			end
		else
			if g_highlighted_vehicle_id > 0 then
				local highlighted_vehicle = update_get_map_vehicle_by_id(g_highlighted_vehicle_id)

				if highlighted_vehicle:get() then
					if get_vehicle_has_robot_dogs(highlighted_vehicle) then
						render_tooltip(10, 10, screen_w - 20, screen_h - 20, g_pointer_pos_x, g_pointer_pos_y, 128, 31, 10, function(w, h) render_vehicle_tooltip(w, h, highlighted_vehicle) end)
					else
						render_tooltip(10, 10, screen_w - 20, screen_h - 20, g_pointer_pos_x, g_pointer_pos_y, 128, 21, 10, function(w, h) render_vehicle_tooltip(w, h, highlighted_vehicle) end)
					end
				end
			end
		
			local cy = screen_h - 15
			local cx = 15
			
			local icon_col = color_grey_mid
			local text_col = color_grey_dark
			
			local map_scale = 500
			local map_scale_size = map_zoom
			
			while map_scale_size > 2000 and map_scale < 16000 do
				map_scale_size = map_scale_size / 2
				map_scale = map_scale * 2
			end
			
			if map_scale < 10000 then
				update_ui_image(cx, cy, atlas_icons.column_distance, icon_col, 0)
				update_ui_text(cx + 15, cy, string.format("%.0f ", map_scale) .. update_get_loc(e_loc.acronym_meters), 100, 0, text_col, 0)
			else
				update_ui_image(cx, cy, atlas_icons.column_distance, icon_col, 0)
				update_ui_text(cx + 15, cy, string.format("%.2f ", map_scale / 1000) .. update_get_loc(e_loc.acronym_kilometers), 100, 0, text_col, 0)
			end
			
			cy = cy - 10
			
			local map_pos_x = g_map_x + g_map_x_offset
			local map_pos_y = g_map_z + g_map_z_offset
			
			if is_local then
				map_pos_x = world_x
				map_pos_y = world_y
			end
			
			update_ui_text(cx, cy, "Y", 100, 0, icon_col, 0)
			update_ui_text(cx + 15, cy, string.format("%.0f", map_pos_x), 100, 0, text_col, 0)
			cy = cy - 10
			
			update_ui_text(cx, cy, "X", 100, 0, icon_col, 0)
			update_ui_text(cx + 15, cy, string.format("%.0f", map_pos_y), 100, 0, text_col, 0)
			cy = cy - 10
		end
		
		-- render cursor last
		if g_pointer_inbounds and is_local then
			local cursor_x, cursor_y = get_holomap_from_world(world_x, world_y, screen_w, screen_h)
			update_ui_text(cursor_x - 3, cursor_y - 6, "x", 6, 0, color_white, 0)
		end

        g_dismiss_counter = 0
        g_notification_time = 0
    end

	if g_pointer_inbounds then
		g_pointer_pos_x_prev = g_pointer_pos_x
		g_pointer_pos_y_prev = g_pointer_pos_y
	end

    -- Adds a scale marker to the holomap; values are derived empirically
    update_ui_image(0, 0, atlas_icons.column_distance, color_white, 0)
    local grid_size_guess = 0

    if g_map_size < 2000 then
        grid_size_guess = 250
    elseif g_map_size >= 2000 and g_map_size < 4000 then
        grid_size_guess = 500
    elseif g_map_size >= 4000 and g_map_size < 8000 then
        grid_size_guess = 1000
    elseif g_map_size >= 8000 and g_map_size < 16000 then
        grid_size_guess = 2000
    elseif g_map_size >= 16000 and g_map_size < 32000 then
        grid_size_guess = 4000
    elseif g_map_size >= 32000 then
        grid_size_guess = 8000
    end
    update_ui_text(-10, 0, string.format("%.0f", grid_size_guess) .. update_get_loc(e_loc.upp_acronym_meters), 128, 1, color_white, 0)

    g_ui:end_ui()
end

function input_event(event, action)
	g_ui:input_event(event, action)
	
	local screen_vehicle = update_get_screen_vehicle()
	local world_x, world_y = get_world_from_holomap(g_pointer_pos_x, g_pointer_pos_y, 512, 256)

    if event == e_input.action_a then
        g_is_dismiss_pressed = action == e_input_action.press
		g_is_ruler = action == e_input_action.press
	elseif event == e_input.action_b then
		if action == e_input_action.press and g_pointer_inbounds and screen_vehicle:get() and screen_vehicle:get_dock_state() ~= e_vehicle_dock_state.docked then
			local screen_vehicle_pos = screen_vehicle:get_position_xz()
			local carrier_pos_x, carrier_pos_y = get_holomap_from_world(screen_vehicle_pos:x(), screen_vehicle_pos:y(), 512, 256)
		
			local carrier_screen_size = 16 * math.max( 1, 2000 / (g_map_size + g_map_size_offset) )
			local carrier_screen_dist = vec2_dist( vec2(carrier_pos_x, carrier_pos_y), vec2(g_pointer_pos_x, g_pointer_pos_y ) )
			
			local waypoint_count = screen_vehicle:get_waypoint_count()
			
			if carrier_screen_dist <= carrier_screen_size then
				screen_vehicle:clear_waypoints()
			elseif waypoint_count < 20 then
				screen_vehicle:add_waypoint(world_x, world_y)
			end
		end
    elseif event == e_input.pointer_1 then
        g_is_pointer_pressed = action == e_input_action.press
    elseif event == e_input.back then
        g_is_ruler = false
        update_set_screen_state_exit()
    end
	
	if not g_is_ruler then
		g_is_ruler_set = false
	end
end

function input_axis(x, y, z, w)
    if update_get_is_notification_holomap_set() == false then
        g_map_x = g_map_x + x * g_map_size * 0.02
        g_map_z = g_map_z + y * g_map_size * 0.02
        map_zoom(1.0 - w * 0.1)
    end
end

function input_pointer(is_hovered, x, y)
	g_ui:input_pointer(is_hovered, x, y)
	
    g_is_pointer_hovered = is_hovered
    
	g_pointer_inbounds = (x > 0 and y > 0)
	
    g_pointer_pos_x = x
    g_pointer_pos_y = y
	
end

function input_scroll(dy)
	g_ui:input_scroll(dy)
	
    if update_get_is_notification_holomap_set() == false then
        if g_is_mouse_mode then
            map_zoom(1 - dy * 0.15)
        end
    end
end

function on_set_focus_mode(mode)
    g_focus_mode = mode
end

function map_zoom(amount)
    g_map_size = g_map_size * amount
    g_map_size = math.max(500, math.min(g_map_size, 200000))
end

function render_notification_display(screen_w, screen_h, notification)
    local notification_type = notification:get_type()
    local notification_color = get_notification_color(notification)
    local text_col = notification_color

    -- g_is_render_holomap_grids = false

    if notification_type == e_map_notification_type.island_captured then
        local tile = update_get_tile_by_id(notification:get_tile_id())
        render_notification_tile(screen_w, screen_h, update_get_loc(e_loc.upp_island_captured), text_col, tile)

        g_is_render_holomap_vehicles = false
        g_is_render_holomap_missiles = false
        g_is_render_team_capture = false
        g_is_override_holomap_island_color = true
        g_holomap_override_island_color_low = g_colors.island_low_default
        g_holomap_override_island_color_high = g_colors.good
        g_holomap_override_base_layer_color = g_colors.base_layer_default
        g_holomap_glow_color = color8(64, 128, 255, 255)
    elseif notification_type == e_map_notification_type.island_lost then
        local tile = update_get_tile_by_id(notification:get_tile_id())
        render_notification_tile(screen_w, screen_h, update_get_loc(e_loc.upp_island_lost), text_col, tile)

        g_is_render_holomap_vehicles = false
        g_is_render_holomap_missiles = false
        g_is_render_team_capture = false
        g_is_override_holomap_island_color = true
        g_holomap_override_island_color_low = color8(32, 0, 0, 255)
        g_holomap_override_island_color_high = color8(255, 32, 0, 255)
        g_holomap_override_base_layer_color = color8(5, 1, 0, 255)
        g_holomap_backlight_color = color8(255, 0, 0, 10)
        g_holomap_grid_1_color = color8(128, 32, 0, 255)
        g_holomap_grid_2_color = color8(100, 0, 0, 128)
        g_holomap_glow_color = color8(255, 16, 8, 255)
    elseif notification_type == e_map_notification_type.blueprint_unlocked then
        render_notification_blueprint(screen_w, screen_h, notification:get_blueprints(), text_col)

        g_is_render_holomap_vehicles = false
        g_is_render_holomap_missiles = false
        g_is_render_team_capture = false
        g_is_render_holomap_tiles = false
        -- g_is_render_holomap_grids = false

        g_holomap_grid_1_color = mult_alpha(text_col, 0.1)
        g_holomap_grid_2_color = mult_alpha(text_col, 0.05)
    end
end

function render_notification_blueprint(screen_w, screen_h, blueprints, text_col)
    if #blueprints > 0 then
        local label = iff(#blueprints == 1, update_get_loc(e_loc.upp_blueprint_unlocked), update_get_loc(e_loc.upp_blueprints_unlocked))
        local item_spacing = 5
        local item_h = 18
        local rows_per_column = 6
        local columns = math.ceil(#blueprints / rows_per_column)
        local rows = iff(#blueprints <= rows_per_column, #blueprints, math.floor((#blueprints - 1) / columns) + 1)

        local display_h = 30 + rows * (item_h + item_spacing)
        local cy = (screen_h - display_h) / 2
        
        update_ui_text_scale(0, cy, label, screen_w, 1, text_col, 0, 3)
        cy = cy + 30 + item_spacing

        local function render_item_data(x, y, w, item)
            update_ui_push_offset(x, y)
            update_ui_rectangle_outline(0, 0, 18, 18, text_col)
            update_ui_image(1, 1, item.icon, color_white, 0)
            update_ui_text(22, 4, item.name, w - 22, 0, color_white, 0)

            update_ui_pop_offset()
        end

        local column_width = 120
        local column_spacing = 5
        local column_items = {}

        local function render_columns(items)
            if #items > 0 then
                local total_column_width = #items * (column_width + column_spacing) - column_spacing
                
                for i = 1, #items do
                    local cx = (screen_w - total_column_width) / 2 + (i - 1) * (column_width + column_spacing)
                    render_item_data(cx, cy, column_width, items[i])
                end

                cy = cy + item_h + item_spacing
            end
        end

        for i = 1, #blueprints do
            table.insert(column_items, g_item_data[blueprints[i]])

            if #column_items == columns then
                render_columns(column_items)
                column_items = {}
            end
        end

        render_columns(column_items)
    end
end

function render_notification_tile(screen_w, screen_h, label, text_col, tile)
    if tile:get() then
        local tile_size = tile:get_size()
        local tile_pos = tile:get_position_xz()
        local tile_rect_size = 128
        local map_size_for_tile = screen_h / tile_rect_size * tile_size:y()

        local cy = (screen_h - tile_rect_size) / 2 - 20
        cy = cy + update_ui_text_scale(0, cy, label, screen_w, 1, text_col, 0, 3)
        
        update_set_screen_map_position_scale(tile_pos:x(), tile_pos:y(), map_size_for_tile)
        -- update_ui_rectangle_outline((screen_w - tile_rect_size) / 2, (screen_h - tile_rect_size) / 2, tile_rect_size, tile_rect_size, text_col)

        cy = (screen_h + tile_rect_size) / 2 - 10
        cy = cy + update_ui_text(0, cy, tile:get_name(), screen_w, 1, text_col, 0)

        local difficulty_level = tile:get_difficulty_level()
        local icon_w = 6
        local icon_spacing = 2
        local total_w = icon_w * difficulty_level + icon_spacing * (difficulty_level - 1)

        for i = 0, difficulty_level - 1 do
            update_ui_image(screen_w / 2 - total_w / 2 + (icon_w + icon_spacing) * i, cy, atlas_icons.column_difficulty, text_col, 0)
        end
        cy = cy + 10

        local facility_type = tile:get_facility_category()
        local facility_data = g_item_categories[facility_type]
        update_ui_image((screen_w - update_ui_get_text_size(facility_data.name, 10000, 0)) / 2 - 8, cy, facility_data.icon, text_col, 0)
        cy = cy + update_ui_text(8, cy, facility_data.name, screen_w, 1, text_col, 0)
    else
        update_ui_text_scale(0, screen_h / 2 - 15, label, screen_w, 1, text_col, 0, 3)
    end
end

function get_notification_color(notification)
    local color = g_colors.holo

    if notification:get() then
        local type = notification:get_type()

        if type == e_map_notification_type.island_captured then
            color = g_colors.good
        elseif type == e_map_notification_type.island_lost then
            color = g_colors.bad
        elseif type == e_map_notification_type.blueprint_unlocked then
            color = color8(16, 255, 128, 255)
        end
    end

    return iff(g_notification_time < 30 and g_notification_time % 10 < 5, color_white, color)
end

function mult_alpha(col, alpha) 
    return color8(col:r(), col:g(), col:b(), math.floor(col:a() * alpha))  
end

function focus_carrier()
    local screen_vehicle = update_get_screen_vehicle()

    if screen_vehicle:get() then
        local pos_xz = screen_vehicle:get_position_xz()
        transition_to_map_pos(pos_xz:x(), pos_xz:y(), 5000)
    end
end

function focus_world()
    local tile_count = update_get_tile_count()

    local function min(a, b)
        if a == nil then return b end
        return math.min(a, b)
    end

    local function max(a, b)
        if a == nil then return b end
        return math.max(a, b)
    end

    local min_x = nil
    local min_z = nil
    local max_x = nil
    local max_z = nil

    for i = 0, tile_count - 1 do
        local tile = update_get_tile_by_index(i)

        if tile:get() then
            local tile_pos_xz = tile:get_position_xz()
            local tile_size = tile:get_size()
            
            min_x = min(min_x, tile_pos_xz:x() - tile_size:x() / 2)
            min_z = min(min_z, tile_pos_xz:y() - tile_size:y() / 2)
            max_x = max(max_x, tile_pos_xz:x() + tile_size:x() / 2)
            max_z = max(max_z, tile_pos_xz:y() + tile_size:y() / 2)
        end
    end

    if min_x ~= nil then
        local target_x = (min_x + max_x) / 2
        local target_z = (min_z + max_z) / 2
        local target_size = math.max(max_x - min_x, max_z - min_z) * 1.5

        transition_to_map_pos(target_x, target_z, target_size)
    end
end

function transition_to_map_pos(x, z, size)
    g_map_x_offset = (g_map_x + g_map_x_offset) - x
    g_map_z_offset = (g_map_z + g_map_z_offset) - z
    g_map_size_offset = (g_map_size + g_map_size_offset) - size
    g_map_x = x
    g_map_z = z
    g_map_size = size
    g_next_pos_x = g_map_x
    g_next_pos_y = g_map_z
    g_next_size = g_map_size
end

function get_holomap_from_world(world_x, world_y, screen_w, screen_h)
	local map_x = g_map_x + g_map_x_offset
	local map_z = g_map_z + g_map_z_offset
	local map_size = g_map_size + g_map_size_offset

    local view_w = map_size * 1.64
    local view_h = map_size
    
    local view_x = (world_x - map_x) / view_w
    local view_y = (map_z - world_y) / view_h

    local screen_x = math.floor(((view_x + 0.5) * screen_w) + 0.5)
    local screen_y = math.floor(((view_y + 0.5) * screen_h) + 0.5)

    return screen_x, screen_y
end

function get_world_from_holomap(screen_x, screen_y, screen_w, screen_h)
	local map_x = g_map_x + g_map_x_offset
	local map_z = g_map_z + g_map_z_offset
	local map_size = g_map_size + g_map_size_offset

	local view_w = map_size * 1.64
    local view_h = map_size

    local view_x = (screen_x / screen_w) - 0.5
    local view_y = (screen_y / screen_h) - 0.5

    local world_x = map_x + (view_x * view_w)
    local world_y = map_z - (view_y * view_h)

    return world_x, world_y
end

function get_is_vehicle_enterable(vehicle)
    local screen_vehicle = update_get_screen_vehicle()
                        
    if screen_vehicle:get() and vehicle:get() then
        local team = vehicle:get_team()
        local def = vehicle:get_definition_index()

        if team == update_get_screen_team_id() and def ~= e_game_object_type.chassis_carrier and def ~= e_game_object_type.chassis_land_robot_dog then
            return true
        end
    end

    return false
end

function get_vehicle_has_robot_dogs(vehicle)
    if get_is_vehicle_land(vehicle:get_definition_index()) then
        local attachment_count = vehicle:get_attachment_count()

        for i = 0, attachment_count - 1 do
            local attachment = vehicle:get_attachment(i)

            if attachment:get() then
                if attachment:get_definition_index() == e_game_object_type.attachment_turret_robot_dog_capsule then
                    return true, attachment
                end
            end
        end
    end

    return false, nil
end

function render_vehicle_tooltip(w, h, vehicle)
    local screen_vehicle = update_get_screen_vehicle()
    local vehicle_pos_xz = vehicle:get_position_xz()
    local vehicle_definition_index = vehicle:get_definition_index()
    local vehicle_definition_name, vehicle_definition_region = get_chassis_data_by_definition_index(vehicle_definition_index)

    local bar_h = 17
    local repair_factor = vehicle:get_repair_factor()
    local fuel_factor = vehicle:get_fuel_factor()
    local ammo_factor = vehicle:get_ammo_factor()
    local repair_bar = math.floor(repair_factor * bar_h)
    local fuel_bar = math.floor(fuel_factor * bar_h)
    local ammo_bar = math.floor(ammo_factor * bar_h)

    local cx = 2
    local cy = 2

    local team = vehicle:get_team()
    local color_inactive = color8(8, 8, 8, 255)

    if vehicle:get_is_observation_type_revealed() then
        update_ui_rectangle(cx + 0, cy, 1, bar_h, color8(16, 16, 16, 255))
        update_ui_rectangle(cx + 0, cy + bar_h - repair_bar, 1, repair_bar, color8(47, 116, 255, 255))
        update_ui_rectangle(cx + 2, cy, 1, bar_h, color8(16, 16, 16, 255))
        update_ui_rectangle(cx + 2, cy + bar_h - fuel_bar, 1, fuel_bar, color8(119, 85, 161, 255))
        update_ui_rectangle(cx + 4, cy, 1, bar_h, color8(16, 16, 16, 255))
        update_ui_rectangle(cx + 4, cy + bar_h - ammo_bar, 1, ammo_bar, color8(201, 171, 68, 255))
    else
        update_ui_rectangle(cx + 0, cy, 1, bar_h, color_inactive)
        update_ui_rectangle(cx + 2, cy, 1, bar_h, color_inactive)
        update_ui_rectangle(cx + 4, cy, 1, bar_h, color_inactive)
    end

    cx = cx + 6

    if vehicle:get_is_observation_type_revealed() then
        update_ui_image(cx, 2, vehicle_definition_region, color8(255, 255, 255, 255), 0)
        cx = cx + 18

		local display_name = vehicle_definition_name

		if vehicle_definition_index == e_game_object_type.chassis_sea_barge then
			display_name = display_name .. " " .. tostring(vehicle:get_id())
		end

        update_ui_text(cx, 6, display_name, 124, 0, color8(255, 255, 255, 255), 0)
        cx = cx + update_ui_get_text_size(display_name, 10000, 0) + 2
    else
        update_ui_image(cx, 2, atlas_icons.icon_chassis_16_wheel_small, color_inactive, 0)
        cx = cx + 18

        local display_name = "***"
        update_ui_text(cx, 6, display_name, 124, 0, color_inactive, 0)
        cx = cx + update_ui_get_text_size(display_name, 10000, 0) + 2
    end

    if vehicle_definition_index ~= e_game_object_type.chassis_carrier then
        if vehicle:get_is_observation_weapon_revealed() then
            -- render primary attachment icon

            for i = 0, vehicle:get_attachment_count() - 1 do
                local attachment_type = vehicle:get_attachment_type(i)
                if attachment_type == e_game_object_attachment_type.plate_large or attachment_type == e_game_object_attachment_type.plate_huge then
                    local attachment = vehicle:get_attachment(i)

                    if attachment:get() then
                        local icon, icon_16 = get_attachment_icons(attachment:get_definition_index())

                        if icon_16 ~= nil then
                            update_ui_image(cx, cy, icon_16, color_white, 0)
                            break
                        end
                    end
                end
            end
        else
            update_ui_image(cx, cy, atlas_icons.icon_attachment_16_unknown, color_inactive, 0)
        end
    end

    if vehicle:get_is_observation_fully_revealed() == false then
        local data_factor = vehicle:get_observation_factor()
        update_ui_text(0, 6, string.format("%.0f%%", data_factor * 100), w - 2, 2, color_inactive, 0)
    end

    if team == update_get_screen_team_id() then
        cx = w - 12

        if get_is_vehicle_air(vehicle_definition_index) then
            local vehicle_attachment_count = vehicle:get_vehicle_attachment_count()

            if vehicle_attachment_count > 0 then
                local is_vehicle_attached = false

                for i = 0, vehicle_attachment_count do
                    if vehicle:get_attached_vehicle_id(i) ~= 0 then
                        is_vehicle_attached = true
                        break
                    end
                end

                if is_vehicle_attached then
                    update_ui_image(cx, 7, atlas_icons.icon_attack_type_airlift, color_status_ok, 0)
                    cx = cx - 8
                end
            end
        end
    end

    local has_robot_dogs, attachment_robot_dogs = get_vehicle_has_robot_dogs(vehicle)
    if attachment_robot_dogs ~= nil then
        cx = 12
        cy = h - 2 - 10
        local ammo_count = attachment_robot_dogs:get_ammo_remaining()
        local virus_text = ammo_count .. " x " .. update_get_loc(e_loc.upp_control_bots)

        update_ui_text(cx, cy, virus_text, w - 4, 0, iff(ammo_count > 0, color_status_ok, color_status_bad), 0)
    end
end

function render_startup_memchk( screen_w, screen_h )
	local anim = (g_animation_time - g_startup_phase_anim) * 2
	
	local mem = math.min( 640, anim )
	update_ui_text(16, 16, string.format("%.0fKB OK", math.floor(mem)), 128, 0, color_white, 0)
	
	if anim > 700 then
		g_startup_phase_anim = g_animation_time
		g_startup_phase = g_startup_phase + 1
	end
end

function render_startup_bios( screen_w, screen_h )
	local anim = math.floor( (g_animation_time - g_startup_phase_anim) / 5 ) + 1
	
	local bios_text = {
		"Firmware Version 3.22.7\n",
		"Firmware Checksum ", ".", ".", ".", " OK\n\n",
		
		
		"Welcome to your:\n",
		"Series 7 - Battlefield Command and Control Mainframe\n",
		"A Sigletics© Tactical Computer System\n\n",
		
		
		"Accessing Master Boot Record ", ".", ".", ".",	" Done\n",
		"Loading Image: ACC Carrier Operating System ", ".", ".", ".", ".", ".", " Done\n",
		"Operating System Handoff\n",
		"******************************************************\n",
		"CRR OS: Loading Drivers:\n",
		"CRR OS:     PS/2 Keyboard ", ".", ".", ".", " Okay\n",
		"CRR OS:     PS/2 Mouse ", ".", ".", ".", " Okay\n",
		"CRR OS:     VGA Graphics ", ".", ".", ".", " Okay\n",
		"CRR OS:     Sound Caster 16 ", ".", ".", ".", " Okay\n",
		"CRR OS:     3D Accelerator ", ".", ".", ".", " Fail\n",
		
		"CRR OS: Starting user interface"
	}
	
	local out = ""
	
	local stop = math.min( #bios_text, anim )
	
	for i = 1, stop, 1 do
		out = out .. bios_text[i]
	end
	
	update_ui_text(16, 16, out, 496, 0, color_white, 0)
	
	if anim > #bios_text + 12 then
		g_startup_phase_anim = g_animation_time
		g_startup_phase = g_startup_phase + 1
	end
end

function render_startup_sys( screen_w, screen_h )
	local anim = (g_animation_time - g_startup_phase_anim)
	
	local vessel_names = {
		"Mu",
		
		"Epsilon",
		"Omega",
		
		"Upsilon",
		"Omicron",
		"Sigma",
		"Lambda",
		
		"Alpha",
		"Beta",
		"Gamma",
		"Delta",
		"Zeta",
		"Eta",
		"Theta",
		"Iota",
		"Kappa"
	}
	
	local team_id = update_get_screen_team_id()
	
	local crew = {"Altus Gage"}
--[[
	if update_get_is_multiplayer() then
		local peer_count = update_get_peer_count()
		for i = 0, peer_count - 1 do
			local name = update_get_peer_name(i)
			local team = update_get_peer_team(i)
			
			if team == team_id then
				crew[#crew + 1] = name
			end
		end
	else
		crew[1] = "Altus Gage"
	end
--]]
	local ui = g_ui
	
	local win_w = 256
	local win_h = 85
	
	local anim_win_w = math.min( win_w, anim * 8 )
	local anim_win_h = math.min( win_h, anim * 8 )
	
	local win_title = ""
	if anim_win_w > 128 then win_title = "Vessel Registration" end
	
	local reg_win = ui:begin_window(win_title, 128, 16, anim_win_w, anim_win_h, atlas_icons.column_pending, true, 2)

	if anim > 37 then ui:stat("Registrant", "United Earth Coalition", color_white) end
	if anim > 42 then ui:stat("Vessel Name", vessel_names[team_id + 1], color_white) end
	if anim > 47 then ui:stat("Vessel Class", "Amphibious Assault Carrier", color_white) end
	if anim > 52 then ui:stat("Operating Number", string.format( "%010.0f", g_startup_op_num), color_white) end
	
	ui:end_window()
	
	if anim > 80 then
		local login_win = ui:begin_window("Crew Manifest", 128, 110, 256, 128, atlas_icons.column_pending, true, 2)
		
		for i = 1, #crew, 1 do
			local status = "Validating Credentials"
		
			if anim > 90 + i * 20 then
				status = "Authenticated"
			end
			
			ui:stat( crew[i], status, color_white )
		end
		
		ui:end_window()
		
		if anim > 120 + #crew * 20 then
			g_startup_phase_anim = g_animation_time
			g_startup_phase = holomap_startup_phases.finish -- bypass manual stage
			--g_startup_phase = g_startup_phase + 1
		end
	end
end

function render_startup_manual( screen_w, screen_h )
	local anim = (g_animation_time - g_startup_phase_anim)

	local ui = g_ui
	
	local win_w = 192
	local win_h = 32
	
	local anim_win_w = math.min( win_w, anim * 4 )
	local anim_win_h = math.min( win_h, anim * 4 )
	
	local win_title = ""
	if anim_win_w > 128 then win_title = "Carrier Command" end
	
	local reg_win = ui:begin_window(win_title, 160, 16, anim_win_w, anim_win_h, atlas_icons.column_pending, true, 2)

	if anim > 37 and imgui_list_item_blink(ui, "Enable Manual Override", true) then
        g_startup_phase_anim = g_animation_time
		g_startup_phase = g_startup_phase + 1
    end
	
	ui:end_window()
end

