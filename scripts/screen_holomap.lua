
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

g_button_mode = 0
g_is_map_pos_initialised = false
g_override = false
g_override_x = -64000
g_override_z = -64000
g_override_zoom = 16000

g_ui = nil

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
g_ruler_x = 0
g_ruler_y = 0

g_highlighted_waypoint_id = 0
g_highlighted_vehicle_id = 0
g_selection_vehicle_id = 0
g_selected_bay_index = -1

g_color_attack_order = color_status_dark_red
g_color_airlift_order = color_status_ok
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
    
    g_is_map_pos_initialised = parse_bool("is_map_init", g_is_map_pos_initialised)
    g_next_pos_x = parse_f32("map_x", g_next_pos_x)
    g_next_pos_y = parse_f32("map_y", g_next_pos_y)
    g_next_size = parse_f32("map_size", g_next_size)
    
    -- End of original parse calls
    
    g_is_mouse_mode = parse_bool("", g_is_mouse_mode)

    g_is_ruler = parse_bool("", g_is_ruler)
    g_ruler_x = parse_f32("", g_ruler_x)
    g_ruler_y = parse_f32("", g_ruler_y)
    
    g_highlighted_waypoint_id = parse_s32("", g_highlighted_waypoint_id)
    g_highlighted_vehicle_id = parse_s32("", g_highlighted_vehicle_id)
    g_selection_vehicle_id = parse_s32("map_selection", g_selection_vehicle_id)
    g_selected_bay_index = parse_s32("", g_selected_bay_index)
end

function begin()
    g_ui = lib_imgui:create_ui()
    begin_load()
    begin_load_inventory_data()

    g_next_pos_x = parse_f32(g_next_pos_x)
    g_next_pos_y = parse_f32(g_next_pos_y)
    g_next_size = parse_f32(g_next_size)
end

function update(screen_w, screen_h, ticks) 
    g_is_mouse_mode = update_get_active_input_type() == e_active_input.keyboard
    g_animation_time = g_animation_time + ticks

    local screen_vehicle = update_get_screen_vehicle()

    local screen_team = update_get_screen_team_id()
    local is_local = update_get_is_focus_local()
    
    local world_x = 0
    local world_y = 0

    local drydock, waypoint = get_team_drydock()
    
    if is_local then
        if not g_is_mouse_mode then
            g_pointer_pos_x = screen_w / 2
            g_pointer_pos_y = screen_h / 2
        end

        world_x, world_y = get_world_from_holomap( g_pointer_pos_x, g_pointer_pos_y, screen_w, screen_h )
        if drydock ~= nil then
            drydock:clear_waypoints()
            drydock:add_waypoint(world_x, world_y)

            waypoint = nil
        end
    elseif waypoint ~= nil then
        local waypoint_pos = waypoint:get_position_xz()
                    
        world_x = waypoint_pos:x()
        world_y = waypoint_pos:y()
        
        g_pointer_pos_x, g_pointer_pos_y = get_holomap_from_world( world_x, world_y, screen_w, screen_h )
    end

    if g_focus_mode ~= 0 then
        if g_focus_mode == 1 then
            focus_carrier()
        elseif g_focus_mode == 2 then
            focus_world()
        end

        g_startup_phase = holomap_startup_phases.finish
        g_focus_mode = 0
    end
    
    if holomap_override(screen_w, screen_h, ticks) then
--        if g_is_mouse_mode and is_local then
--            render_cursor(world_x, world_y, screen_w, screen_h)
--        end
        return
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

    if g_is_map_pos_initialised == false then
        g_is_map_pos_initialised = true
        if screen_vehicle:get() and screen_vehicle:get_dock_state() == e_vehicle_dock_state.docked then
            local pos = screen_vehicle:get_position_xz()
            g_map_x = pos:x()
            g_map_z = pos:y()
            g_map_size = 5000

            focus_world()
        end
    end

    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_pan), e_ui_interaction_special.map_pan)
    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_zoom), e_ui_interaction_special.map_zoom)

    update_add_ui_interaction(update_get_loc(e_loc.interaction_bearing), e_game_input.interact_a)
    if screen_vehicle:get() and screen_vehicle:get_dock_state() ~= e_vehicle_dock_state.docked then
        if not g_is_mouse_mode and g_highlighted_vehicle_id > 0 and g_highlighted_waypoint_id == 0 then
            local vehicle = update_get_map_vehicle_by_id(g_highlighted_vehicle_id)
            if g_highlighted_vehicle_id == screen_vehicle:get_id() then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_carrier), e_game_input.interact_b)
            elseif vehicle:get() and vehicle:get_team() == screen_team then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_vehicle), e_game_input.interact_b)
            end
        elseif g_highlighted_vehicle_id == screen_vehicle:get_id() then
            if g_highlighted_waypoint_id > 0 then
                update_add_ui_interaction("remove carrier waypoint", e_game_input.interact_b)
            elseif g_is_mouse_mode then
                update_add_ui_interaction("remove all carrier waypoints", e_game_input.interact_b)
            end
        else
            update_add_ui_interaction("set carrier waypoint", e_game_input.interact_b)
        end
    end

    if is_local then
        g_next_pos_x = g_map_x
        g_next_pos_y = g_map_z
        g_next_size = g_map_size
    else
        g_blend_tick = g_blend_tick + ticks
        local blend_factor = clamp(g_blend_tick / 10.0, 0.0, 1.0)
        g_map_x = lerp(g_prev_pos_x, g_next_pos_x, blend_factor)
        g_map_z = lerp(g_prev_pos_y, g_next_pos_y, blend_factor)
        g_map_size = lerp(g_prev_size, g_next_size, blend_factor)
    end
    
    if is_local and (g_is_mouse_mode and g_is_pointer_hovered) and g_highlighted_vehicle_id == 0 and g_highlighted_waypoint_id == 0 and not update_get_is_notification_holomap_set() then
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

    update_ui_rectangle(0, 0, screen_w, screen_h, color8(0, 0, 0, 220))

    g_ui:begin_ui()

    if update_get_is_notification_holomap_set() then
        g_notification_time = g_notification_time + ticks

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
            g_dismiss_counter = g_dismiss_counter + ticks
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
        local vehicle_count = update_get_map_vehicle_count()
        local cur_map_zoom = g_map_size + g_map_size_offset

        -- draw island names
        if cur_map_zoom < 95000 then
            local island_count = update_get_tile_count()
            for i = 0, island_count - 1, 1 do
                local island = update_get_tile_by_index(i)

                if island ~= nil and island:get() then
                    local island_color = update_get_team_color(island:get_team_control())
                    local island_pos = island:get_position_xz()
                    local island_size = island:get_size()

                    local screen_pos_x = 0
                    local screen_pos_y = 0
                    
                    if cur_map_zoom < 16000 then
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

                    update_ui_text(screen_pos_x - 64, screen_pos_y, island:get_name(), 128, 1, island_color, 0)
                    
                    local category_data = g_item_categories[island:get_facility_category()]
                    
                    if island:get_team_control() ~= screen_team then
                        local difficulty_level = island:get_difficulty_level() + 2
                        local icon_w = 6
                        local icon_spacing = 2
                        local total_w = icon_w * difficulty_level + icon_spacing * (difficulty_level - 1)

                        for i = 0, difficulty_level - 1 do
                            if i == 0 then
                                update_ui_image(screen_pos_x - total_w / 2 + (icon_w + icon_spacing) * i, screen_pos_y + 10, category_data.icon, island_color, 0)
                            elseif i >= 2 then
                                update_ui_image(screen_pos_x - total_w / 2 + (icon_w + icon_spacing) * i, screen_pos_y + 10, atlas_icons.column_difficulty, island_color, 0)
                            end
                        end
                    else
                        update_ui_image(screen_pos_x - 4, screen_pos_y + 10, category_data.icon, island_color, 0)
                    end
                end
            end
        end
        
        -- find hovered vehilce or waypoint
        if is_local and (not g_is_mouse_mode or g_is_pointer_hovered) then
            g_highlighted_vehicle_id = 0
            g_highlighted_waypoint_id = 0
            local highlighted_distance_best = 4 * math.max( 1, 2000 / cur_map_zoom )

            for i = 0, vehicle_count - 1, 1 do
                local vehicle = update_get_map_vehicle_by_index(i)

                if vehicle:get() then
                    local vehicle_definition_index = vehicle:get_definition_index()

                    if vehicle_definition_index ~= e_game_object_type.chassis_spaceship and vehicle_definition_index ~= e_game_object_type.drydock then
                        local vehicle_team = vehicle:get_team()
                        local vehicle_attached_parent_id = vehicle:get_attached_parent_id()

                        if vehicle_attached_parent_id == 0 and vehicle:get_is_visible() and vehicle:get_is_observation_revealed() then
                            local vehicle_pos_xz = vehicle:get_position_xz()
                            local screen_pos_x, screen_pos_y = get_holomap_from_world(vehicle_pos_xz:x(), vehicle_pos_xz:y(), screen_w, screen_h)

                            local vehicle_distance_to_cursor = vec2_dist( vec2( screen_pos_x, screen_pos_y ), vec2( g_pointer_pos_x, g_pointer_pos_y ) )

                            if vehicle_distance_to_cursor < highlighted_distance_best then
                                g_highlighted_vehicle_id = vehicle:get_id()
                                g_highlighted_waypoint_id = 0
                                highlighted_distance_best = vehicle_distance_to_cursor
                            end
                        end

                        if vehicle_team == screen_team then
                            local waypoint_count = vehicle:get_waypoint_count()

                            for j = 0, waypoint_count - 1, 1 do
                                local waypoint = vehicle:get_waypoint(j)
                                local waypoint_type = waypoint:get_type()

                                if waypoint_type == e_waypoint_type.move or waypoint_type == e_waypoint_type.deploy then
                                    local waypoint_pos = waypoint:get_position_xz(j)
                                    local waypoint_screen_pos_x, waypoint_screen_pos_y = get_holomap_from_world(waypoint_pos:x(), waypoint_pos:y(), screen_w, screen_h)
                                    local waypoint_distance_to_cursor = vec2_dist( vec2( waypoint_screen_pos_x, waypoint_screen_pos_y ), vec2( g_pointer_pos_x, g_pointer_pos_y ) )

                                    if waypoint_distance_to_cursor < highlighted_distance_best then
                                        g_highlighted_vehicle_id = vehicle:get_id()
                                        g_highlighted_waypoint_id = waypoint:get_id()
                                        highlighted_distance_best = waypoint_distance_to_cursor
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- render vehicle stuff
        for i = 0, vehicle_count - 1, 1 do
            local vehicle = update_get_map_vehicle_by_index(i)
            
            local vehicle_pos_xz = vehicle:get_position_xz()
            local screen_pos_x, screen_pos_y = get_holomap_from_world(vehicle_pos_xz:x(), vehicle_pos_xz:y(), screen_w, screen_h)

            local vehicle_team = vehicle:get_team()
            local vehicle_attached_parent_id = vehicle:get_attached_parent_id()
            local vehicle_support_id = vehicle:get_supporting_vehicle_id()
            local vehicle_definition_index = vehicle:get_definition_index()
            local is_render_vehicle_icon = vehicle_attached_parent_id == 0

            local waypoint_count = vehicle:get_waypoint_count()
                        
            local waypoint_pos_x_prev = screen_pos_x
            local waypoint_pos_y_prev = screen_pos_y
                        
            if vehicle_team == screen_team and vehicle_definition_index ~= e_game_object_type.chassis_sea_barge and vehicle_definition_index ~= e_game_object_type.drydock then
                local waypoint_remove = -1
                local waypoint_color = g_color_waypoint

                if g_highlighted_vehicle_id == vehicle:get_id() and g_highlighted_waypoint_id == 0 then
                    waypoint_color = color8(255, 255, 255, 255)
                end

                local vehicle_dock_state = vehicle:get_dock_state()
                local vehicle_dock_queue_id = vehicle:get_dock_queue_vehicle_id()

                if (vehicle_dock_state == e_vehicle_dock_state.dock_queue or vehicle_dock_state == e_vehicle_dock_state.docking) and vehicle_dock_queue_id ~= 0 and is_render_vehicle_icon then
                    local parent_vehicle = update_get_map_vehicle_by_id(vehicle_dock_queue_id)

                    if parent_vehicle:get() then
                        local parent_pos_xz = parent_vehicle:get_position_xz()
                        local parent_screen_pos_x, parent_screen_pos_y = get_holomap_from_world(parent_pos_xz:x(), parent_pos_xz:y(), screen_w, screen_h)

                        render_dashed_line(screen_pos_x, screen_pos_y, parent_screen_pos_x, parent_screen_pos_y, waypoint_color)
                    end
                end

                if vehicle_support_id ~= 0 then
                    local parent_vehicle = update_get_map_vehicle_by_id(vehicle_support_id)

                    if parent_vehicle:get() then
                        local parent_pos_xz = parent_vehicle:get_position_xz()
                        local parent_screen_pos_x, parent_screen_pos_y = get_holomap_from_world(parent_pos_xz:x(), parent_pos_xz:y(), screen_w, screen_h)

                        render_dashed_line(screen_pos_x, screen_pos_y, parent_screen_pos_x, parent_screen_pos_y, waypoint_color)
                    end
                else
                    local waypoint_path = vehicle:get_waypoint_path()
                    local waypoint_start_index = 0

                    -- Computed path to next waypoint
                    if #waypoint_path > 0 then
                        waypoint_start_index = 1

                        for i = 1, #waypoint_path do
                            local waypoint_screen_pos_x, waypoint_screen_pos_y = get_holomap_from_world(waypoint_path[i]:x(), waypoint_path[i]:y(), screen_w, screen_h)

                            update_ui_line(waypoint_pos_x_prev, waypoint_pos_y_prev, waypoint_screen_pos_x, waypoint_screen_pos_y, waypoint_color)

                            update_ui_rectangle(waypoint_screen_pos_x - 1, waypoint_screen_pos_y - 1, 2, 2, waypoint_color)

                            waypoint_pos_x_prev = waypoint_screen_pos_x
                            waypoint_pos_y_prev = waypoint_screen_pos_y
                        end

                        if waypoint_count > 0 then
                            local waypoint = vehicle:get_waypoint(0)
                            local waypoint_pos = waypoint:get_position_xz()
                            local path_end_x, path_end_y = get_holomap_from_world(waypoint_pos:x(), waypoint_pos:y(), screen_w, screen_h)

                            update_ui_line(waypoint_pos_x_prev, waypoint_pos_y_prev, path_end_x, path_end_y, waypoint_color)
                        end
                    end

                    waypoint_pos_x_prev = screen_pos_x
                    waypoint_pos_y_prev = screen_pos_y

                    if is_render_vehicle_icon == false then
                        if vehicle_attached_parent_id ~= 0 then
                            local parent_vehicle = update_get_map_vehicle_by_id(vehicle_attached_parent_id)

                            if parent_vehicle:get() then
                                local parent_vehicle_pos_xz = parent_vehicle:get_position_xz()
                                waypoint_pos_x_prev, waypoint_pos_y_prev = get_holomap_from_world(parent_vehicle_pos_xz:x(), parent_vehicle_pos_xz:y(), screen_w, screen_h)
                            end
                        end
                    end

                    -- Draw waypoint lines
                    for j = 0, waypoint_count - 1, 1 do
                        local waypoint = vehicle:get_waypoint(j)
                        local waypoint_pos = waypoint:get_position_xz()
                        local waypoint_screen_pos_x, waypoint_screen_pos_y = get_holomap_from_world(waypoint_pos:x(), waypoint_pos:y(), screen_w, screen_h)

                        if j >= waypoint_start_index then
                            update_ui_line(waypoint_pos_x_prev, waypoint_pos_y_prev, waypoint_screen_pos_x, waypoint_screen_pos_y, waypoint_color)
                        end

                        waypoint_pos_x_prev = waypoint_screen_pos_x
                        waypoint_pos_y_prev = waypoint_screen_pos_y

                        local waypoint_repeat_index = waypoint:get_repeat_index(j)

                        if waypoint_repeat_index >= 0 then
                            local waypoint_repeat = vehicle:get_waypoint(waypoint_repeat_index)
                            local waypoint_repeat_pos = waypoint_repeat:get_position_xz()

                            local repeat_screen_pos_x, repeat_screen_pos_y = get_holomap_from_world(waypoint_repeat_pos:x(), waypoint_repeat_pos:y(), screen_w, screen_h)

                            update_ui_line(waypoint_screen_pos_x, waypoint_screen_pos_y, repeat_screen_pos_x, repeat_screen_pos_y, waypoint_color)
                            update_ui_image((waypoint_screen_pos_x + repeat_screen_pos_x) / 2 - 4, (waypoint_screen_pos_y + repeat_screen_pos_y) / 2 - 4, atlas_icons.map_icon_loop, waypoint_color, 0)
                        end

                        local attack_target_count = waypoint:get_attack_target_count()

                        for k = 0, attack_target_count - 1, 1 do
                            local is_valid = waypoint:get_attack_target_is_valid(k)

                            if is_valid then
                                local attack_target_pos = waypoint:get_attack_target_position_xz(k)
                                local attack_target_attack_type = waypoint:get_attack_target_attack_type(k)
                                local attack_target_icon = get_attack_type_icon(attack_target_attack_type)

                                local attack_target_screen_pos_x, attack_target_screen_pos_y = get_holomap_from_world(attack_target_pos:x(), attack_target_pos:y(), screen_w, screen_h)

                                local color = g_color_attack_order

                                if attack_target_attack_type == e_attack_type.airlift then
                                    color = g_color_airlift_order
                                end

                                update_ui_line(waypoint_screen_pos_x, waypoint_screen_pos_y, attack_target_screen_pos_x, attack_target_screen_pos_y, color)
                                update_ui_image(attack_target_screen_pos_x - 8, attack_target_screen_pos_y - 8, atlas_icons.map_icon_attack, color, 0)
                                update_ui_image(attack_target_screen_pos_x - 4, attack_target_screen_pos_y - 4 - 8, attack_target_icon, color, 0)
                            end
                        end
                    end

                    -- Draw waypoint icons
                    for j = 0, waypoint_count - 1, 1 do
                        local waypoint = vehicle:get_waypoint(j)
                        local waypoint_pos = waypoint:get_position_xz()

                        local waypoint_distance = vec2_dist( vehicle_pos_xz, waypoint_pos )
                        
                        if vehicle_definition_index == e_game_object_type.chassis_carrier and waypoint_distance < 500 then
                            waypoint_remove = j
                        end

                        local waypoint_screen_pos_x, waypoint_screen_pos_y = get_holomap_from_world(waypoint_pos:x(), waypoint_pos:y(), screen_w, screen_h)

                        local waypoint_color = g_color_waypoint

                        local is_group_a = waypoint:get_is_wait_group(0)
                        local is_group_b = waypoint:get_is_wait_group(1)
                        local is_group_c = waypoint:get_is_wait_group(2)
                        local is_group_d = waypoint:get_is_wait_group(3)

                        local group_text = ""

                        if is_group_a then group_text = group_text..update_get_loc(e_loc.upp_acronym_alpha) end
                        if is_group_b then group_text = group_text..update_get_loc(e_loc.upp_acronym_beta) end
                        if is_group_c then group_text = group_text..update_get_loc(e_loc.upp_acronym_charlie) end
                        if is_group_d then group_text = group_text..update_get_loc(e_loc.upp_acronym_delta) end

                        local is_group = (is_group_a or is_group_b or is_group_c or is_group_d)
                        local is_deploy = waypoint:get_type() == e_waypoint_type.deploy

                        if g_highlighted_vehicle_id == vehicle:get_id() and g_highlighted_waypoint_id == 0 then
                            waypoint_color = color8(255, 255, 255, 255)
                        elseif g_highlighted_vehicle_id == vehicle:get_id() and g_highlighted_waypoint_id == waypoint:get_id() then
                            waypoint_color = color8(255, 255, 255, 255)
                        elseif is_deploy then
                            waypoint_color = g_color_airlift_order
                        elseif is_group then
                            waypoint_color = g_color_attack_order
                        end

                        update_ui_image(waypoint_screen_pos_x - 4, waypoint_screen_pos_y - 4, atlas_icons.map_icon_waypoint, waypoint_color, 0)

                        if is_deploy then
                            update_ui_image(waypoint_screen_pos_x - 4, waypoint_screen_pos_y - 11, atlas_icons.icon_deploy_vehicle, waypoint_color, 0)
                        elseif is_group then
                            update_ui_text(waypoint_screen_pos_x - 64, waypoint_screen_pos_y - 13, group_text, 128, 1, waypoint_color, 0)
                        end
                    end
                end

                local attack_target_type = vehicle:get_attack_target_type()

                if attack_target_type ~= e_attack_type.none then
                    local attack_target_pos = vehicle:get_attack_target_position_xz()
                    local attack_target_attack_type = vehicle:get_attack_target_type()
                    local attack_target_icon = get_attack_type_icon(attack_target_attack_type)

                    local attack_target_screen_pos_x, attack_target_screen_pos_y = get_holomap_from_world(attack_target_pos:x(), attack_target_pos:y(), screen_w, screen_h)

                    local color = g_color_attack_order

                    if attack_target_attack_type == e_attack_type.airlift then
                        color = g_color_airlift_order
                    end

                    render_dashed_line(screen_pos_x, screen_pos_y, attack_target_screen_pos_x, attack_target_screen_pos_y, color)
                    update_ui_image(attack_target_screen_pos_x - 4, attack_target_screen_pos_y - 4, atlas_icons.map_icon_waypoint, color, 0)
                    update_ui_image(attack_target_screen_pos_x - 4, attack_target_screen_pos_y - 4 - 8, attack_target_icon, color, 0)
                    update_ui_text(attack_target_screen_pos_x - 4, attack_target_screen_pos_y - 4 - 8, attack_target_attack_type, 128, 0, color_black, 0)
                end
                
                -- Waypoint cleanup for the carrier
                if waypoint_remove > -1 then
                    local waypoint_path = {}
                    
                    for i = waypoint_remove + 1, waypoint_count - 1, 1 do
                        local waypoint = vehicle:get_waypoint(i)
                        
                        waypoint_path[#waypoint_path + 1] = waypoint:get_position_xz()
                    end
                    
                    vehicle:clear_waypoints()
                    
                    for i = 1, #waypoint_path, 1 do
                        vehicle:add_waypoint(waypoint_path[i]:x(), waypoint_path[i]:y())
                    end
                end
            end
        end
        
        local cy = screen_h - 15
        local cx = 15
        
        local icon_col = color_grey_mid
        local text_col = color_grey_dark

        if g_is_ruler then
            if is_local and not g_is_ruler_set and (not g_is_mouse_mode or g_is_pointer_hovered) then
                g_ruler_x = world_x
                g_ruler_y = world_y
                
                g_is_ruler_set = true
            end
            
            local drag_x, drag_y = get_holomap_from_world(g_ruler_x, g_ruler_y, screen_w, screen_h)

            local team_col = update_get_team_color(update_get_screen_team_id())

            update_ui_circle(drag_x, drag_y, 2, 4, team_col)
            update_ui_line(drag_x, drag_y, g_pointer_pos_x, g_pointer_pos_y, team_col)

            local dist_screen = vec2_dist(vec2(drag_x, drag_y), vec2(g_pointer_pos_x, g_pointer_pos_y))
            local angle = math.atan(g_pointer_pos_y - drag_y, g_pointer_pos_x - drag_x)
            local bearing = 90 + angle / math.pi * 180
            if bearing < 0 then bearing = bearing + 360 end

            if dist_screen > 5 then
                local function rotate(x, y, a)
                    local s = math.sin(a)
                    local c = math.cos(a)
                    return x * c - y * s, x * s + y * c
                end

                local rad = 10

                if dist_screen > rad then
                    local step =  math.pi / 180 * 20
                    local bearing_rad =  bearing / 180 * math.pi

                    update_ui_push_offset(drag_x, drag_y)
                    update_ui_begin_triangles()

                    for a = 0, bearing_rad, step do
                        local a_next = math.min(bearing_rad, a + step)
                        local p0 = vec2(rotate(0, -rad, a))
                        local p1 = vec2(rotate(0, -rad, a_next))
                        update_ui_add_triangle(vec2(0, 0), p0, p1, mult_alpha(team_col, 0.1))
                        update_ui_line(math.floor(p0:x()), math.floor(p0:y()), math.floor(p1:x()), math.floor(p1:y()), team_col)
                    end

                    update_ui_end_triangles()
                    update_ui_pop_offset()
                end

                update_ui_push_offset(g_pointer_pos_x, g_pointer_pos_y)
                update_ui_begin_triangles()
                update_ui_add_triangle(vec2(rotate(0, 0, angle)), vec2(rotate(-10, -4, angle)), vec2(rotate(-10, 4, angle)), team_col)
                update_ui_end_triangles()
                update_ui_pop_offset()
            end

            update_ui_image(cx, cy, atlas_icons.column_angle, icon_col, 0)
            update_ui_text(cx + 15, cy, string.format("%.0f deg", bearing), 100, 0, text_col, 0)
            cy = cy - 10

            local dist = vec2_dist(vec2(g_ruler_x, g_ruler_y), vec2(world_x, world_y))

            if dist < 10000 then
                update_ui_image(cx, cy, atlas_icons.column_distance, icon_col, 0)
                update_ui_text(cx + 15, cy, string.format("%.0f ", dist) .. update_get_loc(e_loc.acronym_meters), 100, 0, text_col, 0)
            else
                update_ui_image(cx, cy, atlas_icons.column_distance, icon_col, 0)
                update_ui_text(cx + 15, cy, string.format("%.2f ", dist / 1000) .. update_get_loc(e_loc.acronym_kilometers), 100, 0, text_col, 0)
            end

            cy = cy - 10
        else                
            if g_highlighted_vehicle_id > 0 then
                local highlighted_vehicle = update_get_map_vehicle_by_id(g_highlighted_vehicle_id)
                if highlighted_vehicle:get() then
                    local vehicle_definition_index = highlighted_vehicle:get_definition_index()
                    
                    if g_highlighted_waypoint_id > 0 then
                        local highlighted_waypoint = highlighted_vehicle:get_waypoint_by_id(g_highlighted_waypoint_id)
                        
                        if get_is_vehicle_air(vehicle_definition_index) then
                            local alt_str = string.format( "%.0f ", highlighted_waypoint:get_altitude() ) .. update_get_loc(e_loc.acronym_meters)
                            local alt_width = update_ui_get_text_size(alt_str, 10000, 0) + 4
                            
                            render_tooltip(10, 10, screen_w - 20, screen_h - 20, g_pointer_pos_x, g_pointer_pos_y, alt_width, 14, 10, function(w, h)    update_ui_text(2, 2, alt_str, w - 4, 0, color_white, 0) end)
                        end
                    else
                        -- render vehicle tooltip
                        local peers = iff( highlighted_vehicle:get_team() == screen_team, get_vehicle_controlling_peers(highlighted_vehicle), {} )
                        local tool_height = 21 + (#peers * 10)

                        render_tooltip(10, 10, screen_w - 20, screen_h - 20, g_pointer_pos_x, g_pointer_pos_y, 128, tool_height, 10, function(w, h) render_vehicle_tooltip(w, h, highlighted_vehicle, peers) end)
                        
                        if vehicle_definition_index ~= e_game_object_type.chassis_carrier then
                            if highlighted_vehicle:get_team() == screen_team or highlighted_vehicle:get_is_observation_weapon_revealed() then
                                local weapon_range = get_vehicle_weapon_range(highlighted_vehicle)
                                local vehicle_pos_xz = highlighted_vehicle:get_position_xz()

                                if weapon_range > 0 then
                                    render_weapon_radius(vehicle_pos_xz:x(), vehicle_pos_xz:y(), weapon_range, screen_w, screen_h)
                                end
                            end
                        end
                    end
                end
            end
        end
            
        render_map_scale(screen_w, screen_h)

        update_ui_text(cx, cy, "Y", 100, 0, icon_col, 0)
        update_ui_text(cx + 15, cy, string.format("%.0f", world_y), 100, 0, text_col, 0)
        cy = cy - 10
        
        update_ui_text(cx, cy, "X", 100, 0, icon_col, 0)
        update_ui_text(cx + 15, cy, string.format("%.0f", world_x), 100, 0, text_col, 0)
        cy = cy - 10

        local label_x = 24
        local label_y = 16
        local label_w = screen_w - 2 * label_x
        local label_h = 10

        update_ui_push_offset(label_x, label_y)

        update_ui_rectangle(0, 0, label_w, label_h, color_black)

        local now = update_get_logic_tick()

        if g_button_mode == 0 then
            update_ui_text(1, 1, "MISSION TIME: " .. format_time( now / 30 ), label_w, 0, color_white, 0)

            -- draw timeline
            local timeline_w = 100

            update_ui_rectangle( label_w - timeline_w - 1, 1, timeline_w, 8, color_white )
            update_ui_rectangle( label_w - timeline_w, 1, timeline_w - 2, 8, color_black )
            update_ui_rectangle( label_w - timeline_w, label_h / 2 - 1, timeline_w - 2, 2, color_white )
            update_ui_rectangle( label_w - timeline_w / 2, 1, 1, 8, color_white )

            update_ui_push_clip( label_w - timeline_w, 0, timeline_w - 2, 10 )

            local day_len = 54000 -- 30 minutes in ticks
            local time = now - 8100 -- Time since midnight on the first day
            local timeline_pos = label_w - ((timeline_w / day_len) * (time % day_len))

            local cy = label_h / 2 - 4

            local color_sun = color8( 255, 255, 0, 255 )
            local color_moon = color8( 0, 0, 255, 255 )

            update_ui_image(timeline_pos + timeline_w,     cy, atlas_icons.map_icon_surface, color_moon, 0)
            update_ui_image(timeline_pos + timeline_w / 2, cy, atlas_icons.map_icon_surface, color_sun,  0)
            update_ui_image(timeline_pos,                  cy, atlas_icons.map_icon_surface, color_moon, 0)
            update_ui_image(timeline_pos - timeline_w / 2, cy, atlas_icons.map_icon_surface, color_sun,  0)
            update_ui_image(timeline_pos - timeline_w,     cy, atlas_icons.map_icon_surface, color_moon, 0)

            update_ui_pop_clip()
        elseif g_button_mode == 1 then
            update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_wind)..": %.2f", update_get_weather_wind_velocity(world_x, world_y)), label_w, 0, color_white, 0)
        elseif g_button_mode == 2 then
            update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_precipitation)..": %.0f%%", update_get_weather_precipitation_factor(world_x, world_y) * 100), label_w, 0, color_white, 0)

            local cx = label_w - 42
            update_ui_image(cx, 1, atlas_icons.column_power, color_white, 0)
            cx = cx + 5
            update_ui_text(cx, 1, string.format(": %.0f%%", update_get_weather_lightning_factor(world_x, world_y) * 100), label_w, 0, color_white, 0)
        elseif g_button_mode == 3 then
            update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_visibility)..": %.0f%%", update_get_weather_fog_factor(world_x, world_y) * 100), label_w, 0, color_white, 0)
        elseif g_button_mode == 4 then
            update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_ocean_current)..": %.2f", update_get_ocean_current_velocity(world_x, world_y)), label_w, 0, color_white, 0)
        elseif g_button_mode == 5 then
            update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_ocean_depth)..": %.2f", update_get_ocean_depth_factor(world_x, world_y)), label_w, 0, color_white, 0)
        end
        update_ui_pop_offset()
        
        -- render cursor last
        render_cursor(world_x, world_y, screen_w, screen_h)
        
        g_dismiss_counter = 0
        g_notification_time = 0
    end

    if (not g_is_mouse_mode or g_is_pointer_hovered) then
        g_pointer_pos_x_prev = g_pointer_pos_x
        g_pointer_pos_y_prev = g_pointer_pos_y
    end
    
    g_ui:end_ui()
end

function render_cursor(world_x, world_y, screen_w, screen_h)
    if not (update_get_is_focus_local() and g_is_mouse_mode) then
        local cursor_x, cursor_y = get_holomap_from_world(world_x, world_y, screen_w, screen_h)
        update_ui_image_rot(cursor_x, cursor_y, atlas_icons.map_icon_crosshair, color_white, 0)
    end
end

function input_event(event, action)
    g_ui:input_event(event, action)
    
    local screen_vehicle = update_get_screen_vehicle()

    if not g_is_mouse_mode then
        g_pointer_pos_x = 256
        g_pointer_pos_y = 128
    end

    local world_x, world_y = get_world_from_holomap(g_pointer_pos_x, g_pointer_pos_y, 512, 256)

    if event == e_input.action_a then
        g_is_dismiss_pressed = action == e_input_action.press
        g_is_ruler = action == e_input_action.press
    elseif event == e_input.action_b then
        if action == e_input_action.press then
            if (not g_is_mouse_mode) and g_highlighted_vehicle_id > 0 and g_highlighted_waypoint_id == 0 then
                local vehicle = update_get_map_vehicle_by_id(g_highlighted_vehicle_id)

                if vehicle:get() and vehicle:get_team() == screen_vehicle:get_team() then
                    g_selection_vehicle_id = g_highlighted_vehicle_id
                end
            elseif (not g_is_mouse_mode or g_is_pointer_hovered) and screen_vehicle:get() and screen_vehicle:get_dock_state() ~= e_vehicle_dock_state.docked then
                local waypoint_count = screen_vehicle:get_waypoint_count()
                -- Delete waypoint
                if g_highlighted_vehicle_id == screen_vehicle:get_id() and g_highlighted_waypoint_id > 0 then
                    local waypoint_path = {}
                    
                    for i = 0, waypoint_count - 1, 1 do
                        local waypoint = screen_vehicle:get_waypoint(i)
                        if waypoint:get_id() ~= g_highlighted_waypoint_id then
                            waypoint_path[#waypoint_path + 1] = waypoint:get_position_xz()
                        end
                    end

                    screen_vehicle:clear_waypoints()

                    for i = 1, #waypoint_path, 1 do
                        screen_vehicle:add_waypoint(waypoint_path[i]:x(), waypoint_path[i]:y())
                    end
                elseif g_is_mouse_mode or g_highlighted_vehicle_id == 0 then
                    -- Add new waypoint
                    if g_highlighted_vehicle_id == screen_vehicle:get_id() then
                        screen_vehicle:clear_waypoints()
                    elseif waypoint_count < 20 then
                        screen_vehicle:add_waypoint(world_x, world_y)
                    end
                end
            end
        end
    elseif event == e_input.pointer_1 then
        g_is_pointer_pressed = action == e_input_action.press
        
        if g_is_pointer_pressed and g_highlighted_vehicle_id > 0 and g_highlighted_waypoint_id == 0 then
            local vehicle = update_get_map_vehicle_by_id(g_highlighted_vehicle_id)
        
            if vehicle:get() and vehicle:get_team() == screen_vehicle:get_team() then
                g_selection_vehicle_id = g_highlighted_vehicle_id
            end
        end
    elseif event == e_input.back and action == e_input_action.press then        
        if g_selection_vehicle_id > 0 then
            g_selection_vehicle_id = 0
        else
            g_is_ruler = false
        
            local drydock, waypoint = get_team_drydock()

            if waypoint ~= nil then
                local waypoint_pos = waypoint:get_position_xz()
                drydock:clear_waypoints()
                drydock:add_waypoint(waypoint_pos:x(), waypoint_pos:y())
            end
        
            update_set_screen_state_exit()
        end
    end
    
    if not g_is_ruler then
        g_is_ruler_set = false
    end
end

function input_axis(x, y, z, w)
    if not g_override and not update_get_is_notification_holomap_set() then
        g_map_x = g_map_x + x * g_map_size * 0.02
        g_map_z = g_map_z + y * g_map_size * 0.02
        map_zoom(1.0 - w * 0.1)
    end
end

function input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
    
    g_is_pointer_hovered = is_hovered
    
    if is_hovered then
        g_pointer_pos_x = x
        g_pointer_pos_y = y
    end
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
    
    if g_override then
        map_x = g_override_x
        map_z = g_override_z
        map_size = g_override_zoom
    end

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

    if g_override then
        map_x = g_override_x
        map_z = g_override_z
        map_size = g_override_zoom
    end

    local view_w = map_size * 1.64
    local view_h = map_size

    local view_x = (screen_x / screen_w) - 0.5
    local view_y = (screen_y / screen_h) - 0.5

    local world_x = map_x + (view_x * view_w)
    local world_y = map_z - (view_y * view_h)

    return world_x, world_y
end

function get_vehicle_weapon_range(vehicle)
    local attachment_count = vehicle:get_attachment_count()
    local weapon_range = 0

    for i = 0, attachment_count - 1 do
        local attachment = vehicle:get_attachment(i)

        if attachment:get() then
            weapon_range = math.max(attachment:get_weapon_range(), weapon_range)
        end
    end

    return weapon_range
end

function render_vehicle_tooltip(w, h, vehicle, peers)
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

    cx = cx + 10

    local display_id = ""
    if vehicle_definition_index == e_game_object_type.chassis_carrier then
        local team_id = vehicle:get_team() + 1
        display_id = string.upper( vessel_names[team_id] )
    else
        display_id = update_get_loc(e_loc.upp_id) .. string.format( " %.0f", vehicle:get_id() )
    end

    if vehicle:get_is_observation_type_revealed() then
--        update_ui_image(cx, 2, vehicle_definition_region, color_white, 0)
--        cx = cx + 18

        update_ui_text(cx, 11, display_id, 124, 0, color_white, 0)

        local display_name = vehicle_definition_name
        update_ui_text(cx, 1, display_name, 124, 0, color_white, 0)
        cx = cx + math.max(update_ui_get_text_size(display_id,   10000, 0),
                           update_ui_get_text_size(display_name, 10000, 0)) + 2
    else
--        update_ui_image(cx, 2, atlas_icons.icon_chassis_16_wheel_small, color_inactive, 0)
--        cx = cx + 18

        update_ui_text(cx, 11, display_id, 124, 0, color_inactive, 0)

        local display_name = "***"
        update_ui_text(cx, 1, display_name, 124, 0, color_inactive, 0)
        cx = cx + math.max(update_ui_get_text_size(display_id,   10000, 0),
                           update_ui_get_text_size(display_name, 10000, 0)) + 2
    end

    if  vehicle_definition_index ~= e_game_object_type.chassis_carrier
--    and vehicle_definition_index ~= e_game_object_type.chassis_sea_ship_light
--    and vehicle_definition_index ~= e_game_object_type.chassis_sea_ship_heavy
    then
        if vehicle:get_is_observation_weapon_revealed() then
            -- render primary attachment icon

            local attachments = {}

            for i = 0, vehicle:get_attachment_count() - 1 do
                local attachment_type = vehicle:get_attachment_type(i)
                if  attachment_type ~= e_game_object_attachment_type.plate_small
                and attachment_type ~= e_game_object_attachment_type.plate_small_inverted then
                    local attachment = vehicle:get_attachment(i)

                    if attachment:get() then
                        table.insert(attachments, attachment)
                    end
                end
            end

            if #attachments > 0 then
                local attachment_index = (math.floor( g_animation_time / 20 ) % (#attachments)) + 1
                local icon, icon_16 = get_attachment_icons(attachments[attachment_index]:get_definition_index())

                if icon_16 ~= nil then
                    update_ui_image(cx, cy, icon_16, color_white, 0)
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

    cx = 2
    cy = 20
    for i = 1, #peers do
        local peer = peers[i]
        local peer_name = peer.name

        local max_text_chars = 19
        local is_clipped = false

        if utf8.len(peer_name) > max_text_chars then
            peer_name = peer_name:sub(1, utf8.offset(peer_name, max_text_chars) - 1)
            is_clipped = true
        end

        local text_render_w, text_render_h = update_ui_get_text_size(peer_name, w, 0)

        if peer.ctrl then
            update_ui_image( cx, cy, atlas_icons.column_controlling_peer, color_white, 0)
        end

        update_ui_text(cx + 10, cy, peer_name, text_render_w, 0, color_white, 0)

        if is_clipped then
            update_ui_image(cx + 10 + text_render_w, cy, atlas_icons.text_ellipsis, color_white, 0)
        end

        cy = cy + 10
    end
end

function get_team_drydock()
    local vehicle_count = update_get_map_vehicle_count()
    for i = 0, vehicle_count - 1, 1 do
        local vehicle = update_get_map_vehicle_by_index(i)
        
        if vehicle:get() and vehicle:get_definition_index() == e_game_object_type.drydock and vehicle:get_team() == update_get_screen_team_id() then
            local waypoint = nil
            
            local waypoint = vehicle:get_waypoint_count()
            if waypoint > 0 then
                waypoint = vehicle:get_waypoint(0)
            end
            
            return vehicle, waypoint
        end
    end
    
    return nil, nil
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

function render_weapon_radius(world_pos_x, world_pos_y, radius, screen_w, screen_h)
    local steps = 16
    local step = math.pi * 2 / steps
    local angle_prev = 0
    local screen_pos_x, screen_pos_y = get_holomap_from_world(world_pos_x, world_pos_y, screen_w, screen_h)

    update_ui_begin_triangles()

    for i = 1, steps do
        local angle = step * i
        local x0, y0 = get_holomap_from_world(world_pos_x + math.cos(angle_prev) * radius, world_pos_y + math.sin(angle_prev) * radius, screen_w, screen_h)
        local x1, y1 = get_holomap_from_world(world_pos_x + math.cos(angle) * radius, world_pos_y + math.sin(angle) * radius, screen_w, screen_h)
        local color = color8(32, 8, 8, 64)

        update_ui_line(x0, y0, x1, y1, color)

        color = color8(32, 8, 8, math.floor(32 * (math.sin(g_animation_time * 0.15) * 0.5 + 0.5)))
        update_ui_add_triangle(vec2(x0, y0), vec2(x1, y1), vec2(screen_pos_x, screen_pos_y), color)

        angle_prev = angle
    end

    update_ui_end_triangles()
end

function holomap_override( screen_w, screen_h, ticks )
    g_override = false

    if update_self_destruct_override(screen_w, screen_h) then
        g_is_render_holomap = false
        g_override = true
    elseif update_access_denied(screen_w, screen_h, ticks) then
        g_is_render_holomap = false
        g_override = true
    elseif holomap_override_startup ( screen_w, screen_h, ticks ) then
        g_override = true
    elseif render_selection(screen_w, screen_h) then
        g_override = true
    end
    
    if g_override then
        update_set_screen_background_type(0)
        update_set_screen_map_position_scale(g_override_x, g_override_z, g_override_zoom)
        g_is_render_holomap_grids = false
    end
    
    return g_override
end

function holomap_override_startup( screen_w, screen_h, ticks )
    local screen_vehicle = update_get_screen_vehicle()

    if g_startup_op_num == 0 then
        g_startup_op_num = math.random(9999999999)
    end

    if g_startup_phase == holomap_startup_phases.finish then
        return false
    elseif g_is_map_pos_initialised or (screen_vehicle:get() and screen_vehicle:get_dock_state() ~= e_vehicle_dock_state.docked) then
        g_startup_phase = holomap_startup_phases.finish
        return false
    end

    if screen_vehicle:get() then
        local veh = update_get_vehicle_by_id(screen_vehicle:get_id())
        local target_desired, target_allocated = veh:get_power_system_state(4) -- Radar
        if target_desired == 0 then g_startup_phase_anim = g_startup_phase_anim + ticks end
    end

    g_is_render_holomap = g_startup_phase >= holomap_startup_phases.sys

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
        return false
    end
    
    return true
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
        
        
        "Accessing Master Boot Record ", ".", ".", ".", " Done\n",
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

    local team_id = update_get_screen_team_id()
    
    local crew = {}

    if update_get_is_multiplayer() then
        local peer_count = update_get_peer_count()
        for i = 0, peer_count - 1 do
            local name = update_get_peer_name(i)
            local team = update_get_peer_team(i)
            
            if team == team_id then
                table.insert( crew, name )
            end
        end
    else
        crew[1] = "Altus Gage"
    end

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
    if anim > 52 then ui:stat("Operating Number", string.format("%010.0f", g_startup_op_num), color_white) end
    
    ui:end_window()
    
    local crew_interval = 30

    if anim > 80 then
        local login_win = ui:begin_window("Crew Manifest", 128, 110, 256, 128, atlas_icons.column_pending, true, 2)
        
        for i = 1, #crew, 1 do
            local status = "Validating Credentials"
        
            if anim > 90 + i * crew_interval then
                status = "Authenticated"
            end
            
            ui:stat( crew[i], status, color_white )
        end
        
        ui:end_window()
        
        if anim > 120 + #crew * crew_interval then
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

function ui_render_selection_carrier_vehicle_overview(x, y, w, h, carrier_vehicle)
    local carrier_pos = carrier_vehicle:get_position_xz()

    local vehicle_count = update_get_map_vehicle_count()
    local deployed_vehicles = {}

    for i = 0, vehicle_count - 1 do
        local vehicle = update_get_map_vehicle_by_index(i)

        if vehicle:get() then
            local vehicle_team = vehicle:get_team()
            local vehicle_dist = vec2_dist( carrier_pos, vehicle:get_position_xz() )

            if vehicle_team == update_get_screen_team_id() and vehicle_dist <= 10000 then
                local def = vehicle:get_definition_index()

                if def ~= e_game_object_type.chassis_carrier and def ~= e_game_object_type.chassis_sea_barge and def ~= e_game_object_type.chassis_land_turret and def ~= e_game_object_type.chassis_land_robot_dog and def ~= e_game_object_type.chassis_spaceship and def ~= e_game_object_type.drydock then
                    local parent_vehicle_index = vehicle:get_attached_parent_id()

                    if parent_vehicle_index == 0 then
                        table.insert(deployed_vehicles, vehicle)
                    end
                end
            end
        end
    end

    local cell_spacing = 2
    local grid_w = w
    local cells_x = 6
    local cell_w = grid_w / cells_x - cell_spacing
    local cell_h = 16

    local grid_x = x + (w - grid_w) / 2
    local grid_y = y
    local cell_x = 0
    local cell_y = 0

    for i = 1, #deployed_vehicles do
        local cx = grid_x + cell_x * (cell_w + cell_spacing)
        local cy = grid_y + cell_y * (cell_h + cell_spacing)

        local vehicle = deployed_vehicles[i]

        local vehicle_definition_type = vehicle:get_definition_index()
        local vehicle_definition_name, vehicle_definition_region = get_chassis_data_by_definition_index(vehicle_definition_type)
        local region_vehicle_icon, icon_offset = get_icon_data_by_definition_index(vehicle_definition_type)

        update_ui_rectangle(cx, cy, cell_w, cell_h, color_black)
        update_ui_image(cx, cy, vehicle_definition_region, color_white, 0)

        local bar_h = 10
        local repair_factor = vehicle:get_repair_factor()
        local fuel_factor = vehicle:get_fuel_factor()
        local ammo_factor = vehicle:get_ammo_factor()
        local repair_bar = math.floor(repair_factor * bar_h)
        local fuel_bar = math.floor(fuel_factor * bar_h)
        local ammo_bar = math.floor(ammo_factor * bar_h)

        local bx = cx + 17
        local by = cy + 3

        update_ui_rectangle(bx, by, 1, bar_h, color8(16, 16, 16, 255))
        update_ui_rectangle(bx, by + bar_h - repair_bar, 1, repair_bar, color8(47, 116, 255, 255))
        update_ui_rectangle(bx + 2, by, 1, bar_h, color8(16, 16, 16, 255))
        update_ui_rectangle(bx + 2, by + bar_h - fuel_bar, 1, fuel_bar, color8(119, 85, 161, 255))
        update_ui_rectangle(bx + 4, by, 1, bar_h, color8(16, 16, 16, 255))
        update_ui_rectangle(bx + 4, by + bar_h - ammo_bar, 1, ammo_bar, color8(201, 171, 68, 255))

        cell_x = cell_x + 1
        if cell_x >= cells_x then
            cell_x = 0
            cell_y = cell_y + 1
        end
    end
end

function render_selection_carrier(screen_w, screen_h, carrier_vehicle)
    local ui = g_ui
    
    local is_local = update_get_is_focus_local()

    local selected_bay_index = -1
    local is_undock = false
    local loadout_w = 74
    local left_w = (screen_w / 2) - loadout_w - 25
    local selected_vehicle = nil
    local region_w = 0
    local region_h = 0

    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_all)

    local window = ui:begin_window(update_get_loc(e_loc.upp_docked), 10 + (screen_w / 4), 10, left_w, 130, atlas_icons.column_pending, true, 2)
        region_w, region_h = ui:get_region()
        update_ui_line(region_w / 2, 0, region_w / 2, region_h, color_white)

        window.cy = window.cy + 5
        selected_bay_index, is_undock = imgui_carrier_docking_bays(ui, carrier_vehicle, 8, 22, g_animation_time)

        if is_local then
            g_selected_bay_index = selected_bay_index
        end

        selected_vehicle = update_get_map_vehicle_by_id(carrier_vehicle:get_attached_vehicle_id(g_selected_bay_index))

    ui:end_window()
    
    ui:begin_window(update_get_loc(e_loc.upp_deployed), 10 + (screen_w / 4), 145, left_w, 100, atlas_icons.column_pending, false, 2)
        ui_render_selection_carrier_vehicle_overview(0, 0, left_w, 100, carrier_vehicle)
    ui:end_window()
    
    window = ui:begin_window(update_get_loc(e_loc.upp_loadout), 10 + (screen_w / 4) + left_w + 5, 10, 74, 84, atlas_icons.column_stock, false, 2)
        region_w, region_h = ui:get_region()
        window.cy = region_h / 2 - 32
        imgui_vehicle_chassis_loadout(ui, selected_vehicle, g_selected_bay_index)
    ui:end_window()
end

function render_selection_vehicle(screen_w, screen_h, vehicle)
    local screen_vehicle = update_get_screen_vehicle()

    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)

    if screen_vehicle:get() then
        local ui = g_ui
        
        local loadout_w = 74
        local left_w = (screen_w / 2) - loadout_w - 25

        local window = ui:begin_window(update_get_loc(e_loc.upp_loadout), 10 + (screen_w / 4) + left_w + 5, (screen_h / 2) - 50, loadout_w, 84, atlas_icons.column_stock, false, 2)
            local region_w, region_h = ui:get_region()
            window.cy = region_h / 2 - 32
            imgui_vehicle_chassis_loadout(ui, vehicle, nil)
        ui:end_window()

        local vehicle_definition_index = vehicle:get_definition_index()
        local vehicle_definition_name, vehicle_definition_region = get_chassis_data_by_definition_index(vehicle_definition_index)

        local hitpoints = vehicle:get_hitpoints()
        local hitpoints_total = vehicle:get_total_hitpoints()
        local damage_factor = clamp(hitpoints / hitpoints_total, 0, 1)
        local fuel_factor = vehicle:get_fuel_factor()
        local ammo_factor = vehicle:get_ammo_factor()
        local color_low = color_status_bad
        local color_mid = color8(255, 255, 0, 255)
        local color_high = color_status_ok

        local title = vehicle_definition_name .. string.format( " ID %.0f", vehicle:get_id() )

        ui:begin_window(title, 10 + (screen_w / 4), (screen_h / 2) - 50, left_w, 100, atlas_icons.column_pending, true, 2)
            ui:stat(update_get_loc(e_loc.hp), hitpoints .. "/" .. hitpoints_total, iff(damage_factor < 0.2, color_low, color_high))

            if vehicle_definition_index == e_game_object_type.chassis_land_turret then
                ui:stat(update_get_loc(e_loc.upp_fuel), "---", color_grey_dark)
                ui:stat(update_get_loc(e_loc.upp_ammo), "---", color_grey_dark)
            else
                ui:stat(update_get_loc(e_loc.upp_fuel), string.format("%.0f%%", fuel_factor * 100), iff(fuel_factor < 0.25, color_low, iff(fuel_factor < 0.5, color_mid, color_high)))
                ui:stat(update_get_loc(e_loc.upp_ammo), string.format("%.0f%%", ammo_factor * 100), iff(ammo_factor < 0.25, color_low, iff(ammo_factor < 0.5, color_mid, color_high)))
            end
--[[ 
            ui:header(update_get_loc(e_loc.upp_actions))
            -- This is broken apparently
            if ui:list_item(update_get_loc(e_loc.upp_center_to_vehicle), true) then
                local pos_xz = vehicle:get_position_xz()
                transition_to_map_pos(pos_xz:x(), pos_xz:y(), 2000)
                g_selection_vehicle_id = 0
                g_is_pointer_pressed = false
            end
--]]
        ui:end_window()
    end
end

function render_selection(screen_w, screen_h)
    update_add_ui_interaction(update_get_loc(e_loc.interaction_cancel), e_game_input.back)

    if g_selection_vehicle_id > 0 then
        local selected_vehicle = update_get_map_vehicle_by_id(g_selection_vehicle_id)

        if selected_vehicle:get() and selected_vehicle:get_team() == update_get_screen_team_id() then
            local vehicle_definition_index = selected_vehicle:get_definition_index()

            if vehicle_definition_index == e_game_object_type.chassis_carrier then
                render_selection_carrier(screen_w, screen_h, selected_vehicle)
            else
                render_selection_vehicle(screen_w, screen_h, selected_vehicle)
            end
        else
            g_selection_vehicle_id = 0
        end
        
        return g_selection_vehicle_id > 0
    end
    
    return false
end

function get_grid_spacing()
    local grid_spacing = 500
    local camera_size = g_map_size + g_map_size_offset

    while camera_size > 2000 and grid_spacing < 16000 do
        camera_size = camera_size / 2
        grid_spacing = grid_spacing * 2
    end

    return grid_spacing
end

function render_map_scale(screen_w, screen_h)
    if g_is_render_holomap_grids then

        local grid_spacing = get_grid_spacing()
        local text = iff( grid_spacing >= 1000, math.floor(grid_spacing / 1000) .. update_get_loc(e_loc.acronym_kilometers), math.floor(grid_spacing) .. update_get_loc(e_loc.acronym_meters) )

        local sx, _ = get_holomap_from_world(0, 0, screen_w, screen_h)
        local ex, _ = get_holomap_from_world(grid_spacing, 0, screen_w, screen_h)
        local dx = ex - sx

        update_ui_push_offset(screen_w - dx/2 - 15, screen_h - 12)

        local w = update_ui_get_text_size(text, 32, 0)
        update_ui_text(-w/2, -10, text, w, 1, color_grey_mid, 0)
        
        update_ui_rectangle(-dx/2, 0, 1, 4, color_grey_dark)
        update_ui_rectangle(0, 2, 1, 2, color_grey_dark)
        update_ui_rectangle(dx/2 - 1, 0, 1, 4, color_grey_dark)
        update_ui_rectangle(-dx/2, 4, dx, 1, color_grey_dark)

        update_ui_pop_offset()
    end
end