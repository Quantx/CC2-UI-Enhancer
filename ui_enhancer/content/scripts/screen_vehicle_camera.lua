g_region_icon = 0

g_cam_x = 0
g_cam_y = 0
g_cam_z = 0
g_cam_rot = 0

function begin()
    begin_load()
    g_region_icon = begin_get_ui_region_index("microprose")
end

function update(screen_w, screen_h, ticks) 
    update_set_screen_background_type(0)
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    local screen_vehicle = update_get_screen_vehicle()

    update_set_screen_background_type(9)
    update_set_screen_camera_pos_orientation(g_cam_x, g_cam_y, g_cam_z, g_cam_rot)
    update_set_screen_camera_attach_vehicle(13, 0)

    local function render_crosshair(x, y, size_inner, size_outer)
        update_ui_push_offset(x, y)
        update_ui_rectangle(-size_outer, -size_outer, size_inner, 1, color_black)
        update_ui_rectangle(-size_outer, -size_outer, 1, size_inner, color_black)
        update_ui_rectangle(-size_outer, size_outer, size_inner, 1, color_black)
        update_ui_rectangle(-size_outer, size_outer, 1, -size_inner, color_black)
        update_ui_rectangle(size_outer, -size_outer, -size_inner, 1, color_black)
        update_ui_rectangle(size_outer, -size_outer, 1, size_inner, color_black)
        update_ui_rectangle(size_outer, size_outer, -size_inner, 1, color_black)
        update_ui_rectangle(size_outer, size_outer, 1, -size_inner, color_black)
        update_ui_pop_offset()
    end

    render_crosshair(screen_w / 2, screen_h / 2, 16, 64)
    render_crosshair(screen_w / 2, screen_h / 2, 8, 16)
    render_crosshair(screen_w / 2, screen_h / 2, 4, 0)
end

function input_event(event, action)
    if action == e_input_action.release then
        if event == e_input.back then
            update_set_screen_state_exit()
        end
    end
end

function input_axis(x, y, z, w)
    local forward_x = math.cos(-g_cam_rot) * x * 10
    local forward_z = math.sin(-g_cam_rot) * x * 10
    local side_x = math.cos(-g_cam_rot + math.pi * 0.5) * y * 10
    local side_z = math.sin(-g_cam_rot + math.pi * 0.5) * y * 10

    g_cam_x = g_cam_x + forward_x + side_x
    g_cam_z = g_cam_z + forward_z + side_z
    g_cam_y = g_cam_y + w * 10
    g_cam_rot = g_cam_rot + z * 0.1
end
