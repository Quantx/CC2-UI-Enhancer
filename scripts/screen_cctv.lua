g_ui = nil
g_animation_time = 0
g_transition_time = 0
g_camera_index = 0
g_render_camera_index_prev = 0

function parse()
    g_camera_index = parse_s32("camera_index", g_camera_index)
end

function begin()
    begin_load()
    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks) 
    update_set_screen_background_type(0)
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    g_animation_time = g_animation_time + ticks
    g_transition_time = g_transition_time + ticks

    local ui = g_ui
    ui:begin_ui()

    local screen_vehicle = update_get_screen_vehicle()
    
    local render_camera_index = g_camera_index - 1
    local camera_cycle_seconds = 5

    if g_camera_index == 0 then
        render_camera_index = math.floor(g_animation_time / 30 / camera_cycle_seconds) % 2
    end

    if g_render_camera_index_prev ~= render_camera_index then
        g_transition_time = 0
    end

    g_render_camera_index_prev = render_camera_index

    local docking_vehicle = nil

    if screen_vehicle:get() then
        local dv_z = -1e309;

        local sf = render_camera_index == 0
        for i = iff(sf, 0,  8), iff(sf, 7, 15) do
            local id = screen_vehicle:get_attached_vehicle_id(i)
            if id ~= 0 then
                local v = update_get_map_vehicle_by_id(id)
                if v:get() then
                    local rp = update_get_map_vehicle_position_relate_to_parent_vehicle(screen_vehicle:get_id(), v:get_id())
                    local ds = v:get_dock_state()
                    if (ds == e_vehicle_dock_state.docking or ds == e_vehicle_dock_state.undocking) and rp:z() > dv_z then
                        docking_vehicle = v
                        dv_z = rp:z()
                    end
                end
            end
        end
    end

    if docking_vehicle ~= nil and docking_vehicle:get() then
        update_set_screen_background_type(9)
        update_set_screen_camera_attach_vehicle(docking_vehicle:get_id(), 0)

        update_set_screen_camera_cull_distance(1000)
        update_set_screen_camera_lod_level(0)
        update_set_screen_camera_render_attached_vehicle(true)
        update_set_screen_camera_is_render_ocean(true)
    elseif screen_vehicle:get() then
        update_set_screen_background_type(9)
        update_set_screen_camera_attach_vehicle(screen_vehicle:get_id(), render_camera_index)

        update_set_screen_camera_cull_distance(200)
        update_set_screen_camera_lod_level(0)
        update_set_screen_camera_render_attached_vehicle(true)
        update_set_screen_camera_is_render_ocean(false)
    end

    local border_l = 5
    local border_r = 5
    local border_t = 5
    local border_b = 5
    local border_col = color_black
    update_ui_rectangle(0, 0, border_l, screen_h, border_col)
    update_ui_rectangle(0, 0, screen_w, border_t, border_col)
    update_ui_rectangle(screen_w - border_r, 0, border_r, screen_h, border_col)
    update_ui_rectangle(0, screen_h - border_b, screen_w, border_b, border_col)

    local window = ui:begin_window(update_get_loc(e_loc.upp_cctv), border_l, border_t, screen_w - border_l - border_r, screen_h - border_t - border_b, atlas_icons.column_controlling_peer, true, 0, update_get_is_focus_local())
        local region_w, region_h = ui:get_region()
        local transition_duration = 10

        if g_transition_time < transition_duration then
            local transition_factor = g_transition_time / transition_duration
            update_ui_rectangle(0, region_h * transition_factor, region_w, region_h, color_black)
        end

		local title = iff(render_camera_index == 0, update_get_loc(e_loc.upp_surface), update_get_loc(e_loc.upp_air)) .. " HANGAR"

        if docking_vehicle ~= nil and docking_vehicle:get() then
            local name = get_chassis_data_by_definition_index(docking_vehicle:get_definition_index())
            title = name .. " " .. update_get_loc(e_loc.upp_id) .. " " .. tostring(docking_vehicle:get_id())
		end

		local title_w = update_ui_get_text_size( title, 10000, 0 ) + 4
		update_ui_rectangle(2, 2, title_w, 11, color_black)
		update_ui_text(4, 3, title, title_w, 0, color_grey_mid, 0)

        local button_h = 18

        update_ui_rectangle(0, region_h - button_h, region_w, button_h, color_black)
        update_ui_rectangle(0, region_h - button_h, region_w, 1, color_white)

        window.cy = region_h - button_h + 3
        local button_action = ui:button_group({ "<", "", "", "", "", ">" }, true)

        if button_action == 0 then
            g_camera_index = g_camera_index - 1
        elseif button_action == 1 then
            g_camera_index = g_camera_index + 1
        end

        g_camera_index = g_camera_index % 3

        local cam_names = { update_get_loc(e_loc.upp_auto), update_get_loc(e_loc.upp_surface), update_get_loc(e_loc.upp_air) }
        local cam_cols = { color_grey_dark, color_grey_mid, color_grey_mid }

        update_ui_text(0, region_h - button_h + 5, cam_names[g_camera_index + 1], region_w, 1, cam_cols[g_camera_index + 1], 0)
    ui:end_window()

    ui:end_ui()
end

function input_event(event, action)
    g_ui:input_event(event, action)

    if action == e_input_action.release then
        if event == e_input.back then
            update_set_screen_state_exit()
        end
    end
end

function input_axis(x, y, z, w)
    g_ui:input_scroll_gamepad(w)
end

function input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
end

function input_scroll(dy)
    g_ui:input_scroll(dy)
end

function wrap_range(val, min, max)
    return min + (val - min) % (max - min)
end
