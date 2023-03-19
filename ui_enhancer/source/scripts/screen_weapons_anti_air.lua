g_animation_time = 0
g_is_beep = false
g_beep_next = 0

function begin()
    begin_load()
    begin_load_inventory_data()
end

function update(screen_w, screen_h, ticks) 
    g_animation_time = g_animation_time + ticks

    local vehicle = update_get_screen_vehicle()
    local attachment_indices = { 6, 5 }

    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    if vehicle:get() then
        local attachments = {}

        for i = 1, #attachment_indices do
            local attachment = vehicle:get_attachment(attachment_indices[i])

            if attachment:get() then
                table.insert(attachments, attachment)
            end
        end

        local border_out = 6
        local border_in = 2
        local section_w = (screen_w - 2 * border_out) / 2
        local section_h = screen_h - 2 * border_out

        render_attachment_info(border_out, border_out, section_w, section_h, attachments[1], vehicle)
        render_attachment_info(border_out + section_w + border_in, border_out, section_w, section_h, attachments[2], vehicle)
    end
    
    if g_is_beep then
        if g_animation_time > g_beep_next then
            g_beep_next = g_animation_time + 10
            g_is_beep = false
            update_play_sound(e_audio_effect_type.telemetry_5)
        end
    else
        g_beep_next = g_animation_time
    end
end

function input_event(event, action)
    if action == e_input_action.press then
        if event == e_input.back then
            update_set_screen_state_exit()
        end
    end
end

function input_axis(x, y, z, w)
end


--------------------------------------------------------------------------------
--
-- ATTACHMENT INFO
--
--------------------------------------------------------------------------------

function render_attachment_info(x, y, w, h, attachment, vehicle)
    update_ui_push_offset(x, y)

    local col = color_white

    if attachment == nil or vehicle:get_dock_state() == e_vehicle_dock_state.docked then
        render_status_label(2, h / 2 - 7, w - 4, 13, update_get_loc(e_loc.upp_offline), col, is_blink_on(15))
    else
        local definition_index = attachment:get_definition_index()
        local ammo_capacity = attachment:get_ammo_capacity()
        local ammo_remaining = attachment:get_ammo_remaining()
        local target_accuracy = attachment:get_target_accuracy() / 255 * 100
        local target_id = attachment:get_target_id()
        local control_mode = attachment:get_control_mode()

        if target_id == 0 then
            target_accuracy = 0
        end

        local _, icon = get_attachment_icons(definition_index)

        local cy = 2
        local cx = 2

        update_ui_image(cx, cy, icon, col, 0)
        update_ui_rectangle(cx + 18, 0, 1, 19, col)
        update_ui_text(cx + 21, cy + 4, update_get_loc(e_loc.upp_a_air), 200, 0, col, 0)
        cy = cy + 17

        update_ui_rectangle(0, cy, w, 1, col)
        cy = cy + 2

        render_health_bar(w - 5, cy, 20, vehicle, col)

        local ammo_stock = vehicle:get_inventory_count_by_item_index(e_inventory_item.hardpoint_missile_aa)

        cx = 4
        update_ui_image(cx, cy, atlas_icons.column_stock, iff(ammo_stock > 0, col, color_status_bad), 0)
        update_ui_text(cx + 10, cy, math.min(ammo_stock, 99999), 200, 0, iff(ammo_stock > 0, col, color_status_bad), 0)
        cy = cy + 10

        update_ui_image(cx, cy, atlas_icons.column_laser, iff(target_id ~= 0, col, color_grey_dark), 0)
        update_ui_text(cx + 10, cy, string.format("%.0f%%", target_accuracy), 200, 0, iff(target_id ~= 0, col, color_grey_dark), 0)
        cy = cy + 11
        
        if attachment:get_is_damaged() then
            render_status_label(2, h - 15, w - 4, 13, update_get_loc(e_loc.upp_damaged), color_status_bad, is_blink_on(15))
        elseif control_mode == "off" then
            render_status_label(2, h - 15, w - 4, 13, update_get_loc(e_loc.upp_offline), col, is_blink_on(15))
        elseif ammo_remaining > 0 then
            if target_id ~= 0 then
                render_status_label(2, h - 15, w - 4, 13, update_get_loc(e_loc.upp_tracking), color_status_bad, is_blink_on(5))

                g_is_beep = true
            else
                render_status_label(2, h - 15, w - 4, 13, update_get_loc(e_loc.upp_armed), color_status_ok, true)
            end
        else
            render_status_label(2, h - 15, w - 4, 13, update_get_loc(e_loc.upp_empty), color_status_bad, true)
        end

        update_ui_rectangle(0, cy, w, 1, col)
        cy = cy + 2

        local function render_missile(x, y, is_ammo, is_tracking)
            update_ui_push_offset(x, y)
            update_ui_rectangle_outline(0, 0, 11, 22, color_grey_dark)
            
            if is_ammo and is_tracking then
                update_ui_image(1, 1, atlas_icons.screen_weapon_missile, iff(is_blink_on(5), color_black, color_status_bad), 0)
            else
                update_ui_image(1, 1, atlas_icons.screen_weapon_missile, iff(is_ammo, color_status_ok, color_black), 0)
            end

            update_ui_pop_offset()
        end

        update_ui_image(cx + 9, cy + 12, atlas_icons.screen_weapon_aa, color_grey_dark, 0)

        update_ui_rectangle(cx + 13, cy + 9, 25, 1, color_grey_dark)
        update_ui_rectangle(cx + 13, cy + 44, 25, 1, color_grey_dark)
        update_ui_rectangle(cx + 25, cy + 9, 1, 5, color_grey_dark)
        update_ui_rectangle(cx + 25, cy + 44, 1, -5, color_grey_dark)

        render_missile(cx + 2, cy + 3, ammo_remaining > 0, ammo_remaining == 1 and target_id ~= 0)
        render_missile(cx + 38, cy + 3, ammo_remaining > 1, ammo_remaining == 2 and target_id ~= 0)
        render_missile(cx + 2, cy + 31, ammo_remaining > 2, ammo_remaining == 3 and target_id ~= 0)
        render_missile(cx + 38, cy + 31, ammo_remaining > 3, ammo_remaining == 4 and target_id ~= 0)
    end

    update_ui_rectangle_outline(0, 0, w, h, col)

    update_ui_pop_offset()
end


--------------------------------------------------------------------------------
--
-- UTIL
--
--------------------------------------------------------------------------------

function render_status_label(x, y, w, h, text, col, is_outline, back_col)
    x = math.floor(x)
    y = math.floor(y)

    update_ui_push_offset(x, y)
    
    if is_outline then
        update_ui_rectangle_outline(0, 0, w, h, col)
        update_ui_text(0, h / 2 - 4, text, math.ceil(w / 2) * 2, 1, col, 0)    
    else
        update_ui_rectangle(0, 0, w, h, col)
        update_ui_text(0, h / 2 - 4, text, math.ceil(w / 2) * 2, 1, back_col or color_black, 0)    
    end

    update_ui_pop_offset()
end

function is_blink_on(rate, is_pulse)
    if is_pulse == nil or is_pulse == false then
        return g_animation_time % (2 * rate) > rate
    else
        return g_animation_time % (2 * rate) == 0
    end
end

function render_health_bar(x, y, h, map_vehicle, col)
    update_ui_push_offset(x, y)

    local vehicle = update_get_vehicle_by_id(map_vehicle:get_id())
    local index = vehicle:get_damage_zone_index_by_name("damage_zone_wep_r")
    
    local hp = vehicle:get_damage_zone_hitpoints(index)
    local total_hp = vehicle:get_damage_zone_total_hitpoints(index)
    
    local health = 0
    if total_hp > 0 then health = hp / total_hp end

    local bar_color = color_status_warning
    
    if health < 0.5 then
        bar_color = color_status_bad
    elseif health == 1.0 then
        bar_color = color_status_ok
    end
    
    update_ui_rectangle(-1, h - 1, 4, 1, col)
    update_ui_rectangle(-1, 0, 4, 1, col)

    local segments = 4
    local step = h / segments
    
    for i = 1, segments - 1 do
        update_ui_rectangle(-1, h - i * step, 1, 1, col)
    end

    local repair_color = bar_color
    
    if vehicle:get_damage_zone_repairing(index) and g_animation_time % 20 > 10 then
        repair_color = color_white
    end

    local bar_size = math.floor(health * (h - 2))
    update_ui_rectangle(0, math.floor(h - bar_size - 1), 2, bar_size, bar_color)

    update_ui_image( -11, h - 8, atlas_icons.icon_health, repair_color, 0 )

    update_ui_pop_offset()
end
