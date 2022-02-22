g_camera_pos_x = 0
g_camera_pos_y = 0
g_is_camera_pos_initialised = false
g_camera_size = (32 * 1024)
g_camera_size_max = 128 * 1024
g_camera_size_min = 4 * 1024
g_screen_index = 2
g_map_render_mode = 1
g_ui = nil
g_is_pointer_pressed = false
g_is_pointer_hovered = false
g_pointer_pos_x = 0
g_pointer_pos_y = 0
g_pointer_pos_x_prev = 0
g_pointer_pos_y_prev = 0
g_drag_distance = 0
g_is_vehicle_team_colors = true
g_is_island_team_colors = true
g_is_island_names = true
g_is_deploy_carrier_triggered = false
g_dock_state_prev = nil
g_color_waypoint = color8(0, 255, 255, 8)
g_animation_time = 0
g_map_window_scroll = 0
g_is_vehicle_links = true
g_is_follow_carrier = true

function parse()
    g_is_camera_pos_initialised = parse_bool("is_map_init", g_is_camera_pos_initialised)
    g_camera_pos_x = parse_f32("map_x", g_camera_pos_x)
    g_camera_pos_y = parse_f32("map_y", g_camera_pos_y)
    g_camera_size = parse_f32("map_size", g_camera_size)
    g_screen_index = parse_s32("", g_screen_index)
    g_map_render_mode = parse_s32("mode", g_map_render_mode)
    g_is_vehicle_team_colors = parse_bool("is_vehicle_team_colors", g_is_vehicle_team_colors)
    g_is_island_team_colors = parse_bool("is_island_team_colors", g_is_island_team_colors)
    
    -- End of original parse calls
    
    g_is_island_names = parse_bool("is_island_names", g_is_island_names)
    g_map_window_scroll = parse_f32("", g_map_window_scroll)
    g_is_vehicle_links = parse_bool("is_vehicle_links", g_is_vehicle_links)
    g_is_follow_carrier = parse_bool("is_follow_carrier", g_is_follow_carrier)
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
    g_animation_time = g_animation_time + ticks

    if update_get_active_input_type() == e_active_input.gamepad then
        -- Set pointer to middle of screen
        g_pointer_pos_x = 64
        g_pointer_pos_y = 64
    end


    local this_vehicle = update_get_screen_vehicle()
    local screen_team = update_get_local_team_id()
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

    local is_local = update_get_is_focus_local()

    local ui = g_ui
    ui:begin_ui()

    update_set_screen_background_type(g_map_render_mode)

    if g_screen_index == 0 then
        if not g_is_follow_carrier then
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_pan), e_ui_interaction_special.map_pan)
        end
        
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_zoom), e_ui_interaction_special.map_zoom)
        update_add_ui_interaction(update_get_loc(e_loc.interaction_map_options), e_game_input.interact_a)

        if this_vehicle:get() then
            local this_vehicle_pos = this_vehicle:get_position_xz()

            if g_is_follow_carrier then
                g_camera_pos_x = this_vehicle_pos:x()
                g_camera_pos_y = this_vehicle_pos:y()
            elseif is_local and g_is_pointer_pressed and g_is_pointer_hovered then
                local pos_dx = g_pointer_pos_x - g_pointer_pos_x_prev
                local pos_dy = g_pointer_pos_y - g_pointer_pos_y_prev
            
                local drag_threshold = iff( update_get_is_vr(), 20, 3 )
                g_drag_distance = g_drag_distance + math.abs(pos_dx) + math.abs(pos_dy)

                if g_drag_distance >= drag_threshold then
                    g_camera_pos_x = g_camera_pos_x - (pos_dx * g_camera_size * 0.005)
                    g_camera_pos_y = g_camera_pos_y + (pos_dy * g_camera_size * 0.005)
                end
            end

            local carrier_x, carrier_y = get_screen_from_world(this_vehicle_pos:x(), this_vehicle_pos:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

            update_set_screen_map_position_scale(g_camera_pos_x, g_camera_pos_y, g_camera_size)

            local is_render_islands = (g_camera_size < (64 * 1024))

            update_set_screen_background_is_render_islands(is_render_islands)

            local island_count = update_get_tile_count()

            for i = 0, island_count - 1, 1 do 
                local island = update_get_tile_by_index(i)

                if island:get() then
                    local island_color = get_island_team_color(island:get_team_control())
                    local island_position = island:get_position_xz()
                                
                    if is_render_islands == false then
                        local screen_pos_x, screen_pos_y = get_screen_from_world(island_position:x(), island_position:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                        update_ui_image(screen_pos_x - 4, screen_pos_y - 4, atlas_icons.map_icon_island, island_color, 0)
                    elseif g_is_island_names then
                        local screen_pos_x, screen_pos_y = get_screen_from_world(island_position:x(), island_position:y() + 3000.0, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                                    
                        update_ui_text(screen_pos_x - 64, screen_pos_y - 9, island:get_name(), 128, 1, island_color, 0)
                                    
                        if island:get_team_control() ~= update_get_screen_team_id() then
                            local difficulty_level = island:get_difficulty_level()
                            local icon_w = 6
                            local icon_spacing = 2
                            local total_w = icon_w * difficulty_level + icon_spacing * (difficulty_level - 1)

                            for i = 0, difficulty_level - 1 do
                                update_ui_image(screen_pos_x - total_w / 2 + (icon_w + icon_spacing) * i, screen_pos_y, atlas_icons.column_difficulty, island_color, 0)
                            end
                        end
                    end
                end
            end

            local vehicle_count = update_get_map_vehicle_count()

            -- render vehicle links to the map
            if g_is_vehicle_links then
                for i = 0, vehicle_count - 1, 1 do
                    local vehicle = update_get_map_vehicle_by_index(i)

                    if vehicle:get() then
                        local vehicle_team = vehicle:get_team()
                        local vehicle_attached_parent_id = vehicle:get_attached_parent_id(i)

                        if vehicle_team == screen_team and vehicle_attached_parent_id == 0 then
                            local def = vehicle:get_definition_index()
                            
                            local veh_pos = vehicle:get_position_xz()
                            local veh_x, veh_y = get_screen_from_world(veh_pos:x(), veh_pos:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                            
                            if def == e_game_object_type.chassis_sea_barge then
                                local action, destination_id, destination_type = vehicle:get_barge_state_data()
                                
                                if destination_type == e_barge_destination_type.vehicle and destination_id == this_vehicle:get_id() then -- The destination of this barge is the carrier
                                    render_dashed_line(veh_x, veh_y, carrier_x, carrier_y, color8(0, 255, 64, 255))
                                end
                            elseif def ~= e_game_object_type.chassis_spaceship and def ~= e_game_object_type.drydock then
                                local is_rotor = (def == e_game_object_type.chassis_air_rotor_light or def == e_game_object_type.chassis_air_rotor_heavy)
                
                                local dock_state = vehicle:get_dock_state()
                                
                                if dock_state == e_vehicle_dock_state.docking then
                                    render_dashed_line(veh_x, veh_y, carrier_x, carrier_y, color8(205, 8, 8, 255))
                                elseif dock_state == e_vehicle_dock_state.dock_queue then
                                    render_dashed_line(veh_x, veh_y, carrier_x, carrier_y, color8(205, 8, 246, 255))
                                end
                            end
                        end
                    end
                end
            end

            -- render vehicles to the map

            for i = 0, vehicle_count - 1, 1 do 
                local vehicle = update_get_map_vehicle_by_index(i)

                if vehicle:get() then
                    local vehicle_team = vehicle:get_team()
                    local vehicle_attached_parent_id = vehicle:get_attached_parent_id(i)

                    if vehicle:get_is_visible() and vehicle:get_is_observation_revealed() and vehicle_attached_parent_id == 0 then
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
 
            -- render carrier direction indicator
            update_ui_image(carrier_x - 5, carrier_y - 5, atlas_icons.map_icon_circle_9, color_white, 0)

            local this_vehicle_dir = this_vehicle:get_direction()
            update_ui_line(carrier_x, carrier_y, carrier_x + (this_vehicle_dir:x() * 20), carrier_y + (this_vehicle_dir:y() * -20), color_white)

            -- render carrier waypoints
            local waypoint_count = this_vehicle:get_waypoint_count()
            
            local screen_vehicle_pos = this_vehicle:get_position_xz()
            local waypoint_prev_x, waypoint_prev_y = get_screen_from_world(screen_vehicle_pos:x(), screen_vehicle_pos:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
            
            for i = 0, waypoint_count - 1, 1 do
                local waypoint = this_vehicle:get_waypoint(i)
                local waypoint_pos = waypoint:get_position_xz()
                
                local waypoint_screen_pos_x, waypoint_screen_pos_y = get_screen_from_world(waypoint_pos:x(), waypoint_pos:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                
                update_ui_line(waypoint_prev_x, waypoint_prev_y, waypoint_screen_pos_x, waypoint_screen_pos_y, g_color_waypoint)
                update_ui_image(waypoint_screen_pos_x - 3, waypoint_screen_pos_y - 3, atlas_icons.map_icon_waypoint, g_color_waypoint, 0)
                
                waypoint_prev_x = waypoint_screen_pos_x
                waypoint_prev_y = waypoint_screen_pos_y
            end

            local missile_count = update_get_missile_count()

            for i = 0, missile_count - 1 do
                local missile = update_get_missile_by_index(i)
                local def = missile:get_definition_index()
                
                local position_xz = missile:get_position_xz()
                local screen_pos_x, screen_pos_y = get_screen_from_world(position_xz:x(), position_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                if missile:get_is_visible() and (def == e_game_object_type.torpedo or def == e_game_object_type.torpedo_decoy or def == e_game_object_type.torpedo_noisemaker) then
                    local missile_trail_count = missile:get_trail_count()
                    local trail_prev_x = screen_pos_x
                    local trail_prev_y = screen_pos_y
                    for missile_trail_index = 0, missile_trail_count - 1 do
                        local trail_xz = missile:get_trail_position(missile_trail_index)
                        local trail_next_x, trail_next_y = get_screen_from_world(trail_xz:x(), trail_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)        
                        update_ui_line(trail_prev_x, trail_prev_y, trail_next_x, trail_next_y, color8(255, 255, 255, 16 - math.floor(missile_trail_index / 4)))
                        trail_prev_x = trail_next_x
                        trail_prev_y = trail_next_y
                    end

                    local is_timer_running = missile:get_timer() > 0
                    local is_own_team = missile:get_team() == screen_team

                    local color_missile = color_white

                    local icon_image = atlas_icons.map_icon_torpedo
                    if def == e_game_object_type.torpedo_decoy or def == e_game_object_type.torpedo_noisemaker then
                        icon_image = atlas_icons.map_icon_torpedo_decoy

                        if is_own_team then
                            if is_timer_running then
                                if g_animation_time % 10 < 5 then
                                    color_missile = color8(64, 64, 255, 255)
                                else
                                    color_missile = color_white
                                end
                            end
                        end
                    else
                        icon_image = atlas_icons.map_icon_torpedo

                        if is_own_team then
                            if is_timer_running then
                                color_missile = color_white
                            else
                                if g_animation_time % 10 < 5 then
                                    color_missile = color8(255, 64, 64, 255)
                                else
                                    color_missile = color_white
                                end
                            end
                        end
                    end

                    update_ui_image(screen_pos_x - 3, screen_pos_y - 3, icon_image, color_missile, 0)
                    
                    if is_local and g_is_pointer_hovered then
                        local missile_distance_to_cursor = math.abs(screen_pos_x - g_pointer_pos_x) + math.abs(screen_pos_y - g_pointer_pos_y)

                        if is_own_team and missile_distance_to_cursor < 8 and is_timer_running then
                            update_ui_text(screen_pos_x - 16, screen_pos_y - 12, tostring(math.floor(missile:get_timer() / 30) + 1), 32, 1, color_missile, 0)
                        end
                    end
                end
            end

            local world_x = g_camera_pos_x
            local world_y = g_camera_pos_y

            if is_local and g_is_pointer_hovered then
                world_x, world_y = get_world_from_screen(g_pointer_pos_x, g_pointer_pos_y, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                local label_x = 5
                local label_y = 5
                local label_w = screen_w - 2 * label_x
                local label_h = 10

                update_ui_push_offset(label_x, label_y)

                if g_map_render_mode > 1 then
                    if g_map_render_mode == 3 then label_h = label_h * 2 end
                    update_ui_rectangle(0, 0, label_w, label_h, color_black)
                end

                if g_map_render_mode == 2 then
                    update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_wind)..": %.2f", update_get_weather_wind_velocity(world_x, world_y)), label_w, 0, color_white, 0)
                elseif g_map_render_mode == 3 then
                    update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_precipitation)..": %.0f%%", update_get_weather_precipitation_factor(world_x, world_y) * 100), label_w, 0, color_white, 0)

                    update_ui_image(1, 10, atlas_icons.column_power, color_white, 0)
                    update_ui_text(1, 10, string.format(": %.0f%%", update_get_weather_lightning_factor(world_x, world_y) * 100), label_w, 0, color_white, 0)
                elseif g_map_render_mode == 4 then
                    update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_visibility)..": %.0f%%", update_get_weather_fog_factor(world_x, world_y) * 100), label_w, 0, color_white, 0)
                elseif g_map_render_mode == 5 then
                    update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_ocean_current)..": %.2f", update_get_ocean_current_velocity(world_x, world_y)), label_w, 0, color_white, 0)
                elseif g_map_render_mode == 6 then
                    update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_ocean_depth)..": %.2f", update_get_ocean_depth_factor(world_x, world_y)), label_w, 0, color_white, 0)
                end

                update_ui_pop_offset()
                
            end
            
            update_ui_text(10, screen_h - 13, string.format("X:%-6.0f ", world_x) .. string.format("Y:%-6.0f", world_y), screen_w - 10, 0, color_grey_dark, 0)
            
            if not g_is_follow_carrier and update_get_active_input_type() == e_active_input.gamepad then
                local crosshair_color = color8(255, 255, 255, 255)

                update_ui_rectangle(g_pointer_pos_x, g_pointer_pos_y + 2, 1, 4, crosshair_color)
                update_ui_rectangle(g_pointer_pos_x, g_pointer_pos_y - 5, 1, 4, crosshair_color)
                update_ui_rectangle(g_pointer_pos_x + 2, g_pointer_pos_y, 4, 1, crosshair_color)
                update_ui_rectangle(g_pointer_pos_x - 5, g_pointer_pos_y, 4, 1, crosshair_color)
            end
        end
    elseif g_screen_index == 1 then
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)
        update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)

        local is_local = update_get_is_focus_local()
        local window = ui:begin_window(update_get_loc(e_loc.upp_map), 10, 10, screen_w - 20, screen_h - 20, atlas_icons.column_pending, true, 2)
            if is_local then
                g_map_window_scroll = window.scroll_y
            else
                window.scroll_y = g_map_window_scroll
            end
            window.label_bias = 0.9
            
            ui:header(update_get_loc(e_loc.upp_map_mode))
            if ui:checkbox(update_get_loc(e_loc.upp_cartographic), g_map_render_mode == 1, true) then g_map_render_mode = 1 end
            if ui:checkbox(update_get_loc(e_loc.upp_wind), g_map_render_mode == 2, true) then g_map_render_mode = 2 end
            if ui:checkbox(update_get_loc(e_loc.upp_precipitation), g_map_render_mode == 3, true) then g_map_render_mode = 3 end
            if ui:checkbox(update_get_loc(e_loc.upp_fog), g_map_render_mode == 4, true) then g_map_render_mode = 4 end
            if ui:checkbox(update_get_loc(e_loc.upp_ocean_current), g_map_render_mode == 5, true) then g_map_render_mode = 5 end
            if ui:checkbox(update_get_loc(e_loc.upp_ocean_depth), g_map_render_mode == 6, true) then g_map_render_mode = 6 end

            ui:divider()

            g_is_follow_carrier = ui:checkbox("FOLLOW CARRIER", g_is_follow_carrier)
            g_is_vehicle_team_colors = ui:checkbox(update_get_loc(e_loc.upp_vehicle_team_colors), g_is_vehicle_team_colors)
            g_is_island_team_colors = ui:checkbox(update_get_loc(e_loc.upp_island_team_colors), g_is_island_team_colors)
            g_is_island_names = ui:checkbox(update_get_loc(e_loc.upp_island_names), g_is_island_names)
            g_is_vehicle_links = ui:checkbox("VEHICLE LINKS", g_is_vehicle_links)

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
            local inventory_capacity = this_vehicle:get_inventory_capacity()

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
            if inventory_capacity > 0 then
                local inventory_factor = this_vehicle:get_inventory_weight() / inventory_capacity
                ui:stat(atlas_icons.column_weight, string.format("%.0f%%", inventory_factor * 100), iff(inventory_factor < 1, color_status_ok, color_status_bad))
            end

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
    
    if g_is_pointer_hovered then
        g_pointer_pos_x_prev = g_pointer_pos_x
        g_pointer_pos_y_prev = g_pointer_pos_y
    end
end

function input_event(event, action)
    g_ui:input_event(event, action)

    if g_screen_index == 0 then
        if action == e_input_action.press then
            if event == e_input.back then
                update_set_screen_state_exit()
            end
        elseif action == e_input_action.release then
            local pos_dx = g_pointer_pos_x - g_pointer_pos_x_prev
            local pos_dy = g_pointer_pos_y - g_pointer_pos_y_prev
        
            local drag_threshold = iff( update_get_is_vr(), 20, 3 )
            g_drag_distance = g_drag_distance + math.abs(pos_dx) + math.abs(pos_dy)
        
            if event == e_input.action_a or (event == e_input.pointer_1 and g_drag_distance < drag_threshold) then
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
    
    if event == e_input.pointer_1 then
        g_is_pointer_pressed = action == e_input_action.press
        if not g_is_pointer_pressed then
            g_drag_distance = 0
        end
    end
end

function input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
    g_is_pointer_hovered = is_hovered
    g_pointer_pos_x = x
    g_pointer_pos_y = y
end

function input_scroll(dy)
    g_ui:input_scroll(dy)

    if g_is_pointer_hovered and update_get_active_input_type() == e_active_input.keyboard then
        input_camera_zoom(1 - dy * 0.2)
    end
end

function input_axis(x, y, z, w)
    input_camera_zoom(1 - w * 0.1)
    
    if not g_is_follow_carrier then
        g_camera_pos_x = g_camera_pos_x + x * g_camera_size * 0.05
        g_camera_pos_y = g_camera_pos_y + y * g_camera_size * 0.05
    end
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

function render_dashed_line(x0, y0, x1, y1, col)
    local line_length = math.max(vec2_dist(vec2(x0, y0), vec2(x1, y1)), 1)
    local normal = vec2((x1 - x0) / line_length, (y1 - y0) / line_length)
    local segment_length = 3
    local segment_spacing = 3
    local step = segment_length + segment_spacing
    local offset = (g_animation_time / 2) % step

    for cursor = offset, line_length, step do
        local length = math.min(segment_length, line_length - cursor)

        update_ui_line(x0 + normal:x() * cursor, y0 + normal:y() * cursor, x0 + normal:x() * (cursor + length), y0 + normal:y() * (cursor + length), col)
    end
end