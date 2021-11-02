g_ui = {}
g_page = 0

function begin()
    begin_load()
    begin_load_inventory_data()
    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    local ui = g_ui
    ui:begin_ui()

    local top_h = 113

    local window = ui:begin_window(update_get_loc(e_loc.upp_currency_report), 10, 10, screen_w - 20, top_h, atlas_icons.column_currency, false, 0, false, true)
        local region_w, region_h = ui:get_region()
        local team = update_get_team(update_get_screen_team_id())

        if team:get() then
            local accounts = {}

            for i = 0, team:get_currency_account_count() - 1 do
                local account = team:get_currency_account_ordered(i)
                table.insert(accounts, account)
            end

            local column_widths = { 100, 44, 44, 44 }
            local column_margins = { 5, 2, 2, 2 }

            local function get_account_name(index)
                if index < #accounts + 1 and accounts[index].id > 0 then
                    return update_get_loc(e_loc.upp_day).." " .. accounts[index].id
                end

                return "---"
            end

            imgui_table_header(ui, {
                { w=column_widths[1], margin=column_margins[1], value=atlas_icons.column_pending },
                { w=column_widths[2], margin=column_margins[2], value=get_account_name(3) },
                { w=column_widths[3], margin=column_margins[3], value=get_account_name(2) },
                { w=column_widths[4], margin=column_margins[4], value=get_account_name(1) }
            })

            imgui_table_entry(ui, {
                { w=column_widths[1], margin=column_margins[1], value=update_get_loc(e_loc.balance_start) },
                { w=column_widths[2], margin=column_margins[2], value=iff(accounts[3].id == 0, "---", tostring(accounts[3].currency_start)) },
                { w=column_widths[3], margin=column_margins[3], value=iff(accounts[2].id == 0, "---", tostring(accounts[2].currency_start)) },
                { w=column_widths[4], margin=column_margins[4], value=iff(accounts[1].id == 0, "---", tostring(accounts[1].currency_start)) }
            }, false)

            ui:divider(0, 1)

            local function account_column(column_index, index, value)
                return { 
                    w=column_widths[column_index], 
                    margin=column_margins[column_index], 
                    value=render_currency_amount(accounts[index][value], index == 1)
                }
            end

            imgui_table_entry(ui, {
                { w=column_widths[1], margin=column_margins[1], value=update_get_loc(e_loc.island_control) },
                account_column(2, 3, "currency_captured_islands"),
                account_column(3, 2, "currency_captured_islands"),
                account_column(4, 1, "currency_captured_islands")
            }, false)

            imgui_table_entry(ui, {
                { w=column_widths[1], margin=column_margins[1], value=update_get_loc(e_loc.island_captures) },
                account_column(2, 3, "currency_island_captures"),
                account_column(3, 2, "currency_island_captures"),
                account_column(4, 1, "currency_island_captures")
            }, false)

            imgui_table_entry(ui, {
                { w=column_widths[1], margin=column_margins[1], value=update_get_loc(e_loc.vehicle_salvage) },
                account_column(2, 3, "currency_destroyed_vehicles"),
                account_column(3, 2, "currency_destroyed_vehicles"),
                account_column(4, 1, "currency_destroyed_vehicles")
            }, false)

            imgui_table_entry(ui, {
                { w=column_widths[1], margin=column_margins[1], value=update_get_loc(e_loc.item_production) },
                account_column(2, 3, "currency_facility_production"),
                account_column(3, 2, "currency_facility_production"),
                account_column(4, 1, "currency_facility_production")
            }, false)

            ui:divider(0, 1)
            ui:divider(2, 1)

            local function render_team_currency(w, h)
                local amount = team:get_currency()
                local col = iff(amount, color_status_ok, color_status_bad)
                update_ui_image(0, 3, atlas_icons.column_currency, col, 0)
                update_ui_text(8, 3, tostring(math.min(amount, 999999)), w, 0, col, 0) 
            end

            imgui_table_entry(ui, {
                { w=column_widths[1], margin=column_margins[1], value=update_get_loc(e_loc.balance_end) },
                { w=column_widths[2], margin=column_margins[2], value=iff(accounts[3].id == 0, "---", tostring(accounts[3].currency_end)) },
                { w=column_widths[3], margin=column_margins[3], value=iff(accounts[2].id == 0, "---", tostring(accounts[2].currency_end)) },
                { w=column_widths[4], margin=column_margins[4], value=render_team_currency }
            }, false)

            ui:divider(0, 1)
            ui:divider(2, 1)
        end
    ui:end_window()

    ui.window_col_inactive = color_white

    update_ui_rectangle_outline(10, top_h + 13, screen_w - 20, screen_h - top_h - 37, color_white)
    window = ui:begin_window(update_get_loc(e_loc.upp_recent_transactions), 11, top_h + 14, screen_w - 22, screen_h - top_h - 39, atlas_icons.column_time, true, 1, false)
        region_w, region_h = ui:get_region()
        
        local column_widths = { 55, 133, 44 }
        local column_margins = { 5, 2, 2 }

        imgui_table_header(ui, {
            { w=column_widths[1], margin=column_margins[1], value=atlas_icons.column_time },
            { w=column_widths[2], margin=column_margins[2], value=update_get_loc(e_loc.upp_recent_transactions)},
            { w=column_widths[3], margin=column_margins[3], value=atlas_icons.column_currency},
        })

        local max_logs = 7
        local log_count = update_get_currency_log_count()
        local page_count = math.ceil(log_count / max_logs)
        local view_start = g_page * max_logs
        local view_end = view_start + max_logs
        g_page = clamp(g_page, 0, page_count - 1)

        if log_count == 0 then
            ui:spacer(5)
            update_ui_text(0, window.cy, "---", region_w, 1, color_grey_dark, 0)
        else
            for i = log_count - 1 - view_start, math.max(log_count - view_end, 0), -1 do
                local log = update_get_currency_log(i)

                if log:get() then
                    imgui_currency_log(column_widths, column_margins, log)
                end
            end
        end
    ui:end_window()
    ui:end_ui()

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
    update_ui_image(15, 0, atlas_icons.column_pending, color_white, 0)
    update_ui_text(25, 0, (g_page + 1) .. "/" .. math.max(page_count, 1), 85, 0, color_white, 0)
    update_ui_pop_offset()
end

function input_event(event, action)
    g_ui:input_event(event, action)

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

function input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
end

function input_scroll(dy)
    g_ui:input_scroll(dy)
end

function input_axis(x, y, z, w)
    g_ui:input_scroll_gamepad(w)
end

function currency_col(amount, is_highlight) 
    if amount > 0 then
        return iff(is_highlight, color_status_ok, color8(8, 32, 20, 255))
    elseif amount < 0 then
        return iff(is_highlight, color_status_bad, color8(32, 8, 8, 255))
    end

    return color_grey_dark
end

function render_currency_amount(amount, is_highlight)
    return function(w, h)
        local col = currency_col(amount, is_highlight)
        
        if amount > 0 then
            update_ui_image(0, 5, atlas_icons.text_back, col, 1)
            update_ui_text(7, 3, tostring(math.min(math.abs(amount), 999999)), w, 0, col, 0)
        elseif amount < 0 then
            update_ui_image(-1, 4, atlas_icons.text_back, col, 3)
            update_ui_text(7, 3, tostring(math.min(math.abs(amount), 999999)), w, 0, col, 0)
        else
            update_ui_text(0, 3, "---", w, 0, col, 0)
        end
    end
end

function imgui_currency_log(column_widths, column_margins, log)
    local ui = g_ui
    local log_type = log:get_type()
    local currency_amount = log:get_delivery_amount()
    
    if log_type == e_map_notification_type.currency_destroyed_vehicle then
        local definition_name = get_chassis_data_by_definition_index(log:get_vehicle_definition_index())
        local log_message = update_get_loc(e_loc.enemy) .. " " .. definition_name .. " " .. update_get_loc(e_loc.destroyed)

        local columns = { 
            { w=column_widths[1], margin=column_margins[1], value=format_time(log:get_time()), col=color_grey_dark },
            { w=column_widths[2], margin=column_margins[2], value=log_message, col=color_grey_dark },
            { w=column_widths[3], margin=column_margins[3], value=render_currency_amount(currency_amount, true) },
        }

        imgui_table_entry(ui, columns)
    elseif log_type == e_map_notification_type.currency_island_capture then
        local log_message = update_get_loc(e_loc.captured_island) .. " " .. get_tile_name(log:get_tile_id())

        local columns = { 
            { w=column_widths[1], margin=column_margins[1], value=format_time(log:get_time()), col=color_grey_dark },
            { w=column_widths[2], margin=column_margins[2], value=log_message, col=color_grey_dark },
            { w=column_widths[3], margin=column_margins[3], value=render_currency_amount(currency_amount, true) },
        }

        imgui_table_entry(ui, columns)
    elseif log_type == e_map_notification_type.currency_captured_islands then
        local columns = { 
            { w=column_widths[1], margin=column_margins[1], value=format_time(log:get_time()), col=color_grey_dark },
            { w=column_widths[2], margin=column_margins[2], value=update_get_loc(e_loc.island_control), col=color_grey_dark },
            { w=column_widths[3], margin=column_margins[3], value=render_currency_amount(currency_amount, true) },
        }

        imgui_table_entry(ui, columns)
    elseif log_type == e_map_notification_type.currency_refunded_production then
        local item_type = log:get_inventory_item()
        local item = g_item_data[item_type]

        local columns = { 
            { w=column_widths[1], margin=column_margins[1], value=format_time(log:get_time()), col=color_grey_dark },
            { w=column_widths[2], margin=column_margins[2], value=update_get_loc(e_loc.cancel_production), col=color_grey_dark },
            { w=column_widths[3], margin=column_margins[3], value=render_currency_amount(currency_amount, true) },
        }

        imgui_table_entry(ui, columns)
    elseif log_type == e_map_notification_type.currency_spend_on_production then
        local columns = { 
            { w=column_widths[1], margin=column_margins[1], value=format_time(log:get_time()), col=color_grey_dark },
            { w=column_widths[2], margin=column_margins[2], value=update_get_loc(e_loc.item_production), col=color_grey_dark },
            { w=column_widths[3], margin=column_margins[3], value=render_currency_amount(-currency_amount, true) },
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
