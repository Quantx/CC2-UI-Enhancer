g_flight_deck_states = { 
    none = 0,
    taxi = 1,
    queued = 2,
    landing = 3,
    launch = 4,
    holding = 5,
}

g_flight_deck_color = {
    [g_flight_deck_states.none] = color_grey_dark,
    [g_flight_deck_states.taxi] = color_grey_mid,
    [g_flight_deck_states.queued] = color8(205, 8, 246, 255),
    [g_flight_deck_states.landing] = color8(205, 8, 8, 255),
    [g_flight_deck_states.launch] = color_status_dark_green,
    [g_flight_deck_states.holding] = color_status_bad
}

g_flight_deck_state = g_flight_deck_states.none
g_flight_deck_state_prev = g_flight_deck_states.none

function begin()
    begin_load()
end

function update(screen_w, screen_h, ticks)
    if update_screen_overrides(screen_w, screen_h, ticks) then return end

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

    -- carrier

    update_ui_image(22, 11, atlas_icons.screen_propulsion_carrier, color_grey_dark, 0)

    -- thrusters and props

    local cycle = math.floor(update_get_logic_tick() / 10) % 3
    
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

    local cy = 12
    local cx = 68
    local spacing = 4

    -- prop speed
    
    render_status_indicator_outline(cx, cy, 48, 12, string.format("%.0f", 8000 * rpm), color_white)
    cy = cy + 12 + spacing

    render_speed_gauge(cx, cy, math.pi * (1 + throttle_factor))
    cy = cy + 24 + spacing

    -- forward or reverse gear

    if is_engine_on == false then
        render_status_indicator(cx, cy, 48, 12, update_get_loc(e_loc.upp_engine), color_status_dark_red)
    elseif is_reverse then
        render_status_indicator(cx, cy, 48, 12, update_get_loc(e_loc.upp_reverse), color_status_dark_yellow)
    else
        render_status_indicator(cx, cy, 48, 12, update_get_loc(e_loc.upp_forward), color_status_dark_green)
    end
    cy = cy + 12 + spacing

    -- speed

    render_status_indicator_outline(cx, cy, 48, 24, string.format("%.0f\n", speed) .. update_get_loc(e_loc.upp_knots), color_white)
    cy = cy + 24 + spacing

    -- docking/undocking status

    g_flight_deck_state = 0

    if this_vehicle:get() then
        render_docking_queue_info(22, 11, this_vehicle)
    end
    
    local flight_deck_str = {
        [g_flight_deck_states.none] = "---",
        [g_flight_deck_states.taxi] = update_get_loc(e_loc.upp_air_traffic_taxi),
        [g_flight_deck_states.queued] = update_get_loc(e_loc.upp_air_traffic_queued),
        [g_flight_deck_states.landing] = update_get_loc(e_loc.upp_air_traffic_landing),
        [g_flight_deck_states.launch] = update_get_loc(e_loc.upp_air_traffic_launch),
        [g_flight_deck_states.holding] = update_get_loc(e_loc.upp_air_traffic_holding)
    }

    if g_flight_deck_state == g_flight_deck_states.landing or g_flight_deck_state == g_flight_deck_states.launch then
        render_status_indicator(cx, cy, 48, 12, flight_deck_str[g_flight_deck_state], g_flight_deck_color[g_flight_deck_state])
    elseif g_flight_deck_state > g_flight_deck_states.none then
        render_status_indicator(cx, cy, 48, 12, flight_deck_str[g_flight_deck_state], g_flight_deck_color[g_flight_deck_state])
    else
        render_status_indicator_outline(cx, cy, 48, 12, flight_deck_str[g_flight_deck_state], g_flight_deck_color[g_flight_deck_state])
    end

    if g_flight_deck_state_prev ~= g_flight_deck_state and g_flight_deck_state > g_flight_deck_states.none then
        update_play_sound(e_audio_effect_type.telemetry_3)
    end

    g_flight_deck_state_prev = g_flight_deck_state
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

function render_speed_gauge(x, y, angle)
    update_ui_push_offset(x, y)
    update_ui_image(0, 0, atlas_icons.screen_propulsion_gauge, color_white, 0)
    
    local ax, ay = arc_position(24, 23, 20, angle)
    update_ui_line(24, 23, ax, ay, color_white)
    update_ui_pop_offset()
end

function render_status_indicator(x, y, w, h, text, col)
    update_ui_push_offset(x, y)
    update_ui_rectangle(0, 0, w, h, col)
    update_ui_text(0, h / 2 - 4, text, w, 1, color_black, 0)
    update_ui_pop_offset()
end

function render_status_indicator_outline(x, y, w, h, text, col)
    local text_w, text_h = update_ui_get_text_size(text, w, 1)

    update_ui_push_offset(x, y)
    update_ui_rectangle_outline(0, 0, w, h, col)
    update_ui_text(0, (h - text_h) / 2 + 1, text, w, 1, col, 0)
    update_ui_pop_offset()
end

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

function render_docking_queue_info(x, y, this_vehicle)
    update_ui_push_offset(x, y)
    update_ui_push_offset(16, 52)

    local vehicle_count = update_get_map_vehicle_count()
    local screen_team = update_get_screen_team_id()
    g_flight_deck_state = 0

    for i = 0, vehicle_count - 1, 1 do
        local vehicle = update_get_map_vehicle_by_index(i)
        
        if vehicle:get() then
            local def = vehicle:get_definition_index()

            if vehicle:get_team() == screen_team and get_is_vehicle_air(def) then
                local is_rotor = (def == e_game_object_type.chassis_air_rotor_light or def == e_game_object_type.chassis_air_rotor_heavy)
                local dock_state = vehicle:get_dock_state()
                local deck_state = g_flight_deck_states.none
                local is_within_carrier_bounds = get_is_within_carrier_bounds(this_vehicle, vehicle)

                if dock_state == e_vehicle_dock_state.undocking then
                    deck_state = g_flight_deck_states.launch
                elseif dock_state == e_vehicle_dock_state.undock_holding then
                    deck_state = g_flight_deck_states.holding
                elseif dock_state == e_vehicle_dock_state.docking then
                    deck_state = g_flight_deck_states.landing
                elseif dock_state == e_vehicle_dock_state.docking_taxi then
                    deck_state = g_flight_deck_states.taxi
                elseif dock_state == e_vehicle_dock_state.dock_queue then
                    deck_state = g_flight_deck_states.queued
                end

                if deck_state > g_flight_deck_states.none then
                    local pos_rel = update_get_map_vehicle_position_relate_to_parent_vehicle(this_vehicle:get_id(), vehicle:get_id())
                    local pos_x = pos_rel:x() * 0.5
                    local pos_y = pos_rel:z() * -0.5
                    local is_blink_on = update_get_logic_tick() % 20 > 10

                    if deck_state == g_flight_deck_states.queued or (is_within_carrier_bounds == false and deck_state == g_flight_deck_states.landing) then
                        if is_blink_on and deck_state >= g_flight_deck_state then
                            update_ui_image(-5, 40, atlas_icons.text_back, g_flight_deck_color[deck_state], 3)
                        end
                    else
                        local carrier_dir = this_vehicle:get_direction()
                        local carrier_ang = math.atan(carrier_dir:y(), carrier_dir:x())
                        local vehicle_dir = vehicle:get_direction()
                        local vehicle_ang = math.atan(vehicle_dir:y(), vehicle_dir:x())
                    
                        local _, vehicle_icon = get_chassis_data_by_definition_index(def)
                        local col = mult_alpha(g_flight_deck_color[deck_state], iff(pos_rel:y() > 16, 1, 0.25))

                        if deck_state ~= g_flight_deck_states.holding or is_blink_on then
                            update_ui_image_rot(pos_x, pos_y, vehicle_icon, col, round_to(-(vehicle_ang - carrier_ang), math.pi / 8))
                        end
                    end
                    
                    g_flight_deck_state = math.max(deck_state, g_flight_deck_state)
                end
            end
        end
    end

    update_ui_pop_offset()
    update_ui_pop_offset()
end

function round_to(a, b)
    return math.floor(a / b + 0.5) * b
end

function get_is_within_carrier_bounds(this_vehicle, vehicle)
    local pos_rel = update_get_map_vehicle_position_relate_to_parent_vehicle(this_vehicle:get_id(), vehicle:get_id())
    local pos_x = pos_rel:x() * 0.5
    local pos_y = pos_rel:z() * -0.5
    return point_in_rect(-20, -54, 40, 120, pos_x, pos_y)
end