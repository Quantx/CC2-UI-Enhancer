g_tick = 0

g_radius = 56
g_scan_increment_count = 64
g_scan_layer_count = 4
g_layer_colors = { 
    color8(255, 0, 0, 255), 
    color8(255, 255, 0, 255), 
    color8(0, 255, 0, 255), 
    color8(0, 0, 255, 255),
}
g_max_scan_distance = 400
g_depth_data = {}
g_scan_cursor = 1

g_is_mute = false

function arc_position(x, y, radius, angle)
    return (x + (radius * math.cos(angle - (math.pi * 0.5)))), (y + (radius * math.sin(angle - (math.pi * 0.5))))
end

function parse()
    -- End of original parse calls
    g_is_mute = parse_bool("is_mute", g_is_mute)
end

function begin()
    begin_load()

    g_depth_data = {}
    g_scan_cursor = 1

    for i=1, g_scan_layer_count do
        g_depth_data[i] = {}

        for j=1, g_scan_increment_count do
            local scan_angle = math.pi * 2 * (j - 1) / g_scan_increment_count
            local ax, ay = arc_position(64, 64, g_radius, scan_angle)
            g_depth_data[i][j] = 
            {
                depth = g_max_scan_distance,
                nx = ax,
                ny = ay,
                fx = ax,
                fy = ay,
            }
        end
    end
end

function update(screen_w, screen_h, ticks) 
    g_tick = g_tick + ticks

    g_scan_cursor = g_scan_cursor + ticks
    local scan_angle = math.pi * 2 * (g_scan_cursor - 1) / g_scan_increment_count

    if g_scan_cursor > g_scan_increment_count then
        g_scan_cursor = 1
    end

    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    update_add_ui_interaction(iff( g_is_mute, "unmute", "mute"), e_game_input.interact_a)

    local this_vehicle = update_get_screen_vehicle()
    if this_vehicle:get() then
        local this_vehicle_object = update_get_vehicle_by_id(this_vehicle:get_id())
        if this_vehicle_object:get() then
            if this_vehicle_object:get_sensor_count() > 0 then
                for i=1, g_scan_layer_count do
                    g_depth_data[i][g_scan_cursor].depth = math.min(g_max_scan_distance, this_vehicle_object:get_carrier_raycast(scan_angle, -0.02 * i))
                    local nx, ny = arc_position(64, 64, g_depth_data[i][g_scan_cursor].depth * (g_radius - 1) / g_max_scan_distance, scan_angle)
                    g_depth_data[i][g_scan_cursor].nx = nx
                    g_depth_data[i][g_scan_cursor].ny = ny
                end
            end
        end
    end
    
    local min_distance = g_max_scan_distance
    for j=1, g_scan_increment_count do
        min_distance = math.min(min_distance, g_depth_data[g_scan_layer_count][j].depth)
    end

    for i=g_scan_layer_count, 1, -1 do
        update_ui_begin_triangles()
        for j=1, g_scan_increment_count do
            local cursor_next = (j + ticks)
            if cursor_next > g_scan_increment_count then
                cursor_next = 1
            end

            local v0 = vec2(g_depth_data[i][j].nx, g_depth_data[i][j].ny)
            local v1 = vec2(g_depth_data[i][j].fx, g_depth_data[i][j].fy)
            local v2 = vec2(g_depth_data[i][cursor_next].fx, g_depth_data[i][cursor_next].fy)
            local v3 = vec2(g_depth_data[i][cursor_next].nx, g_depth_data[i][cursor_next].ny)

            update_ui_add_triangle(v0, v1, v2, g_layer_colors[i])
            update_ui_add_triangle(v2, v3, v0, g_layer_colors[i])
        end
        update_ui_end_triangles()
    end

    local ax, ay = arc_position(64, 64, g_radius, scan_angle)
    update_ui_line(64, 64, ax, ay, color_white)

    local mx = 14
    local my = 14

    update_ui_image_rot(mx, my, atlas_icons.hud_audio, color_white, 0)
    if g_is_mute then
        local ms = 7
    
        update_ui_line(mx - ms, my - ms, mx + ms, my + ms, color8(255, 0, 0, 255))
        update_ui_line(mx - ms, my + ms, mx + ms, my - ms, color8(255, 0, 0, 255))
    end

    local warning_blink_rate = iff(min_distance < 50, 10, 30)
    local is_pulse_warning = g_tick % warning_blink_rate == math.floor(warning_blink_rate / 2)
    local is_blink_warning = g_tick % warning_blink_rate > math.floor(warning_blink_rate / 2)

    local warning_sound = e_audio_effect_type.telemetry_5

    if min_distance < 50 then
        if is_blink_warning then
            update_ui_rectangle(11, 105, 106, 14, color_status_bad)
            update_ui_text(0, 108, update_get_loc(e_loc.upp_collision), 128, 1, color_black, 0)
        end

        if is_pulse_warning and not g_is_mute then
            update_play_sound(warning_sound)
        end
    elseif min_distance < 100 then
        if is_blink_warning then
            update_ui_rectangle(11, 105, 106, 14, color_status_warning)
            update_ui_text(0, 108, update_get_loc(e_loc.upp_warning), 128, 1, color_black, 0)
        end

        if is_pulse_warning and not g_is_mute then
            update_play_sound(warning_sound)
        end
    end
end

function input_event(event, action)
    if action == e_input_action.release then
        if event == e_input.back then
            update_set_screen_state_exit()
        elseif event == e_input.action_a or event == e_input.pointer_1 then
            g_is_mute = not g_is_mute
        end
    end
end

function input_axis(x, y, z, w)
end
