g_region_icon = 0

g_damage_zones = {
    front_left = { index=nil, def="damage_zone_fl", name="" },
    front_right = { index=nil, def="damage_zone_fr", name="" },
    back_left = { index=nil, def="damage_zone_bl", name="" },
    back_right = { index=nil, def="damage_zone_br", name="" },
    bridge = { index=nil, def="damage_zone_bridge", name="" },
    wep_left = { index=nil, def="damage_zone_wep_l", name="" },
    wep_right = { index=nil, def="damage_zone_wep_r", name="" },
    hull = { index=nil, def="damage_zone_hull", name="" }
}

g_colors = {
    hp_low = color_status_bad,
    hp_mid = color_status_warning,
    hp_high = color_status_ok,
    inactive = color_grey_dark,
    invisible = color8(0, 0, 0, 0),
    repair = color_white,
}

g_animation_time = 0
g_highlighted_zone_index = -1

g_ui = {}

function begin()
    begin_load()
    g_region_icon = begin_get_ui_region_index("microprose")
    g_ui = lib_imgui:create_ui()

    g_damage_zones.front_left.name = update_get_loc(e_loc.upp_acronym_weapon_front_left)
    g_damage_zones.front_right.name = update_get_loc(e_loc.upp_acronym_weapon_front_right)
    g_damage_zones.back_left.name = update_get_loc(e_loc.upp_acronym_weapon_back_left)
    g_damage_zones.back_right.name = update_get_loc(e_loc.upp_acronym_weapon_back_right)
    g_damage_zones.bridge.name = update_get_loc(e_loc.upp_bridge)
    g_damage_zones.wep_left.name = update_get_loc(e_loc.upp_acronym_weapon_left)
    g_damage_zones.wep_right.name = update_get_loc(e_loc.upp_acronym_weapon_right)
    g_damage_zones.hull.name = update_get_loc(e_loc.upp_hull)
end

function update(screen_w, screen_h, ticks) 
    if update_self_destruct_override(screen_w, screen_h) then return end
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end
    
    local map_vehicle = update_get_screen_vehicle()
    if map_vehicle:get() == false then return end

    local vehicle = update_get_vehicle_by_id(map_vehicle:get_id())
    if vehicle:get() == false then return end

    local ui = g_ui
    update_damage_zones(vehicle)
    g_animation_time = g_animation_time + ticks
    g_highlighted_zone_index = -1

    ui:begin_ui()

    local hitpoints = map_vehicle:get_hitpoints()
    local hitpoints_total = map_vehicle:get_total_hitpoints()
    local hull_hp_factor = hitpoints / hitpoints_total

    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)

    local window = ui:begin_window(update_get_loc(e_loc.upp_repair), screen_w / 2 - 2, 5, screen_w / 2 - 8, screen_h - 10, atlas_icons.column_repair, true, 0, update_get_is_focus_local())
        window.label_bias = 0.8

        local ordered_zones = {
            g_damage_zones.front_left,
            g_damage_zones.front_right,
            g_damage_zones.wep_left,
            g_damage_zones.wep_right,
            g_damage_zones.bridge,
            g_damage_zones.back_left,
            g_damage_zones.back_right
        }

        local function damage_zone_checkbox(zone, hp_factor)
            local is_repairing = vehicle:get_damage_zone_repairing(zone.index)
            local is_modified = false
            is_repairing, is_modified = imgui_checkbox_toggle(ui, zone.name, is_repairing, hp_factor < 1.0)

            if ui:get_is_item_selected() and update_get_is_focus_local() then
                g_highlighted_zone_index = zone.index
            end

            if is_modified then
                vehicle:set_damage_zone_repairing(zone.index, is_repairing)
            end
        end

        damage_zone_checkbox(g_damage_zones.hull, hull_hp_factor)
        ui:divider()

        for _, v in pairs(ordered_zones) do
            local hp_factor = get_damage_zone_hitpoint_factor(vehicle, v.index)
            damage_zone_checkbox(v, hp_factor)
        end
    ui:end_window()

    local back_col = color_white

    if hull_hp_factor < 0.25 then
        if g_animation_time % 20 > 10 then
            back_col = g_colors.hp_low
        else
            back_col = g_colors.invisible
            text_col = g_colors.hp_low
        end
    end

    ui.window_col_inactive = back_col

    local window = ui:begin_window(update_get_loc(e_loc.upp_damage_status), 10, 5, screen_w / 2 - 16, screen_h - 10, nil, false, 0)
        local region_w, region_h = ui:get_region()
        local text_col = color_black
        
        render_damage_zones(24, 3, map_vehicle, vehicle)

        local hp_factor = clamp(hitpoints / hitpoints_total, 0, 1)
        local hp_text = string.format("%.2f%%", hp_factor * 100) 
        update_ui_rectangle(0, region_h - 10, region_w, 10, back_col)
        update_ui_text(0, region_h - 8, hp_text, math.floor(region_w / 2) * 2, 1, text_col, 0)
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

function update_damage_zones(vehicle)
    for _, v in pairs(g_damage_zones) do
        v.index = v.index or vehicle:get_damage_zone_index_by_name(v.def)
    end
end

function render_damage_zones(x, y, map_vehicle, vehicle)
    update_ui_push_offset(x, y)

    -- update_ui_image(14, 0, atlas_icons.damage_bg, g_colors.inactive, 0)

    local hull_hp_factor = map_vehicle:get_hitpoints() / map_vehicle:get_total_hitpoints()
    update_ui_image(17, 8, atlas_icons.damage_hull, iff(g_highlighted_zone_index == g_damage_zones.hull.index, color_white, get_damage_hull_color(vehicle, hull_hp_factor)), 0)

    render_damage_zone_icon(20, 2, atlas_icons.damage_fl, 0, vehicle, g_damage_zones.front_left.index, g_highlighted_zone_index == g_damage_zones.front_left.index)
    render_damage_zone_icon(31, 2, atlas_icons.damage_fr, 0, vehicle, g_damage_zones.front_right.index, g_highlighted_zone_index == g_damage_zones.front_right.index)
    render_damage_zone_rect(16, 36, 7, 14, vehicle, g_damage_zones.wep_left.index, g_highlighted_zone_index == g_damage_zones.wep_left.index)
    render_damage_zone_rect(39, 36, 7, 36, vehicle, g_damage_zones.wep_right.index, g_highlighted_zone_index == g_damage_zones.wep_right.index)
    render_damage_zone_icon(16, 53, atlas_icons.damage_bridge, 0, vehicle, g_damage_zones.bridge.index, g_highlighted_zone_index == g_damage_zones.bridge.index)
    render_damage_zone_icon(16, 84, atlas_icons.damage_bl, 0, vehicle, g_damage_zones.back_left.index, g_highlighted_zone_index == g_damage_zones.back_left.index)
    render_damage_zone_icon(31, 84, atlas_icons.damage_br, 0, vehicle, g_damage_zones.back_right.index, g_highlighted_zone_index == g_damage_zones.back_right.index)

    local label_l_x = -23
    local label_r_x = 55

    local cy = -2
    render_damage_zone_label(label_l_x, cy, vehicle, g_damage_zones.front_left.index, 12, g_highlighted_zone_index == g_damage_zones.front_left.index)
    render_damage_zone_label(label_r_x, cy, vehicle, g_damage_zones.front_right.index, -12, g_highlighted_zone_index == g_damage_zones.front_right.index)
    cy = cy + 38

    render_damage_zone_label(label_l_x, cy, vehicle, g_damage_zones.wep_left.index, 8, g_highlighted_zone_index == g_damage_zones.wep_left.index)
    render_damage_zone_label(label_r_x, cy + 11, vehicle, g_damage_zones.wep_right.index, -8, g_highlighted_zone_index == g_damage_zones.wep_right.index)
    cy = cy + 20

    render_damage_zone_label(label_l_x, cy, vehicle, g_damage_zones.bridge.index, 8, g_highlighted_zone_index == g_damage_zones.bridge.index)
    cy = cy + 23

    render_damage_zone_label(label_l_x, cy, vehicle, g_damage_zones.back_left.index, 8, g_highlighted_zone_index == g_damage_zones.back_left.index)
    render_damage_zone_label(label_r_x, cy, vehicle, g_damage_zones.back_right.index, -8, g_highlighted_zone_index == g_damage_zones.back_right.index)
    
    update_ui_pop_offset()
end

function render_damage_zone_icon(x, y, icon, rot, vehicle, index, is_highlight)
    update_ui_image(x, y, icon, iff(is_highlight, color_white, get_damage_zone_color(vehicle, index)), rot)
end

function render_damage_zone_rect(x, y, w, h, vehicle, index, is_highlight)
    update_ui_rectangle(x, y, w, h, iff(is_highlight, color_white, get_damage_zone_color(vehicle, index)))
end

function render_damage_zone_label(x, y, vehicle, index, line_edge, is_highlight)
    update_ui_push_offset(x, y)

    local hp_factor = get_damage_zone_hitpoint_factor(vehicle, index)
    local is_repairing = vehicle:get_damage_zone_repairing(index)

    local hp_color = iff(hp_factor >= 0.5, color_white, get_damage_color(hp_factor))
    local bg_color = iff(is_highlight, color_white,g_colors.inactive)

    if is_repairing and g_animation_time % 20 > 10 then
        bg_color = g_colors.repair
    end

    update_ui_rectangle_outline(0, 0, 30, 13, bg_color)
    
    if line_edge > 0 then
        update_ui_line(30, 6, 30 + line_edge, 6, bg_color)
    else
        update_ui_line(0, 6, line_edge, 6, bg_color)
    end

    update_ui_text(0, 2, string.format("%.0f%%", hp_factor * 100), 30, 1, hp_color, 0)

    update_ui_pop_offset()
end

function get_damage_zone_hitpoint_factor(vehicle, index)
    local zone_hp = vehicle:get_damage_zone_hitpoints(index)
    local zone_total_hp = vehicle:get_damage_zone_total_hitpoints(index)

    if zone_total_hp > 0 then
        return zone_hp / zone_total_hp
    end

    return 1
end

function get_damage_zone_color(vehicle, index)
    local hp_factor = get_damage_zone_hitpoint_factor(vehicle, index)
    local is_repairing = vehicle:get_damage_zone_repairing(index)
    local col = get_damage_color(hp_factor)
    
    if is_repairing then
        if g_animation_time % 20 > 10 then
            col = g_colors.repair
        end
    end

    return col
end

function get_damage_hull_color(vehicle, hp_factor)
    local is_repairing = vehicle:get_damage_zone_repairing(g_damage_zones.hull.index)
    if is_repairing then
        if g_animation_time % 20 > 10 then
            return g_colors.repair
        end
    end

    if hp_factor < 0.25 then
        return g_colors.hp_low
    elseif hp_factor < 0.5 then
        return g_colors.hp_low
    elseif hp_factor < 1.0 then
        return g_colors.hp_mid
    end

    return g_colors.hp_high
end

function get_damage_color(hp_factor)
    if hp_factor < 0.25 then
        return g_colors.hp_low
    elseif hp_factor < 0.5 then
        return g_colors.hp_low
    elseif hp_factor < 1.0 then
        return g_colors.hp_mid
    end

    return g_colors.hp_high
end
