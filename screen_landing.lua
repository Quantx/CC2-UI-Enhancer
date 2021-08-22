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
g_hovered_lmr = 1

g_is_hovered = false
g_pointer_pos_x = 0
g_pointer_pos_y = 0

function begin()
    begin_load()
    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    local ui = g_ui

	local is_local = update_get_is_focus_local()
    local this_vehicle = update_get_screen_vehicle()

	if not (is_local and g_is_hovered) then g_hovered_lmr = 1 end
    g_hovered_vehicle_id = 0

	local title = ""
	
	if g_hovered_lmr ~= 2 then title = title .. "SURFACE TRAFFIC" end
	if g_hovered_lmr == 1 then title = title .. "       " end
	if g_hovered_lmr ~= 0 then title = title .. update_get_loc(e_loc.upp_air_traffic) end

    ui:begin_ui()

    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)

    ui:begin_window(title, 5, 5, screen_w - 10, screen_h - 10, atlas_icons.column_controlling_peer, false, 0, true, true)
        local region_w, region_h = ui:get_region()
        local left_w = 125
        local right_w = region_w - left_w

	    if is_local and g_is_hovered then
	    	g_hovered_lmr = iff( g_pointer_pos_x < right_w, 0, 2 )
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
        		update_ui_push_offset(right_w + (left_w - 100) / 2, region_h - 22)
				update_ui_rectangle_outline(0, 0, 100, 16, color_grey_dark)
				update_ui_text(0, 4, "DOCKING QUEUE", 100, 1, color_grey_dark, 0)
				update_ui_pop_offset()

				update_ui_push_offset(right_w + 20, region_h / 2 - 8)
			    update_ui_image( -13, -7, atlas_icons.holomap_icon_carrier, g_colors.carrier, 3)
			
				local vehicle_list = get_all_surface_vehicles()
		        for _, v in pairs(vehicle_list) do
		            --prevents the drones that are not in the holding or landing pattern to show up on the left side of the screen
		            local vehicle = v.vehicle
		            local vehicle_dock_state = vehicle:get_dock_state()

		            if vehicle_dock_state == e_vehicle_dock_state.dock_queue or vehicle_dock_state == e_vehicle_dock_state.docking then
		            	render_docking_vehicle_surface(this_vehicle, v.vehicle, -(right_w + 20) + (left_w - 1))
					end
		        end
		        
                update_ui_pop_offset()
			elseif g_hovered_lmr == 2 then
				update_ui_push_offset((left_w - 100) / 2, region_h - 22)
				update_ui_rectangle_outline(0, 0, 100, 16, color_grey_dark)
				update_ui_text(0, 4, update_get_loc(e_loc.upp_holding_pattern), 100, 1, color_grey_dark, 0)
				update_ui_pop_offset()

				update_ui_push_offset(left_w / 2, region_h / 2 - 8)
				render_landing_pattern()
			
				local vehicle_list = get_all_air_vehicles()
		        for _, v in pairs(vehicle_list) do
		            --prevents the drones that are not in the holding or landing pattern to show up on the left side of the screen
		            local vehicle = v.vehicle
		            local vehicle_dock_state = vehicle:get_dock_state()

		            if vehicle_dock_state == e_vehicle_dock_state.dock_queue or vehicle_dock_state == e_vehicle_dock_state.docking then
				        if v.is_wing then
				            render_docking_vehicle_wing( this_vehicle, v.vehicle, -(left_w / 2) + (left_w - 1))
				        elseif v.is_rotor then
				            render_docking_vehicle_rotor(this_vehicle, v.vehicle, -(left_w / 2) + (left_w - 1))
				        end
					end
		        end
		        
                update_ui_pop_offset()
            end
        end

        update_ui_rectangle(left_w - 1, 0, 1, region_h, color_white)
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
    
    g_is_hovered = is_hovered
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

	local list_region_w, list_region_h = ui:get_region()

	local act_w	 = update_ui_get_text_size("AAAA", 10000, 0) + 4
	local name_w = update_ui_get_text_size("AAA",  10000, 0) + 4
	local num_w  = update_ui_get_text_size("00",   10000, 0) + 4
	
	local column_widths = { act_w, name_w, num_w, num_w, num_w, -1 }
	local column_margins = { 3, 3, 3, 3, 3, 3 }

	imgui_table_header(ui, {
	    { w=column_widths[1], margin=column_margins[1], value=atlas_icons.column_transit },
	    { w=column_widths[2], margin=column_margins[2], value=atlas_icons.column_stock },
	    { w=column_widths[3], margin=column_margins[3], value=atlas_icons.column_fuel },
	    { w=column_widths[4], margin=column_margins[4], value=atlas_icons.column_repair },
	    { w=column_widths[5], margin=column_margins[5], value=atlas_icons.column_ammo },
	    { w=column_widths[6], margin=column_margins[6], value=atlas_icons.column_controlling_peer }
	})

	local vehicle_list = iff( is_air, get_all_air_vehicles(), get_all_surface_vehicles() )

	if #vehicle_list > 0 then
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
	        local damage_string = iff( damage_factor < 1, string.format("%.0f", damage_factor * 100), "" )
	        
			-- ammo tab
			local ammo_factor = clamp(vehicle:get_ammo_factor(), 0, 1)
	        local ammo_color = iff(ammo_factor < 0.25, color_status_bad, iff(ammo_factor < 0.5, color_status_warning, color_status_ok))
	        local ammo_string = iff( ammo_factor < 1, string.format("%.0f", ammo_factor * 100), "" )
	        
	        -- drone name tab, this has to be after fuel and damage because it takes those into account
	        local full_name, vehicle_icon, vehicle_handle = get_chassis_data_by_definition_index(vehicle:get_definition_index())
	        local name_color = color_status_ok
	        
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
	        
	        -- drone mode tab, set the list entry string and color
	        local vehicle_state_string = "????"
	        local vehicle_state_color = color_white
	        
	        --TODO: incoming damage alert mode, this status is quite short lived, maybe replace it with something else
	        if damage_indicator_factor > 0 then
	        
	            vehicle_state_string = "DAMG"
	            vehicle_state_color = color_status_bad
	        
	        --TODO: plane landing mode. helis don't get the "docking" aka landing state even though the final approach is not cancelable
	        --TODO: had to add the landing check for helis here, because they are in the dock_queue state all the way down to the runway.
	        elseif vehicle_dock_state == e_vehicle_dock_state.docking or (v.is_rotor and rotor_landed_carrier(vehicle)) then
	        
	        	if is_air then
		            vehicle_state_string = "LAND"
		            vehicle_state_color = g_colors.docking
		            
		            if vehicle:get_attached_parent_id() ~= 0 then
			            vehicle_state_string = "PARK"
			            vehicle_state_color = color_status_dark_red
			        end
		        else
			        vehicle_state_string = "DOCK"
		            vehicle_state_color = g_colors.dockings
		        end
	        
	        -- holding mode and helicopter landing mode
	        elseif vehicle_dock_state == e_vehicle_dock_state.dock_queue then
	            
	            vehicle_state_string = "HOLD"
	            vehicle_state_color = g_colors.dock_queue
	 
	        --TODO: launch mode. "undocking" is also active when the drone is on the crane and going up on the elevator, maybe add a "TAXI" state that is set while the drone is on them? couldn't find a way to check for that though
	        elseif vehicle_dock_state == e_vehicle_dock_state.undocking then
	        
	            vehicle_state_string = "LNCH"
	            vehicle_state_color = color_status_dark_green
	        
	        -- standby mode, "pending_undock" is active when the drone is rearming and refueling, or waiting inside the drone bay for the crane and elevator to be free
	        elseif vehicle_dock_state == e_vehicle_dock_state.pending_undock then
	        
	            vehicle_state_string = "STBY"
	            vehicle_state_color = g_colors.carrier
	        
	        -- manual flight control mode
	        elseif vehicle_manual_flight_control then
	        
	            vehicle_state_string = "HPLT"
	            vehicle_state_color = color_grey_dark
	        
	        -- attack mode, the Petrel's airlift order is a type of attack, make sure to filter it
	        elseif attack_target_type ~= e_attack_type.none then
	        
	            vehicle_state_string = "ATTK"
	            vehicle_state_color = color_status_warning
	        
	        	if attack_target_type == e_attack_type.airlift then
	        		vehicle_state_string = "LIFT"
	            	vehicle_state_color = color8(255, 100, 0, 255)
	        	end
	        
	        -- waypoint modes
	        elseif waypoint_count > 0 then
	        
	            vehicle_state_string = "WYPT"
	            vehicle_state_color = color_friendly
	            
	            local waypoint = vehicle:get_waypoint(0)
    	        
    	        local waypoint_dist = vec2_dist( vehicle:get_position_xz(), waypoint:get_position_xz() ) < iff( v.is_wing, 350, 20 )
    	        
    	        if waypoint:get_type() == e_waypoint_type.deploy then
					vehicle_state_string = "DPLY"
					vehicle_state_color = color8(255, 100, 0, 255)
				elseif waypoint:get_is_wait_group(0) and waypoint_dist then
					vehicle_state_string = "WG A"
			        vehicle_state_color = color_status_warning
				elseif waypoint:get_is_wait_group(1) and waypoint_dist then
					vehicle_state_string = "WG B"
			        vehicle_state_color = color_status_warning
				elseif waypoint:get_is_wait_group(2) and waypoint_dist then
					vehicle_state_string = "WG C"
			        vehicle_state_color = color_status_warning
				elseif waypoint:get_is_wait_group(3) and waypoint_dist then
					vehicle_state_string = "WG D"
			        vehicle_state_color = color_status_warning
	            else
			        --iterate through the waypoints and see if they loop on themselves
			        for w = 0, waypoint_count - 1, 1 do
			            waypoint = vehicle:get_waypoint(w)
			            
			            if waypoint:get_repeat_index(w) >= 0 then
			                vehicle_state_string = "LOOP"
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
	        end
	        
	        -- remote control tab
	        local controlling_peer_string = iff( vehicle:get_controlling_peer_id() ~= 0, atlas_icons.column_controlling_peer, " " )
	        
	        -- insert entry into table
	        imgui_table_entry(ui, {

	            { w=column_widths[1], margin=column_margins[1], value=vehicle_state_string,		col=vehicle_state_color },
	            { w=column_widths[2], margin=column_margins[2], value=vehicle_handle,			col=name_color },
	            { w=column_widths[3], margin=column_margins[3], value=fuel_string,				col=fuel_col },
	            { w=column_widths[4], margin=column_margins[4], value=damage_string,			col=damage_color },
	            { w=column_widths[5], margin=column_margins[5], value=ammo_string,				col=ammo_color },
	            { w=column_widths[6], margin=column_margins[6], value=controlling_peer_string,	col=color_friendly },
	            
	        }, false)

	        if ui:is_item_selected() and update_get_is_focus_local() then
	            g_hovered_vehicle_id = id
	        end
	    end
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

function render_docking_vehicle_wing(vehicle_parent, vehicle, right_bound)
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

    if p0x + 3 < right_bound then
	    update_ui_image(p0x - 3, p0z - 3, atlas_icons.map_icon_air, col, 0)
	end
end

--TODO: this is the unchanged vanilla icon render function for helis on the holding pattern, it has two bugs at the moment, maybe fix this or just remove the pattern render for more drone-list-entry space
-- 1) its relative range checks are not properly done at the moment so the icon will render at the wrong place or too early sometimes
function render_docking_vehicle_rotor(vehicle_parent, vehicle, right_bound)
    local final_arc = g_landing_pattern.final_arc
    local vehicle_dock_state = vehicle:get_dock_state()
    local relative_position = update_get_map_vehicle_position_relate_to_parent_vehicle(vehicle_parent:get_id(), vehicle:get_id())

	local p0x = -((relative_position:z() + 120) * 0.14)
    local p0z = -final_arc + math.min(p0x - 10, final_arc)

    if relative_position:z() < -120 then
        local col = iff(rotor_landed_carrier(vehicle), g_colors.docking, g_colors.dock_queue)

        if g_hovered_vehicle_id == vehicle:get_id() then
            col = color_white
        end
        
        if p0x + 3 < right_bound then
			update_ui_image(p0x - 3, p0z - 3, atlas_icons.map_icon_air, col, 0)
		end
    end
end

function render_docking_vehicle_surface(vehicle_parent, vehicle, left_bound)
    local final_arc = g_landing_pattern.final_arc
    local vehicle_dock_state = vehicle:get_dock_state()
    local relative_position = update_get_map_vehicle_position_relate_to_parent_vehicle(vehicle_parent:get_id(), vehicle:get_id())

    local p0x = relative_position:z() * -0.4
    local p0z = relative_position:x() * 0.4
    
    local col = iff(vehicle_dock_state == e_vehicle_dock_state.dock_queue, g_colors.dock_queue, g_colors.docking)

    if g_hovered_vehicle_id == vehicle:get_id() then
        col = color_white
    end
        
    if p0x - 3 > left_bound then
		update_ui_image(p0x - 3, p0z - 3, atlas_icons.map_icon_air, col, 0)
	end
end


--------------------------------------------------------------------------------
--
-- UTILITY FUNCTIONS
--
--------------------------------------------------------------------------------

--TODO: modded func of the Air Operations screen
function get_all_air_vehicles()
    local vehicle_list = {}

    local vehicle_count = update_get_map_vehicle_count()
    local screen_team = update_get_screen_team_id()
    
    for i = 0, vehicle_count - 1, 1 do 
        local vehicle = update_get_map_vehicle_by_index(i)

        if vehicle:get() and vehicle:get_team() == screen_team and vehicle:get_dock_state() ~= e_vehicle_dock_state.docked then
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

    local vehicle_count = update_get_map_vehicle_count()
    local screen_team = update_get_screen_team_id()
    
    for i = 0, vehicle_count - 1, 1 do 
        local vehicle = update_get_map_vehicle_by_index(i)

        if vehicle:get() and vehicle:get_team() == screen_team and vehicle:get_dock_state() ~= e_vehicle_dock_state.docked then
            local def_index = vehicle:get_definition_index()
            if def_index == e_game_object_type.chassis_land_wheel_light or def_index == e_game_object_type.chassis_land_wheel_medium or def_index == e_game_object_type.chassis_land_wheel_heavy then
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

-- This basically checks if the heli is inside a 3D box behind the carrier's runway
function rotor_landed_carrier(vehicle)
	local vehicle_parent = update_get_screen_vehicle()
	local relative_position = update_get_map_vehicle_position_relate_to_parent_vehicle(vehicle_parent:get_id(), vehicle:get_id())
	local relative_position_z = relative_position:z()
	local relative_position_x = relative_position:x()
	local relative_position_y = relative_position:y()

    --TODO: rough 3D box size of the heli landing slope
    return relative_position_z > -230 and relative_position_z < 20 and relative_position_x > -100 and relative_position_x < 15 and relative_position_y < 150
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
