g_animation_time = 0

g_screen_index = 0

g_transmission_selected_index = -1
g_transmission_playing_index_prev = -1
g_ui = nil
g_is_focus_local_prev = false

function begin()
    begin_load()
    
    g_ui = lib_imgui:create_ui()
end

function parse()
    g_transmission_selected_index = parse_s32("", g_transmission_selected_index)
end

function update(screen_w, screen_h, ticks)
    g_animation_time = g_animation_time + ticks

    if update_screen_overrides(screen_w, screen_h, ticks)  then return end
    
    local ui = g_ui
    local team = update_get_team(update_get_screen_team_id())

    ui:begin_ui()

    local transmission_playing_index = update_get_transmission_playing_index()

    if team:get() then
        local main_win_h = screen_h - 30

        if transmission_playing_index == -1 and g_transmission_playing_index_prev ~= -1 then
            g_transmission_selected_index = g_transmission_playing_index_prev
        end

        if update_get_is_focus_local() and g_is_focus_local_prev == false and transmission_playing_index == -1 then
            local unread_transmission = get_first_unread_transmission(team)
            g_transmission_selected_index = unread_transmission
            update_play_transmission(unread_transmission)
        elseif update_get_is_focus_local() == false and transmission_playing_index == -1 then
            g_transmission_selected_index = -1
        end

        if transmission_playing_index ~= -1 then
            g_transmission_selected_index = -1
            render_transmission_screen(ui, screen_w, main_win_h, team, transmission_playing_index)
        elseif g_transmission_selected_index == -1 then
            local win_main = ui:begin_window(update_get_loc(e_loc.upp_transmissions), 5, 5, screen_w - 10, main_win_h, atlas_icons.column_message, update_get_is_focus_local(), 0, true, true)
            local region_w, region_h = ui:get_region()
            local transmission_unlock_count = team:get_transmission_unlocked_count()

            local transmission_unread_count = get_transmission_unread_count(team)

            if transmission_unread_count > 0 and update_get_is_focus_local() == false then
                if transmission_unread_count > 0 and update_get_is_focus_local() == false then
                    render_status_label(4, region_h / 2 - 8, region_w - 8, 13, update_get_loc(e_loc.upp_new_transmission), color_status_ok, is_blink_on(10))
                end
            else
                if transmission_unlock_count > 0 then
                    for i = 0, update_get_team_transmission_count() - 1 do
                        if get_is_transmission_unlocked(team, i) then
                            local is_unread = get_is_transmission_unread(team, i)
                            local is_playing = transmission_playing_index == i
    
                            if imgui_transmission_button(ui, update_get_team_transmission_name(i), is_unread, is_playing) then
                                g_transmission_selected_index = i
                            end
                        end
                    end 
    
                    ui:spacer(2)
                else
                    render_status_label(4, region_h / 2 - 8, region_w - 8, 13, update_get_loc(e_loc.upp_no_transmissions), color_grey_dark, false)
                end
            end
            
            ui:end_window()
        else
            render_transmission_screen(ui, screen_w, main_win_h, team, g_transmission_selected_index)
        end

        local cy = 5 + main_win_h + 4
        update_ui_push_offset(5, cy)
        update_ui_rectangle_outline(0, 0, screen_w - 10, screen_h - cy - 5, color_white)
        
        local is_playing = update_get_transmission_playing_index() ~= -1
        local playback_progress = update_get_transmission_playback_progress()

        update_ui_image(5, 3, atlas_icons.column_audio, iff(is_playing, color_status_ok, color_grey_dark), 0)
        update_ui_rectangle(18, 6, 94, 4, color_grey_dark)

        if is_playing then
            update_ui_rectangle(18, 6, math.floor(94 * playback_progress + 0.5), 4, color_grey_mid)
        end

        update_ui_pop_offset()
    end

    ui:end_ui()

    g_is_focus_local_prev = update_get_is_focus_local()
    g_transmission_playing_index_prev = transmission_playing_index
end

function input_event(event, action)
    g_ui:input_event(event, action)

    if action == e_input_action.press and  event == e_input.back then
        if g_transmission_selected_index == -1 then
            update_set_screen_state_exit()
        else
            g_transmission_selected_index = -1
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

function render_transmission_screen(ui, screen_w, h, team, transmission_index)
    local transmission_playing_index = update_get_transmission_playing_index()
    local is_playing = transmission_playing_index == transmission_index

    local win_transmission = ui:begin_window("##transmission", 5, 5, screen_w - 10, h, atlas_icons.column_message, true)
        win_transmission.label_bias = 0.11
        ui:stat(atlas_icons.column_message, update_get_team_transmission_name(transmission_index), color_grey_mid)
        win_transmission.label_bias = 0.5

        ui:divider()
        
        if is_playing then
            if ui:list_item(update_get_loc(e_loc.upp_audio_stop), true) then
                update_stop_transmission()
            end
        else
            if ui:list_item(update_get_loc(e_loc.upp_audio_play), true) then
                update_play_transmission(transmission_index)
            end
        end
    ui:end_window()
end

function render_status_label(x, y, w, h, text, col, is_blink_on)
    update_ui_push_offset(x, y)
                
    if is_blink_on then
        update_ui_rectangle(0, 0, w, h, col)
        update_ui_text(0, 2, text, math.floor(w / 2 + 0.5) * 2, 1, color_black, 0)
    else
        update_ui_rectangle_outline(0, 0, w, h, col)
        update_ui_text(0, 2, text, math.floor(w / 2 + 0.5) * 2, 1, col, 0)
    end

    update_ui_pop_offset()
end

function imgui_transmission_button(ui, name, is_unread, is_playing)
    local window = ui:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = ui:get_region()
    local is_active = window.is_active
    local is_selected = window.selected_index_y == window.index_y and window.is_selection_enabled

    local text_col = iff(is_active, iff(is_selected, iff(is_unread, color_white, color_grey_mid), color_grey_dark), color_grey_dark)
    local icon_col = iff(is_active, iff(is_selected, iff(is_unread, color_status_ok, color_grey_dark), iff(is_unread, color_status_ok, color_grey_dark)), color_grey_dark)
    local back_col = iff(is_active, iff(is_selected, iff(is_unread, color_highlight, color_grey_mid), iff(is_unread, color_button_bg, color_button_bg_inactive)), color_button_bg_inactive)
    
    local icon = atlas_icons.column_message

    if is_active and is_playing and is_blink_on(10) then
        icon_col = color_status_ok
        icon = atlas_icons.column_audio
    end

    update_ui_image(x + 5, y + 3, icon, icon_col, 0)

    local _, text_name_height = update_ui_get_text_size(name, w - 27, 0)
    render_button_bg_outline(x + 2, y, w - 4, text_name_height + 5, back_col)

    update_ui_text(x + 17, y + 3, name, w - 27, 0, text_col, 0)
    y = y + text_name_height + 3
    
    local is_hovered = ui:hoverable(x, window.cy, w, y - window.cy, true)
    window.cy = y + 3

    local is_action = false

    if is_selected and is_active then
        local is_clicked = is_hovered and ui.input_pointer_1

        if is_hovered or update_get_active_input_type() == e_active_input.gamepad then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
        end

        if ui.input_action or is_clicked then
            is_action = true
            ui.input_action = false
            ui.input_pointer_1 = false
        end
    end

    return is_action
end

function is_blink_on(rate, is_pulse)
    if is_pulse == nil or is_pulse == false then
        return g_animation_time % (2 * rate) > rate
    else
        return g_animation_time % (2 * rate) == 0
    end
end

function get_is_transmission_unlocked(team, index)
    local transmissions_unlocked = team:get_transmission_unlocked_bitset()
    return (transmissions_unlocked >> index) & 1 == 1
end

function get_is_transmission_unread(team, index)
    local transmissions_unread = team:get_transmission_unread_bitset()
    return (transmissions_unread >> index) & 1 == 1
end

function get_transmission_unread_count(team)
    local count = 0

    for i = 0, update_get_team_transmission_count() - 1 do
        if get_is_transmission_unlocked(team, i) and get_is_transmission_unread(team, i) then
            count = count + 1
        end
    end

    return count
end

function get_first_unread_transmission(team)
    for i = 0, update_get_team_transmission_count() - 1 do
        if get_is_transmission_unlocked(team, i) and get_is_transmission_unread(team, i) then
            return i
        end
    end

    return -1
end
