g_region_icon = 0
g_selected_panel = 0
g_hovered_panel = 0
g_selected_category = 0
g_ui = {}

g_pointer_pos_x = 0
g_pointer_pos_y = 0
g_is_pointer_hovered = false
g_is_pointer_down = false

function begin()
    begin_load()
    g_region_icon = begin_get_ui_region_index("microprose")
    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    update_interaction_ui()

    local ui = g_ui
    local lx = 15
    local ly = 15
    local lw = 64
    local lh = screen_h - 30
    local rx = lx + lw + 5
    local rw = screen_w - rx - lx

    local rebinding_keyboard = update_get_rebinding_keyboard()
    local rebinding_gamepad = update_get_rebinding_gamepad()

    if rebinding_keyboard ~= -1 or rebinding_gamepad ~= -1 then
        g_selected_panel = 1
    elseif update_get_active_input_type() == e_active_input.keyboard and g_is_pointer_hovered and update_get_screen_state_active() and ui:get_is_scroll_drag() == false then
        if g_pointer_pos_x < lx + lw + 2 then
            g_hovered_panel = 0
        else
            g_hovered_panel = 1
        end
    end

    ui:begin_ui()

    local is_mouse_active = update_get_active_input_type() == e_active_input.keyboard and g_is_pointer_hovered
    local is_panel_0_selected = g_selected_panel == 0
    local is_panel_1_selected = g_selected_panel == 1

    if is_mouse_active then
        is_panel_0_selected = g_hovered_panel == 0
        is_panel_1_selected = g_hovered_panel == 1
    end

    local is_panel_0_highlight = g_selected_panel == 0
    local is_panel_1_highlight = g_selected_panel == 1

    local win_main = ui:begin_window(update_get_loc(e_loc.upp_options).."##main", lx, ly, lw, lh, atlas_icons.column_pending, is_panel_0_selected, 0, true, is_panel_0_highlight)
    ui:list_item(update_get_loc(e_loc.upp_graphics))
    ui:list_item(update_get_loc(e_loc.upp_audio))
    ui:list_item(update_get_loc(e_loc.upp_ui))

    if update_get_is_vr() == false then
        ui:list_item(update_get_loc(e_loc.upp_settings_gameplay))
    end
    
    if update_get_is_vr() then
        ui:list_item(update_get_loc(e_loc.upp_vr))
    else
        ui:list_item(update_get_loc(e_loc.upp_keyboard))
        ui:list_item(update_get_loc(e_loc.upp_mouse))
        ui:list_item(update_get_loc(e_loc.upp_gamepad))
    end
    ui:end_window()

    g_selected_category = win_main.selected_index_y

    imgui_options_menu(ui, rx, ly, rw, lh, is_panel_1_selected, g_selected_category, is_panel_1_highlight)

    ui:end_ui()

    imgui_menu_focus_overlay(ui, screen_w, screen_h, update_get_loc(e_loc.upp_options), ticks)
end

function update_interaction_ui()
    if g_selected_panel ~= 0 then
        update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)
    end

    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)
end

function input_event(event, action)
    if action == e_input_action.press then
        if event == e_input.pointer_1 then
            g_selected_panel = g_hovered_panel
        end
    end

    if action == e_input_action.release then
        if event == e_input.back then
            if g_selected_panel == 0 then
                update_set_screen_state_exit()
                g_selected_panel = 0
                g_pointer_pos_x = 0
                g_pointer_pos_y = 0
            else
                g_selected_panel = 0
            end
        else
            g_ui:input_event(event, action)
        end
    elseif action == e_input_action.press then
        if event == e_input.action_a and g_selected_panel == 0 then
           g_selected_panel = 1 
        else
            g_ui:input_event(event, action)
        end
    end
end

function input_pointer(is_hovered, x, y)
    g_is_pointer_hovered = is_hovered

    if is_hovered then
        g_pointer_pos_x = x
        g_pointer_pos_y = y
    end
    
    g_ui:input_pointer(is_hovered, x, y)
end

function input_scroll(dy)
    g_ui:input_scroll(dy)
end

function input_axis(x, y, z, w)
end
