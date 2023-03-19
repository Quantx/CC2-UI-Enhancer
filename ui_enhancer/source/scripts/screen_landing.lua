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
g_animation_time = 0

g_hovered_lmr = 1
g_locked_lmr = 1

g_middle_boundry = 125

g_is_pointer_pressed = false
g_is_pointer_hovered = false
g_pointer_pos_x = 0
g_pointer_pos_y = 0
g_is_mouse_mode = false

function parse()
    g_hovered_lmr = parse_s32("", g_hovered_lmr)
    g_locked_lmr = parse_s32("view", g_locked_lmr)
end

function begin()
    begin_load()
    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks)
    g_is_mouse_mode = update_get_active_input_type() == e_active_input.keyboard
    g_animation_time = g_animation_time + ticks
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    local ui = g_ui

    local is_local = update_get_is_focus_local()
    local this_vehicle = update_get_screen_vehicle()

    if g_locked_lmr == 1 then
        update_add_ui_interaction("pin view", e_game_input.interact_a)
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_lr)
    else
        update_add_ui_interaction("unpin view", e_game_input.interact_a)
        g_hovered_lmr = g_locked_lmr
    end

    local title = ""
    
    if g_hovered_lmr ~= 2 then title = title .. "SURFACE TRAFFIC" end
    if g_hovered_lmr == 1 then title = title .. "       " end
    if g_hovered_lmr ~= 0 then title = title .. update_get_loc(e_loc.upp_air_traffic) end

    ui:begin_ui()

    ui:begin_window(title, 5, 5, screen_w - 10, screen_h - 10, atlas_icons.column_controlling_peer, false, 0, true, true)
        local region_w, region_h = ui:get_region()
        local left_w = g_middle_boundry
        local right_w = region_w - left_w

        if is_local and g_is_mouse_mode and g_is_pointer_hovered and g_locked_lmr == 1 then
            g_hovered_lmr = iff( g_pointer_pos_x < left_w, 0, 2 )
        end

        if g_hovered_lmr ~= 2 then
            local win_list = ui:begin_window("##list", 0, 0, left_w, region_h, nil, true, 1, is_local)
                render_vehicle_list(win_list, false)
            ui:end_window()
        end
        
        if g_hovered_lmr ~= 0 then
            local win_list = ui:begin_window("##list", left_w, 0, right_w, region_h, nil, true, 1, is_local)
                render_vehicle_list(win_list, true)
            ui:end_window()
        end

        if this_vehicle:get() then
            if g_hovered_lmr == 0 then
                local dmc = iff( g_hovered_lmr == g_locked_lmr, color_status_warning, color_grey_dark )
            
                update_ui_push_offset(right_w + (left_w - 100) / 2, region_h - 22)
                update_ui_rectangle_outline(0, 0, 100, 16, dmc)
                update_ui_text(0, 4, "DOCKING QUEUE", 100, 1, dmc, 0)
                update_ui_pop_offset()

                update_ui_push_clip( left_w, 0, right_w, region_h )
                update_ui_push_offset(right_w + 20, region_h / 2 - 8)
                update_ui_image( -13, -7, atlas_icons.holomap_icon_carrier, g_colors.carrier, 3)
            
                local vehicle_list = get_all_surface_vehicles()
                for _, v in pairs(vehicle_list) do
                    --prevents the drones that are not in the holding or landing pattern to show up on the left side of the screen
                    local vehicle = v.vehicle
                    local vehicle_dock_state = vehicle:get_dock_state()

                    if vehicle_dock_state == e_vehicle_dock_state.dock_queue or vehicle_dock_state == e_vehicle_dock_state.docking then
                        render_docking_vehicle_surface(this_vehicle, v.vehicle)
                    end
                end
                
                update_ui_pop_offset()
                update_ui_pop_clip()
            elseif g_hovered_lmr == 2 then
                local dmc = iff( g_hovered_lmr == g_locked_lmr, color_status_warning, color_grey_dark )
            
                update_ui_push_offset((left_w - 100) / 2, region_h - 22)
                update_ui_rectangle_outline(0, 0, 100, 16, dmc)
                update_ui_text(0, 4, update_get_loc(e_loc.upp_holding_pattern), 100, 1, dmc, 0)
                update_ui_pop_offset()

                update_ui_push_clip( 0, 0, left_w - 2, region_h )
                update_ui_push_offset(left_w / 2, region_h / 2 - 8)
                render_landing_pattern()
            
                local vehicle_list = get_all_air_vehicles()
                for _, v in pairs(vehicle_list) do
                    --prevents the drones that are not in the holding or landing pattern to show up on the left side of the screen
                    local vehicle = v.vehicle
                    local vehicle_dock_state = vehicle:get_dock_state()

                    if vehicle_dock_state == e_vehicle_dock_state.dock_queue or vehicle_dock_state == e_vehicle_dock_state.docking then
                        if v.is_wing then
                            render_docking_vehicle_wing( this_vehicle, v.vehicle)
                        elseif v.is_rotor then
                            render_docking_vehicle_rotor(this_vehicle, v.vehicle)
                        end
                    end
                end
                
                update_ui_pop_offset()
                update_ui_pop_clip()
            end
        end

        update_ui_rectangle(left_w - 1, 0, 1, region_h, color_white)
    ui:end_window()

    ui:end_ui()
end

function input_event(event, action)
    g_ui:input_event(event, action)

    if action == e_input_action.release and event == e_input.back then
        g_hovered_lmr = 1
        g_hovered_vehicle_id = 0
        update_set_screen_state_exit()
    elseif event == e_input.action_a or event == e_input.pointer_1 then
        g_is_pointer_pressed = action == e_input_action.press
        
        if (not g_is_mouse_mode or g_is_pointer_hovered) and g_is_pointer_pressed then
            g_locked_lmr = iff( g_locked_lmr == g_hovered_lmr, 1, g_hovered_lmr )
        end
    elseif event == e_input.left and action == e_input_action.press and not g_is_mouse_mode then
        g_hovered_lmr = 0
    elseif event == e_input.right and action == e_input_action.press and not g_is_mouse_mode then
        g_hovered_lmr = 2
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
end

function input_axis(x, y, z, w)
end

function render_vehicle_list( win_list, is_air )
    local ui = g_ui

    local is_local = update_get_is_focus_local()
    local list_region_w, list_region_h = ui:get_region()

    local act_w    = update_ui_get_text_size("AAAA", 10000, 0) + 4
    local name_w   = update_ui_get_text_size("AAAA", 10000, 0) + 4
    local num_w    = update_ui_get_text_size("00",   10000, 0) + 4
    local symbol_w = update_ui_get_text_size("AAA",  10000, 0) + 4
    
    local column_widths = { act_w, name_w, num_w, num_w, num_w, symbol_w }
    local column_margins = { 3, 3, 3, 3, 3, 3 }

    local blink = 30
    
    local column_name = iff( g_animation_time % (blink * 2) > blink, update_get_loc(e_loc.upp_id), update_get_loc(e_loc.upp_acronym_vehicle_name_handle) )

    imgui_table_header(ui, {
        { w=column_widths[1], margin=column_margins[1], value=atlas_icons.column_transit },
        { w=column_widths[2], margin=column_margins[2], value=column_name },
        { w=column_widths[3], margin=column_margins[3], value=atlas_icons.column_fuel },
        { w=column_widths[4], margin=column_margins[4], value=atlas_icons.column_repair },
        { w=column_widths[5], margin=column_margins[5], value=atlas_icons.column_ammo },
        { w=column_widths[6], margin=column_margins[6], value=atlas_icons.column_controlling_peer }
    })

    local vehicle_list = iff( is_air, get_all_air_vehicles(), get_all_surface_vehicles() )

    if not is_local then
        g_hovered_vehicle_id = 0
    end

    if #vehicle_list > 0 then
        local tooltip = nil

        for _, v in pairs(vehicle_list) do
            local vehicle = v.vehicle
            local id = vehicle:get_id()
            
            -- fuel tab
            local fuel_factor = clamp(vehicle:get_fuel_factor(), 0, 1)
            local fuel_col = iff(fuel_factor < 0.25, color_status_bad, iff(fuel_factor < 0.5, color_status_warning, color_status_ok))
            local fuel_string = iff( fuel_factor <= 0.99, string.format("%.0f", fuel_factor * 100), "" )
            
            -- damage tab
            local damage_factor = clamp(vehicle:get_hitpoints() / vehicle:get_total_hitpoints(), 0, 1)
            local damage_color = iff(damage_factor < 0.25, color_status_bad, iff(damage_factor < 0.5, color_status_warning, color_status_ok))
            local damage_string = iff( damage_factor <= 0.99, string.format("%.0f", damage_factor * 100), "" )
            
            -- ammo tab
            local ammo_factor = clamp(vehicle:get_ammo_factor(), 0, 1)
            local ammo_color = iff(ammo_factor < 0.25, color_status_bad, iff(ammo_factor < 0.5, color_status_warning, color_status_ok))
            local ammo_string = iff( ammo_factor <= 0.99, string.format("%.0f", ammo_factor * 100), "" )
            
            -- drone name tab, this has to be after fuel and damage because it takes those into account
            local full_name, vehicle_icon, vehicle_handle = get_chassis_data_by_definition_index(vehicle:get_definition_index())
            local name_color = color_status_ok
            
            if g_animation_time % (blink * 2) > blink then
                vehicle_handle = tostring(id)
            end
            
            if damage_color == color_status_warning or fuel_col == color_status_warning or ammo_color == color_status_warning then
                name_color = color_status_warning
            end
            
            if damage_color == color_status_bad or fuel_col == color_status_bad or ammo_color == color_status_bad then
                name_color = color_status_bad
            end
            
            -- drone mode tab, first gets the needed stats from the drone
            local vehicle_dock_state = vehicle:get_dock_state()
                
            local damage_indicator_factor = vehicle:get_damage_indicator_factor()
            
            local attack_target_type = vehicle:get_attack_target_type()
            
            local waypoint_count = vehicle:get_waypoint_count()
            
            local vehicle_manual_flight_control = false
            local attachment_control_camera = vehicle:get_attachment(0)

            if attachment_control_camera:get() then
                if attachment_control_camera:get_definition_index() == e_game_object_type.attachment_camera_vehicle_control then
                    
                     --we don't have to worry about the "override" control mode during landing because the landing check takes priority to the human pilot check
                    if attachment_control_camera:get_control_mode() ~= "auto" then
                    
                        vehicle_manual_flight_control = true
                    end
                
                else -- normally the flight control module sits in slot 0, but just in case it doesn't for some reason here is a fallback
                    for a = 1, vehicle:get_attachment_count() , 1 do
                        attachment_control_camera = vehicle:get_attachment(a)
                        if attachment_control_camera:get() then
                            if attachment_control_camera:get_definition_index() == e_game_object_type.attachment_camera_vehicle_control then
                                if attachment_control_camera:get_control_mode() ~= "auto" then
                                    vehicle_manual_flight_control = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
            
            local vehicle_peer_id = vehicle:get_controlling_peer_id()
            
            -- drone mode tab, set the list entry string and color
            local vehicle_state_string = "????"
            local vehicle_state_description = "Unknown"
            local vehicle_state_color = color_white
            
            --TODO: incoming damage alert mode, this status is quite short lived, maybe replace it with something else
            if damage_indicator_factor > 0 then
            
                vehicle_state_string = "DAMG"
                vehicle_state_description = "Vehicle under attack"
                vehicle_state_color = color_status_bad
            
            --TODO: plane landing mode. helis don't get the "docking" aka landing state even though the final approach is not cancelable
            --TODO: had to add the landing check for helis here, because they are in the dock_queue state all the way down to the runway.
            elseif vehicle_dock_state == e_vehicle_dock_state.docking then
            
                vehicle_state_string = iff(is_air, "LAND", "DOCK")
                vehicle_state_description = iff(is_air, "Landing", "Docking")
                vehicle_state_color = g_colors.docking
                
            -- holding mode and helicopter landing mode
            elseif vehicle_dock_state == e_vehicle_dock_state.dock_queue then
                
                vehicle_state_string = "PTRN"
                vehicle_state_description = iff(is_air, "In Landing Pattern", "In Docking Pattern")
                vehicle_state_color = g_colors.dock_queue
     
            --TODO: launch mode. "undocking" is also active when the drone is on the crane and going up on the elevator, maybe add a "TAXI" state that is set while the drone is on them? couldn't find a way to check for that though
            elseif vehicle_dock_state == e_vehicle_dock_state.undocking then
            
                vehicle_state_string = "LNCH"
                vehicle_state_description = "Launching"
                vehicle_state_color = color_status_dark_green
            
            -- standby mode, "pending_undock" is active when the drone is rearming and refueling, or waiting inside the drone bay for the crane and elevator to be free
            elseif vehicle_dock_state == e_vehicle_dock_state.pending_undock then
            
                vehicle_state_string = "STBY"
                vehicle_state_description = "Waiting to Launch"
                vehicle_state_color = g_colors.carrier
            
            -- taxi
            elseif vehicle_dock_state == e_vehicle_dock_state.docking_taxi then
            
                vehicle_state_string = "TAXI"
                vehicle_state_description = "Taxiing to Launch"
                vehicle_state_color = color_grey_mid
                
            -- holding for launch
            elseif vehicle_dock_state == e_vehicle_dock_state.undock_holding then
                
                vehicle_state_string = "HOLD"
                vehicle_state_description = "Holding for Launch"
                vehicle_state_color = color_status_bad
                
            -- manual flight control mode
            elseif vehicle_manual_flight_control then
            
                vehicle_state_string = "HPLT"
                vehicle_state_description = "Human Piloted"
                vehicle_state_color = color_grey_dark
                
                if vehicle_peer_id ~= 0 then
                    local peer_index = update_get_peer_index_by_id(vehicle_peer_id)
                    vehicle_state_description = "Piloted by " .. update_get_peer_name(peer_index)
                end
            
            -- attack mode, the Petrel's airlift order is a type of attack, make sure to filter it
            elseif attack_target_type ~= e_attack_type.none then
            
                vehicle_state_string = "ATTK"
                vehicle_state_description = "Attacking Target"
                vehicle_state_color = color_status_warning
            
                if attack_target_type == e_attack_type.airlift then
                    vehicle_state_string = "LIFT"
                    vehicle_state_description = "Airlifting Target"
                    vehicle_state_color = color8(255, 100, 0, 255)
                end
            
            -- waypoint modes
            elseif waypoint_count > 0 then
            
                vehicle_state_string = "WYPT"
                vehicle_state_description = "Heading to Waypoint"
                vehicle_state_color = color_friendly
                
                local waypoint = vehicle:get_waypoint(0)
                
                local waypoint_dist = vec2_dist( vehicle:get_position_xz(), waypoint:get_position_xz() ) < iff( v.is_wing, 350, 20 )
                
                if waypoint:get_type() == e_waypoint_type.deploy then
                    vehicle_state_string = "DPLY"
                    vehicle_state_description = "Deploying Payload"
                    vehicle_state_color = color8(255, 100, 0, 255)
                elseif waypoint:get_type() == e_waypoint_type.dock then
                    vehicle_state_string = "RTRN"
                    vehicle_state_description = "Returning to Carrier"
                    vehicle_state_color = g_colors.dock_queue
                elseif waypoint:get_type() == e_waypoint_type.support then
                    vehicle_state_string = "SUPP"
                    vehicle_state_description = "Supporting Target"
                    vehicle_state_color = color_white
                elseif waypoint:get_is_wait_group(0) and waypoint_dist then
                    vehicle_state_string = "WG A"
                    vehicle_state_description = "Waiting for Alpha Go"
                    vehicle_state_color = color_status_warning
                elseif waypoint:get_is_wait_group(1) and waypoint_dist then
                    vehicle_state_string = "WG B"
                    vehicle_state_description = "Waiting for Bravo Go"
                    vehicle_state_color = color_status_warning
                elseif waypoint:get_is_wait_group(2) and waypoint_dist then
                    vehicle_state_string = "WG C"
                    vehicle_state_description = "Waiting for Charlie Go"
                    vehicle_state_color = color_status_warning
                elseif waypoint:get_is_wait_group(3) and waypoint_dist then
                    vehicle_state_string = "WG D"
                    vehicle_state_description = "Waiting for Delta Go"
                    vehicle_state_color = color_status_warning
                else
                    --iterate through the waypoints and see if they loop on themselves
                    for w = 0, waypoint_count - 1, 1 do
                        waypoint = vehicle:get_waypoint(w)
                        
                        if waypoint:get_repeat_index(w) >= 0 then
                            vehicle_state_string = "LOOP"
                            vehicle_state_description = "Following Waypoint Loop"
                            vehicle_state_color = color8(0, 30, 230, 255)
                            break
                        end
                    end
                end
            
            -- free and hover modes
            elseif waypoint_count <= 0 then
                
                -- drone behavior depends on drone type here. planes fly straight ahead, helis hover stationary
                if v.is_wing then
                    vehicle_state_string = "FREE"
                elseif v.is_rotor then
                    vehicle_state_string = "HOVR"
                else
                    vehicle_state_string = "IDLE"
                end
                vehicle_state_description = "Waiting for Tasking"
            end
            
            -- remote control tab
            local controlling_peer_string = iff( vehicle_peer_id ~= 0, atlas_icons.column_controlling_peer, " " )
            
            -- insert entry into table
            local is_action, selected_col, sx, sy, sw, sh = imgui_table_entry_grid(ui, {

                { w=column_widths[1], margin=column_margins[1], value=vehicle_state_string,     col=vehicle_state_color },
                { w=column_widths[2], margin=column_margins[2], value=vehicle_handle,           col=name_color },
                { w=column_widths[3], margin=column_margins[3], value=fuel_string,              col=fuel_col },
                { w=column_widths[4], margin=column_margins[4], value=damage_string,            col=damage_color },
                { w=column_widths[5], margin=column_margins[5], value=ammo_string,              col=ammo_color },
                { w=column_widths[6], margin=column_margins[6], value=controlling_peer_string,  col=color_friendly },
                
            })

            if ui:is_item_selected() and is_local then
                if selected_col >= 1 and selected_col <= 5 then
                    sx = sx + sw / 2

                    if g_is_mouse_mode and g_is_pointer_hovered then
                        sx = g_pointer_pos_x - iff(is_air, g_middle_boundry + 6, 6)
                    end
                
                    local text = vehicle_state_description
                    
                    if selected_col == 2 then
                        text = string.format("%s ID %d", full_name, id)
                    elseif selected_col == 3 then
                        text = string.format("Fuel")
                    elseif selected_col == 4 then
                        text = string.format("Health")
                    elseif selected_col == 5 then
                        text = string.format("Ammo")
                    end

                    tooltip = {
                        msg = text,
                        x = sx,
                        y = sy,
                        h = sh
                    }
                end

                g_hovered_vehicle_id = id
            end
        end

        if tooltip ~= nil then
            local text_w, text_h = update_ui_get_text_size(tooltip.msg, list_region_w - 10, 1)

            local function callback_render_tooltip(w, h)
                update_ui_text(2, 1, tooltip.msg, w - 2, 1, color_grey_mid, 0)
            end

            render_tooltip(0, 0, list_region_w - 5, list_region_h, tooltip.x, tooltip.y + tooltip.h / 2, text_w + 4, text_h + 2, tooltip.h / 2 + 4, callback_render_tooltip, color_button_bg_inactive)
        end

        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)
    else
        ui:spacer(3)
        update_ui_text(0, win_list.cy, "---", list_region_w, 1, color_grey_dark, 0)
    end
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

    local vehicle_icon, icon_offset = get_icon_data_by_definition_index(vehicle:get_definition_index())
    update_ui_image(p0x - icon_offset, p0z - icon_offset, vehicle_icon, col, 0)
end

--TODO: this is the unchanged vanilla icon render function for helis on the holding pattern, it has two bugs at the moment, maybe fix this or just remove the pattern render for more drone-list-entry space
-- 1) its relative range checks are not properly done at the moment so the icon will render at the wrong place or too early sometimes
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
        
        local vehicle_icon, icon_offset = get_icon_data_by_definition_index(vehicle:get_definition_index())
        update_ui_image(p0x - icon_offset, p0z - icon_offset, vehicle_icon, col, 0)
    end
end

function render_docking_vehicle_surface(vehicle_parent, vehicle)
    local final_arc = g_landing_pattern.final_arc
    local vehicle_dock_state = vehicle:get_dock_state()
    local relative_position = update_get_map_vehicle_position_relate_to_parent_vehicle(vehicle_parent:get_id(), vehicle:get_id())

    local p0x = relative_position:z() * -0.4
    local p0z = relative_position:x() * 0.4
    
    local col = iff(vehicle_dock_state == e_vehicle_dock_state.dock_queue, g_colors.dock_queue, g_colors.docking)

    if g_hovered_vehicle_id == vehicle:get_id() then
        col = color_white
    end
    
    local vehicle_icon, icon_offset = get_icon_data_by_definition_index(vehicle:get_definition_index())
    update_ui_image(p0x - icon_offset, p0z - icon_offset, vehicle_icon, col, 0)
end


--------------------------------------------------------------------------------
--
-- UTILITY FUNCTIONS
--
--------------------------------------------------------------------------------

--TODO: modded func of the Air Operations screen
function get_all_air_vehicles()
    local vehicle_list = {}

    local carrier_vehicle = update_get_screen_vehicle()
    local carrier_pos = carrier_vehicle:get_position_xz()

    local vehicle_count = update_get_map_vehicle_count()
    local screen_team = update_get_screen_team_id()
    
    for i = 0, vehicle_count - 1, 1 do 
        local vehicle = update_get_map_vehicle_by_index(i)

        if vehicle:get() and vehicle:get_team() == screen_team and vehicle:get_dock_state() ~= e_vehicle_dock_state.docked and vec2_dist( carrier_pos, vehicle:get_position_xz() ) <= 10000 then
            local def_index = vehicle:get_definition_index()
            if def_index == e_game_object_type.chassis_air_wing_light or def_index == e_game_object_type.chassis_air_wing_heavy then
                table.insert(vehicle_list, {
                    vehicle = vehicle,
                    is_wing = true,
                    is_rotor = false
                })
            elseif def_index == e_game_object_type.chassis_air_rotor_light or def_index == e_game_object_type.chassis_air_rotor_heavy then
                table.insert(vehicle_list, {
                    vehicle = vehicle,
                    is_wing = false,
                    is_rotor = true
                })
            end
        end
    end

    return vehicle_list
end

function get_all_surface_vehicles()
    local vehicle_list = {}

    local carrier_vehicle = update_get_screen_vehicle()
    local carrier_pos = carrier_vehicle:get_position_xz()

    local vehicle_count = update_get_map_vehicle_count()
    local screen_team = update_get_screen_team_id()
    
    for i = 0, vehicle_count - 1, 1 do 
        local vehicle = update_get_map_vehicle_by_index(i)

        if vehicle:get() and vehicle:get_team() == screen_team and vehicle:get_dock_state() ~= e_vehicle_dock_state.docked and vec2_dist( carrier_pos, vehicle:get_position_xz() ) <= 10000 then
            local def_index = vehicle:get_definition_index()
            if def_index == e_game_object_type.chassis_land_wheel_light
            or def_index == e_game_object_type.chassis_land_wheel_medium
            or def_index == e_game_object_type.chassis_land_wheel_heavy
            or def_index == e_game_object_type.chassis_land_wheel_mule
            then
                table.insert(vehicle_list, {
                    vehicle = vehicle,
                    is_wing = false,
                    is_rotor = false
                })
            end
        end
    end

    return vehicle_list
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
