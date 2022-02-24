g_camera_pos_x = 0
g_camera_pos_y = 0
g_is_camera_pos_initialised = false
g_camera_size = (64 * 1024)
g_screen_index = 0
g_highlighted_vehicle_id = 0
g_highlighted_waypoint_id = 0
g_drag_vehicle_id = 0
g_drag_waypoint_id = 0
g_selection_vehicle_id = 0
g_selection_waypoint_id = 0
g_selection_attack_target_vehicle_id = 0
g_selected_child_vehicle_id = 0
g_is_selection_map = false
g_map_render_mode = 1
g_is_drag_pan_map = false
g_viewing_vehicle_id = 0
g_is_vehicle_team_colors = true
g_is_island_team_colors = true
g_is_carrier_waypoint = false
g_is_pip_enable = true
g_is_render_grid = true

g_map_window_scroll = 0
g_selected_bay_index = -1

g_blend_tick = 0
g_prev_pos_x = 0
g_prev_pos_y = 0
g_prev_size = (64 * 1024)
g_next_pos_x = 0
g_next_pos_y = 0
g_next_size = (64 * 1024)

g_drag_distance = 0
g_blink_timer = 0

g_input_x = 0
g_input_y = 0
g_input_z = 0
g_input_w = 0

g_team_carrier_pos = vec3(0, 0, 0)

g_animation_time = 0
g_go_code = 0
g_go_code_time = 100000

g_color_attack_order = color_status_dark_red
g_color_airlift_order = color_status_ok
g_color_waypoint = color8(0, 255, 255, 8)
g_color_resupply = color8(0, 255, 128, 32)

g_is_mouse_mode = false
g_pointer_pos_x = 0
g_pointer_pos_y = 0
g_pointer_pos_x_prev = 0
g_pointer_pos_y_prev = 0
g_is_pointer_hovered = false
g_is_pointer_pressed = false

g_cursor_pos_x = 0
g_cursor_pos_y = 0

g_ui = nil

g_holomap_last_x = 0
g_holomap_last_y = 0
g_holomap_last_anim = 0

-- tutorial controls
g_tut_is_carrier_selected = false
g_tut_is_context_menu_open = false
g_tut_undocking_vehicle_id = 0
g_tut_selected_vehicle_id = 0
g_tut_selected_waypoint_id = 0

function get_is_selection()
    return (g_selection_vehicle_id > 0 or g_selection_waypoint_id > 0 or g_selection_attack_target_vehicle_id > 0 or g_is_selection_map)
--[[
    if g_selection_vehicle_id > 0 or g_selection_waypoint_id > 0 or g_selection_attack_target_index >= 0 or g_is_selection_map then
        return true
    else
        return false
    end
--]]
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
    local left_w = screen_w - loadout_w - 25
    local selected_vehicle = nil
    local region_w = 0
    local region_h = 0

    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_all)
    g_tut_is_carrier_selected = true

    local window = ui:begin_window(update_get_loc(e_loc.upp_docked), 10, 10, left_w, 130, atlas_icons.column_pending, true, 2)
        region_w, region_h = ui:get_region()
        update_ui_line(region_w / 2, 0, region_w / 2, region_h, color_white)

        window.cy = window.cy + 5
        selected_bay_index, is_undock = imgui_carrier_docking_bays(ui, carrier_vehicle, 8, 22, g_animation_time)

        if is_local then
            g_selected_bay_index = selected_bay_index
        end

        selected_vehicle = update_get_map_vehicle_by_id(carrier_vehicle:get_attached_vehicle_id(g_selected_bay_index))

        if selected_vehicle ~= nil and selected_vehicle:get() then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_deploy), e_game_input.interact_a)
        end

        if is_undock and selected_vehicle ~= nil and selected_vehicle:get() then
            undock_by_bay_index(carrier_vehicle, g_selected_bay_index)
        end
    ui:end_window()
    
    ui:begin_window(update_get_loc(e_loc.upp_deployed), 10, 145, left_w, 100, atlas_icons.column_pending, false, 2)
        ui_render_selection_carrier_vehicle_overview(0, 0, left_w, 100, carrier_vehicle)
    ui:end_window()
    
    window = ui:begin_window(update_get_loc(e_loc.upp_loadout), 10 + left_w + 5, 10, 74, 84, atlas_icons.column_stock, false, 2)
        region_w, region_h = ui:get_region()
        window.cy = region_h / 2 - 32
        imgui_vehicle_chassis_loadout(ui, selected_vehicle, g_selected_bay_index)
    ui:end_window()
end

function render_selection_vehicle(screen_w, screen_h, vehicle)
    local screen_vehicle = update_get_screen_vehicle()

    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)

    if screen_vehicle:get() then
        if screen_vehicle:get_team() == vehicle:get_team() then
            local ui = g_ui
            
            local loadout_w = 74
            local left_w = screen_w - loadout_w - 25

            local window = ui:begin_window(update_get_loc(e_loc.upp_loadout), 10 + left_w + 5, 10, loadout_w, 84, atlas_icons.column_stock, false, 2)
                local region_w, region_h = ui:get_region()
                window.cy = region_h / 2 - 32
                imgui_vehicle_chassis_loadout(ui, vehicle, selected_bay_index)
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

            ui:begin_window(title, 10, 10, left_w, 100, atlas_icons.column_pending, true, 2)
                ui:stat(update_get_loc(e_loc.hp), hitpoints .. "/" .. hitpoints_total, iff(damage_factor < 0.2, color_low, color_high))

                if vehicle_definition_index == e_game_object_type.chassis_land_turret then
                    ui:stat(update_get_loc(e_loc.upp_fuel), "---", color_grey_dark)
                    ui:stat(update_get_loc(e_loc.upp_ammo), "---", color_grey_dark)
                else
                    ui:stat(update_get_loc(e_loc.upp_fuel), string.format("%.0f%%", fuel_factor * 100), iff(fuel_factor < 0.25, color_low, iff(fuel_factor < 0.5, color_mid, color_high)))
                    ui:stat(update_get_loc(e_loc.upp_ammo), string.format("%.0f%%", ammo_factor * 100), iff(ammo_factor < 0.25, color_low, iff(ammo_factor < 0.5, color_mid, color_high)))
                end

                ui:header(update_get_loc(e_loc.upp_actions))
                
                if ui:list_item(update_get_loc(e_loc.upp_center_to_vehicle), true) then
                    g_camera_pos_x = vehicle:get_position_xz():x()
                    g_camera_pos_y = vehicle:get_position_xz():y()
                end

                if get_is_vehicle_enterable(vehicle) then
                    if ui:list_item(update_get_loc(e_loc.upp_camera), true) then
                        update_set_screen_vehicle_control_id(vehicle:get_id())
                        g_viewing_vehicle_id = vehicle:get_id()
                        g_screen_index = 1
                    end
                end
            ui:end_window()
        end
    end
end

function undock_by_bay_index(carrier_vehicle, bay_index)
    local child_vehicle_id = carrier_vehicle:get_attached_vehicle_id(bay_index)

    if child_vehicle_id >= 0 then
        g_selected_child_vehicle_id = child_vehicle_id
    end
    
    g_selection_vehicle_id = 0
    g_selection_waypoint_id = 0
    g_selection_attack_target_vehicle_id = 0
    g_is_selection_map = false
    g_screen_index = 0
end

function render_selection_waypoint(screen_w, screen_h)
    local selected_vehicle = update_get_map_vehicle_by_id(g_selection_vehicle_id)

    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)

    if selected_vehicle:get() then
        local selected_waypoint = selected_vehicle:get_waypoint_by_id(g_selection_waypoint_id)

        if selected_waypoint:get() then
            local ui = g_ui
            local attack_type = -1
        
            local is_group_a = selected_waypoint:get_is_wait_group(0)
            local is_group_b = selected_waypoint:get_is_wait_group(1)
            local is_group_c = selected_waypoint:get_is_wait_group(2)
            local is_group_d = selected_waypoint:get_is_wait_group(3)
            local is_deploy = selected_waypoint:get_type() == e_waypoint_type.deploy
            local waypoint_altitude = selected_waypoint:get_altitude()
            local is_modified = false

            local window = ui:begin_window(update_get_loc(e_loc.upp_waypoint), 30, 30, screen_w - 60, screen_h - 60, atlas_icons.column_distance, true, 2)
                window.label_bias = 0.8

                ui:header(update_get_loc(e_loc.upp_wait_group))
        
                is_group_a, is_modified = ui:checkbox(update_get_loc(e_loc.upp_wait_alpha), is_group_a)
                if is_modified then selected_vehicle:set_waypoint_wait_group(g_selection_waypoint_id, 0, is_group_a) end

                is_group_b, is_modified = ui:checkbox(update_get_loc(e_loc.upp_wait_bravo), is_group_b)
                if is_modified then selected_vehicle:set_waypoint_wait_group(g_selection_waypoint_id, 1, is_group_b) end

                is_group_c, is_modified = ui:checkbox(update_get_loc(e_loc.upp_wait_charlie), is_group_c)
                if is_modified then selected_vehicle:set_waypoint_wait_group(g_selection_waypoint_id, 2, is_group_c) end

                is_group_d, is_modified = ui:checkbox(update_get_loc(e_loc.upp_wait_delta), is_group_d)
                if is_modified then selected_vehicle:set_waypoint_wait_group(g_selection_waypoint_id, 3, is_group_d) end
                
                local vehicle_definition_index = selected_vehicle:get_definition_index()
                local is_robot_dog_deploy = get_is_vehicle_robot_dog_deploy_available(selected_vehicle)

                if vehicle_definition_index == e_game_object_type.chassis_air_rotor_heavy or is_robot_dog_deploy then
                    ui:header(update_get_loc(e_loc.upp_actions))

                    is_deploy, is_modified = ui:checkbox(update_get_loc(e_loc.upp_deploy_vehicle), is_deploy)
                    if is_modified then selected_vehicle:set_waypoint_type_deploy(g_selection_waypoint_id, is_deploy) end
                end
                
                window.label_bias = 0.5

                if get_is_vehicle_air(vehicle_definition_index) then
                    ui:header(update_get_loc(e_loc.upp_air))

                    -- waypoint altitude selector
                    waypoint_altitude, is_modified = ui:selector(update_get_loc(e_loc.upp_altitude), waypoint_altitude, 0, 2000, 50)
                    if is_modified then selected_vehicle:set_waypoint_altitude(g_selection_waypoint_id, waypoint_altitude) end

                    -- waypoint altitude increments
                    local inc_val = { -500, -100, 100, 500 }
                    local inc_act = ui:button_group({ "-500", "-100", "+100", "+500" }, true)
                    if inc_act >= 0 and inc_act < #inc_val then
                        selected_vehicle:set_waypoint_altitude(g_selection_waypoint_id, math.max( 0, math.min( 2000, waypoint_altitude + inc_val[inc_act + 1])))
                    end

                    -- waypoint altitude presets
                    local pre_val = { 400, 1100, 1700, 2000 }
                    local pre_act = ui:button_group({ "400", "1100", "1700", "2000" }, true)
                    if pre_act >= 0 and pre_act < #pre_val then
                        selected_vehicle:set_waypoint_altitude(g_selection_waypoint_id, pre_val[pre_act + 1])
                    end
                end
            ui:end_window()
        else
            g_selection_waypoint_id = 0
            g_selection_vehicle_id = 0
        end
    else
        g_selection_waypoint_id = 0
        g_selection_vehicle_id = 0
    end
end

function render_selection_attack_target(screen_w, screen_h)
    local ui = g_ui
    local attack_type = -1

    local selected_vehicle = update_get_map_vehicle_by_id(g_selection_vehicle_id)
    local attack_target_vehicle = update_get_map_vehicle_by_id(g_selection_attack_target_vehicle_id)

    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)

    if selected_vehicle:get() and attack_target_vehicle:get() then
        ui:begin_window(update_get_loc(e_loc.upp_attack_target), 64, 64, screen_w - 128, screen_h - 128, atlas_icons.column_laser, true, 2)
        
        local is_air = get_is_vehicle_air(attack_target_vehicle:get_definition_index())
        local is_land = get_is_vehicle_land(attack_target_vehicle:get_definition_index())
        local is_sea = get_is_vehicle_sea(attack_target_vehicle:get_definition_index())

        MM_LOG(tostring(is_air) .. ", " .. tostring(is_land) .. ", " .. tostring(is_sea))

        local is_attack_type_any_capable = selected_vehicle:get_is_attack_type_capable(e_attack_type.any, is_air, is_land, is_sea)
        local is_attack_type_bomb_single_capable = selected_vehicle:get_is_attack_type_capable(e_attack_type.bomb_single, is_air, is_land, is_sea)
        local is_attack_type_bomb_double_capable = selected_vehicle:get_is_attack_type_capable(e_attack_type.bomb_double, is_air, is_land, is_sea)
        local is_attack_type_missile_single_capable = selected_vehicle:get_is_attack_type_capable(e_attack_type.missile_single, is_air, is_land, is_sea)
        local is_attack_type_missile_double_capable = selected_vehicle:get_is_attack_type_capable(e_attack_type.missile_double, is_air, is_land, is_sea)
        local is_attack_type_torpedo_single_capable = selected_vehicle:get_is_attack_type_capable(e_attack_type.torpedo_single, is_air, is_land, is_sea)
        local is_attack_type_gun_capable = selected_vehicle:get_is_attack_type_capable(e_attack_type.gun, is_air, is_land, is_sea)
        local is_attack_type_rockets_capable = selected_vehicle:get_is_attack_type_capable(e_attack_type.rockets, is_air, is_land, is_sea)
        local is_attack_type_order_main_gun_capable = selected_vehicle:get_is_attack_type_capable(e_attack_type.order_main_gun, is_air, is_land, is_sea)
        local is_attack_type_order_cruise_missile_capable = selected_vehicle:get_is_attack_type_capable(e_attack_type.order_cruise_missile, is_air, is_land, is_sea)

        if is_attack_type_any_capable == false then
            ui:text_basic(update_get_loc(e_loc.no_attack_options_available), color_grey_dark)
        else
            if is_attack_type_any_capable and ui:list_item(update_get_loc(e_loc.upp_any), true) then attack_type = e_attack_type.any end
            if is_attack_type_bomb_single_capable and ui:list_item(update_get_loc(e_loc.upp_bomb_single), true) then attack_type = e_attack_type.bomb_single end
            if is_attack_type_bomb_double_capable and ui:list_item(update_get_loc(e_loc.upp_bomb_double), true) then attack_type = e_attack_type.bomb_double end
            if is_attack_type_missile_single_capable and ui:list_item(update_get_loc(e_loc.upp_missile_single), true) then attack_type = e_attack_type.missile_single end
            if is_attack_type_missile_double_capable and ui:list_item(update_get_loc(e_loc.upp_missile_double), true) then attack_type = e_attack_type.missile_double end
            if is_attack_type_torpedo_single_capable and ui:list_item(update_get_loc(e_loc.upp_torpedo), true) then attack_type = e_attack_type.torpedo_single end
            if is_attack_type_gun_capable and ui:list_item(update_get_loc(e_loc.upp_gun), true) then attack_type = e_attack_type.gun end
            if is_attack_type_rockets_capable and ui:list_item(update_get_loc(e_loc.upp_rockets), true) then attack_type = e_attack_type.rockets end
            if is_attack_type_order_main_gun_capable and ui:list_item(update_get_loc(e_loc.upp_attack_type_main_gun), true) then attack_type = e_attack_type.order_main_gun end
            if is_attack_type_order_cruise_missile_capable and ui:list_item(update_get_loc(e_loc.upp_attack_type_cruise_missile), true) then attack_type = e_attack_type.order_cruise_missile end
        end
        
        ui:end_window()

        if attack_type ~= -1 then
            if g_selection_waypoint_id == 0 then
                -- no waypoint selected so add one at selected vehicle's current position

                local selected_vehicle_pos_xz = selected_vehicle:get_position_xz()
                selected_vehicle:clear_waypoints()
                selected_vehicle:clear_attack_target()
                g_selection_waypoint_id = selected_vehicle:add_waypoint(selected_vehicle_pos_xz:x(), selected_vehicle_pos_xz:y())
            end

            local selected_waypoint = selected_vehicle:get_waypoint_by_id(g_selection_waypoint_id)
            
            if selected_waypoint:get() then
                local attack_target_index = selected_waypoint:get_attack_target_count()
                selected_vehicle:set_waypoint_attack_target_target_id(g_selection_waypoint_id, g_selection_attack_target_vehicle_id)
                selected_vehicle:set_waypoint_attack_target_attack_type(g_selection_waypoint_id, attack_target_index, attack_type)

                g_selection_vehicle_id = 0
                g_selection_waypoint_id = 0
                g_selection_attack_target_vehicle_id = 0
            else
                g_selection_vehicle_id = 0
                g_selection_waypoint_id = 0
            end
        end
    else
        g_selection_vehicle_id = 0
        g_selection_waypoint_id = 0
        g_selection_attack_target_vehicle_id = 0
    end
end

function render_selection_map(screen_w, screen_h)
    local ui = g_ui

    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)

    local is_local = update_get_is_focus_local()

    local window = ui:begin_window(update_get_loc(e_loc.upp_map), 30, 30, screen_w - 60, screen_h - 60, atlas_icons.column_pending, true, 2)
        if is_local then
            g_map_window_scroll = window.scroll_y
        else
            window.scroll_y = g_map_window_scroll
        end

        window.label_bias = 0.8    

        ui:header(update_get_loc(e_loc.upp_actions))

        if ui:list_item(update_get_loc(e_loc.upp_center_to_carrier), true) then
            g_camera_pos_x = g_team_carrier_pos:x()
            g_camera_pos_y = g_team_carrier_pos:z()
        end

        ui:header(update_get_loc(e_loc.upp_orders))
        
        if ui:list_item(update_get_loc(e_loc.upp_alpha_go), true) then
            update_set_go_code(0)
            g_go_code = 0
            g_go_code_time = 0
        end

        if ui:list_item(update_get_loc(e_loc.upp_bravo_go), true) then
            update_set_go_code(1)
            g_go_code = 1
            g_go_code_time = 0
        end

        if ui:list_item(update_get_loc(e_loc.upp_charlie_go), true) then
            update_set_go_code(2)
            g_go_code = 2
            g_go_code_time = 0
        end

        if ui:list_item(update_get_loc(e_loc.upp_delta_go), true) then
            update_set_go_code(3)
            g_go_code = 3
            g_go_code_time = 0
        end
        
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

        g_is_carrier_waypoint = ui:checkbox("SHOW CARRIER WAYPOINTS", g_is_carrier_waypoint)
        g_is_pip_enable = ui:checkbox("ENABLE CCTV FEED", g_is_pip_enable)
        g_is_render_grid = ui:checkbox("SHOW GRID", g_is_render_grid)

        ui:spacer(5)

    ui:end_window()
end

function render_selection(screen_w, screen_h)
    update_ui_rectangle(0, 0, 256, 256, color8(0, 0, 0, 128))

    update_add_ui_interaction(update_get_loc(e_loc.interaction_cancel), e_game_input.back)

    if g_selection_attack_target_vehicle_id > 0 then
        render_selection_attack_target(screen_w, screen_h)
    elseif g_selection_waypoint_id > 0 then
        render_selection_waypoint(screen_w, screen_h)
    elseif g_selection_vehicle_id > 0 then
        local selected_vehicle = update_get_map_vehicle_by_id(g_selection_vehicle_id)

        if selected_vehicle:get() then
            local vehicle_definition_index = selected_vehicle:get_definition_index()
        
            if vehicle_definition_index == 0 then -- carrier
                render_selection_carrier(screen_w, screen_h, selected_vehicle)
            elseif selected_vehicle:get_team() == update_get_screen_team_id() then
                render_selection_vehicle(screen_w, screen_h, selected_vehicle)
            end
        else
            g_selection_vehicle_id = 0
        end
    else
        render_selection_map(screen_w, screen_h)
    end
end

function input_selection(event, action)
    if action == e_input_action.press and event == e_input.back then
        g_selection_vehicle_id = 0
        g_selection_waypoint_id = 0
        g_selection_attack_target_vehicle_id = 0
        g_is_selection_map = false
    else
        g_ui:input_event(event, action)
    end
end

function parse()
    g_prev_pos_x = g_next_pos_x
    g_prev_pos_y = g_next_pos_y
    g_prev_size = g_next_size
    g_blend_tick = 0

    g_is_camera_pos_initialised = parse_bool("is_map_init", g_is_camera_pos_initialised)
    g_next_pos_x = parse_f32("map_x", g_next_pos_x)
    g_next_pos_y = parse_f32("map_y", g_next_pos_y)
    g_next_size = parse_f32("map_size", g_next_size)
    g_screen_index = parse_s32("", g_screen_index)
    g_highlighted_vehicle_id = parse_s32("", g_highlighted_vehicle_id)
    g_drag_vehicle_id = parse_s32("", g_drag_vehicle_id)
    g_drag_waypoint_id = parse_s32("", g_drag_waypoint_id)
    g_selection_vehicle_id = parse_s32("", g_selection_vehicle_id)
    g_selection_waypoint_id = parse_s32("", g_selection_waypoint_id)
    g_selected_child_vehicle_id = parse_s32("", g_selected_child_vehicle_id)
    g_is_selection_map = parse_bool("", g_is_selection_map)
    g_map_render_mode = parse_s32("mode", g_map_render_mode)
    g_cursor_pos_x = parse_f32("", g_cursor_pos_x)
    g_cursor_pos_y = parse_f32("", g_cursor_pos_y)
    g_is_vehicle_team_colors = parse_bool("is_vehicle_team_colors", g_is_vehicle_team_colors)
    g_viewing_vehicle_id = parse_s32("", g_viewing_vehicle_id)
    g_is_island_team_colors = parse_bool("is_island_team_colors", g_is_island_team_colors)
    
    -- End of original parse calls
    
    g_is_carrier_waypoint = parse_bool("is_show_carrier_waypoints", g_is_carrier_waypoint)
    g_is_pip_enable = parse_bool("is_show_cctv", g_is_pip_enable)
    g_is_render_grid = parse_bool("is_show_grid", g_is_render_grid)
    g_map_window_scroll = parse_f32("", g_map_window_scroll)
    g_selected_bay_index = parse_s32("", g_selected_bay_index)
end

function begin()
    begin_load()
    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks) 
    g_is_mouse_mode = g_is_pointer_hovered and update_get_active_input_type() == e_active_input.keyboard
    g_animation_time = g_animation_time + ticks

    local screen_vehicle = update_get_screen_vehicle()

    if g_is_camera_pos_initialised == false and screen_vehicle:get() then
        g_is_camera_pos_initialised = true
        
        local position_xz = screen_vehicle:get_position_xz()
        g_camera_pos_x = position_xz:x()
        g_camera_pos_y = position_xz:y()
        g_next_pos_x = g_camera_pos_x
        g_next_pos_y = g_camera_pos_y
    end

    update_set_screen_vehicle_control_id(g_viewing_vehicle_id)

    g_blink_timer = g_blink_timer + ticks
    if g_blink_timer > 30 then 
        g_blink_timer = 0 
    end

    if update_get_is_focus_local() then
        g_next_pos_x = g_camera_pos_x
        g_next_pos_y = g_camera_pos_y
        g_next_size = g_camera_size
    else
        g_blend_tick = g_blend_tick + ticks
        local blend_factor = clamp(g_blend_tick / 10.0, 0.0, 1.0)
        g_camera_pos_x = lerp(g_prev_pos_x, g_next_pos_x, blend_factor)
        g_camera_pos_y = lerp(g_prev_pos_y, g_next_pos_y, blend_factor)
        g_camera_size = lerp(g_prev_size, g_next_size, blend_factor)
    end

    if update_screen_overrides(screen_w, screen_h, ticks) then return end

    g_tut_is_carrier_selected = false
    g_tut_is_context_menu_open = get_is_selection()
    g_tut_undocking_vehicle_id = 0
    g_tut_selected_vehicle_id = g_selection_vehicle_id
    g_tut_selected_waypoint_id = g_selection_waypoint_id

    update_interaction_ui()

    g_ui:begin_ui()

    update_cursor_state(screen_w, screen_h)

    if g_screen_index == 0 then
        if get_is_selection() == false then
            g_camera_pos_x = g_camera_pos_x + (g_input_x * g_camera_size * 0.01)
            g_camera_pos_y = g_camera_pos_y + (g_input_y * g_camera_size * 0.01)
            input_zoom_camera(1 - (g_input_w * 0.1))

            if update_get_active_input_type() == e_active_input.keyboard and g_is_pointer_pressed then
                g_drag_distance = g_drag_distance + math.abs(g_pointer_pos_x - g_pointer_pos_x_prev) + math.abs(g_pointer_pos_y - g_pointer_pos_y_prev)
            end
            
            if g_is_drag_pan_map then
                local pointer_dx, pointer_dy = get_world_delta_from_screen(g_pointer_pos_x - g_pointer_pos_x_prev, g_pointer_pos_y - g_pointer_pos_y_prev, g_camera_size, screen_w, screen_h)

                g_camera_pos_x = g_camera_pos_x - pointer_dx
                g_camera_pos_y = g_camera_pos_y - pointer_dy
            end

            g_drag_distance = g_drag_distance + math.abs(g_input_x) + math.abs(g_input_y)
        end

        update_set_screen_background_type(g_map_render_mode)
        update_set_screen_map_position_scale(g_camera_pos_x, g_camera_pos_y, g_camera_size)

        is_render_islands = (g_camera_size < (64 * 1024))

        update_set_screen_background_is_render_islands(is_render_islands)

        if is_render_islands == false then
            local island_count = update_get_tile_count()

            for i = 0, island_count - 1, 1 do 
                local island = update_get_tile_by_index(i)

                if island:get() then
                    local island_position = island:get_position_xz()
                    local island_color = get_island_team_color(island:get_team_control())
    
                    local screen_pos_x, screen_pos_y = get_screen_from_world(island_position:x(), island_position:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
    
                    update_ui_image(screen_pos_x - 4, screen_pos_y - 4, atlas_icons.map_icon_island, island_color, 0)
                end
            end
        else
            local island_count = update_get_tile_count()

            for i = 0, island_count - 1, 1 do 
                local island = update_get_tile_by_index(i)

                if island:get() then
                    local command_center_count = island:get_command_center_count()
                    local island_color = get_island_team_color(island:get_team_control())

                    if command_center_count > 0 then
                        local command_center_position = island:get_command_center_position(0)

                        local screen_pos_x, screen_pos_y = get_screen_from_world(command_center_position:x(), command_center_position:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                        local island_capture = island:get_team_capture()
                        local island_team = island:get_team_control()
                        local island_capture_progress = island:get_team_capture_progress()
                        local team_color = get_island_team_color(island_capture)

                        if island_capture ~= island_team and island_capture ~= -1 and island_capture_progress > 0 then  
                            update_ui_image(screen_pos_x - 8, screen_pos_y - 11, atlas_icons.map_icon_command_center, iff(g_blink_timer > 15, team_color, island_color), 0)

                            update_ui_rectangle(screen_pos_x - 9, screen_pos_y + 6, 18, 5, color8(0, 0, 0, 255))
                            update_ui_rectangle(screen_pos_x - 8, screen_pos_y + 7, 16 * island_capture_progress, 3, team_color)
                        else
                            update_ui_image(screen_pos_x - 8, screen_pos_y - 11, atlas_icons.map_icon_command_center, island_color, 0)
                        end
                    end
                    
                    local island_position = island:get_position_xz()
                    local island_name = island:get_name()
                    local screen_pos_x, screen_pos_y = get_screen_from_world(island_position:x(), island_position:y() + 3000.0, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
            
                    update_ui_text(screen_pos_x - 64, screen_pos_y - 9, island_name, 128, 1, island_color, 0)

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

        -- find highlighted vehicle

        g_highlighted_vehicle_id = 0
        g_highlighted_waypoint_id = 0

        if g_is_mouse_mode == false or g_is_drag_pan_map == false then
            highlighted_distance_best = 8

            for i = 0, vehicle_count - 1, 1 do 
                local vehicle = update_get_map_vehicle_by_index(i)

                if vehicle:get() then
                    local vehicle_definition_index = vehicle:get_definition_index()

                    if vehicle_definition_index ~= e_game_object_type.chassis_spaceship and vehicle_definition_index ~= e_game_object_type.drydock then
                        local vehicle_team = vehicle:get_team()
                        local vehicle_attached_parent_id = vehicle:get_attached_parent_id()

                        if vehicle_definition_index == e_game_object_type.chassis_carrier and vehicle_team == update_get_screen_team_id() then -- carrier
                            local vehicle_pos_xz = vehicle:get_position_xz()
                            g_team_carrier_pos:x(vehicle_pos_xz:x())
                            g_team_carrier_pos:z(vehicle_pos_xz:y())
                        end

                        if vehicle_attached_parent_id == 0 and vehicle:get_is_visible() and vehicle:get_is_observation_revealed() then
                            local vehicle_pos_xz = vehicle:get_position_xz()

                            local screen_pos_x, screen_pos_y = get_screen_from_world(vehicle_pos_xz:x(), vehicle_pos_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                            local vehicle_distance_to_cursor = math.abs(screen_pos_x - g_cursor_pos_x) + math.abs(screen_pos_y - g_cursor_pos_y)

                            if vehicle_distance_to_cursor < highlighted_distance_best then
                                g_highlighted_vehicle_id = vehicle:get_id()
                                g_highlighted_waypoint_id = 0
                                highlighted_distance_best = vehicle_distance_to_cursor
                            end
                        end

                        if vehicle_team == update_get_screen_team_id() and vehicle_definition_index ~= e_game_object_type.chassis_carrier then
                            local waypoint_count = vehicle:get_waypoint_count()
                            
                            if g_drag_vehicle_id == 0 or g_drag_vehicle_id == vehicle:get_id() then
                                for j = 0, waypoint_count - 1, 1 do
                                    local waypoint = vehicle:get_waypoint(j)
                                    local waypoint_type = waypoint:get_type()

                                    if waypoint_type == e_waypoint_type.move or waypoint_type == e_waypoint_type.deploy then
                                        local waypoint_pos = waypoint:get_position_xz(j)
                                        local waypoint_screen_pos_x, waypoint_screen_pos_y = get_screen_from_world(waypoint_pos:x(), waypoint_pos:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                                        local waypoint_distance_to_cursor = math.abs(waypoint_screen_pos_x - g_cursor_pos_x) + math.abs(waypoint_screen_pos_y - g_cursor_pos_y)

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
        end

        -- render grid

        if g_is_render_grid and g_map_render_mode == 1 then
            local function floor_to(x, y)
                return math.floor(x / y) * y
            end

            local screen_min_x, screen_min_y = get_world_from_screen(0, 0, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
            local screen_max_x, screen_max_y = get_world_from_screen(screen_w, screen_h, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

            local grid_spacing = get_grid_spacing(g_camera_size)
            local grid_min_x = floor_to(screen_min_x, grid_spacing)
            local grid_min_y = floor_to(screen_min_y, grid_spacing)
            local grid_max_x = floor_to(screen_max_x, grid_spacing) + grid_spacing
            local grid_max_y = floor_to(screen_max_y, grid_spacing) + grid_spacing
            local grid_col_maj = color8(0, 255, 255, 5)
            local grid_col_min = color8(0, 255, 255, 1)

            for x = grid_min_x, grid_max_x, grid_spacing do
                local line_x = get_screen_from_world(x, 0, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                update_ui_rectangle(line_x, 0, 1, screen_h, grid_col_maj)

                line_x = get_screen_from_world(x + grid_spacing / 2, 0, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                update_ui_rectangle(line_x, 0, 1, screen_h, grid_col_min)
            end

            for y = grid_min_y, grid_max_y, -grid_spacing do
                local _, line_y = get_screen_from_world(0, y, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                update_ui_rectangle(0, line_y, screen_w, 1, grid_col_maj)

                _, line_y = get_screen_from_world(0, y + grid_spacing / 2, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                update_ui_rectangle(0, line_y, screen_w, 1, grid_col_min)
            end
        end

        -- render weapon radius

        local function render_weapon_radius(world_pos_x, world_pos_y, radius, col)
            local steps = 16
            local step = math.pi * 2 / steps
            local angle_prev = 0               
            local screen_pos_x, screen_pos_y = get_screen_from_world(world_pos_x, world_pos_y, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

            update_ui_begin_triangles()

            for i = 1, steps do
                local angle = step * i
                local x0, y0 = get_screen_from_world(world_pos_x + math.cos(angle_prev) * radius, world_pos_y + math.sin(angle_prev) * radius, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                local x1, y1 = get_screen_from_world(world_pos_x + math.cos(angle) * radius, world_pos_y + math.sin(angle) * radius, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                update_ui_line(x0, y0, x1, y1, col)

                local fill_col = color8(col:r(), col:g(), col:b(), math.floor(col:a() / 2 * (math.sin(g_animation_time * 0.15) * 0.5 + 0.5)))
                update_ui_add_triangle(vec2(x0, y0), vec2(x1, y1), vec2(screen_pos_x, screen_pos_y), fill_col)

                angle_prev = angle
            end

            update_ui_end_triangles()
        end

        if g_drag_vehicle_id > 0 then
            local weapon_radius_vehicle = update_get_map_vehicle_by_id(g_drag_vehicle_id)

            if weapon_radius_vehicle:get() then
                if weapon_radius_vehicle:get_team() == update_get_screen_team_id() then
                    local weapon_range = get_vehicle_weapon_range(weapon_radius_vehicle)
                    local world_x, world_y = get_world_from_screen(g_cursor_pos_x, g_cursor_pos_y, g_camera_pos_x, g_camera_pos_y, g_camera_size, 256, 256)

                    if weapon_range > 0 then
                        render_weapon_radius(world_x, world_y, weapon_range, color8(32, 8, 8, 64))
                    end

                    local def = weapon_radius_vehicle:get_definition_index()

                    if def == e_game_object_type.chassis_sea_ship_light or def == e_game_object_type.chassis_sea_ship_heavy then
                        local team_carrier = screen_vehicle
                        local vehicle_pos_xz = team_carrier:get_position_xz()
                        render_weapon_radius(vehicle_pos_xz:x(), vehicle_pos_xz:y(), 500, color8(0, 255, 128, 8))
                    end
                end
            end
        elseif g_highlighted_vehicle_id > 0 and g_highlighted_waypoint_id == 0 then
            local weapon_radius_vehicle = update_get_map_vehicle_by_id(g_highlighted_vehicle_id)

            if weapon_radius_vehicle:get() then
                local def = weapon_radius_vehicle:get_definition_index()

                if def ~= e_game_object_type.chassis_carrier then
                    if weapon_radius_vehicle:get_team() == update_get_screen_team_id() or weapon_radius_vehicle:get_is_observation_weapon_revealed() then
                        local weapon_range = get_vehicle_weapon_range(weapon_radius_vehicle)
                        local vehicle_pos_xz = weapon_radius_vehicle:get_position_xz()

                        if weapon_range > 0 then
                            render_weapon_radius(vehicle_pos_xz:x(), vehicle_pos_xz:y(), weapon_range, color8(32, 8, 8, 64))
                        end
                    end

                    if weapon_radius_vehicle:get_team() == update_get_screen_team_id() then
                        if def == e_game_object_type.chassis_sea_ship_light or def == e_game_object_type.chassis_sea_ship_heavy then
                            local team_carrier = screen_vehicle
                            local vehicle_pos_xz = team_carrier:get_position_xz()
                            render_weapon_radius(vehicle_pos_xz:x(), vehicle_pos_xz:y(), 500, color8(0, 255, 128, 8))
                        end
                    end
                end
            end
        end

        -- render destroyed vehicles to the map

        local destroyed_vehicle_count = update_get_map_destroyed_vehicle_count()

        for i = 0, destroyed_vehicle_count - 1, 1
        do 
            local destroyed_vehicle = update_get_map_destroyed_vehicle(i)

            if destroyed_vehicle:get() then

                local destroyed_vehicle_position = destroyed_vehicle:get_position_xz(i)
                local destroyed_vehicle_team_id = destroyed_vehicle:get_team(i)
                local destroyed_vehicle_factor = destroyed_vehicle:get_factor(i)

                screen_pos_x, screen_pos_y = get_screen_from_world(destroyed_vehicle_position:x(), destroyed_vehicle_position:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                update_ui_image(screen_pos_x - 4, screen_pos_y - 4, atlas_icons.map_icon_waypoint, color_status_dark_red, 0)
            end
        end

        -- render weapon firing lines

        if g_camera_size < 1024 * 16 then
            local weapon_line_count = update_get_weapon_line_count()

            for i = 0, weapon_line_count - 1 do
                local vehicle_id, direction_xz, tick = update_get_weapon_line_by_index(i)
                local life = 6
                local factor = 1 - clamp(tick / life, 0, 1)
                
                if factor > 0 then
                    if vehicle_id ~= 0 then
                        local vehicle = update_get_map_vehicle_by_id(vehicle_id)

                        if vehicle:get() and vehicle:get_is_visible() and vehicle:get_is_observation_revealed() then
                            local position_xz = vehicle:get_position_xz()
                            local length = 0.04 * g_camera_size

                            local s0x, s0y = get_screen_from_world(position_xz:x(), position_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                            local s1x, s1y = get_screen_from_world(position_xz:x() + direction_xz:x() * length, position_xz:y() + direction_xz:y() * length, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                            update_ui_line(s0x, s0y, s1x, s1y, color8(255, 255, 0, math.floor(factor * 255)))
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
                local vehicle_attached_parent_id = vehicle:get_attached_parent_id()
                local vehicle_definition_index = vehicle:get_definition_index()
                local is_render_vehicle_icon = vehicle_attached_parent_id == 0

                if vehicle_definition_index ~= e_game_object_type.chassis_spaceship and vehicle_definition_index ~= e_game_object_type.drydock then
                    local is_visible = vehicle:get_is_visible()
                    local is_revealed = vehicle:get_is_observation_revealed()

                    if is_visible and is_revealed then
                        local vehicle_pos_xz = vehicle:get_position_xz()
                        local screen_pos_x, screen_pos_y = get_screen_from_world(vehicle_pos_xz:x(), vehicle_pos_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                        -- render waypoints
                        
                        local vehicle_support_id = vehicle:get_supporting_vehicle_id()

                        local waypoint_count = vehicle:get_waypoint_count()
                        
                        local waypoint_pos_x_prev = screen_pos_x
                        local waypoint_pos_y_prev = screen_pos_y
                        
                        local show_waypoints = true
                        if vehicle:get_definition_index() == e_game_object_type.chassis_sea_barge then
                            show_waypoints = false
                        elseif vehicle:get_definition_index() == e_game_object_type.chassis_carrier then
                            show_waypoints = g_is_carrier_waypoint
                        end
                        
                        if vehicle_team == update_get_screen_team_id() and show_waypoints then
                            local waypoint_color = g_color_waypoint

                            if g_highlighted_vehicle_id == vehicle:get_id() and g_highlighted_waypoint_id == 0 then
                                waypoint_color = color8(255, 255, 255, 255)
                            end

                            local vehicle_dock_state = vehicle:get_dock_state()
                            local vehicle_dock_queue_id = vehicle:get_dock_queue_vehicle_id()
                            local dock_state_queue = 5
                            local dock_state_docking = 1

                            if (vehicle_dock_state == dock_state_queue or vehicle_dock_state == dock_state_docking) and vehicle_dock_queue_id ~= 0 and is_render_vehicle_icon then
                                local parent_vehicle = update_get_map_vehicle_by_id(vehicle_dock_queue_id)
                                
                                if parent_vehicle:get() then
                                    local parent_pos_xz = parent_vehicle:get_position_xz()
                                    local parent_screen_pos_x, parent_screen_pos_y = get_screen_from_world(parent_pos_xz:x(), parent_pos_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                                    render_dashed_line(screen_pos_x, screen_pos_y, parent_screen_pos_x, parent_screen_pos_y, waypoint_color)
                                end
                            end
                            
                            local vehicle_resupply_id = vehicle:get_resupply_vehicle_id()

                            if vehicle_resupply_id ~= 0 then
                                local resupply_vehicle = update_get_map_vehicle_by_id(vehicle_resupply_id)

                                if resupply_vehicle:get() then
                                    local resupply_pos_xz = resupply_vehicle:get_position_xz()
                                    local resupply_screen_pos_x, resupply_screen_pos_y = get_screen_from_world(resupply_pos_xz:x(), resupply_pos_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                                    local fuel_factor = vehicle:get_fuel_factor()
                                    local ammo_factor = vehicle:get_ammo_factor()
                                    local is_resupplying = math.floor(fuel_factor * 100 + 0.5) < 100 or math.floor(ammo_factor * 100 + 0.5) < 100
                                    local color = color8(g_color_resupply:r(), g_color_resupply:g(), g_color_resupply:b(), g_color_resupply:a())

                                    if is_resupplying == false then
                                        color:a(color:a() / 4)
                                    end

                                    render_dashed_line(resupply_screen_pos_x, resupply_screen_pos_y, screen_pos_x, screen_pos_y, color)

                                    if get_grid_spacing() < 2000 and g_animation_time % 20 > 10 and is_resupplying then
                                        update_ui_image((screen_pos_x + resupply_screen_pos_x) / 2 - 3, (screen_pos_y + resupply_screen_pos_y) / 2 - 4, atlas_icons.column_stock, color, 0)
                                    end
                                end
                            end

                            if vehicle_support_id ~= 0 then
                                local parent_vehicle = update_get_map_vehicle_by_id(vehicle_support_id)
                                
                                if parent_vehicle:get() then
                                    local parent_pos_xz = parent_vehicle:get_position_xz()
                                    local parent_screen_pos_x, parent_screen_pos_y = get_screen_from_world(parent_pos_xz:x(), parent_pos_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                                    render_dashed_line(screen_pos_x, screen_pos_y, parent_screen_pos_x, parent_screen_pos_y, waypoint_color)
                                end
                            else
                                local waypoint_path = vehicle:get_waypoint_path()
                                local waypoint_start_index = 0

                                if #waypoint_path > 0 then
                                    waypoint_start_index = 1

                                    for i = 1, #waypoint_path do
                                        local waypoint_screen_pos_x, waypoint_screen_pos_y = get_screen_from_world(waypoint_path[i]:x(), waypoint_path[i]:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                                        update_ui_line(waypoint_pos_x_prev, waypoint_pos_y_prev, waypoint_screen_pos_x, waypoint_screen_pos_y, waypoint_color)

                                        update_ui_rectangle(waypoint_screen_pos_x - 1, waypoint_screen_pos_y - 1, 2, 2, waypoint_color)

                                        waypoint_pos_x_prev = waypoint_screen_pos_x;
                                        waypoint_pos_y_prev = waypoint_screen_pos_y;
                                    end

                                    if waypoint_count > 0 then
                                        local waypoint = vehicle:get_waypoint(0)
                                        local waypoint_pos = waypoint:get_position_xz()
                                        local path_end_x, path_end_y = get_screen_from_world(waypoint_pos:x(), waypoint_pos:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

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
                                            waypoint_pos_x_prev, waypoint_pos_y_prev = get_screen_from_world(parent_vehicle_pos_xz:x(), parent_vehicle_pos_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                                        end
                                    end
                                end

                                for j = 0, waypoint_count - 1, 1 do
                                    local waypoint = vehicle:get_waypoint(j)
                                    local waypoint_pos = waypoint:get_position_xz()
                                    local waypoint_screen_pos_x, waypoint_screen_pos_y = get_screen_from_world(waypoint_pos:x(), waypoint_pos:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                                    if j >= waypoint_start_index then
                                        update_ui_line(waypoint_pos_x_prev, waypoint_pos_y_prev, waypoint_screen_pos_x, waypoint_screen_pos_y, waypoint_color)
                                    end

                                    waypoint_pos_x_prev = waypoint_screen_pos_x
                                    waypoint_pos_y_prev = waypoint_screen_pos_y

                                    local waypoint_repeat_index = waypoint:get_repeat_index()

                                    if waypoint_repeat_index >= 0 then
                                        local waypoint_repeat = vehicle:get_waypoint(waypoint_repeat_index)
                                        local waypoint_repeat_pos = waypoint_repeat:get_position_xz()

                                        local repeat_screen_pos_x, repeat_screen_pos_y = get_screen_from_world(waypoint_repeat_pos:x(), waypoint_repeat_pos:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

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

                                            local attack_target_screen_pos_x, attack_target_screen_pos_y = get_screen_from_world(attack_target_pos:x(), attack_target_pos:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

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

                                for j = 0, waypoint_count - 1, 1 do
                                    local waypoint = vehicle:get_waypoint(j)
                                    local waypoint_pos = waypoint:get_position_xz()

                                    local waypoint_screen_pos_x, waypoint_screen_pos_y = get_screen_from_world(waypoint_pos:x(), waypoint_pos:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

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

                                local attack_target_screen_pos_x, attack_target_screen_pos_y = get_screen_from_world(attack_target_pos:x(), attack_target_pos:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                                local color = g_color_attack_order

                                if attack_target_attack_type == e_attack_type.airlift then
                                    color = g_color_airlift_order
                                end

                                render_dashed_line(screen_pos_x, screen_pos_y, attack_target_screen_pos_x, attack_target_screen_pos_y, color)
                                update_ui_image(attack_target_screen_pos_x - 4, attack_target_screen_pos_y - 4, atlas_icons.map_icon_waypoint, color, 0)
                                update_ui_image(attack_target_screen_pos_x - 4, attack_target_screen_pos_y - 4 - 8, attack_target_icon, color, 0)
                                update_ui_text(attack_target_screen_pos_x - 4, attack_target_screen_pos_y - 4 - 8, attack_target_attack_type, 128, 0, color_black, 0)
                            end
                        end

                        if is_render_vehicle_icon then
                            -- render vehicle icon
                    
                            local region_vehicle_icon, icon_offset = get_icon_data_by_definition_index(vehicle_definition_index)
            
                            local element_color = get_vehicle_team_color(vehicle_team)
                            local is_highlight = false

                            if g_selection_vehicle_id == vehicle:get_id() then
                                element_color = color8(255, 255, 255, 255)
                                is_highlight = true
                            elseif g_drag_vehicle_id == vehicle:get_id() then
                                element_color = color8(255, 255, 255, 255)
                                is_highlight = true
                            elseif g_highlighted_vehicle_id == vehicle:get_id() then
                                element_color = color8(255, 255, 255, 255)
                                is_highlight = true
                            end
            
                            if get_vehicle_has_robot_dogs(vehicle) and g_animation_time % 20 < 10 then
                                region_vehicle_icon = atlas_icons.map_icon_surface_capture
                            end

                            update_ui_image(screen_pos_x - icon_offset, screen_pos_y - icon_offset, region_vehicle_icon, element_color, 0)
                            
                            if vehicle:get_definition_index() == e_game_object_type.chassis_carrier then
                                update_ui_image(screen_pos_x - 5, screen_pos_y - 5, atlas_icons.map_icon_circle_9, color_white, 0)

                                local vehicle_dir = vehicle:get_direction()
                                
                                local screen_icon_x = screen_pos_x - icon_offset
                                local screen_icon_y = screen_pos_y - icon_offset
                                
                                update_ui_line(screen_pos_x, screen_pos_y, screen_pos_x + (vehicle_dir:x() * 20), screen_pos_y + (vehicle_dir:y() * -20), color_white)
                            end

                            local damage_indicator_factor = vehicle:get_damage_indicator_factor()
                            local damage_factor = clamp(vehicle:get_hitpoints() / vehicle:get_total_hitpoints(), 0, 1)
                            local fuel_factor = vehicle:get_fuel_factor()
                            local ammo_factor = vehicle:get_ammo_factor()

                            if damage_indicator_factor > 0 then
                                update_ui_image(screen_pos_x - 4, screen_pos_y - 4, atlas_icons.map_icon_damage_indicator, color8(255, 0, 0, math.floor(255 * damage_indicator_factor)), 0)
                            end

                            local cy = screen_pos_y + 4

                            if damage_factor < 1 then
                                -- render healthbar

                                local bar_w = 8
                                local bar_x = screen_pos_x - bar_w / 2
                                local bar_y = cy
                                
                                local bar_color = iff(damage_factor <= 0.2, color8(255, 0, 0, 255), color8(0, 255, 0, 255))
                                local back_color = color_black

                                if damage_indicator_factor > 0.8 then
                                    if g_animation_time % 4 < 2 then
                                        bar_color = color_white
                                    else
                                        bar_color = color8(255, 0, 0, 255)
                                    end
                                end

                                if is_highlight then
                                    bar_color = color_white
                                end

                                update_ui_rectangle(bar_x, bar_y, bar_w, 1, back_color)
                                update_ui_rectangle(bar_x, bar_y, math.floor(damage_factor * bar_w + 0.5), 1, bar_color)

                                cy = cy + 2
                            end

                            if vehicle_team == update_get_screen_team_id() and vehicle_definition_index ~= e_game_object_type.chassis_land_robot_dog then
                                cx = screen_pos_x - 4
                                
                                local is_visible_by_enemy = vehicle:get_is_visible_by_enemy()

                                if is_visible_by_enemy and g_animation_time % 20 > 10 then
                                    local icon_color =  color_enemy

                                    if is_highlight then
                                        icon_color = color_white
                                    end

                                    update_ui_image(screen_pos_x + 3, screen_pos_y - 2, atlas_icons.map_icon_visible, icon_color, 0)
                                end

                                if fuel_factor < 0.5 and get_is_render_fuel_indicator(vehicle) then
                                    local icon_color = iff(fuel_factor < 0.25, color8(255, 0, 0, 255), color8(255, 255, 0, 255))
                                    
                                    if vehicle:get_resupply_vehicle_id() ~= 0 and g_animation_time % 20 > 10 then
                                        icon_color = g_color_resupply
                                    end

                                    if is_highlight then
                                        icon_color = color_white
                                    end

                                    update_ui_image(cx, cy, atlas_icons.map_icon_low_fuel, icon_color, 0)
                                    cx = cx + 4
                                end

                                if ammo_factor < 0.5 and get_is_render_ammo_indicator(vehicle) then
                                    local icon_color = iff(ammo_factor < 0.25, color8(255, 0, 0, 255), color8(255, 255, 0, 255))

                                    if is_highlight then
                                        icon_color = color_white
                                    end

                                    update_ui_image(cx, cy, atlas_icons.map_icon_low_ammo, icon_color, 0)
                                    cx = cx + 4
                                end
                            end

                            if vehicle_team == update_get_screen_team_id() then
                                if vehicle:get_controlling_peer_id() ~= 0 then
                                    update_ui_image(screen_pos_x - icon_offset, screen_pos_y - icon_offset, atlas_icons.map_icon_vehicle_control, element_color, 0)
                                end
                            end
                        elseif g_selected_child_vehicle_id == vehicle:get_id() then
                            -- render as selected child vehicle

                            local parent_vehicle = update_get_map_vehicle_by_id(vehicle_attached_parent_id)

                            g_tut_undocking_vehicle_id = vehicle:get_id()

                            if parent_vehicle:get() then
                                local parent_vehicle_pos_xz = parent_vehicle:get_position_xz()
                                local vehicle_definition_index = vehicle:get_definition_index(i)
                        
                                local screen_pos_x, screen_pos_y = get_screen_from_world(parent_vehicle_pos_xz:x(), parent_vehicle_pos_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                                local region_vehicle_icon, icon_offset = get_icon_data_by_definition_index(vehicle_definition_index)
            
                                update_ui_rectangle(screen_pos_x - icon_offset - 1, screen_pos_y - icon_offset - 14 - 1, 10, 10, color_black)
                                update_ui_image(screen_pos_x - icon_offset, screen_pos_y - icon_offset - 14, region_vehicle_icon, color_white, 0)
                            end
                        end
                    elseif is_revealed then
                        local last_known_position_xz, is_last_known_position_set = vehicle:get_vision_last_known_position_xz()

                        if is_last_known_position_set then
                            local screen_pos_x, screen_pos_y = get_screen_from_world(last_known_position_xz:x(), last_known_position_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                            if vehicle_attached_parent_id == 0 then
                                local element_color = get_vehicle_team_color(vehicle_team)
    
                                update_ui_image(screen_pos_x - 2, screen_pos_y - 2, atlas_icons.map_icon_last_known_pos, element_color, 0)
                            end
                        end
                    end
                end
            end
        end

        -- render missiles to map

        local missile_count = update_get_missile_count()

        for i = 0, missile_count - 1 do
            local missile = update_get_missile_by_index(i)
            local def = missile:get_definition_index()
            
            local position_xz = missile:get_position_xz()
            local screen_pos_x, screen_pos_y = get_screen_from_world(position_xz:x(), position_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

            if missile:get_is_visible() then
                if def == e_game_object_type.missile_robot_dog_payload then
                elseif def == e_game_object_type.torpedo or def == e_game_object_type.torpedo_decoy or def == e_game_object_type.torpedo_noisemaker then
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
                    local is_own_team = missile:get_team() == update_get_local_team_id()

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
                    
                    local missile_distance_to_cursor = math.abs(screen_pos_x - g_cursor_pos_x) + math.abs(screen_pos_y - g_cursor_pos_y)

                    if is_own_team and missile_distance_to_cursor < 8 and is_timer_running then
                        update_ui_text(screen_pos_x - 16, screen_pos_y - 12, tostring(math.floor(missile:get_timer() / 30) + 1), 32, 1, color_missile, 0)
                    end
                else
                    if g_animation_time % 20 < 10 then
                        local color_missile = color8(0, 255, 0, 255)

                        update_ui_image(screen_pos_x - 3, screen_pos_y - 3, atlas_icons.map_icon_missile, color_missile, 0)
                        update_ui_image(screen_pos_x - 3, screen_pos_y - 3, atlas_icons.map_icon_missile_outline, color_missile, 0)
                    else
                        update_ui_image(screen_pos_x - 3, screen_pos_y - 3, atlas_icons.map_icon_missile, color_white, 0)
                    end
                end
            end
        end

        local drag_start_pos = nil

        if get_is_selection() then
            -- selection

            render_selection(screen_w, screen_h)
        elseif g_drag_vehicle_id > 0 and g_drag_waypoint_id > 0 then
            -- drag

            local drag_vehicle = update_get_map_vehicle_by_id(g_drag_vehicle_id)

            if drag_vehicle:get() then
                local drag_waypoint = drag_vehicle:get_waypoint_by_id(g_drag_waypoint_id)

                if drag_waypoint:get() then
                    local waypoint_pos = drag_waypoint:get_position_xz()
                    local screen_pos_x, screen_pos_y = get_screen_from_world(waypoint_pos:x(), waypoint_pos:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                    update_ui_line(screen_pos_x, screen_pos_y, g_cursor_pos_x, g_cursor_pos_y, color8(255, 255, 255, 255))

                    if g_drag_distance > 2 then
                        drag_start_pos = waypoint_pos
                    end
                else
                    g_drag_vehicle_id = 0
                    g_drag_waypoint_id = 0
                end
            end
        elseif g_drag_vehicle_id > 0 then
            -- drag

            local drag_vehicle = update_get_map_vehicle_by_id(g_drag_vehicle_id)

            if drag_vehicle:get() then
                local vehicle_pos_xz = drag_vehicle:get_position_xz()
                local screen_pos_x, screen_pos_y = get_screen_from_world(vehicle_pos_xz:x(), vehicle_pos_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                drag_line_color = iff(get_is_vehicle_type_waypoint_capable(drag_vehicle:get_definition_index()), color_white, color_grey_dark)

                update_ui_line(screen_pos_x, screen_pos_y, g_cursor_pos_x, g_cursor_pos_y, drag_line_color)

                if g_drag_distance > 2 then
                    drag_start_pos = vehicle_pos_xz
                end
            else
                g_drag_vehicle_id = 0
            end
        elseif g_selected_child_vehicle_id ~= 0 then
            -- drag

            local drag_vehicle = update_get_map_vehicle_by_id(g_selected_child_vehicle_id)

            if drag_vehicle:get() then
                local vehicle_pos_xz = drag_vehicle:get_position_xz()
                local screen_pos_x, screen_pos_y = get_screen_from_world(vehicle_pos_xz:x(), vehicle_pos_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                if drag_vehicle:get_attached_parent_id() ~= 0 then
                    local parent_vehicle = update_get_map_vehicle_by_id(drag_vehicle:get_attached_parent_id())

                    if parent_vehicle:get() then
                        local parent_vehicle_pos_xz = parent_vehicle:get_position_xz()
                        screen_pos_x, screen_pos_y = get_screen_from_world(parent_vehicle_pos_xz:x(), parent_vehicle_pos_xz:y(), g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
                    end
                end

                update_ui_line(screen_pos_x, screen_pos_y, g_cursor_pos_x, g_cursor_pos_y, color8(255, 255, 255, 255))
                
                drag_start_pos = vehicle_pos_xz
            end
        elseif g_highlighted_vehicle_id > 0 then
            local highlighted_vehicle = update_get_map_vehicle_by_id(g_highlighted_vehicle_id)

            if highlighted_vehicle:get() then
                local vehicle_definition_index = highlighted_vehicle:get_definition_index()

                if g_highlighted_waypoint_id > 0 then
                    -- render waypoint tooltip
                    local highlighted_waypoint = highlighted_vehicle:get_waypoint_by_id(g_highlighted_waypoint_id)

                    if get_is_vehicle_air(vehicle_definition_index) then
                        local alt_str = string.format( "%.0f ", highlighted_waypoint:get_altitude() ) .. update_get_loc(e_loc.acronym_meters)
                        local alt_width = update_ui_get_text_size(alt_str, 10000, 0) + 4

                        render_tooltip(10, 10, screen_w - 20, screen_h - 20, g_pointer_pos_x, g_pointer_pos_y, alt_width, 14, 10, function(w, h)    update_ui_text(2, 2, alt_str, w - 4, 0, color_white, 0) end)
                    end
                else
                    -- render vehicle tooltip
                    local peers = iff( highlighted_vehicle:get_team() == update_get_screen_team_id(), get_vehicle_controlling_peers(highlighted_vehicle), {} )
                    local tool_height = 21 + (#peers * 10)

                    render_tooltip(10, 10, screen_w - 20, screen_h - 20, g_pointer_pos_x, g_pointer_pos_y, 128, tool_height, 10, function(w, h) render_vehicle_tooltip(w, h, highlighted_vehicle, peers) end)
                end
            end
        elseif g_highlighted_vehicle_id > 0 and g_higlighted_waypoint_id ~= 0 then
            -- render waypoint tooltip

            local highlighted_vehicle = update_get_map_vehicle_by_id(g_highlighted_vehicle_id)

            if highlighted_vehicle:get() then
                if get_is_vehicle_air(highlighted_vehicle:get_definition_index()) then
                    local waypoint = highlighted_vehicle:get_waypoint_by_id(g_highlighted_waypoint_id)

                    if waypoint:get() then
                        local altitude_text = waypoint:get_altitude() .. update_get_loc(e_loc.acronym_meters)
                        local text_w = update_ui_get_text_size(altitude_text, 200, 0)

                        render_tooltip(10, 10, screen_w - 20, screen_h - 20, g_cursor_pos_x, g_cursor_pos_y, text_w + 8, 13, 10, function(w, h)  
                            update_ui_text(0, 2, altitude_text, w, 1, color_white, 0)
                        end)
                    end
                end
            end
        end

        if get_is_selection() == false then
            if update_get_active_input_type() == e_active_input.gamepad or update_get_is_focus_local() == false then
                local crosshair_color = color8(255, 255, 255, 255)

                if g_highlighted_vehicle_id > 0 or g_highlighted_waypoint_id > 0 then
                    crosshair_color = color8(0, 0, 0, 255)
                end

                update_ui_rectangle(g_cursor_pos_x, g_cursor_pos_y + 2, 1, 4, crosshair_color)
                update_ui_rectangle(g_cursor_pos_x, g_cursor_pos_y - 5, 1, 4, crosshair_color)
                update_ui_rectangle(g_cursor_pos_x + 2, g_cursor_pos_y, 4, 1, crosshair_color)
                update_ui_rectangle(g_cursor_pos_x - 5, g_cursor_pos_y, 4, 1, crosshair_color)
            end

            local vehicle_count = update_get_map_vehicle_count()
            for i = 0, vehicle_count - 1, 1 do
                local vehicle = update_get_map_vehicle_by_index(i)
                local waypoint_count = vehicle:get_waypoint_count()

                if vehicle:get() and vehicle:get_definition_index() == e_game_object_type.drydock and vehicle:get_team() == update_get_screen_team_id() and waypoint_count > 0 then
                    local waypoint = vehicle:get_waypoint(0)
                    local waypoint_pos = waypoint:get_position_xz()

                    local waypoint_x = waypoint_pos:x()
                    local waypoint_y = waypoint_pos:y()

                    local cursor_x, cursor_y = get_screen_from_world( waypoint_x, waypoint_y, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)

                    if waypoint_x ~= g_holomap_last_x or waypoint_y ~= g_holomap_last_y then
                        g_holomap_last_x = waypoint_x
                        g_holomap_last_y = waypoint_y
                        g_holomap_last_anim = g_animation_time
                    end

                    local fade = math.max( 255 - math.floor(g_animation_time - g_holomap_last_anim), 0 )
                    update_ui_image_rot(cursor_x, cursor_y, atlas_icons.map_icon_crosshair, color8(255, 255, 255, fade), math.pi / 4)

                    break
                end
            end
            
            render_cursor_info(screen_w, screen_h, drag_start_pos)
            render_map_scale(screen_w, screen_h)

            local sample_x, sample_y = get_world_from_screen(g_cursor_pos_x, g_cursor_pos_y, g_camera_pos_x, g_camera_pos_y, g_camera_size, 256, 256)

            local label_x = 24
            local label_y = 23
            local label_w = screen_w - 2 * label_x
            local label_h = 10

            update_ui_push_offset(label_x, label_y)

            if g_map_render_mode > 1 then
                update_ui_rectangle(0, 0, label_w, label_h, color_black)
            end

            if g_map_render_mode == 2 then
                update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_wind)..": %.2f", update_get_weather_wind_velocity(sample_x, sample_y)), label_w, 0, color_white, 0)
            elseif g_map_render_mode == 3 then
                update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_precipitation)..": %.0f%%", update_get_weather_precipitation_factor(sample_x, sample_y) * 100), label_w, 0, color_white, 0)

                local cx = label_w - 42
                update_ui_image(cx, 1, atlas_icons.column_power, color_white, 0)
                cx = cx + 5
                update_ui_text(cx, 1, string.format(": %.0f%%", update_get_weather_lightning_factor(sample_x, sample_y) * 100), label_w, 0, color_white, 0)
            elseif g_map_render_mode == 4 then
                update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_visibility)..": %.0f%%", update_get_weather_fog_factor(sample_x, sample_y) * 100), label_w, 0, color_white, 0)
            elseif g_map_render_mode == 5 then
                update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_ocean_current)..": %.2f", update_get_ocean_current_velocity(sample_x, sample_y)), label_w, 0, color_white, 0)
            elseif g_map_render_mode == 6 then
                update_ui_text(1, 1, string.format(update_get_loc(e_loc.upp_ocean_depth)..": %.2f", update_get_ocean_depth_factor(sample_x, sample_y)), label_w, 0, color_white, 0)
            end

            update_ui_pop_offset()
        end

        local go_code_factor = 0

        if g_go_code_time < 5 then
            go_code_factor = clamp(g_go_code_time / 5, 0, 1)
        else
            go_code_factor = 1 - clamp((g_go_code_time - 5 - 55) / 5, 0, 1)
        end

        g_go_code_time = g_go_code_time + 1

        if go_code_factor > 0 then
            local go_code_text = ""

            if g_go_code == 0 then
                go_code_text = update_get_loc(e_loc.upp_go_code_alpha)
            elseif g_go_code == 1 then
                go_code_text = update_get_loc(e_loc.upp_go_code_bravo)
            elseif g_go_code == 2 then
                go_code_text = update_get_loc(e_loc.upp_go_code_charlie)
            elseif g_go_code == 3 then
                go_code_text = update_get_loc(e_loc.upp_go_code_delta)
            end

            local rect_w = update_ui_get_text_size(go_code_text, screen_w, 2) + 8
            local rect_h = 14

            update_ui_push_offset((screen_w - rect_w) / 2, screen_h - rect_h - 10)
            update_ui_push_clip(0, 0, rect_w, math.ceil(rect_h * go_code_factor))
            update_ui_rectangle(0, 0, rect_w, rect_h, color_status_bad)
            update_ui_text(0, rect_h / 2 - 4, go_code_text, rect_w, 1, color_black, 0)
            
            update_ui_pop_clip()
            update_ui_pop_offset()
        end
    elseif g_screen_index == 1 then
        update_set_screen_background_type(0)
        local viewing_vehicle = update_get_map_vehicle_by_id(g_viewing_vehicle_id)

        if viewing_vehicle:get() then
            if update_get_is_focus_local() or not g_is_pip_enable then
                g_camera_pos_x = viewing_vehicle:get_position_xz():x()
                g_camera_pos_y = viewing_vehicle:get_position_xz():y()

                local connecting_text = update_get_loc(e_loc.connecting)
                local dot_count = math.floor(g_animation_time / (30 / 4)) % 4

                for i = 1, dot_count, 1 do
                    connecting_text = connecting_text .. "."
                end

                local cx = screen_w / 2 - 40
                local cy = screen_h / 2 - 5
                update_ui_text(cx, cy, connecting_text, 100, 0, color_white, 0)

                local anim = g_animation_time / 30.0
                local bound_left = cx
                local bound_right = bound_left + 75
                local left = bound_left + (bound_right - bound_left) * math.abs(math.sin((anim - math.pi / 2) % (math.pi / 2))) ^ 4
                local right = left + (bound_right - left) * math.abs(math.sin(anim % (math.pi / 2)))

                update_ui_rectangle(left, cy + 12, right - left, 1, color_status_ok)
                update_ui_rectangle(bound_right + bound_left - right, cy - 3, right - left, 1, color_status_ok)
            else
                local is_render_vehicle = viewing_vehicle:get_definition_index() ~= e_game_object_type.chassis_sea_barge
            
                update_set_screen_background_type(9)
                update_set_screen_camera_attach_vehicle(g_viewing_vehicle_id, 0)

                update_set_screen_camera_cull_distance(5000)
                update_set_screen_camera_lod_level(0)
                update_set_screen_camera_is_render_map_vehicles(true)
                update_set_screen_camera_render_attached_vehicle(is_render_vehicle)
                update_set_screen_camera_is_render_ocean(true)
            end
        else
            local cx = screen_w / 2 - 50
            local cy = screen_h / 2
            local connecting_text = update_get_loc(e_loc.connection_lost)

            local text_w, text_h = update_ui_get_text_size(connecting_text, 100, 1)
            update_ui_text(cx, cy - text_h / 2, connecting_text, 100, 1, color_status_bad, 0)
            
            if g_animation_time % 20 > 10 then
                update_ui_image(cx + 50 - text_w / 2 - 16, cy - 5, atlas_icons.hud_warning, color_status_bad, 0)
                update_ui_image(cx + 50 + text_w / 2 + 6, cy - 5, atlas_icons.hud_warning, color_status_bad, 0)
            end
        end
    elseif g_screen_index == 2 then
        -- attack type menu

        update_ui_rectangle(32, 32, 128, 32, color_black)
        update_ui_text(32, 32, update_get_loc(e_loc.upp_attack_selector), 128, 0, color_white, 0)
    end

    g_ui:end_ui()

    g_pointer_pos_x_prev = g_pointer_pos_x
    g_pointer_pos_y_prev = g_pointer_pos_y
end

function update_interaction_ui()
    if g_screen_index == 1 then
        update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)
    elseif get_is_selection() == false then
        if g_selected_child_vehicle_id ~= 0 then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_cancel), e_game_input.back)
            update_add_ui_interaction(update_get_loc(e_loc.interaction_set_waypoint), e_game_input.interact_a)
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_pan), e_ui_interaction_special.map_pan)
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_zoom), e_ui_interaction_special.map_zoom)
        elseif g_drag_vehicle_id > 0 then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_cancel), e_game_input.back)
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_pan), e_ui_interaction_special.map_pan)
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_zoom), e_ui_interaction_special.map_zoom)
        elseif g_highlighted_vehicle_id > 0 then
            if g_highlighted_waypoint_id > 0 then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_waypoint), e_game_input.interact_a)
                update_add_ui_interaction_special(update_get_loc(e_loc.interaction_add_waypoint), e_ui_interaction_special.map_drag)
            else
                local highlighted_vehicle = update_get_map_vehicle_by_id(g_highlighted_vehicle_id)

                if highlighted_vehicle:get() then
                    local vehicle_definition_index = highlighted_vehicle:get_definition_index()
                   
                    if highlighted_vehicle:get_team() == update_get_screen_team_id() then
                        if vehicle_definition_index == e_game_object_type.chassis_carrier then
                            update_add_ui_interaction(update_get_loc(e_loc.interaction_carrier), e_game_input.interact_a)
                        else
                            update_add_ui_interaction(update_get_loc(e_loc.interaction_vehicle), e_game_input.interact_a)

                            if get_is_vehicle_enterable(highlighted_vehicle) then
                                update_add_ui_interaction(update_get_loc(e_loc.interaction_camera), e_game_input.interact_b)
                            end
                        end

                        if get_is_vehicle_type_waypoint_capable(vehicle_definition_index) then
                            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_add_waypoint), e_ui_interaction_special.map_drag)
                        end
                    end
                end
            end
        else
            update_add_ui_interaction(update_get_loc(e_loc.interaction_map_options), e_game_input.interact_a)
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_pan), e_ui_interaction_special.map_pan)
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_zoom), e_ui_interaction_special.map_zoom)
        end
    end
end

function update_cursor_state(screen_w, screen_h)
    if update_get_is_focus_local() == false then return end
    
    if update_get_active_input_type() == e_active_input.keyboard then
        g_cursor_pos_x = g_pointer_pos_x
        g_cursor_pos_y = g_pointer_pos_y
    else
        g_cursor_pos_x = screen_w / 2
        g_cursor_pos_y = screen_h / 2
    end
end

function input_zoom_camera(factor)
    if g_screen_index == 0 then
        if get_is_selection() == false then
            g_camera_size = g_camera_size * factor
            g_camera_size = math.min(g_camera_size, 256 * 1024)
            g_camera_size = math.max(g_camera_size, 128)
        end
    end
end

function input_event(event, action)
    if event == e_input.pointer_1 then
        g_is_pointer_pressed = action == e_input_action.press
    end

    if g_screen_index == 0 then
        if get_is_selection() then
            input_selection(event, action)
        else
            if action == e_input_action.press then
                if event == e_input.action_a or event == e_input.pointer_1 then
                    if g_selected_child_vehicle_id ~= 0 then
                        -- add waypoint to vehicle

                        local world_x, world_y = get_world_from_screen(g_cursor_pos_x, g_cursor_pos_y, g_camera_pos_x, g_camera_pos_y, g_camera_size, 256, 256)
                        local child_vehicle = update_get_map_vehicle_by_id(g_selected_child_vehicle_id)
                        
                        if child_vehicle:get() then
                            child_vehicle:clear_waypoints()
                            child_vehicle:clear_attack_target()
                            child_vehicle:add_waypoint(world_x, world_y)
                        end

                        g_selected_child_vehicle_id = 0
                    elseif g_highlighted_vehicle_id > 0 and g_highlighted_waypoint_id == 0 then
                        local highlighted_vehicle = update_get_map_vehicle_by_id(g_highlighted_vehicle_id)

                        if highlighted_vehicle:get() and highlighted_vehicle:get_team() == update_get_screen_team_id() then
                            g_drag_vehicle_id = g_highlighted_vehicle_id
                            g_drag_waypoint_id = 0
                        end
                    elseif g_highlighted_vehicle_id > 0 and g_highlighted_waypoint_id > 0 then
                        local highlighted_vehicle = update_get_map_vehicle_by_id(g_highlighted_vehicle_id)

                        if highlighted_vehicle:get() and highlighted_vehicle:get_team() == update_get_screen_team_id() then
                            g_drag_vehicle_id = g_highlighted_vehicle_id
                            g_drag_waypoint_id = g_highlighted_waypoint_id
                        end
                    elseif event == e_input.pointer_1 then
                        g_is_drag_pan_map = true
                    end

                    g_drag_distance = 0
                elseif event == e_input.action_b then
                    if g_highlighted_vehicle_id > 0 and g_highlighted_waypoint_id == 0 then
                        local highlighted_vehicle = update_get_map_vehicle_by_id(g_highlighted_vehicle_id)
                            
                        if highlighted_vehicle:get() ~= nil and get_is_vehicle_enterable(highlighted_vehicle) then
                            g_viewing_vehicle_id = highlighted_vehicle:get_id()
                            g_screen_index = 1
                        end
                    end
                elseif event == e_input.back then
                    if g_selected_child_vehicle_id ~= 0 then
                        g_selected_child_vehicle_id = 0
                    elseif g_drag_vehicle_id > 0 then
                        g_drag_vehicle_id = 0
                        g_drag_waypoint_id = 0
                    else
                        update_set_screen_state_exit()
                    end
                end
            else 
                if event == e_input.action_a or event == e_input.pointer_1 then
                    if event == e_input.pointer_1 then
                        g_is_drag_pan_map = false
                    end

                    if g_drag_vehicle_id == g_highlighted_vehicle_id and g_drag_waypoint_id == g_highlighted_waypoint_id and g_selected_child_vehicle_id == 0 then
                        -- tap

                        local drag_threshold = 3

                        if update_get_is_vr() then
                            drag_threshold = 20
                        end

                        if event == e_input.action_a or g_is_pointer_hovered then
                            if g_drag_waypoint_id > 0 then
                                g_selection_vehicle_id = g_drag_vehicle_id
                                g_selection_waypoint_id = g_drag_waypoint_id
                                g_selection_attack_target_vehicle_id = 0
                                g_is_selection_map = false
                            elseif g_drag_vehicle_id > 0 then
                                g_selection_vehicle_id = g_drag_vehicle_id
                                g_selection_waypoint_id = 0
                                g_selection_attack_target_vehicle_id = 0
                                g_is_selection_map = false
                            elseif g_highlighted_vehicle_id == 0 and g_drag_distance < drag_threshold then
                                g_selection_vehicle_id = 0
                                g_selection_waypoint_id = 0
                                g_selection_attack_target_vehicle_id = 0
                                g_is_selection_map = true
                            end
                        end
                    else
                        local drag_vehicle = update_get_map_vehicle_by_id(g_drag_vehicle_id)

                        if drag_vehicle:get() then
                            local vehicle_definition_index = drag_vehicle:get_definition_index()

                            if get_is_vehicle_type_waypoint_capable(vehicle_definition_index) then
                                -- drag

                                if g_highlighted_vehicle_id == g_drag_vehicle_id and g_highlighted_waypoint_id > 0 and g_highlighted_waypoint_id ~= g_drag_waypoint_id then
                                    drag_vehicle:set_waypoint_repeat(g_drag_waypoint_id, g_highlighted_waypoint_id)                 
                                elseif g_highlighted_vehicle_id > 0 then
                                    local highlighted_vehicle = update_get_map_vehicle_by_id(g_highlighted_vehicle_id)

                                    if highlighted_vehicle:get() then
                                        local highlighted_vehicle_team = highlighted_vehicle:get_team()
                                        local highlighted_vehicle_definition = highlighted_vehicle:get_definition_index()

                                        if highlighted_vehicle_team == update_get_screen_team_id() then
                                            if g_drag_waypoint_id > 0 and vehicle_definition_index == e_game_object_type.chassis_air_rotor_heavy and get_is_vehicle_airliftable(highlighted_vehicle_definition) then
                                                -- toggle an "attack" target to perform airlift operation on friendly vehicle

                                                local is_highlighted_vehicle_found = false
                                                local drag_waypoint = drag_vehicle:get_waypoint_by_id(g_drag_waypoint_id)
                                                local attack_target_count = drag_waypoint:get_attack_target_count()

                                                for i = 0, attack_target_count - 1, 1 do
                                                    local attack_target_vehicle_id = drag_waypoint:get_attack_target_target_id(i)

                                                    if attack_target_vehicle_id == g_highlighted_vehicle_id then
                                                        is_highlighted_vehicle_found = true
                                                        drag_vehicle:remove_waypoint_attack_target(g_drag_waypoint_id, i)
                                                        break
                                                    end
                                                end

                                                if is_highlighted_vehicle_found == false then
                                                    local highlighted_vehicle_id = highlighted_vehicle:get_id()

                                                    drag_vehicle:set_waypoint_attack_target_target_id(g_drag_waypoint_id, highlighted_vehicle_id)
                                                    drag_vehicle:set_waypoint_attack_target_attack_type(g_drag_waypoint_id, attack_target_count, e_attack_type.airlift)
                                                end
                                            else
                                                if g_drag_vehicle_id == g_highlighted_vehicle_id then
                                                    if g_drag_waypoint_id > 0 then
                                                        local world_x, world_y = get_world_from_screen(g_cursor_pos_x, g_cursor_pos_y, g_camera_pos_x, g_camera_pos_y, g_camera_size, 256, 256)
                            
                                                        drag_vehicle:clear_waypoints_from(g_drag_waypoint_id)
                                                        drag_vehicle:add_waypoint(world_x, world_y)
                                                    elseif g_drag_vehicle_id > 0 then
                                                        -- add waypoint to vehicle
                            
                                                        local world_x, world_y = get_world_from_screen(g_cursor_pos_x, g_cursor_pos_y, g_camera_pos_x, g_camera_pos_y, g_camera_size, 256, 256)
                                                        drag_vehicle:clear_waypoints()
                                                        drag_vehicle:clear_attack_target()
                                                        drag_vehicle:add_waypoint(world_x, world_y)
                                                    end
                                                else
                                                    -- add a support waypoint to friendly vehicle

                                                    if g_drag_waypoint_id > 0 then
                                                        drag_vehicle:clear_waypoints_from(g_drag_waypoint_id)
                                                        local support_waypoint_id = drag_vehicle:add_waypoint(highlighted_vehicle:get_position_xz():x(), highlighted_vehicle:get_position_xz():y())
                                                        drag_vehicle:set_target_vehicle(support_waypoint_id, g_highlighted_vehicle_id)
                                                    else
                                                        drag_vehicle:clear_waypoints()
                                                        drag_vehicle:clear_attack_target()
                                                        local support_waypoint_id = drag_vehicle:add_waypoint(highlighted_vehicle:get_position_xz():x(), highlighted_vehicle:get_position_xz():y())
                                                        drag_vehicle:set_target_vehicle(support_waypoint_id, g_highlighted_vehicle_id)
                                                    end
                                                end
                                            end
                                        else
                                            -- toggle attack target on enemy vehicle

                                            if g_drag_waypoint_id > 0 then 
                                                local is_highlighted_vehicle_found = false
                                                local drag_waypoint = drag_vehicle:get_waypoint_by_id(g_drag_waypoint_id)
                                                local attack_target_count = drag_waypoint:get_attack_target_count()

                                                for i = 0, attack_target_count - 1, 1 do
                                                    local attack_target_vehicle_id = drag_waypoint:get_attack_target_target_id(i)

                                                    if attack_target_vehicle_id == g_highlighted_vehicle_id then
                                                        is_highlighted_vehicle_found = true
                                                        drag_vehicle:remove_waypoint_attack_target(g_drag_waypoint_id, i)
                                                        break
                                                    end
                                                end

                                                if is_highlighted_vehicle_found == false then
                                                    local highlighted_vehicle_id = highlighted_vehicle:get_id()

                                                    -- go to attack type context menu

                                                    g_selection_vehicle_id = g_drag_vehicle_id
                                                    g_selection_waypoint_id = g_drag_waypoint_id
                                                    g_selection_attack_target_vehicle_id = highlighted_vehicle_id
                                                end
                                            else
                                                local highlighted_vehicle_id = highlighted_vehicle:get_id()

                                                -- go to attack type context menu

                                                g_selection_vehicle_id = g_drag_vehicle_id
                                                g_selection_waypoint_id = 0
                                                g_selection_attack_target_vehicle_id = highlighted_vehicle_id
                                            end
                                        end
                                    end
                                else
                                    if g_drag_waypoint_id > 0 then
                                        local world_x, world_y = get_world_from_screen(g_cursor_pos_x, g_cursor_pos_y, g_camera_pos_x, g_camera_pos_y, g_camera_size, 256, 256)
            
                                        drag_vehicle:clear_waypoints_from(g_drag_waypoint_id)
                                        drag_vehicle:add_waypoint(world_x, world_y)
                                    elseif g_drag_vehicle_id > 0 then
                                        -- add waypoint to vehicle
            
                                        local world_x, world_y = get_world_from_screen(g_cursor_pos_x, g_cursor_pos_y, g_camera_pos_x, g_camera_pos_y, g_camera_size, 256, 256)
                                        drag_vehicle:clear_waypoints()
                                        drag_vehicle:clear_attack_target()
                                        drag_vehicle:add_waypoint(world_x, world_y)
                                    end
                                end
                            end
                        end

                        g_is_selection_map = false
                    end
    
                    g_drag_vehicle_id = 0
                    g_drag_waypoint_id = 0
                end
            end
        end
    elseif g_screen_index == 1 then
        if action == e_input_action.release then
            if event == e_input.back then
                g_viewing_vehicle_id = 0
                g_screen_index = 0
            end
        end
    elseif g_screen_index == 2 then
        if action == e_input_action.release then
            if event == e_input.back then
                g_screen_index = 0
            end
        end
    end
end

function input_axis(x, y, z, w)
    g_input_x = x
    g_input_y = y
    g_input_z = z
    g_input_w = w
end

function input_scroll(dy)
    if g_is_pointer_hovered then
        input_zoom_camera(1 - dy * 0.15)
    end
    
    if get_is_selection() then
        g_ui:input_scroll(dy)
    end
end

function input_pointer(is_hovered, x, y)
    g_is_pointer_hovered = is_hovered

    g_pointer_pos_x = x
    g_pointer_pos_y = y

    if get_is_selection() then
        g_ui:input_pointer(is_hovered, x, y)
    end
end

function render_map_scale(screen_w, screen_h)
    if g_is_render_grid then
        local grid_spacing = get_grid_spacing()
        local text = iff( grid_spacing >= 1000, math.floor(grid_spacing / 1000) .. update_get_loc(e_loc.acronym_kilometers), math.floor(grid_spacing) .. update_get_loc(e_loc.acronym_meters) )

        local sx, _ = get_screen_from_world(0, 0, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
        local ex, _ = get_screen_from_world(grid_spacing, 0, g_camera_pos_x, g_camera_pos_y, g_camera_size, screen_w, screen_h)
        local dx = ex - sx

        local inbound = true
        
        if dx > 175 then
            dx = 175
            inbound = false
        end

        update_ui_push_offset(screen_w - dx/2 - 15, screen_h - 20)

        local w = update_ui_get_text_size(text, 32, 0)
        update_ui_text(-w/2, -10, text, w, 1, color_grey_mid, 0)
        
        if inbound then
            update_ui_rectangle(-dx/2, 0, 1, 4, color_grey_dark)
            update_ui_rectangle(dx/2 - 1, 0, 1, 4, color_grey_dark)
        end
        
        update_ui_rectangle(0, 2, 1, 2, color_grey_dark)
        
        update_ui_rectangle(-dx/2, 4, dx, 1, color_grey_dark)

        update_ui_pop_offset()
    end
end

function render_cursor_info(screen_w, screen_h, world_pos_drag_start)
    -- render bearing/position information

    local cy = screen_h - iff(world_pos_drag_start, 55, 35)
    local cx = 15
    local world_x, world_y = get_world_from_screen(g_cursor_pos_x, g_cursor_pos_y, g_camera_pos_x, g_camera_pos_y, g_camera_size, 256, 256)
    local icon_col = color_grey_mid
    local text_col = color_grey_dark

    update_ui_text(cx, cy, "X", 100, 0, icon_col, 0)
    update_ui_text(cx + 15, cy, string.format("%.0f", world_x), 100, 0, text_col, 0)
    cy = cy + 10

    update_ui_text(cx, cy, "Y", 100, 0, icon_col, 0)
    update_ui_text(cx + 15, cy, string.format("%.0f", world_y), 100, 0, text_col, 0)
    cy = cy + 10

    if world_pos_drag_start then
        local dist =  vec2_dist(world_pos_drag_start, vec2(world_x, world_y))

        if dist < 10000 then
            update_ui_image(cx, cy, atlas_icons.column_distance, icon_col, 0)
            update_ui_text(cx + 15, cy, string.format("%.0f ", dist) .. update_get_loc(e_loc.acronym_meters), 100, 0, text_col, 0)
        else
            update_ui_image(cx, cy, atlas_icons.column_distance, icon_col, 0)
            update_ui_text(cx + 15, cy, string.format("%.2f ", dist / 1000) .. update_get_loc(e_loc.acronym_kilometers), 100, 0, text_col, 0)
        end

        cy = cy + 10

        local bearing = 90 - math.atan(world_y - world_pos_drag_start:y(), world_x - world_pos_drag_start:x()) / math.pi * 180

        if bearing < 0 then bearing = bearing + 360 end

        update_ui_image(cx, cy, atlas_icons.column_angle, icon_col, 0)
        update_ui_text(cx + 15, cy, string.format("%.0f deg", bearing), 100, 0, text_col, 0)
        cy = cy + 10
    end
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

    cx = cx + 6

    local display_id = ""
    if vehicle_definition_index == e_game_object_type.chassis_carrier then
        local team_id = vehicle:get_team() + 1
        display_id = string.upper( vessel_names[team_id] )
    else
        display_id = update_get_loc(e_loc.upp_id) .. string.format( " %.0f", vehicle:get_id() )
    end

    if vehicle:get_is_observation_type_revealed() then
        update_ui_image(cx, 2, vehicle_definition_region, color_white, 0)
        cx = cx + 18

        update_ui_text(cx, 11, display_id, 124, 0, color_white, 0)

        local display_name = vehicle_definition_name
        update_ui_text(cx, 1, display_name, 124, 0, color_white, 0)
        cx = cx + math.max(update_ui_get_text_size(display_id,   10000, 0),
                           update_ui_get_text_size(display_name, 10000, 0)) + 2
    else
        update_ui_image(cx, 2, atlas_icons.icon_chassis_16_wheel_small, color_inactive, 0)
        cx = cx + 18

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

        if get_is_vehicle_enterable(vehicle) then
            update_ui_image(cx, 6, atlas_icons.column_transit, color_highlight, 0)
            cx = cx - 8
        end

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

function get_is_vehicle_robot_dog_deploy_available(vehicle)
    local attachment_count = vehicle:get_attachment_count()

    for i = 0, attachment_count - 1 do
        local attachment = vehicle:get_attachment(i)

        if attachment:get() then
            if attachment:get_definition_index() == e_game_object_type.attachment_turret_robot_dog_capsule and attachment:get_ammo_remaining() > 0 then
                return true
            end
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

function get_is_render_ammo_indicator(vehicle)
    local definition_index = vehicle:get_definition_index()
    return definition_index ~= e_game_object_type.chassis_land_turret
end

function get_is_render_fuel_indicator(vehicle)
    local definition_index = vehicle:get_definition_index()
    return definition_index ~= e_game_object_type.chassis_land_turret
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

function get_grid_spacing()
    local grid_spacing = 500
    local camera_size = g_camera_size

    while camera_size > 2000 and grid_spacing < 16000 do
        camera_size = camera_size / 2
        grid_spacing = grid_spacing * 2
    end

    return grid_spacing
end