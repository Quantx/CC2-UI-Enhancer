g_ui = nil
g_last_read_index = 0
g_page = 0

function begin()
    begin_load()
    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    local ui = g_ui
    ui:begin_ui()

    local log_count = update_get_notification_log_count()
    ui.window_col_active = iff(g_last_read_index < log_count, pulse(0.25, color_status_bad, color_grey_dark), color_white)

    local window = ui:begin_window(update_get_loc(e_loc.upp_log), 10, 10, screen_w - 20, screen_h - 35, atlas_icons.column_pending, true, 0, false)
        local region_w, region_h = ui:get_region()
        local column_widths = { 55, region_w - 55 }
        local column_margins = { 5, 5 }
        local max_logs = 15
        local page_count = math.ceil(log_count / max_logs)
        g_page = clamp(g_page, 0, page_count - 1)

        local columns_header = {
            { w=column_widths[1], margin=column_margins[1], value=atlas_icons.column_time },
            { w=column_widths[2], margin=column_margins[2], value=atlas_icons.column_pending },
        }

        imgui_table_header(ui, columns_header)

        local view_start = g_page * max_logs
        local view_end = view_start + max_logs

        for i = log_count - 1 - view_start, math.max(log_count - view_end, 0), -1 do
            local log = update_get_notification_log(i)
            
            if update_get_is_focus_local() then
                g_last_read_index = math.max(i + 1, g_last_read_index)
            end

            if log:get() then
                imgui_notification_log(ui, log, column_widths, column_margins, i < g_last_read_index)
            end
        end
    ui:end_window()

    if window.is_scrollbar_visible then
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_scroll), e_ui_interaction_special.gamepad_scroll)
    end

    if page_count > 0 then
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_page), e_ui_interaction_special.gamepad_dpad_ud)

        if update_get_active_input_type() == e_active_input.keyboard then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_prev_page), e_game_input.dpad_up)
            update_add_ui_interaction(update_get_loc(e_loc.interaction_next_page), e_game_input.dpad_down)
        end
    end

    if update_get_is_focus_local() == false then
        g_is_scroll_down = false
        g_is_scroll_up = false
        window.scroll_y = 0
        g_page = 0
    end

    update_ui_push_offset(0, screen_h - 20)
    update_ui_text(0, 0, format_time(update_get_logic_tick() / 30), screen_w, 1, color_grey_mid, 0)
    update_ui_image(screen_w / 2 - 35, 0, atlas_icons.column_time, color_grey_mid, 0)
    
    update_ui_image(15, 0, atlas_icons.column_pending, color_white, 0)
    update_ui_text(25, 0, (g_page + 1) .. "/" .. page_count, 85, 0, color_white, 0)

    if g_last_read_index < log_count then
        update_ui_image(screen_w - 20, 0, atlas_icons.hud_warning, color_status_bad, 0)
        update_ui_text(0, 0, (log_count - g_last_read_index), screen_w - 20, 2, color_status_bad, 0)
    end

    update_ui_pop_offset()

    ui:end_ui()
end

function input_event(event, action)
    if action == e_input_action.press then
        if event == e_input.up then
            g_page = g_page - 1
        elseif event == e_input.down then
            g_page = g_page + 1
        end
    end

    if action == e_input_action.release then
        if event == e_input.back then
            update_set_screen_state_exit()
        end
    end
end

function input_axis(x, y, z, w)
    g_ui:input_scroll_gamepad(w)
end

function input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
end

function input_scroll(dy)
    g_ui:input_scroll(dy)
end

function imgui_notification_log(ui, log, column_widths, column_margins, is_read)
    local log_message = ""
    local log_type = log:get_type()
    local text_col = color_grey_dark

    if log_type == e_map_notification_type.island_captured then
        log_message = update_get_loc(e_loc.island_captured) .. " - " .. get_tile_name(log:get_tile_id())
        text_col = color_status_ok
    elseif log_type == e_map_notification_type.island_lost then
        log_message = update_get_loc(e_loc.island_lost) .. " - " .. get_tile_name(log:get_tile_id())
        text_col = color_status_bad
    elseif log_type == e_map_notification_type.blueprint_unlocked then
        local blueprints = log:get_blueprints()
        log_message = update_get_loc(e_loc.unlocked) .. " " .. #blueprints .. " " .. iff(#blueprints > 1, update_get_loc(e_loc.blueprints), update_get_loc(e_loc.blueprint))
        text_col = color_highlight
    elseif log_type == e_map_notification_type.enemy_vehicle_destroyed then
        local definition_name = get_chassis_data_by_definition_index(log:get_vehicle_definition_index())
        log_message = update_get_loc(e_loc.vehicle_destroyed) .. " - " .. definition_name .. " - " .. log:get_team_id()
    elseif log_type == e_map_notification_type.team_vehicle_destroyed then
        local definition_name = get_chassis_data_by_definition_index(log:get_vehicle_definition_index())
        log_message = update_get_loc(e_loc.vehicle_destroyed) .. " - "  .. definition_name
        text_col = color_status_bad
    elseif log_type == e_map_notification_type.team_player_joined then
        log_message = update_get_loc(e_loc.crew_joined) .. " - "  .. log:get_name()
    elseif log_type == e_map_notification_type.team_player_left then
        log_message = update_get_loc(e_loc.crew_left) .. " - "  .. log:get_name()
    elseif log_type == e_map_notification_type.team_virus_bot_retired then
        log_message = update_get_loc(e_loc.virus_bot_retired)
    end

    if #log_message > 0 then
        local columns = { 
            { w=column_widths[1], margin=column_margins[1], value=format_time(log:get_time()), col=color_grey_dark },
            { w=column_widths[2], margin=column_margins[2], value=log_message, col=text_col },
        }

        imgui_table_entry(ui, columns)
    end
end

function get_tile_name(id)
    local tile = update_get_tile_by_id(id)

    if tile:get() then
        return tile:get_name()
    end

    return id
end

function pulse(rate, col1, col2)
    local factor = math.sin(update_get_logic_tick() * rate) * 0.5 + 0.5
    return color8_lerp(col1, col2, factor)
end
