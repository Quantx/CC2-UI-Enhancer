g_camera_pos_x = 0
g_camera_pos_y = 0
g_is_camera_pos_initialised = false
g_camera_size = (32 * 1024)
g_camera_size_max = 128 * 1024
g_camera_size_min = 4 * 1024
g_screen_index = 2
g_map_render_mode = 1
g_ui = nil
g_is_pointer_hovered = false
g_is_vehicle_team_colors = false
g_is_island_team_colors = true
g_is_island_names = false
g_is_deploy_carrier_triggered = false
g_dock_state_prev = nil

function parse()
    g_is_camera_pos_initialised = parse_bool("is_map_init", g_is_camera_pos_initialised)
    g_camera_pos_x = parse_f32("map_x", g_camera_pos_x)
    g_camera_pos_y = parse_f32("map_y", g_camera_pos_y)
    g_camera_size = parse_f32("map_size", g_camera_size)
    g_screen_index = parse_s32("", g_screen_index)
    g_map_render_mode = parse_s32("mode", g_map_render_mode)
    g_is_vehicle_team_colors = parse_bool("is_vehicle_team_colors", g_is_vehicle_team_colors)
    g_is_island_team_colors = parse_bool("is_island_team_colors", g_is_island_team_colors)
    g_is_island_names = parse_bool("is_island_names", g_is_island_names)
end

function begin()
    begin_load()

    if g_is_camera_pos_initialised == false then
        g_is_camera_pos_initialised = true

        local screen_name = begin_get_screen_name()

        if screen_name == "screen_nav_l" then
            g_map_render_mode = 2
            g_camera_size = (4 * 1024)
        elseif screen_name == "screen_nav_m" then
            g_map_render_mode = 3
            g_camera_size = (16 * 1024)
        elseif screen_name == "screen_nav_r" then
            g_map_render_mode = 4
            g_camera_size = (64 * 1024)
        end
    end

    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks) 
    local this_vehicle = update_get_screen_vehicle()
    update_set_screen_background_type(0)

    if g_is_deploy_carrier_triggered and this_vehicle:get_dock_state() ~= e_vehicle_dock_state.docked then
        update_set_screen_state_exit()
        g_is_deploy_carrier_triggered = false
    end

    if g_dock_state_prev ~= nil and g_dock_state_prev == e_vehicle_dock_state.docked and g_dock_state_prev ~= this_vehicle:get_dock_state() then
        g_boot_counter = 30
        g_screen_index = 0
    end

    g_dock_state_prev = this_vehicle:get_dock_state()

    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    local ui = g_ui
    ui:begin_ui()

    update_set_screen_background_type(g_map_render_mode)

    if g_screen_index == 0 then
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_zoom), e_ui_interaction_special.map_zoom)
        update_add_ui_interaction(update_get_loc(e_loc.interaction_map_options), e_game_input.interact_a)

        if this_vehicle:get() then
            local this_vehicle_pos = this_vehicle:get_position_xz()

            g_camera_pos_x = this_vehicle_pos:x()
            g_camera_pos_y = this_vehicle_pos:y()

            update_set_screen_map_position_scale(g_camera_pos_x, g_camera_pos_y, g_camera_size)

            local is_render_islands = (g_camera_size < (64 * 1024))

            update_set_screen_background_is_render_islands(is_render_islands)

            island_count = update_get_tile_count()

            if is_render_islands == false or g_is_island_names then
                for i = 0, island_count - 1, 1 do 
                    local island = update_get_tile_by_index(i)
                    
                    if island:get() then
                        local island_position = island:get_position_xz()
                        local island_color = get_island_team_color(island:get_team_control())
                        
                        local screen_pos_x, screen_pos_y = get_screen_from_world(island_position:x(), island_position:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                        if is_render_islands == false then
                            update_ui_image(screen_pos_x - 4, screen_pos_y - 4, atlas_icons.map_icon_island, island_color, 0)
                        end

                        if g_is_island_names and is_render_islands then
                            local island_name = island:get_name()
                            local island_size = island:get_size()
                            local _, name_pos_y = get_screen_from_world(0, island_position:y() + island_size:y() * 0.5, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                            update_ui_text(screen_pos_x - 100, math.min(name_pos_y - 5, screen_pos_y - 14), island_name, 200, 1, island_color, 0)
                        end
                    end
                end
            end

            local vehicle_count = update_get_map_vehicle_count()

            -- render vehicles to the map

            for i = 0, vehicle_count - 1, 1 do 
                local vehicle = update_get_map_vehicle_by_index(i)

                if vehicle:get() then
                    local vehicle_team = vehicle:get_team()
                    local vehicle_attached_parent_id = vehicle:get_attached_parent_id(i)

                    if vehicle:get_is_visible() and vehicle:get_is_observation_revealed() then
                        if vehicle_attached_parent_id == 0 and i ~= this_vehicle_index then
                            -- render vehicle icon

                            local vehicle_definition_index = vehicle:get_definition_index()
                            
                            if vehicle_definition_index ~= e_game_object_type.chassis_spaceship and vehicle_definition_index ~= e_game_object_type.drydock then

                                local vehicle_pos_xz = vehicle:get_position_xz()
                                local screen_pos_x, screen_pos_y = get_screen_from_world(vehicle_pos_xz:x(), vehicle_pos_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                                local region_vehicle_icon, icon_offset = get_icon_data_by_definition_index(vehicle_definition_index)
                                local element_color = get_vehicle_team_color(vehicle_team)
                
                                update_ui_image(screen_pos_x - icon_offset, screen_pos_y - icon_offset, region_vehicle_icon, element_color, 0)
                            end
                        end
                    end
                end
            end

            update_ui_image(64 - 5, 64 - 5, atlas_icons.map_icon_circle_9, color_white, 0)

            local this_vehicle_dir = this_vehicle:get_direction()
            update_ui_line(64, 64, 64 + (this_vehicle_dir:x() * 20), 64 + (this_vehicle_dir:y() * -20), color_white)

            local cy = screen_h - 15
            update_ui_text(10, cy, "Y", 100, 0, color_grey_mid, 0)
            update_ui_text(20, cy, string.format("%-6.0f ", g_camera_pos_y), screen_w - 10, 0, color_grey_dark, 0)
            cy = cy - 10

            update_ui_text(10, cy, "X", 100, 0, color_grey_mid, 0)
            update_ui_text(20, cy, string.format("%-6.0f ", g_camera_pos_x), screen_w - 10, 0, color_grey_dark, 0)
        end
    elseif g_screen_index == 1 then
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)
        update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)

        local window = ui:begin_window(update_get_loc(e_loc.upp_map), 10, 10, screen_w - 20, screen_h - 20, atlas_icons.column_pending, true, 2)
            window.label_bias = 0.9
            
            ui:header(update_get_loc(e_loc.upp_map_mode))
            if ui:checkbox(update_get_loc(e_loc.upp_cartographic), g_map_render_mode == 1, true) then g_map_render_mode = 1 end
            if ui:checkbox(update_get_loc(e_loc.upp_wind), g_map_render_mode == 2, true) then g_map_render_mode = 2 end
            if ui:checkbox(update_get_loc(e_loc.upp_precipitation), g_map_render_mode == 3, true) then g_map_render_mode = 3 end
            if ui:checkbox(update_get_loc(e_loc.upp_fog), g_map_render_mode == 4, true) then g_map_render_mode = 4 end
            if ui:checkbox(update_get_loc(e_loc.upp_ocean_current), g_map_render_mode == 5, true) then g_map_render_mode = 5 end
            if ui:checkbox(update_get_loc(e_loc.upp_ocean_depth), g_map_render_mode == 6, true) then g_map_render_mode = 6 end

            ui:divider()

            g_is_vehicle_team_colors = ui:checkbox(update_get_loc(e_loc.upp_vehicle_team_colors), g_is_vehicle_team_colors)
            g_is_island_team_colors = ui:checkbox(update_get_loc(e_loc.upp_island_team_colors), g_is_island_team_colors)
            g_is_island_names = ui:checkbox(update_get_loc(e_loc.upp_island_names), g_is_island_names)
    
            ui:spacer(5)
    
        ui:end_window()
    elseif g_screen_index == 2 then
        update_set_screen_background_type(0)
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)

        if this_vehicle:get() and this_vehicle:get_dock_state() == e_vehicle_dock_state.docked then
            local window = ui:begin_window(update_get_loc(e_loc.upp_carrier) .. "###launch", 10, 20, screen_w - 20, screen_h - 40, atlas_icons.column_pending, true, 2)
            window.label_bias = 0.15

            ui:header(update_get_loc(e_loc.upp_status))

            local fuel_factor = this_vehicle:get_fuel_factor()
            local hitpoints = this_vehicle:get_hitpoints()
            local total_hitpoints = this_vehicle:get_total_hitpoints()
            local inventory_factor = this_vehicle:get_inventory_weight() / this_vehicle:get_inventory_capacity()

            local function get_factor_color(factor)
                if factor < 0.25 then
                    return color_status_bad
                elseif factor < 0.75 then
                    return color_status_warning
                end

                return color_status_ok
            end

            ui:stat(atlas_icons.column_fuel, string.format("%.0f%%", fuel_factor * 100), get_factor_color(fuel_factor))
            ui:stat(atlas_icons.icon_health, string.format("%.0f/%.0f", hitpoints, total_hitpoints), get_factor_color(hitpoints / total_hitpoints))
            ui:stat(atlas_icons.column_weight, string.format("%.0f%%", inventory_factor * 100), iff(inventory_factor < 1, color_status_ok, color_status_bad))

            ui:header(update_get_loc(e_loc.upp_operation))

            if imgui_list_item_blink(ui, update_get_loc(e_loc.upp_launch_carrier), true) then
                g_screen_index = 0
                g_boot_counter = 30
                g_is_deploy_carrier_triggered = true
                update_launch_carrier(this_vehicle:get_id())
            end

            ui:end_window()
        else
            g_screen_index = 0
        end
    end
    
    ui:end_ui()
end

function input_event(event, action)
    g_ui:input_event(event, action)

    if g_screen_index == 0 then
        if action == e_input_action.press then
            if event == e_input.back then
                update_set_screen_state_exit()
            end
        elseif action == e_input_action.release then
            if event == e_input.action_a or event == e_input.pointer_1 then
                if g_boot_counter <= 0 then
                    g_screen_index = 1 
                end
            end
        end
    elseif g_screen_index == 1 then
        if action == e_input_action.press then
            if event == e_input.back then
                g_screen_index = 0
            end
        end
	elseif g_screen_index == 2 then
		if action == e_input_action.release then
            if event == e_input.back then
                update_set_screen_state_exit()
            end
        end
	end
end

function input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
    g_is_pointer_hovered = is_hovered
end

function input_scroll(dy)
    g_ui:input_scroll(dy)

    if g_is_pointer_hovered and update_get_active_input_type() == e_active_input.keyboard then
        input_camera_zoom(1 - dy * 0.2)
    end
end

function input_axis(x, y, z, w)
    input_camera_zoom(1 - w * 0.1)
end

function input_camera_zoom(factor)
    if g_screen_index == 0 then
        g_camera_size = clamp(g_camera_size * factor, g_camera_size_min, g_camera_size_max)
    end
end

function get_vehicle_team_color(team)
    if g_is_vehicle_team_colors then
        return update_get_team_color(team)
    elseif team == update_get_screen_team_id() then
        return color_friendly
    else
        return color_enemy
    end
end

function get_island_team_color(team)
    if g_is_island_team_colors or team == 0 then
        return update_get_team_color(team)
    elseif team == update_get_screen_team_id() then
        return color_friendly
    else
        return color_enemy
    end
end