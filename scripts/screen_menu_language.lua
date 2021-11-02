g_region_icon = 0
g_highlight_x = 0
g_highlight_y = 0
g_active_x = 0
g_active_y = 0

g_grid_size_x = 2
g_grid_size_y = 4

g_is_pointer_hovered = false
g_pointer_pos_x = 0
g_pointer_pos_y = 0

function begin()
    begin_load()
    g_region_icon = begin_get_ui_region_index("microprose")
    local settings = update_get_game_settings()
    g_active_x = settings.language % g_grid_size_x
    g_active_y = math.floor(settings.language / g_grid_size_x)
    g_highlight_x = g_active_x
    g_highlight_y = g_active_y
end

function get_flag_icon(index)
    local flag_icons = {
        [0] = { atlas_icons.flag_en},
        [1] = { atlas_icons.flag_fr},
        [2] = { atlas_icons.flag_de},
        [3] = { atlas_icons.flag_es},
        [4] = { atlas_icons.flag_ru},
        [5] = { atlas_icons.flag_pt},
        [6] = { atlas_icons.flag_cn},
        [7] = { atlas_icons.flag_jp},
    }

    local def_data = flag_icons[index]
    return def_data[1]
end

function get_event_string(index)
    return "set_game_setting language "..tostring(index)
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    update_interaction_ui()
    
    local flag_size_x = 36
    local flag_size_y = 24
    local flag_spacing_x = 10
    local flag_spacing_y = 2
    local flag_border_x = 22
    local flag_border_y = 14
    
    local is_use_pointer = g_is_pointer_hovered and update_get_active_input_type() == e_active_input.keyboard
    
    local flag_icons = {atlas_icons.flag_en, atlas_icons.flag_fr, atlas_icons.flag_de, atlas_icons.flag_sp, atlas_icons.flag_ru, atlas_icons.flag_pt, atlas_icons.flag_cn, atlas_icons.flag_jp}
    
    local icon = flag_icons[0]

    for x = 0, g_grid_size_x - 1, 1 do 
        for y = 0, g_grid_size_y - 1, 1 do 
            local rect_x = flag_border_x + (x * (flag_size_x + flag_spacing_x))
            local rect_y = flag_border_y + (y * (flag_size_y + flag_spacing_y))
            local rect_w = flag_size_x + 2
            local rect_h = flag_size_y + 2

            if is_use_pointer then
                if g_pointer_pos_x >= rect_x and g_pointer_pos_y >= rect_y and g_pointer_pos_x < rect_x + rect_w and g_pointer_pos_y < rect_y + rect_h then
                    g_highlight_x = x
                    g_highlight_y = y
                end
            end

            if (x == g_highlight_x) and (y == g_highlight_y) and update_get_is_focus_local() then
                update_ui_rectangle(rect_x, rect_y, rect_w, rect_h, color8(255, 255, 255, 255))
            end
            
            if (x == g_active_x) and (y == g_active_y) then
                update_ui_image(flag_border_x + 1 + (x * (flag_size_x + flag_spacing_x)), flag_border_y + 1 + (y * (flag_size_y + flag_spacing_y)), get_flag_icon(x+(y*g_grid_size_x)), color8(255, 255, 255, 255), 0)
            else
                update_ui_image(flag_border_x + 1 + (x * (flag_size_x + flag_spacing_x)), flag_border_y + 1 + (y * (flag_size_y + flag_spacing_y)), get_flag_icon(x+(y*g_grid_size_x)), color8(16, 16, 16, 255), 0)
            end
        end
    end
end

function update_interaction_ui()
    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_all)
    update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
end

function input_event(event, action)
    if action == e_input_action.press then
        if event == e_input.down then
            g_highlight_y = (g_highlight_y + 1) % g_grid_size_y
        elseif event == e_input.up then
            g_highlight_y = (g_highlight_y + g_grid_size_y - 1) % g_grid_size_y
        elseif event == e_input.left then
            g_highlight_x = (g_highlight_x + g_grid_size_x - 1) % g_grid_size_x
        elseif event == e_input.right then
            g_highlight_x = (g_highlight_x + 1) % g_grid_size_x
        elseif event == e_input.action_a or event == e_input.pointer_1 then
            g_active_x = g_highlight_x
            g_active_y = g_highlight_y
            update_ui_event(get_event_string(g_active_x + (g_active_y * g_grid_size_x)))
        end
    end

    if action == e_input_action.release then
        if event == e_input.back then
            update_set_screen_state_exit()
        end
    end
end

function input_pointer(is_hovered, x, y)
    g_is_pointer_hovered = is_hovered

    if is_hovered then
        g_pointer_pos_x = x
        g_pointer_pos_y = y
    end
end

function input_axis(x, y, z, w)
end
