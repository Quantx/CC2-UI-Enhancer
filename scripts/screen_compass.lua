
function begin()
    begin_load()
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    update_ui_image(0, 0, atlas_icons.screen_compass_background, color_white, 0)
    update_ui_rectangle(50, 28, 28, 12, color_white)
    update_ui_rectangle(51, 29, 26, 10, color_black)

    local this_vehicle = update_get_screen_vehicle()

    if this_vehicle:get() then
        local this_vehicle_bearing = this_vehicle:get_rotation_y();
        local this_vehicle_roll = this_vehicle:get_rotation_z();
        local this_vehicle_pitch = this_vehicle:get_rotation_x();

        if(this_vehicle_bearing < 0.0) then
            this_vehicle_bearing = this_vehicle_bearing + (math.pi * 2.0)
        end
    
        update_ui_image_rot(26 + 38, 42 + 38, atlas_icons.screen_compass_dial_pivot, color_white, -this_vehicle_bearing)
        
        update_ui_image_rot(26, 26, atlas_icons.screen_compass_tilt_side_pivot, color_white, -this_vehicle_roll)
    
        update_ui_image_rot(102, 26, atlas_icons.screen_compass_tilt_front_pivot, color_white, -this_vehicle_pitch)

        update_ui_text(0, 30, string.format("%.0f", this_vehicle_bearing * (360 / (math.pi * 2))), 128, 1, color_white, 0)
    end
    
    update_ui_line(11, 27, 41, 27, color8(205, 8, 246, 255))
    update_ui_line(87, 27, 117, 27, color8(205, 8, 246, 255))
    update_ui_image(26, 42, atlas_icons.screen_compass_dial_overlay, color_white, 0)
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