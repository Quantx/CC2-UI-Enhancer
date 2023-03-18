g_ui = nil
g_last_read_index = 0
g_page = 0

function begin()
    begin_load()
    begin_load_inventory_data()
    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end
    local screen_vehicle_id = update_get_screen_vehicle():get_id()

    local ui = g_ui
    ui:begin_ui()

    local logs = {}

    for i = 0, update_get_delivery_log_count() - 1 do
        local log_time, modified_tick, log = update_get_delivery_log(i)

        if log:get_carrier_id() == screen_vehicle_id  then
            table.insert(logs, { log_time, modified_tick, log })
        end
    end

    local log_count = #logs
    
    ui.window_col_active = iff(g_last_read_index < log_count, pulse(0.25, color_status_ok, color_grey_dark), color_white)

    local window = ui:begin_window(update_get_loc(e_loc.upp_barge_delivery_log), 10, 10, screen_w - 20, screen_h - 35, atlas_icons.column_pending, true, 0, false)
        local region_w, region_h = ui:get_region()
        
        local id_w = update_ui_get_text_size("0000", 10000, 0) + 8
        
        local column_widths = { 55, id_w, 112, -1 }
        local column_margins = { 5, 5, 5, 5 }
        local max_logs = 15
        local page_count = math.ceil(log_count / max_logs)
        g_page = clamp(g_page, 0, page_count - 1)

        local columns_header = {
            { w=column_widths[1], margin=column_margins[1], value=atlas_icons.column_time },
            { w=column_widths[2], margin=column_margins[2], value=update_get_loc(e_loc.upp_id) },
            { w=column_widths[3], margin=column_margins[3], value=atlas_icons.column_stock },
            { w=column_widths[4], margin=column_margins[4], value=atlas_icons.column_pending },
        }

        imgui_table_header(ui, columns_header)

        local view_start = g_page * max_logs
        local view_end = view_start + max_logs

        if log_count == 0 then
            ui:spacer(5)
            update_ui_text(0, window.cy, "---", region_w, 1, color_grey_dark, 0)
        else
            for i = log_count - 1 - view_start, math.max(log_count - view_end, 0), -1 do
                local log_time, modified_tick, log = table.unpack(logs[i + 1])
                
                if update_get_is_focus_local() then
                    g_last_read_index = math.max(i + 1, g_last_read_index)
                end
    
                if log:get() then
                    local log_type = log:get_type()
                    local barge_id = log:get_barge_id()
                    local inventory_item = log:get_inventory_item()
                    local delivery_amount = math.min(log:get_delivery_amount(), 99999)
                    local item_data = g_item_data[inventory_item]
                    local item_name = "unknown item"
                    local item_icon = atlas_icons.icon_attachment_16_unknown
    
                    if item_data ~= nil then
                        item_name = item_data.name
                        item_icon = item_data.icon
                    end
    
                    if log_type == e_map_notification_type.barge_delivery then
                        local columns = { 
                            { w=column_widths[1], margin=column_margins[1], value=format_time(log:get_time()), col=color_grey_dark },
                            { w=column_widths[2], margin=column_margins[2], value=tostring(barge_id), col=color_grey_dark },
                            { w=column_widths[3], margin=column_margins[3], value=item_name, col=color_grey_dark },
                            { w=column_widths[4], margin=column_margins[4], value="+" .. delivery_amount, col=color_status_ok },
                        }
    
                        imgui_table_entry(ui, columns)
                    elseif log_type == e_map_notification_type.barge_collection then
                        local columns = { 
                            { w=column_widths[1], margin=column_margins[1], value=format_time(log:get_time()), col=color_grey_dark },
                            { w=column_widths[2], margin=column_margins[2], value=tostring(barge_id), col=color_grey_dark },
                            { w=column_widths[3], margin=column_margins[3], value=item_name, col=color_grey_dark },
                            { w=column_widths[4], margin=column_margins[4], value="-" .. delivery_amount, col=color_status_bad },
                        }
    
                        imgui_table_entry(ui, columns)
                    end
                end
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
        window.scroll_y = 0
        g_page = 0
    end

    update_ui_push_offset(0, screen_h - 20)
    update_ui_text(0, 0, format_time(update_get_logic_tick() / 30), screen_w, 1, color_grey_mid, 0)
    update_ui_image(screen_w / 2 - 35, 0, atlas_icons.column_time, color_grey_mid, 0)
    
    update_ui_image(15, 0, atlas_icons.column_pending, color_white, 0)
    update_ui_text(25, 0, (g_page + 1) .. "/" .. math.max(page_count, 1), 85, 0, color_white, 0)

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

function pulse(rate, col1, col2)
    local factor = math.sin(update_get_logic_tick() * rate) * 0.5 + 0.5
    return color8_lerp(col1, col2, factor)
end
