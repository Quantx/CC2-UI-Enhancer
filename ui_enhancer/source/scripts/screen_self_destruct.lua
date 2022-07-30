g_blink_timer = 0

function begin()
    begin_load()
end

function update(screen_w, screen_h, ticks) 

    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    local this_vehicle = update_get_screen_vehicle()
    if this_vehicle:get() == false then return end
    local this_vehicle_object = update_get_vehicle_by_id(this_vehicle:get_id())
    if this_vehicle_object:get() == false then return end

    g_blink_timer = g_blink_timer + 1
    if(g_blink_timer > 30)
    then 
        g_blink_timer = 0 
    end

    local active_mode = this_vehicle_object:get_self_destruct_mode()
    local countdown = this_vehicle_object:get_self_destruct_countdown()

    update_ui_rectangle_outline((screen_w/2)-20, (screen_h/2)-2, 40, 12, color_white)

    if active_mode == g_self_destruct_modes.locked then
        update_ui_text(0, screen_h/2, update_get_loc(e_loc.upp_lck), 128, 1, color_white, 0)
    elseif active_mode == g_self_destruct_modes.input then
        if g_blink_timer > 5 then
          update_ui_text(0, screen_h/2, string.format("%.2f", countdown / 30), 128, 1, color_white, 0)
        end
    elseif active_mode == g_self_destruct_modes.ready then
        col = color_status_warning
        update_ui_text(0, screen_h/2-12, update_get_loc(e_loc.upp_armed), 128, 1, color_white, 0)
        update_ui_text(0, screen_h/2, string.format("%.2f", countdown / 30), 128, 1, color_white, 0)
    end 
end

function input_event(event, action)
    if action == e_input_action.release then
        if event == e_input.back then
            update_set_screen_state_exit()
        end
    end
end