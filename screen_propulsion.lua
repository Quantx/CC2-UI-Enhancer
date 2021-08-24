g_tick = 0
g_flight_deck_last = 0

g_flight_deck_str = {
	"PARKED",
	"QUEUED",
	"LANDING",
	"LAUNCH"
}
g_flight_deck_color = {
	color_status_dark_red,
	color8(205, 8, 246, 255),
	color8(205, 8, 8, 255),
	color_status_dark_green
}

function arc_position(x, y, radius, angle)
    return (x + (radius * math.cos(angle))), (y + (radius * math.sin(angle)))
end

function line_arc(x, y, radius, start_angle, end_angle, segment_count, color)
    for i=0, segment_count - 1, 1 do
        local p0x, p0y = arc_position(x, y, radius, lerp(start_angle, end_angle, i / segment_count))
        local p1x, p1y = arc_position(x, y, radius, lerp(start_angle, end_angle, (i + 1) / segment_count))
        update_ui_line(p0x, p0y, p1x, p1y, color)
    end
end

function render_thruster(x, y, is_right, is_thrust, cycle)
    update_ui_rectangle(x, y, 2, 6, color_white)
    
    if is_thrust then
        if is_right then
            for i = 0, 2 do
                local offset = 2 + cycle + (i * 3)
                local color_value = 255 - math.floor(255 * offset / 10)
                update_ui_rectangle(x + offset, y, 1, 6, color8(color_value, color_value, color_value, 255))
            end
        else
            for i = 0, 2 do
                local offset = -1 - cycle - (i * 3)
                local color_value = 255 - math.floor(255 * -offset / 10)
                update_ui_rectangle(x + offset, y, 1, 6, color8(color_value, color_value, color_value, 255))
            end
        end
    end
end

function render_prop(x, y, cycle)
    for i = 0, 2 do
        local offset = cycle + (i * 3)
        local color_value = 255 - math.floor(255 * offset / 8)
        update_ui_rectangle(x, y + offset, 8, 1, color8(color_value, color_value, color_value, 255))
    end
end

function begin()
    begin_load()
end

function update(screen_w, screen_h, ticks) 
    g_tick = g_tick + 1

    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    local throttle_factor = 0
    local steering = 0
    local side_thrust = 0
    local is_reverse = false
    local is_side_thruster = false
    local speed = 0
    local is_engine_on = false

    local this_vehicle = update_get_screen_vehicle()
    if this_vehicle:get() then
        local this_vehicle_object = update_get_vehicle_by_id(this_vehicle:get_id())
        if this_vehicle_object:get() then
            is_reverse = this_vehicle_object:get_carrier_is_reverse()
            is_side_thruster = this_vehicle_object:get_carrier_is_side_thruster()
            speed = this_vehicle_object:get_velocity_magnitude() * 1.94
            local control_factors = this_vehicle_object:get_carrier_control_factors()
            is_engine_on = this_vehicle_object:get_carrier_is_engine_on()
            throttle_factor = control_factors:y()
            steering = control_factors:x()
            side_thrust = control_factors:x()
            rpm = control_factors:w()
        end
    end

    if is_engine_on == false then
        throttle_factor = 0
    end

    -- background

    update_ui_image(0, 0, atlas_icons.screen_propulsion, color_white, 0)

    -- thrusters and props

    local cycle = math.floor(g_tick / 10) % 3
    
    if is_side_thruster then
        render_thruster(54, 48, true, side_thrust < -0.01, cycle)
        render_thruster(54, 88, true, side_thrust < -0.01, cycle)
        render_thruster(19, 48, false, side_thrust > 0.01, cycle)
        render_thruster(19, 88, false, side_thrust > 0.01, cycle)
    else
        if steering > 0.01 then
            render_thruster(54, 88, true, true, cycle)
            render_thruster(19, 48, false, true, cycle)
        elseif steering < -0.01 then
            render_thruster(54, 48, true, true, cycle)
            render_thruster(19, 88, false, true, cycle)
        end
    end

    if throttle_factor > 0.01 then
        render_prop(25, 111, cycle)
        render_prop(42, 111, cycle)
    end

    -- prop speed
    
    update_ui_rectangle(68, 12, 48, 12, color_white)
    update_ui_rectangle(69, 13, 46, 10, color_black)
    update_ui_text(28, 14, string.format("%.0f", 8000 * rpm), 128, 1, color_white, 0)

    local ax, ay = arc_position(92, 52, 20, math.pi * (1 + throttle_factor))
    update_ui_line(92, 52, ax, ay, color_white)
    
    -- forward or reverse gear

	if is_engine_on == false then
		update_ui_rectangle(68, 56, 48, 12, color_status_dark_red)
		update_ui_text(28, 58, update_get_loc(e_loc.upp_engine), 128, 1, color_black, 0)
	else
		update_ui_rectangle(68, 56, 48, 12, color_white)
		if is_reverse then
		    update_ui_text(28, 58, update_get_loc(e_loc.upp_reverse), 128, 1, color_black, 0)
		else
		    update_ui_text(28, 58, update_get_loc(e_loc.upp_forward), 128, 1, color_black, 0)
		end
	end

    -- speed

    update_ui_rectangle(68, 72, 48, 22, color_white)
    update_ui_rectangle(69, 73, 46, 20, color_black)
    update_ui_text(28, 73, string.format("%.0f", speed), 128, 1, color_white, 0)
    update_ui_text(28, 83, update_get_loc(e_loc.upp_knots), 128, 1, color_white, 0)
    
    -- render vehicles
    
    local flight_deck = 0
    
    local vehicle_count = update_get_map_vehicle_count()
    local screen_team = update_get_screen_team_id()
    
    update_ui_push_offset(37, 64) -- Center of carrier image
    
    for i = 0, vehicle_count - 1, 1 do
        local vehicle = update_get_map_vehicle_by_index(i)
        
        if vehicle:get() then
	        local def = vehicle:get_definition_index()

		    if vehicle:get_team() == screen_team and get_is_vehicle_air(def) then
		    	local is_rotor = (def == e_game_object_type.chassis_air_rotor_light or def == e_game_object_type.chassis_air_rotor_heavy)
		    
		    	local dock_state = vehicle:get_dock_state()

				local deck = 0

		    	if dock_state == e_vehicle_dock_state.undocking then
					deck = 4
		    	elseif dock_state == e_vehicle_dock_state.docking or (is_rotor and dock_state == e_vehicle_dock_state.dock_queue and rotor_landed_carrier(vehicle)) then
					deck = iff( vehicle:get_attached_parent_id() == 0, 3, 1 )
		    	elseif dock_state == e_vehicle_dock_state.dock_queue then
					deck = 2
		    	end
		    	
		    	if deck > 0 then
		    		local pos_rel = update_get_map_vehicle_position_relate_to_parent_vehicle(this_vehicle:get_id(), vehicle:get_id())
		    	
					local pos_x = pos_rel:x() *  0.5
				    local pos_y = pos_rel:z() * -0.5

					if pos_x + 4 <= 64 and pos_rel:y() > 16 then
						local carrier_dir = this_vehicle:get_direction()
						local carrier_ang = math.atan( carrier_dir:y(), carrier_dir:x() )
						local vehicle_dir = vehicle:get_direction()
						local vehicle_ang = math.atan( vehicle_dir:y(), vehicle_dir:x() )
					
			    		local vehicle_name, vehicle_icon, vehicle_abb = get_chassis_data_by_definition_index(def)
						update_ui_image_rot(pos_x, pos_y, vehicle_icon, g_flight_deck_color[deck], -(vehicle_ang - carrier_ang))
					end
		    	
		    		flight_deck = math.max( flight_deck, deck )
		    	end
		    end
		end
	end
	
	update_ui_pop_offset()

	if flight_deck > 0 then
		update_ui_rectangle(68, 98, 48, 12, g_flight_deck_color[flight_deck])
	    update_ui_text(28, 100, g_flight_deck_str[flight_deck], 128, 1, color_black, 0)
	    
	    if g_flight_deck_last == 0 then
	    	update_play_sound(e_audio_effect_type.telemetry_3)
	    end
	end
	
	g_flight_deck_last = flight_deck
end

function input_event(event, action)
    if action == e_input_action.release then
        if event == e_input.back then
            update_set_screen_state_exit()
        end
    end
end

function input_axis(x, y, z, w)
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
