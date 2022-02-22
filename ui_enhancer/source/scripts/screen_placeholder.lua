g_region_icon = 0

function begin()
    begin_load()
    g_region_icon = begin_get_ui_region_index("microprose")
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    update_ui_image((screen_w / 2) - 37, (screen_h / 2) - 6, g_region_icon, color8(16, 16, 16, 255), 0)
end

function input_event(event, action)
    if action == e_input_action.release then
        if event == e_input.back then
            update_set_screen_state_exit()
        end
    end
end

function input_axis(x, y, z, w)
end
