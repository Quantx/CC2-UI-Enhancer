g_region_icon = 0
g_is_intro_shuttle_unlocked = false

function begin()
    begin_load()
    g_region_icon = begin_get_ui_region_index("microprose")
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    update_ui_text(5, 10, "Placeholder intro screen", screen_w, 1, color_white, 0)
    if g_is_intro_shuttle_unlocked == false then
        update_ui_text(0, 60, "Press E to continue", screen_w, 1, color_status_bad, 0)
    else
        update_ui_text(0, 60, "Shuttle door is now unlocked", screen_w, 1, color_status_ok, 0)
    end
    
end

function input_event(event, action)
    if action == e_input_action.press then
        if event == e_input.action_a then
            g_is_intro_shuttle_unlocked = true
        end
    end
    
    if action == e_input_action.release then
        if event == e_input.back then
            update_set_screen_state_exit()
        end
    end
end


function input_axis(x, y, z, w)
end
