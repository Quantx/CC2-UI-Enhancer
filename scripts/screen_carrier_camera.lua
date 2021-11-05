g_is_exit = false
g_state_counter = 0
g_vehicle_id = 0

function update(screen_w, screen_h, ticks) 
    if update_get_is_focus_local() then
        g_state_counter = g_state_counter + 1
    else
        g_state_counter = 0
    end

    if g_state_counter > 1 then
        if g_is_exit then
            if g_vehicle_id ~= 0 then
                g_vehicle_id = 0
                g_state_counter = 0
            else
                g_is_exit = false
                g_state_counter = 0
                update_set_screen_state_exit()
            end
        elseif update_get_is_focus_local() and update_get_screen_state_active() then
            local vehicle = update_get_screen_vehicle()
    
            if vehicle:get() and g_vehicle_id ~= vehicle:get_id() then
                g_state_counter = 0
                g_vehicle_id = vehicle:get_id() 
            end
        end
    end
    
    update_set_screen_vehicle_control_id(g_vehicle_id)
    
    update_ui_rectangle(7, 6, screen_w / 2 - 9, screen_h - 13, color8(64, 128, 255, 255))
    update_ui_rectangle(screen_w / 2 + 2, 6, screen_w / 2 - 9, screen_h - 13, color8(64, 128, 255, 255))
end

function input_event(event, action)
    if action == e_input_action.release then
        if event == e_input.back then
            g_is_exit = true
            g_state_counter = 0
        end
    end
end
