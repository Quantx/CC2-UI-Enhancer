g_ui = nil

g_landing_pattern = {
    run_length = 52,
    run_arc = 28,
    final_arc = 16,
    pattern_length = 1000
}

g_colors = {
    dock_queue = color8(205, 8, 246, 255),
    docking = color8(205, 8, 8, 255),
    carrier = color8(101, 243, 97, 255),
    path = color_grey_dark,
}

g_hovered_vehicle_id = 0

function begin()
    begin_load()
    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    local ui = g_ui
    ui:begin_ui()

    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)

    ui:begin_window(update_get_loc(e_loc.upp_air_traffic), 5, 5, screen_w - 10, screen_h - 10, atlas_icons.column_controlling_peer, false, 0, true, true)
        local region_w, region_h = ui:get_region()
        local left_w = 125
        local right_w = region_w - left_w

        update_ui_push_offset((left_w - 100) / 2, region_h - 22)
        update_ui_rectangle_outline(0, 0, 100, 16, color_grey_dark)
        update_ui_text(0, 4, update_get_loc(e_loc.upp_holding_pattern), 100, 1, color_grey_dark, 0)
        update_ui_pop_offset()

        update_ui_push_offset(left_w / 2, region_h / 2 - 8)
        render_landing_pattern()

        local this_vehicle = update_get_screen_vehicle()
        local docking_vehicles = {}

        if this_vehicle:get() then
            docking_vehicles = get_docking_vehicles(this_vehicle)

            for _, v in pairs(docking_vehicles) do
                if v.is_wing then
                    render_docking_vehicle_wing(this_vehicle, v.vehicle)
                elseif v.is_rotor then
                    render_docking_vehicle_rotor(this_vehicle, v.vehicle)
                end
            end
        end

        update_ui_pop_offset()

        update_ui_rectangle(left_w - 1, 0, 1, region_h, color_white)

        local win_list = ui:begin_window("##list", left_w, 0, right_w, region_h, nil, true, 1, update_get_is_focus_local())
            local list_region_w, list_region_h = ui:get_region()
            
            local column_widths = { 20, 65, -1 }
            local column_margins = { 2, 2, 2 }

            imgui_table_header(ui, {
                { w=column_widths[1], margin=column_margins[1], value=update_get_loc(e_loc.upp_id) },
                { w=column_widths[2], margin=column_margins[2], value=update_get_loc(e_loc.upp_acronym_vehicle_name_handle) },
                { w=column_widths[3], margin=column_margins[3], value=atlas_icons.column_fuel },
            })

            g_hovered_vehicle_id = 0

            if #docking_vehicles > 0 then
                for _, v in pairs(docking_vehicles) do
                    local vehicle = v.vehicle
                    local id = vehicle:get_id()
                    local fuel_factor = vehicle:get_fuel_factor()
                    local vehicle_name = get_chassis_data_by_definition_index(vehicle:get_definition_index())
                    local fuel_col = iff(fuel_factor < 0.25, color_status_bad, iff(fuel_factor < 0.5, color_status_warning, color_status_ok))

                    imgui_table_entry(ui, {
                        { w=column_widths[1], margin=column_margins[1], value=tostring(id % 1000) },
                        { w=column_widths[2], margin=column_margins[2], value=vehicle_name },
                        { w=column_widths[3], margin=column_margins[3], value=string.format("%.0f%%", fuel_factor * 100), col=fuel_col },
                    }, false)

                    if ui:is_item_selected() and update_get_is_focus_local() then
                        g_hovered_vehicle_id = id
                    end
                end
            else
                ui:spacer(3)
                update_ui_text(0, win_list.cy, "---", right_w, 1, color_grey_dark, 0)
            end
        ui:end_window()
    ui:end_window()

    ui:end_ui()
end

function input_event(event, action)
    g_ui:input_event(event, action)

    if action == e_input_action.release then
        if event == e_input.back then
            update_set_screen_state_exit()
        end
    end
end

function input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
end

function input_scroll(dy)
    g_ui:input_scroll(dy)
end

function input_axis(x, y, z, w)
end


--------------------------------------------------------------------------------
--
-- RENDER HELPERS
--
--------------------------------------------------------------------------------

function render_landing_pattern()
    local run_length = g_landing_pattern.run_length
    local run_arc = g_landing_pattern.run_arc
    local final_arc = g_landing_pattern.final_arc

    -- render landing paths
    line_arc(run_length / 2, 0, run_arc, math.pi * -0.5, math.pi * 0.5, 8, g_colors.path)
    line_arc(-run_length / 2, 0, run_arc, math.pi * 0.5, math.pi * 1.5, 8, g_colors.path)
    update_ui_line(-run_length / 2, -run_arc, run_length / 2, -run_arc, g_colors.path)
    update_ui_line(-run_length / 2, run_arc, run_length / 2, run_arc, g_colors.path)
    line_arc(run_length / 2 + run_arc - final_arc, 0, final_arc, 0, math.pi * -0.5, 4, g_colors.path)
    update_ui_line(run_length / 2 + run_arc - final_arc, -final_arc, -14, -final_arc, g_colors.path)
    update_ui_line(10, -final_arc, 10 + final_arc, 0, g_colors.path)
    update_ui_line(run_length / 2 + final_arc, 0, 10 + final_arc, 0, g_colors.path)
    
    update_ui_image(-22, -final_arc - 7, atlas_icons.holomap_icon_carrier, g_colors.carrier, 3)
end

function render_docking_vehicle_wing(vehicle_parent, vehicle)
    local run_length = g_landing_pattern.run_length
    local run_arc = g_landing_pattern.run_arc
    local final_arc = g_landing_pattern.final_arc
    local pattern_length = g_landing_pattern.pattern_length
    local relative_position = update_get_map_vehicle_position_relate_to_parent_vehicle(vehicle_parent:get_id(), vehicle:get_id())
    local vehicle_dock_state = vehicle:get_dock_state()
    local p0x = 0
    local p0z = 0
    
    if vehicle_dock_state == e_vehicle_dock_state.dock_queue then
        if relative_position:z() > pattern_length then
            local angle = update_get_angle_2d(relative_position:x() + 1000, relative_position:z() - pattern_length) - (math.pi * 0.5)
            p0x, p0z = arc_position(-run_length / 2, 0, run_arc, angle)
        elseif relative_position:z() < -pattern_length then
            local angle = update_get_angle_2d(relative_position:x() + 1000, relative_position:z() + pattern_length) - (math.pi * 0.5)
            p0x, p0z = arc_position(run_length / 2, 0, run_arc, angle)
        else
            if relative_position:x() > -200 then
                p0z = -run_arc
            else
                p0z = run_arc
            end
            
            local z_factor = (relative_position:z() - pattern_length) / (pattern_length * 2)
            p0x = -run_length / 2 - z_factor * run_length
        end
    elseif vehicle_dock_state == e_vehicle_dock_state.docking then
        if relative_position:z() < -pattern_length then
            local angle = update_get_angle_2d(relative_position:x() + 200, relative_position:z() + pattern_length) - (math.pi * 0.5)
            p0x, p0z = arc_position(run_length / 2 + run_arc - final_arc, 0, final_arc, angle)
        elseif relative_position:z() > -120 then
            return
        else
            p0z = -final_arc + 1
            
            local z_factor = (relative_position:z() + pattern_length) / (pattern_length - 120)
            p0x = run_length - 14 - (z_factor * ((run_length / 2) + 12))
        end
    end

    local col = iff(vehicle_dock_state == e_vehicle_dock_state.dock_queue, g_colors.dock_queue, g_colors.docking)
    
    if g_hovered_vehicle_id == vehicle:get_id() then
        col = color_white
    end

    update_ui_image(p0x - 3, p0z - 3, atlas_icons.map_icon_air, col, 0)
end

function render_docking_vehicle_rotor(vehicle_parent, vehicle)
    local final_arc = g_landing_pattern.final_arc
    local vehicle_dock_state = vehicle:get_dock_state()
    local relative_position = update_get_map_vehicle_position_relate_to_parent_vehicle(vehicle_parent:get_id(), vehicle:get_id())

    local p0x = -((relative_position:z() + 120) * 0.14)
    local p0z = -final_arc + math.min(p0x - 10, final_arc)
    
    if relative_position:z() < -120 then
        local col = iff(vehicle_dock_state == e_vehicle_dock_state.dock_queue, g_colors.dock_queue, g_colors.docking)

        if g_hovered_vehicle_id == vehicle:get_id() then
            col = color_white
        end
        
        update_ui_image(p0x - 3, p0z - 3, atlas_icons.map_icon_air, col, 0)
    end
end


--------------------------------------------------------------------------------
--
-- UTILITY FUNCTIONS
--
--------------------------------------------------------------------------------

function get_docking_vehicles(vehicle_parent)
    local docking_vehicles = {}

    local vehicle_count = update_get_map_vehicle_count()
    
    for i = 0, vehicle_count - 1, 1 do 
        local vehicle = update_get_map_vehicle_by_index(i)

        if vehicle:get() then
            local vehicle_dock_state = vehicle:get_dock_state()

            if vehicle_dock_state == e_vehicle_dock_state.docking or vehicle_dock_state == e_vehicle_dock_state.dock_queue then
                local vehicle_dock_parent_id = vehicle:get_dock_parent_id()

                if vehicle_dock_parent_id == vehicle_parent:get_id() then
                    if vehicle:get_definition_index() == e_game_object_type.chassis_air_wing_light or vehicle:get_definition_index() == e_game_object_type.chassis_air_wing_heavy then
                        table.insert(docking_vehicles, { 
                            vehicle = vehicle,  
                            is_wing = true,
                            is_rotor = false
                        })
                    elseif vehicle:get_definition_index() == e_game_object_type.chassis_air_rotor_light or vehicle:get_definition_index() == e_game_object_type.chassis_air_rotor_heavy then
                        table.insert(docking_vehicles, {
                            vehicle = vehicle,
                            is_wing = false,
                            is_rotor = true
                        })
                    end
                end
            end
        end
    end

    return docking_vehicles
end

function arc_position(x, y, radius, angle)
    return (x + (radius * math.cos(angle))), (y + (radius * math.sin(angle)))
end

function line_arc(x, y, radius, start_angle, end_angle, segment_count, color)
    for i=0, segment_count - 1, 1 do
        local p0x, p0y = arc_position(x, y, radius, lerp(start_angle, end_angle, i / segment_count))
        local p1x, p1y = arc_position(x, y, radius, lerp(start_angle, end_angle, (i + 1) / segment_count))
        update_ui_line(math.floor(p0x + 0.5), math.floor(p0y + 0.5), math.floor(p1x + 0.5), math.floor(p1y + 0.5), color)
    end
end