g_launch_factor = 0
g_launch_time = 0
g_animation_time = 0

g_ui = nil

function begin()
    begin_load()
    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    local ui = g_ui
    ui:begin_ui()

    g_animation_time = g_animation_time + ticks

    local function get_timing_factor(timing_pair)
        return invlerp_clamp(g_launch_time, timing_pair[1], timing_pair[2])
    end
    
    local function get_timing_active(timing_pair)
        return g_launch_time >= timing_pair[1] and g_launch_time < timing_pair[2]
    end

    local function get_timing_complete(timing_pair)
        return g_launch_time > timing_pair[2]
    end

    -- test_sequence()

    local timing_begin = { 0, 0.1 }
    local timing_launch = { 7.6, 9 }
    local timing_launch_end = { 8.5, 9 }
    local timing_burn = { 8, 20 }
    local timing_reach_atmosphere = { 9, 21 }
    local timing_cross_atmosphere = { 21, 28 }
    local timing_reach_dock = { 28, 35 }
    local timing_freefall = { 28, 35 }
    local timing_parachute = { 36, 40 }
    local timing_impact = { 36, 40 }
    local timing_travel = { 9, 38 }

    local win_spacing = 2
    local win_border = 10
    local win_right_w = 40
    local win_left_w = screen_w - win_right_w - 2 * win_border - win_spacing
    local win_top_h = 68
    local win_bot_h = screen_h - win_top_h - 2 * win_border - win_spacing

    local shield_factor = math.max((math.cos(get_timing_factor(timing_cross_atmosphere) ^ 2 * math.pi * 1.1) * 0.5 + 0.5) * 0.8 + 0.2, lerp(0, 1,  get_timing_factor(timing_reach_dock)))
    local fuel_factor = 1 - get_timing_factor(timing_burn) ^ 0.5
    local window_col = iff(get_timing_complete(timing_begin), color_white, color_grey_dark)

    ui.window_col_active = iff(get_timing_active(timing_impact), blink(10, color_status_bad, color_empty), window_col)
    local window = ui:begin_window("##status", win_border, win_border, win_left_w, win_top_h, atlas_icons.column_pending, true, 2, false)
        window.label_bias = 0.2
        local region_w, region_h = ui:get_region()

        render_flow_icon(region_w - 11, 3, 10, 10, atlas_icons.column_parachute, 2, -1, iff(get_timing_active(timing_parachute), color_status_ok, color_grey_dark), 0)
        update_ui_image(4, 3, atlas_icons.column_difficulty, iff(get_timing_active(timing_cross_atmosphere), pulse(0.5, color_status_warning, color_grey_dark), color_grey_dark), 0)
        update_ui_rectangle(11, 6, 13, 1, color_grey_dark)
        update_ui_rectangle(region_w - 22, 6, 10, 1, color_grey_dark)

        render_flow_icon(4, 20, 10, 10, atlas_icons.column_propulsion, 2, 1, iff(get_timing_active(timing_burn), color_status_warning, color_grey_dark), 1)
        render_flow_icon(region_w - 10, 20, 10, 10, atlas_icons.column_propulsion, 2, 1, iff(get_timing_active(timing_burn), color_status_warning, color_grey_dark), 1)
        update_ui_rectangle(7, 16, 1, 3, color_grey_dark)
        update_ui_rectangle(7, 16, 9, 1, color_grey_dark)
        update_ui_rectangle(region_w - 7, 16, 1, 3, color_grey_dark)
        update_ui_rectangle(region_w - 14, 16, 8, 1, color_grey_dark)

        update_ui_image(region_w / 2 - 32, region_h / 2 - 42, atlas_icons.icon_chassis_shuttle, color_grey_dark, 0)
        update_ui_rectangle(0, 31, region_w, 1, ui.window_col_active)

        ui:spacer(30)

        local impact_time = clamp((timing_travel[2] - timing_travel[1]) - (g_launch_time - timing_travel[1]), 0, timing_travel[2] - timing_travel[1])
        local impact_distance = lerp(93, 0, get_timing_factor(timing_travel) ^ 1.4)

        if get_timing_active(timing_travel) then
            ui:stat(atlas_icons.column_time, format_impact_time(impact_time), color_grey_mid)
            ui:stat(atlas_icons.column_distance, string.format("%.1f", impact_distance) .. update_get_loc(e_loc.acronym_kilometers), iff(get_timing_active(timing_impact), color_status_bad, color_grey_mid))
        else
            ui:stat(atlas_icons.column_time, "--.--", color_grey_dark)
            ui:stat(atlas_icons.column_distance, string.format("%.1f", impact_distance) .. update_get_loc(e_loc.acronym_kilometers), color_grey_dark)
        end
    ui:end_window()

    ui.window_col_active = iff(shield_factor < 0.25, blink(10, color_status_bad, color_empty), window_col)
    local window = ui:begin_window("##eta", win_border, screen_h - win_border - win_bot_h, win_left_w, win_bot_h, atlas_icons.column_power, true, 2, false)
        window.label_bias = 0.2
        ui:stat(atlas_icons.column_difficulty, string.format("%.0f%%", shield_factor * 100), status_color(shield_factor))        
        ui:stat(atlas_icons.column_fuel, string.format("%.0f%%", fuel_factor * 100), iff(fuel_factor < 0.01, color_grey_dark, status_color(fuel_factor)))        
    ui:end_window()

    ui.window_col_active = iff(get_timing_active(timing_cross_atmosphere), blink(10, color_status_bad, color_empty), window_col)
    ui:begin_window("##distance", screen_w - 40 - win_border, win_border, 40, screen_h - win_border * 2, atlas_icons.column_distance, true, 2)
        local region_w, region_h = ui:get_region()

        local col_planet = iff(get_timing_complete(timing_cross_atmosphere), color_grey_mid, color_grey_dark)
        local col_atmosphere = iff(get_timing_active(timing_cross_atmosphere), pulse(1, color_status_bad, color_black), iff(get_timing_complete(timing_cross_atmosphere), color_grey_dark, color_highlight))
        local planet_rad = math.floor(lerp(30, 150, get_timing_factor(timing_travel) ^ 2))
        local steps = 40
        local planet_border = 2
        local atmosphere_rad = 10

        update_ui_push_offset(0, math.floor(lerp(38, 0, get_timing_factor(timing_launch_end))))
        update_ui_push_offset(0, math.floor(lerp(5, -20, get_timing_factor(timing_travel))))

        update_ui_push_offset(math.floor(region_w / 2), region_h + planet_rad - 30)
        update_ui_circle(0, 0, planet_rad + planet_border + atmosphere_rad, steps, col_atmosphere)
        update_ui_circle(0, 0, planet_rad + planet_border, steps, color_black)
        update_ui_circle(0, 0, planet_rad, steps, col_planet)
        update_ui_pop_offset()
        
        update_ui_image(region_w / 2 - 16, region_h, atlas_icons.holomap_icon_carrier, iff(get_timing_active(timing_impact), blink(5, color_white, color_black), color_black), 1)
        update_ui_image(region_w / 2 - 8, -4, atlas_icons.icon_chassis_16_spaceship, iff(get_timing_complete(timing_launch), color_grey_dark, iff(get_timing_active(timing_launch), blink(10, color_status_ok, color_black), color_white)), 1)

        update_ui_push_offset(math.floor(region_w / 2), 14)
        render_path_v(0, 0, 40, 6, 2, get_timing_factor(timing_reach_atmosphere), get_timing_active(timing_reach_atmosphere), color_white, color_grey_dark)
        render_path_v(0, 42, 8, 3, 1, get_timing_factor(timing_cross_atmosphere), get_timing_active(timing_cross_atmosphere), color_white, color_black)
        render_path_v(0, 54, 28, 3, 1, get_timing_factor(timing_reach_dock), get_timing_active(timing_reach_dock), color_white, color_black)
        update_ui_pop_offset()

        update_ui_pop_offset()
        update_ui_pop_offset()
    ui:end_window()
    
    ui:end_ui()
end

function render_path_v(x, y, h, spacing, rad, factor, is_active, col1, col2)
    local cy = y

    while cy < y + h do
        local segment_factor = invlerp(factor * h, cy - y, cy - y + spacing)

        update_ui_circle(x, cy, rad, 8, iff(segment_factor > 0 and segment_factor < 1 and is_active, blink(10, col1, col2), col2))
        cy = cy + spacing
    end
end

function render_bar(x, y, w, h, factor, col)
    update_ui_push_offset(x, y)
    update_ui_rectangle(0, 0, w, h, color_grey_dark)
    update_ui_rectangle(0, 0, w * factor, h, col)
    update_ui_pop_offset()
end

function render_flow_icon(x, y, w, h, icon, thickness, dir, col, rot)
    update_ui_push_offset(x, y)
    update_ui_image(0, 0, icon, color_grey_dark, rot)

    if dir == -1 then
        update_ui_push_clip(0, math.floor(lerp(h + thickness, -thickness, g_animation_time % 15 / 15)), w, thickness)
    else
        update_ui_push_clip(0, math.floor(lerp(-thickness, h + thickness, g_animation_time % 15 / 15)), w, thickness)
    end

    update_ui_image(0, 0, icon, col, rot)
    update_ui_pop_clip()
    update_ui_pop_offset()
end

function test_sequence()
    g_launch_time = clamp(g_launch_time + 1 / 30, 0, 40)
    g_launch_factor = g_launch_time / 40
end

function input_event(event, action)
    if action == e_input_action.release then
        if event == e_input.back then
            update_set_screen_state_exit()
        end
    end
end

function blink(rate, col1, col2)
    if g_animation_time % rate * 2 < rate then
        return col1
    else
        return col2 or color_empty
    end
end

function format_impact_time(time)
    local milliseconds = math.floor(time * 100) % 100
    local seconds = math.floor(time) % 60
    return string.format("%02.f.%02.f", seconds, milliseconds)
end

function pulse(rate, col1, col2)
    local factor = math.sin(g_animation_time * rate) * 0.5 + 0.5
    return color8_lerp(col1, col2, factor)
end

function status_color(factor)
    if factor < 0.25 then
        return color_status_bad
    elseif factor < 0.75 then
        return color_status_warning
    end

    return color_status_ok
end
