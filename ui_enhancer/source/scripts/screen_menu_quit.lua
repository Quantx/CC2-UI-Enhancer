g_region_icon = 0
g_ui = {}
g_selected_panel = 0

function begin()
    begin_load()
    g_region_icon = begin_get_ui_region_index("microprose")
    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    update_interaction_ui()
    
    local ui = g_ui
    
    ui:begin_ui()

        if g_selected_panel == 0 then
            ui:begin_window("##main", 10, 10, screen_w - 20, 27, atlas_icons.column_transit, g_selected_panel == 0)
            
                if ui:list_item(update_get_loc(e_loc.upp_quit_to_desktop)) then
                    g_selected_panel = 1
                end

            ui:end_window()

            ui:begin_window(update_get_loc(e_loc.upp_credits), 10, 39, screen_w - 20, screen_h - 50, atlas_icons.column_pending, false)
                local w, h = ui:get_region()
                
                update_ui_image(w / 2 - 36, 30, atlas_icons.microprose, color_grey_mid, 0)
                update_ui_text(0, 10, "GEOMETA\n+\n\n\nUI Mod by QuantX", w, 1, color_grey_mid, 0)

            ui:end_window()
        else
            ui:begin_window_dialog(update_get_loc(e_loc.upp_sure), screen_w / 2, screen_h / 2, screen_w - 60, screen_h - 40, nil, g_selected_panel == 1)
            
                if ui:button(update_get_loc(e_loc.upp_no), true, 1) then
                    g_selected_panel = 0
                end

                if ui:button(update_get_loc(e_loc.upp_yes), true, 1) then
                    update_ui_event("quit_game")
                end

            ui:end_window()
        end

    ui:end_ui()
end

function update_interaction_ui()
    if g_selected_panel ~= 0 then
        update_add_ui_interaction(update_get_loc(e_loc.interaction_cancel), e_game_input.back)
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)
    end
end

function input_event(event, action)
    if action == e_input_action.release then
        if event == e_input.back then
            if g_selected_panel == 0 then
                update_set_screen_state_exit()
            else
                g_selected_panel = 0
            end
        else
            g_ui:input_event(event, action)
        end
    elseif action == e_input_action.press then
        g_ui:input_event(event, action)
    end
end

function input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
end

function input_axis(x, y, z, w)
end
