g_is_connected = false
g_selected_attachment_index = -1
g_selected_target_id = -1
g_animation_time = 0
g_selected_target_id = 0
g_selected_target_type = 0
g_is_input_cycle_target_next = false
g_is_input_cycle_target_prev = false
g_is_map_overlay = false
g_active_attachment_time = 0

g_attachment_factors = {}
g_attachment_info_factor = 0
g_attachment_link_factor = 0
g_is_attachment_linked = false

g_selected_attachment_index_prev = -1
g_selected_definition_index_prev = -1
g_selected_camera_weapon_prev = 0
g_time_camera_weapon_set = 0
g_weapon_list_factor = 0

g_attachment_slot_size = vec2(18, 19)

g_gun_funnel_history = {}
g_gun_funnel_sample_time = 0

g_is_render_speed = true
g_is_render_altitude = true
g_is_render_fuel = true
g_is_render_hp = true
g_is_render_control_mode = true
g_is_render_compass = true

g_notification = {
    notification_vehicle_control_mode = {
        text = "",
        time = 0,
        col = color8(0, 255, 0, 255)
    },
    notification_attachment_control_mode = {
        text = "",
        time = 0,
        col = color8(0, 255, 0, 255)
    },
    notification_support_order_mode = {
        text = "",
        time = 0,
        col = color8(0, 255, 0, 255)
    },

    time = 0,

    vehicle_id_prev = 0,
    vehicle_control_mode_prev = "",
    attachment_control_mode_prev = "",
    selected_attachment_index_prev = -1,
    attachment_target_data_state_prev = nil,

    clear = function(self)
        self.notification_vehicle_control_mode.text = ""
        self.notification_attachment_control_mode.text = ""
        self.notification_support_order_mode.text = ""
        self.attachment_target_data_state_prev = nil
    end,

    update = function(self, delta_time, vehicle)
        self.time = self.time + delta_time

        if vehicle:get() and g_is_connected then
            local vehicle_id = vehicle:get_id()
            local vehicle_control_mode = vehicle:get_control_mode()
            local attachment_control_mode = ""
            local attachment_target_data_state = attachment_target_data_state_prev

            if vehicle_control_mode_prev ~= vehicle_control_mode then
                local notification_text = get_control_mode_loc(vehicle_control_mode) .. ": " .. update_get_loc(e_loc.hud_notification_vehicle)
                self:set_notification(self.notification_vehicle_control_mode, notification_text, get_control_mode_color(vehicle_control_mode))
            end

            local attachment = vehicle:get_attachment(g_selected_attachment_index)

            if attachment:get() then
                attachment_control_mode = attachment:get_control_mode()

                if attachment:get_is_weapon_target_data_set() then
                    attachment_target_data_state = attachment:get_weapon_target_state()
                else
                    attachment_target_data_state = e_team_target_state.cancelled
                end

                if selected_attachment_index_prev == g_selected_attachment_index and attachment:get_definition_index() ~= e_game_object_type.attachment_camera_vehicle_control then
                    if attachment_control_mode_prev ~= attachment_control_mode then
                        local notification_text = get_control_mode_loc(attachment_control_mode) .. ": " .. get_attachment_display_name(vehicle, attachment)
                        self:set_notification(self.notification_attachment_control_mode, notification_text, get_control_mode_color(attachment_control_mode))
                    end
                end
            end

            if attachment_target_data_state_prev ~= nil and attachment_target_data_state_prev ~= attachment_target_data_state then
                if (attachment_target_data_state_prev == e_team_target_state.pending or attachment_target_data_state_prev == e_team_target_state.active) and attachment_target_data_state == e_team_target_state.cancelled then
                    self:set_notification(self.notification_support_order_mode, update_get_loc(e_loc.support_cancelled), color8(255, 255, 0, 255))
                elseif attachment_target_data_state == e_team_target_state.complete then
                    self:set_notification(self.notification_support_order_mode, update_get_loc(e_loc.support_complete), color8(0, 255, 0, 255))
                elseif attachment_target_data_state == e_team_target_state.failed then
                    self:set_notification(self.notification_support_order_mode, update_get_loc(e_loc.support_failed), color8(255, 0, 0, 255))
                elseif attachment_target_data_state == e_team_target_state.pending or (attachment_target_data_state_prev ~= e_team_target_state.pending and attachment_target_data_state == e_team_target_state.active) then
                    self:set_notification(self.notification_support_order_mode, update_get_loc(e_loc.requesting_support).."...", color8(0, 255, 0, 255))
                end
            end

            if vehicle_id_prev ~= vehicle_id then
                self:clear()
            end

            vehicle_id_prev = vehicle_id
            vehicle_control_mode_prev = vehicle_control_mode
            attachment_control_mode_prev = attachment_control_mode
            selected_attachment_index_prev = g_selected_attachment_index
            attachment_target_data_state_prev = attachment_target_data_state
        else
            self:clear()
        end
    end,

    set_notification = function(self, notification, text, col)
        notification.text = text
        notification.time = self.time
        notification.col = col
    end,
}

function begin()
    begin_load()

    for i = 0, 15, 1 do
        g_attachment_factors[i] = 0
    end
end


--------------------------------------------------------------------------------
--
-- UPDATE
--
--------------------------------------------------------------------------------

function update(screen_w, screen_h, tick_fraction, delta_time, local_peer_id, vehicle, map_data)
    update_animations(delta_time, vehicle)
    g_notification:update(delta_time, vehicle)

    g_is_attachment_linked = false

    g_is_render_speed = true
    g_is_render_altitude = true
    g_is_render_fuel = true
    g_is_render_hp = true
    g_is_render_control_mode = true
    g_is_render_compass = true

    if vehicle:get() == nil or g_is_connected == false then
        update_add_ui_interaction(update_get_loc(e_loc.interaction_cancel), e_game_input.back)
    elseif g_is_map_overlay == false then
        update_add_ui_interaction(update_get_loc(e_loc.interaction_exit), e_game_input.back)
    end

    if vehicle:get() then
        if g_is_connected then
            Variometer:update(vehicle)
            local attachment = vehicle:get_attachment(g_selected_attachment_index)
            local is_attachment_render_center = false

            if g_is_map_overlay == false then
                if vehicle:get_attachment_count() > 1 and vehicle:get_definition_index() ~= e_game_object_type.chassis_carrier then
                    if update_get_active_input_type() == e_active_input.gamepad then
                        update_add_ui_interaction(update_get_loc(e_loc.interaction_select_attachment), e_game_input.select_attachment_prev)
                    elseif update_get_active_input_type() == e_active_input.keyboard then
                        update_add_ui_interaction(update_get_loc(e_loc.interaction_select_attachment), e_game_input.select_attachment_1)
                    end
                end
                
                update_add_ui_interaction(update_get_loc(e_loc.interaction_show_map), e_game_input.map_overlay)

                if attachment:get() then
                    if attachment:get_is_controllable() then
                        local control_mode = attachment:get_control_mode()

                        if control_mode == "auto" then
                            update_add_ui_interaction(update_get_loc(e_loc.interaction_manual), e_game_input.toggle_control_mode)
                        elseif control_mode == "manual" then
                            update_add_ui_interaction(update_get_loc(e_loc.interaction_auto), e_game_input.toggle_control_mode)
                            
                            if attachment:get_is_controlling_peer() and attachment:get_definition_index() == e_game_object_type.attachment_hardpoint_missile_tv and attachment:get_is_viewing_sub_camera() then
                                update_add_ui_interaction_special(update_get_loc(e_loc.interaction_throttle), e_ui_interaction_special.air_throttle)
                                update_add_ui_interaction_special(update_get_loc(e_loc.interaction_roll), e_ui_interaction_special.air_roll)
                                update_add_ui_interaction_special(update_get_loc(e_loc.interaction_pitch), e_ui_interaction_special.air_pitch)
                                update_add_ui_interaction_special(update_get_loc(e_loc.interaction_yaw), e_ui_interaction_special.air_yaw)
                            end
                            
                            if attachment:get_ammo_capacity() > 0 then
                                update_add_ui_interaction(update_get_loc(e_loc.interaction_fire), e_game_input.attachment_fire)
                            end
                        end
                    end
                end

                local attachment_control_camera = vehicle:get_attachment(0)

                if attachment_control_camera:get() and attachment_control_camera:get_definition_index() == e_game_object_type.attachment_camera_vehicle_control then
                    if vehicle:get_control_mode() == "manual" and attachment_control_camera:get_controlling_peer_id() == local_peer_id then
                        if get_is_vehicle_air(vehicle:get_definition_index()) then
                            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_throttle), e_ui_interaction_special.air_throttle)
                            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_roll), e_ui_interaction_special.air_roll)
                            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_pitch), e_ui_interaction_special.air_pitch)
                            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_yaw), e_ui_interaction_special.air_yaw)
                        else
                            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_throttle), e_ui_interaction_special.land_throttle)
                            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_steer), e_ui_interaction_special.land_steer)
                        end
                    end
                end
            else
                update_add_ui_interaction(update_get_loc(e_loc.interaction_hide_map), e_game_input.map_overlay)
            end
            
            if g_is_map_overlay == false then
                if attachment:get() then       
                    if attachment:get_definition_index() < e_game_object_type.count then
                        render_attachment_info(vec2(10, screen_h / 2 - 80), map_data, vehicle, attachment, 255, screen_w, screen_h)
                        is_render_center = render_attachment_hud(screen_w, screen_h, map_data, tick_fraction, vehicle, attachment, local_peer_id)
                    end
                end
            
                local def = vehicle:get_definition_index()
                
                if def == e_game_object_type.chassis_air_wing_light
                or def == e_game_object_type.chassis_air_wing_heavy
                or def == e_game_object_type.chassis_air_rotor_light 
                or def == e_game_object_type.chassis_air_rotor_heavy 
                then
                    render_flight_hud(screen_w, screen_h, is_render_center == false, vehicle)
                end

                if def == e_game_object_type.chassis_land_wheel_light
                or def == e_game_object_type.chassis_land_wheel_medium
                or def == e_game_object_type.chassis_land_wheel_heavy 
                or def == e_game_object_type.chassis_land_wheel_mule 
                or def == e_game_object_type.chassis_deployable_droid
                then
                    render_ground_hud(screen_w, screen_h, vehicle)
                end

                if def == e_game_object_type.chassis_sea_barge
                or def == e_game_object_type.chassis_sea_ship_light
                or def == e_game_object_type.chassis_sea_ship_heavy
                then
                    render_barge_hud(screen_w, screen_h, vehicle)
                end

                if def == e_game_object_type.chassis_carrier then
                    render_carrier_hud(screen_w, screen_h, vehicle)
                end
                
                if def == e_game_object_type.chassis_land_turret then
                    render_turret_hud(screen_w, screen_h, vehicle)
                end
            end

            render_attachment_hotbar(screen_w, screen_h, vehicle)
            render_notification(screen_w, screen_h)

            -- render_vehicle_info(vec2(screen_w - 100, screen_h - 65), vehicle)

            update_set_screen_background_type(0)

            if g_is_map_overlay then
                local map_x = 10
                local map_y = 40
                local map_w = screen_w - 20
                local map_h = screen_h - 50

                update_set_screen_background_clip(map_x, screen_h - map_y - map_h, map_w, map_h)
                update_set_screen_background_type(8)
                update_set_screen_background_tile_color_custom(color8(64, 64, 64, 255))
                update_set_screen_background_color(color8(0, 0, 0, 64))

                update_ui_push_clip(map_x, map_y, map_w, map_h)
                render_map_details(map_x, map_y, map_w, map_h, screen_w, screen_h, vehicle, attachment)
                update_ui_pop_clip()

                update_ui_rectangle_outline(map_x, map_y, map_w, map_h, color8(0, 255, 0, 255))
            end
        else
            render_connecting_overlay(screen_w, screen_h)
        end
    end
end

function update_animations(delta_time, vehicle)
    local selected_definition_index = -1

    if vehicle:get() and vehicle:get_attachment(g_selected_attachment_index):get() then
        local selected_attachment = vehicle:get_attachment(g_selected_attachment_index)
        selected_definition_index = selected_attachment:get_definition_index()

        local weapon_type = selected_attachment:get_weapon_target_type()

        if weapon_type ~= g_selected_camera_weapon_prev then
            g_time_camera_weapon_set = g_animation_time
            g_selected_camera_weapon_prev = weapon_type
        end
    end
    
    local anim_speed = 0.005
    
    g_animation_time = g_animation_time + delta_time
    g_active_attachment_time = g_active_attachment_time + delta_time

    for i = 0, 10, 1 do
        if g_selected_attachment_index == i then
            g_attachment_factors[i] = math.max(0.0, math.min(g_attachment_factors[i] + anim_speed * delta_time, 1.0))
        else
            g_attachment_factors[i] = math.max(0.0, math.min(g_attachment_factors[i] - anim_speed * delta_time, 1.0))
        end
    end

    local anim_speed_info = 0.0015
    g_attachment_info_factor = math.min(g_attachment_info_factor + anim_speed_info * delta_time, 1.0)

    local attachment_link_factor_target = iff(g_is_attachment_linked, 1, 0)
    g_attachment_link_factor = clamp(g_attachment_link_factor + clamp(attachment_link_factor_target - g_attachment_link_factor, -anim_speed * delta_time, anim_speed * delta_time), 0.0, 1.0)

    if g_selected_attachment_index_prev ~= g_selected_attachment_index then
        g_attachment_info_factor = 0
        g_gun_funnel_history = {}
        g_gun_funnel_sample_time = 0
        g_active_attachment_time = 0
        g_time_camera_weapon_set = -1
    end
    
    if g_selected_definition_index_prev ~= selected_definition_index then
        g_attachment_link_factor = 0
        g_time_camera_weapon_set = -1
    end
    
    if g_time_camera_weapon_set < 0 then
        g_weapon_list_factor = 0
    else
        local weapon_list_anim_time = g_animation_time - g_time_camera_weapon_set

        if weapon_list_anim_time < 1500 then
            g_weapon_list_factor = clamp(g_weapon_list_factor + delta_time / 150, 0, 1)
        else
            g_weapon_list_factor = clamp(g_weapon_list_factor - delta_time / 150, 0, 1)
        end
    end

    g_selected_definition_index_prev = selected_definition_index
    g_selected_attachment_index_prev = g_selected_attachment_index
end


--------------------------------------------------------------------------------
--
-- MAP OVERLAY RENDERING
--
--------------------------------------------------------------------------------

function render_map_details(x, y, w, h, screen_w, screen_h, screen_vehicle, attachment)
    local camera_x = screen_vehicle:get_position():x()
    local camera_y = screen_vehicle:get_position():z()
    local is_viewing_sub_camera = false
    
    if attachment:get() then
        attachment:get_is_viewing_sub_camera()
    end

    if is_viewing_sub_camera then
        camera_x = update_get_camera_position():x()
        camera_y = update_get_camera_position():z()
    end

    local camera_size = 5000
    update_set_screen_map_position_scale(camera_x, camera_y, camera_size)

    local function world_to_screen(x, y)
        return get_screen_from_world(x, y, camera_x, camera_y, camera_size, screen_w, screen_h)
    end

    local is_render_islands = (camera_size < (64 * 1024))
    update_set_screen_background_is_render_islands(is_render_islands)

    -- render tiles

    if is_render_islands then
        for _, tile in iter_tiles() do
            local tile_color = tile:get_team_color()
            local position_xz = tile:get_position_xz()
            local island_name = tile:get_name()
            local label_x, label_y = world_to_screen(position_xz:x(), position_xz:y() + 3000)
            update_ui_text(label_x - 64, label_y - 9, island_name, 128, 1, tile_color, 0)
        end
    else
        for _, tile in iter_tiles() do
            local tile_color = tile:get_team_color()
            local position_xz = tile:get_position_xz()
            local screen_x, screen_y = world_to_screen(position_xz:x(), position_xz:y())
            update_ui_image(screen_x - 4, screen_y - 4, atlas_icons.map_icon_island, tile_color, 0)
        end
    end

    local team_color = color_friendly
    local screen_x, screen_y = world_to_screen(camera_x, camera_y)
    local heading = update_get_camera_heading()
    local fov = update_get_camera_fov()
    local cone_length = 1000
    local p1 = vec2(math.sin(heading - fov / 2) * cone_length, -math.cos(heading - fov / 2) * cone_length)
    local p2 = vec2(math.sin(heading + fov / 2) * cone_length, -math.cos(heading + fov / 2) * cone_length)
    
    update_ui_begin_triangles()
    update_ui_add_triangle(vec2(screen_x, screen_y), vec2(screen_x + p2:x(), screen_y + p2:y()), vec2(screen_x + p1:x(), screen_y + p1:y()), color8(255, 255, 255, 30))
    update_ui_end_triangles()

    local p3 = vec2(math.sin(heading) * 32, -math.cos(heading) * 32)
    update_ui_line(screen_x, screen_y, screen_x + p1:x(), screen_y + p1:y(), color8(255, 255, 255, 64))
    update_ui_line(screen_x, screen_y, screen_x + p2:x(), screen_y + p2:y(), color8(255, 255, 255, 64))
    update_ui_line(screen_x, screen_y, screen_x + p3:x(), screen_y + p3:y(), color8(255, 255, 255, 64))

    if is_viewing_sub_camera then
        update_ui_image_rot(screen_x, screen_y, atlas_icons.map_icon_camera, color_friendly, 0)
    end
    
    local vehicle_dir = screen_vehicle:get_forward()
    local vehicle_dir_xz = vec2_normal(vec2(vehicle_dir:x(), vehicle_dir:z()))
    local screen_x, screen_y = world_to_screen(screen_vehicle:get_position():x(), screen_vehicle:get_position():z())
    update_ui_line(screen_x, screen_y, screen_x + vehicle_dir_xz:x() * 32, screen_y - vehicle_dir_xz:y() * 32, team_color)
    
    -- render vehicles

    local function filter_vehicles(v)
        local def = v:get_definition_index()
        return v:get_is_docked() == false and def ~= e_game_object_type.drydock and def ~= e_game_object_type.chassis_spaceship and v:get_is_observation_revealed()
    end

    for _, vehicle in iter_vehicles(filter_vehicles) do
        local icon_region, icon_offset = get_icon_data_by_definition_index(vehicle:get_definition_index())
        local position_xz = vehicle:get_position()
        local screen_x, screen_y = world_to_screen(position_xz:x(), position_xz:z())
        local vehicle_team = vehicle:get_team_id()

        local element_color = color8(16, 16, 16, 255)

        if vehicle_team == update_get_screen_team_id() then
            element_color = color_friendly
        else
            element_color = color_enemy
        end

        if vehicle:get_is_visible() then
            update_ui_image(screen_x - icon_offset, screen_y - icon_offset, icon_region, element_color, 0)
        else
            local last_known_position_xz, is_last_known_position_set = vehicle:get_vision_last_known_position_xz()

            if is_last_known_position_set then
                local screen_x, screen_y = world_to_screen(last_known_position_xz:x(), last_known_position_xz:y())
                update_ui_image(screen_x - 2, screen_y - 2, atlas_icons.map_icon_last_known_pos, element_color, 0)
            end
        end
    end

    update_ui_push_offset(x + 10, y + 10)
    local arrow_w = 8
    local arrow_h = 15
    local arrow_col = color8(0, 255, 0, 255)
    update_ui_line(0, arrow_w / 2, arrow_w / 2, 0, arrow_col)
    update_ui_line(arrow_w / 2, 0, arrow_w, arrow_w / 2, arrow_col)
    update_ui_line(arrow_w / 2, 0, arrow_w / 2, arrow_h, arrow_col)
    update_ui_text(0, arrow_h + 1, update_get_loc(e_loc.upp_compass_n), arrow_w, 1, arrow_col, 0)
    update_ui_pop_offset()

    if attachment:get() then
        local def = attachment:get_definition_index()

        if def == e_game_object_type.attachment_camera
        or def == e_game_object_type.attachment_camera_plane
        or def == e_game_object_type.attachment_camera_observation
        or def == e_game_object_type.attachment_turret_carrier_camera
        then
            if attachment:get_stabilisation_mode() == "tracking" then
                local hit_pos = attachment:get_hitscan_position()
                local screen_x, screen_y = world_to_screen(hit_pos:x(), hit_pos:z())

                update_ui_image(screen_x - 4, screen_y - 4, atlas_icons.column_laser, color8(0, 255, 0, 255), 0)
            end
        elseif def == e_game_object_type.attachment_turret_artillery then
            local artillery_pos, is_valid_artillery_hit = attachment:get_artillery_hit_position()

            if is_valid_artillery_hit then
                local screen_x, screen_y = world_to_screen(artillery_pos:x(), artillery_pos:z())

                screen_x = clamp( screen_x, x, x + w )
                screen_y = clamp( screen_y, y, y + h )

                update_ui_image(screen_x - 4, screen_y - 4, atlas_icons.column_laser, color8(0, 255, 0, 255), 0)
            end
        end
    end

    update_ui_push_offset(x, y)

    update_ui_text(10, h - 20, 
        string.format("x:%-6.0f ", camera_x) .. 
        string.format("y:%-6.0f ", camera_y),
        w - 10, 0, color8(0, 255, 0, 255), 0
    )

    update_ui_pop_offset()
end


--------------------------------------------------------------------------------
--
-- ATTACHMENT HOTBAR RENDERING
--
--------------------------------------------------------------------------------

function render_attachment_hotbar(screen_w, screen_h, vehicle)
    local attachment_count = get_vehicle_attachment_count(vehicle)

    for i = 0, attachment_count - 1, 1 do
        local attachment = vehicle:get_attachment(i)
        
        if attachment:get() then
            local cursor = get_attachment_slot_position(screen_w, attachment_count, i)

            local bay_color = color8(0, 255, 0, 255)
            if g_selected_attachment_index == i then bay_color = color8(255, 255, 255, 255) end
            
            render_bay_outline(cursor, g_attachment_slot_size, bay_color, g_attachment_factors[i])
            render_attachment_icon(vec2(cursor:x() + g_attachment_slot_size:x() / 2, cursor:y() + g_attachment_slot_size:y() / 2 - 1), vehicle, attachment, bay_color) 

            if attachment:get_is_controllable() and get_is_attachment_observation_camera_controlled(attachment:get_definition_index()) == false then
                update_ui_rectangle(cursor:x(), cursor:y() + g_attachment_slot_size:y(), g_attachment_slot_size:x(), 3, get_control_mode_color(attachment:get_control_mode()))
            end

            if g_selected_attachment_index == i then
                local selection_factor = clamp(1 - (g_active_attachment_time - 1000) / 1000, 0, 1)

                if selection_factor > 0 then
                    local hint_col = color8(0, 255, 0, math.floor(selection_factor * 255))
                    update_ui_text(0, cursor:y() + 23, get_attachment_display_name(vehicle, attachment), math.floor(screen_w / 2) * 2, 1, hint_col, 0)
                end
            end
        end
    end
end

function get_attachment_slot_position(screen_w, attachment_count, index) 
    local total_w = attachment_count * 19
    local cx = (screen_w - total_w) / 2
    return vec2(cx + 19 * index, 5) 
end

function render_bay_outline(pos, size, col, factor)
    update_ui_rectangle_outline(pos:x(), pos:y(), size:x(), size:y(), color8(col:r(), col:g(), col:b(), math.floor(col:a() * 0.5)))

    local w = size:x() * factor
    update_ui_rectangle(pos:x() + size:x() * 0.5 - w * 0.5, pos:y(), w, 1, col)
end

function render_attachment_icon(pos, vehicle, attachment, col)
    if attachment:get_definition_index() == e_game_object_type.attachment_camera_vehicle_control and get_is_vehicle_controllable(vehicle) then
        update_ui_image_rot(pos:x(), pos:y(), atlas_icons.hud_manual_control, col, 0)
    else
        local icon_region_l, icon_region_s = get_attachment_icons(attachment:get_definition_index())
    
        if icon_region_s ~= -1 then
            if attachment:get_ammo_capacity() > 0 and attachment:get_ammo_remaining() == 0 then
                update_ui_image_rot(pos:x(), pos:y(), icon_region_s, color8(255, 0, 0, 128), 0)
                update_ui_image_rot(pos:x(), pos:y(), atlas_icons.icon_attachment_16_unknown, color8(255, 0, 0, 255), 0)
            else
                update_ui_image_rot(pos:x(), pos:y(), icon_region_s, col, 0)
            end
        end
    end
end


--------------------------------------------------------------------------------
--
-- ATTACHMENT INFO RENDERING
--
--------------------------------------------------------------------------------

function render_attachment_info(info_pos, map_data, vehicle, attachment, alpha, screen_w, screen_h)
    local border_size = 3
    local pos = vec2(info_pos:x() + border_size, info_pos:y() + border_size)
    local ammo_capacity = attachment:get_ammo_capacity()
    local ammo_count = attachment:get_ammo_remaining()
    local bounds = vec2(0, 0)

    -- update_ui_push_clip()

    local colors = {
        green = color8(0, 255, 0, alpha),
        grey = color8(64, 64, 64, alpha),
        red = color8(255, 0, 0, alpha),
        yellow = color8(255, 255, 0, alpha),
    }

    -- Build list of linked attachments (i.e, attachments that will trigger when we trigger the current attachment)

    local linked_attachments = {}

    if attachment:get_is_control_linked() then
        for i = 0, vehicle:get_attachment_count() - 1 do
            local attachment_other = vehicle:get_attachment(i)

            if i ~= attachment:get_index() and attachment_other:get() and attachment_other:get_definition_index() == attachment:get_definition_index() and attachment_other:get_control_mode() == "manual" then
                table.insert(linked_attachments, attachment_other)
            end
        end
    end

    -- Render link between attachments

    if #linked_attachments > 0 then
        if attachment:get_control_mode() == "manual" then
            g_is_attachment_linked = true
        end

        local attachment_count = get_vehicle_attachment_count(vehicle)
        local link_min = get_attachment_slot_position(screen_w, attachment_count, attachment:get_index())
        local link_max = vec2(link_min:x(), link_min:y())

        local link_y = link_min:y() - 3
        local start_segment_factor = 1.0 - remap_clamp(g_attachment_link_factor, 0, 0.1, 0, 1)
        local mid_segment_factor = remap_clamp(g_attachment_link_factor, 0.1, 0.9, 0, 1)
        local end_segment_factor = remap_clamp(g_attachment_link_factor, 0.9, 1, 0, 1)

        local start_x = link_min:x() 
        update_ui_line(start_x + g_attachment_slot_size:x() / 2, link_y + 3 * start_segment_factor, start_x + g_attachment_slot_size:x() / 2, link_y + 3, color8(255, 255, 255, 255))

        for k, v in pairs(linked_attachments) do
            local other_pos = get_attachment_slot_position(screen_w, attachment_count, v:get_index()):x()
            link_min:x(math.min(link_min:x(), other_pos))
            link_max:x(math.max(link_max:x(), other_pos))

            update_ui_line(other_pos + g_attachment_slot_size:x() / 2, link_y, other_pos + g_attachment_slot_size:x() / 2, link_y + 3 * end_segment_factor, color8(255, 255, 255, 255))
        end

        local mid_x_min = lerp(start_x, link_min:x(), mid_segment_factor)
        local mid_x_max = lerp(start_x, link_max:x(), mid_segment_factor)
        update_ui_line(mid_x_min + g_attachment_slot_size:x() / 2, link_y, mid_x_max + g_attachment_slot_size:x() / 2, link_y, color8(255, 255, 255, 255))
    end

    update_ui_push_clip(pos:x(), pos:y(), 300, math.floor((screen_h - pos:y()) * g_attachment_info_factor))
    
    local attachment_def = attachment:get_definition_index()

    -- render vehicle id
    if vehicle:get_definition_index() ~= e_game_object_type.chassis_carrier then
        update_ui_text(pos:x(), pos:y(), update_get_loc(e_loc.upp_id) .. " " .. tostring(vehicle:get_id()), 200, 0, colors.green, 0)
        pos:y(pos:y() + 10)
    end

    if attachment_def ~= e_game_object_type.attachment_camera_vehicle_control then
        if get_is_attachment_observation_camera_controlled(attachment_def) then
            update_ui_image(pos:x(), pos:y(), atlas_icons.column_laser, colors.green, 0)
            update_ui_text(pos:x() + 12, pos:y(), update_get_loc(e_loc.upp_guided), 200, 0, colors.green, 0)
            pos:y(pos:y() + 10)
        elseif attachment:get_is_controllable() then
            update_ui_image(pos:x(), pos:y(), atlas_icons.column_control_mode, colors.green, 0)
            update_ui_text(pos:x() + 12, pos:y(), get_control_mode_loc(attachment:get_control_mode()), 200, 0, colors.green, 0)
            pos:y(pos:y() + 10)

            if attachment:get_type() == "camera" or attachment:get_type() == "turret" then
                if attachment_def ~= e_game_object_type.attachment_turret_robot_dog_capsule and attachment_def ~= e_game_object_type.attachment_turret_plane_chaingun and attachment_def ~= e_game_object_type.attachment_turret_rocket_pod and attachment_def ~= e_game_object_type.attachment_deployable_droid then
                    if attachment:get_type() == "turret" then
                        update_add_ui_interaction(update_get_loc(e_loc.interaction_zoom), e_game_input.attachment_primary)
                    end

                    if vehicle:get_definition_index() ~= e_game_object_type.chassis_land_turret then
                        update_ui_image(pos:x(), pos:y(), atlas_icons.column_stabilisation_mode, colors.green, 0)
                        update_ui_text(pos:x() + 12, pos:y(), get_stabilisation_mode_loc(attachment:get_stabilisation_mode()), 200, 0, colors.green, 0)
                        pos:y(pos:y() + 10)

                        update_add_ui_interaction(update_get_loc(e_loc.interaction_stabilisation), e_game_input.toggle_stabilisation_mode)
                    end
                end
            end
            
            if attachment:get_fuel_capacity() > 0 then
                update_ui_image(pos:x(), pos:y(), atlas_icons.column_fuel, colors.green, 0)
                update_ui_text(pos:x() + 12, pos:y(), string.format("%d/%d", attachment:get_fuel_remaining(), attachment:get_fuel_capacity()), 200, 0, colors.green, 0)
                pos:y(pos:y() + 10)
            end
        end
    end

    if update_get_is_multiplayer() then
        local controlling_peer_id = attachment:get_controlling_peer_id()

        if controlling_peer_id ~= 0 then
            local color = iff(attachment:get_is_controlling_peer(), colors.green, colors.red)
            local peer_index = update_get_peer_index_by_id(controlling_peer_id)
            local peer_name = update_get_peer_name(peer_index)
            local max_text_chars = 10
            local is_clipped = false

            if utf8.len(peer_name) > max_text_chars then
                peer_name = peer_name:sub(1, utf8.offset(peer_name, max_text_chars) - 1)
                is_clipped = true
            end

            local text_render_w, text_render_h = update_ui_get_text_size(peer_name, 200, 0)
            update_ui_image(pos:x(), pos:y(), atlas_icons.column_controlling_peer, color, 0)
            update_ui_text(pos:x() + 12, pos:y(), peer_name, 200, 0, color, 0)

            if is_clipped then
                update_ui_image(pos:x() + 12 + text_render_w, pos:y(), atlas_icons.text_ellipsis, color, 0)
            end
            
            pos:y(pos:y() + 10)
        end
    end
    
    -- Render ammo

    if ammo_capacity > 0 and vehicle:get_definition_index() ~= e_game_object_type.chassis_land_turret then   
        if attachment_def ~= e_game_object_type.attachment_turret_robot_dog_capsule and attachment_def ~= e_game_object_type.attachment_deployable_droid then 
            local ammo_col = iff(ammo_count > 0, colors.green, colors.red)

            update_ui_image(pos:x(), pos:y(), atlas_icons.column_ammo, ammo_col, 0)
            update_ui_text(pos:x() + 12, pos:y(), ammo_count .. "/" .. ammo_capacity, 200, 0, ammo_col, 0)
            pos:y(pos:y() + 10)

            if attachment:get_control_mode() == "manual" then
                for k, v in pairs(linked_attachments) do
                    local ammo_capacity = v:get_ammo_capacity()
                    local ammo_count = v:get_ammo_remaining()
                    
                    if ammo_capacity > 0 then
                        local ammo_col = iff(ammo_count > 0, colors.green, colors.red)
                        update_ui_image(pos:x(), pos:y(), atlas_icons.icon_tree_next, ammo_col, 0)
                        update_ui_text(pos:x() + 12, pos:y(), ammo_count .. "/" .. ammo_capacity, 200, 0, ammo_col, 0)
                        pos:y(pos:y() + 10)
                    end
                end
            end
        end
    end

    -- Render observation camera data
    if attachment_def == e_game_object_type.attachment_camera_observation
    or attachment_def == e_game_object_type.attachment_turret_carrier_camera
    or attachment_def == e_game_object_type.attachment_camera_plane
    then
        local weapon_type = attachment:get_weapon_target_type()
        local weapon_names = {
            [0] = update_get_loc(e_loc.upp_crs_msl),
            [1] = update_get_loc(e_loc.upp_crr_gun),
            [2] = update_get_loc(e_loc.upp_crr_flr),
            [3] = update_get_loc(e_loc.upp_gnd_art),
            [4] = update_get_loc(e_loc.upp_guided_msl)
        }

        local weapon_text = weapon_names[weapon_type] or update_get_loc(e_loc.upp_unknown)

        local is_target_data_set = attachment:get_is_weapon_target_data_set()
        local is_active = attachment:get_is_active()
        local is_target_data_complete = false
    
        if is_target_data_set then
            local target_state = attachment:get_weapon_target_state()
            is_target_data_complete = target_state == e_team_target_state.cancelled or target_state == e_team_target_state.complete or target_state == e_team_target_state.failed
        end
        
        local weapon_col = iff(is_active == false or is_target_data_complete, colors.green, colors.grey)
        update_ui_image(pos:x(), pos:y(), atlas_icons.column_weapon, weapon_col, 0)
        update_ui_text(pos:x() + 12, pos:y(), weapon_text, 200, 0, weapon_col, 0)
        pos:y(pos:y() + 10)

        local laser_mode_text = update_get_loc(e_loc.upp_ready)
        local laser_mode_col = colors.yellow

        if is_active and not is_target_data_complete then
            laser_mode_text = update_get_loc(e_loc.upp_engaged)
            laser_mode_col = colors.green
        end

        update_ui_image(pos:x(), pos:y(), atlas_icons.column_laser, laser_mode_col, 0)
        update_ui_text(pos:x() + 12, pos:y(), laser_mode_text, 200, 0, laser_mode_col, 0)
        pos:y(pos:y() + 10)

        update_add_ui_interaction(update_get_loc(e_loc.interaction_cycle_weapon), e_game_input.attachment_primary)

        if attachment:get_control_mode() == "manual" then
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_zoom), e_ui_interaction_special.vehicle_zoom)

            if is_target_data_set then
                update_add_ui_interaction(iff(is_target_data_complete or is_active == false, update_get_loc(e_loc.interaction_fire), update_get_loc(e_loc.interaction_cancel)), e_game_input.attachment_fire)
            else
                update_add_ui_interaction(iff(is_active, update_get_loc(e_loc.interaction_cancel), update_get_loc(e_loc.interaction_fire)), e_game_input.attachment_fire)
            end
        end
        
        if is_active == false or is_target_data_complete then
            if g_weapon_list_factor > 0 then
                local list_h = (#weapon_names + 1) * 10
                update_ui_push_offset(pos:x(), pos:y() + 10)
                update_ui_push_clip(0, 0, 200, math.ceil(list_h * g_weapon_list_factor))
                
                local cx = 0
                local cy = 0

                for i = 0, #weapon_names do
                    if i == weapon_type and g_animation_time % 250 < 125 then
                        update_ui_image(cx + 2, cy + 1, atlas_icons.text_back, color_white, 2)
                    end

                    update_ui_text(cx + 12, cy, weapon_names[i], 200, 0, iff(i == weapon_type, color_white, colors.green), 0)
                    cy = cy + 10
                end

                update_ui_pop_clip()
                update_ui_pop_offset()
            end
        end

        if is_target_data_set and g_weapon_list_factor == 0 then
            pos:y(pos:y() + 10)

            local state_names = {
                [e_team_target_state.pending] = update_get_loc(e_loc.upp_waiting).."...",
                [e_team_target_state.active] = update_get_loc(e_loc.upp_active),
                [e_team_target_state.complete] = update_get_loc(e_loc.upp_complete),
                [e_team_target_state.cancelled] = update_get_loc(e_loc.upp_cancelled),
                [e_team_target_state.failed] = update_get_loc(e_loc.upp_failed),
            }

            local error_names = {
                [e_team_target_error.none] = update_get_loc(e_loc.upp_none),
                [e_team_target_error.busy] = update_get_loc(e_loc.upp_busy),
                [e_team_target_error.no_ammo] = update_get_loc(e_loc.upp_no_ammo),
                [e_team_target_error.out_of_range] = update_get_loc(e_loc.upp_out_of_range),
                [e_team_target_error.inactive] = update_get_loc(e_loc.upp_inactive),
                [e_team_target_error.no_power] = update_get_loc(e_loc.upp_no_power),
                [e_team_target_error.damaged] = update_get_loc(e_loc.upp_damaged),
                [e_team_target_error.destroyed] = update_get_loc(e_loc.upp_destroyed),
                [e_team_target_error.unavailable] = update_get_loc(e_loc.upp_unavailable),
            } 

            local error_colors = {
                [e_team_target_error.none] = colors.grey,
                [e_team_target_error.busy] = colors.yellow,
                [e_team_target_error.no_ammo] = colors.red,
                [e_team_target_error.out_of_range] = colors.red,
                [e_team_target_error.inactive] = colors.red,
                [e_team_target_error.no_power] = colors.red,
                [e_team_target_error.damaged] = colors.red,
                [e_team_target_error.destroyed] = colors.red,
                [e_team_target_error.unavailable] = colors.red,
            } 

            local state_colors = {
                [e_team_target_state.pending] = colors.grey,
                [e_team_target_state.active] = colors.green,
                [e_team_target_state.complete] = colors.green,
                [e_team_target_state.cancelled] = colors.yellow,
                [e_team_target_state.failed] = colors.red,
            }

            local consuming_type_names = {
                [e_team_target_consuming_type.none] = "---",
                [e_team_target_consuming_type.attachment] = update_get_loc(e_loc.upp_wep),
                [e_team_target_consuming_type.missile] = update_get_loc(e_loc.upp_msl),
            }

            local consuming_type = attachment:get_weapon_target_consuming_type()
            local target_state = attachment:get_weapon_target_state()
            local target_error = attachment:get_weapon_target_error()
            local id, idx = attachment:get_weapon_target_consuming_id()

            update_ui_image(pos:x(), pos:y(), atlas_icons.column_pending, state_colors[target_state], 0)
            update_ui_text(pos:x() + 12, pos:y(), state_names[target_state], 100, 0, state_colors[target_state], 0)
            pos:y(pos:y() + 10)

            if target_state ~= e_team_target_state.complete and target_state ~= e_team_target_state.cancelled then
                if g_animation_time % 500 > 250 and target_error ~= e_team_target_error.none then
                    update_ui_image(pos:x(), pos:y(), atlas_icons.hud_warning, error_colors[target_error], 0)
                    update_ui_text(pos:x() + 12, pos:y(), error_names[target_error], 100, 0, error_colors[target_error], 0)
                end
            end

            pos:y(pos:y() + 10)

            if consuming_type == e_team_target_consuming_type.attachment then
                update_ui_text(pos:x() + 12, pos:y(), consuming_type_names[consuming_type] .. ":" .. id .. "[" .. idx .. "]", 200, 0, state_colors[target_state], 0)
                pos:y(pos:y() + 10)

                if target_state == e_team_target_state.active or target_state == e_team_target_state.complete then
                    local consuming_attachment = get_vehicle_attachment(id, idx)

                    if consuming_attachment ~= nil then
                        local ammo = consuming_attachment:get_ammo_remaining()

                        update_ui_image(pos:x(), pos:y(), atlas_icons.column_ammo, iff(ammo > 0, colors.green, colors.red), 0)
                        update_ui_text(pos:x() + 12, pos:y(), ammo, 200, 0, iff(ammo > 0, colors.green, colors.red), 0)
                        pos:y(pos:y() + 10)

                        local accuracy = consuming_attachment:get_target_accuracy()

                        update_ui_image(pos:x(), pos:y(), atlas_icons.column_laser, colors.green, 0)
                        update_ui_text(pos:x() + 12, pos:y(), string.format("%.0f%%", accuracy * 100), 200, 0, colors.green, 0)
                        pos:y(pos:y() + 10)
                    end
                end
            elseif consuming_type == e_team_target_consuming_type.missile then
                update_ui_text(pos:x() + 12, pos:y(), consuming_type_names[consuming_type], 200, 0, state_colors[target_state], 0)
                pos:y(pos:y() + 10)
    
                if target_state == e_team_target_state.failed then
                    if g_animation_time % 500 > 250 then
                        update_ui_text(pos:x() + 12, pos:y(), update_get_loc(e_loc.upp_destroyed), 200, 0, state_colors[target_state], 0)
                        pos:y(pos:y() + 10)
                    end
                elseif target_state == e_team_target_state.complete then
                    if g_animation_time % 500 > 250 then
                        update_ui_text(pos:x() + 12, pos:y(), update_get_loc(e_loc.upp_impact), 200, 0, state_colors[target_state], 0)
                        pos:y(pos:y() + 10)
                    end
                else
                    local consuming_missile = update_get_missile_by_id(id)
        
                    if consuming_missile:get() then
                        local hit_pos = attachment:get_hitscan_position()
                        local dist = vec3_dist(hit_pos, consuming_missile:get_position())
                        
                        update_ui_image(pos:x(), pos:y(), atlas_icons.column_laser, colors.green, 0)
                        update_ui_text(pos:x() + 12, pos:y(), string.format("%.0f", dist) .. update_get_loc(e_loc.acronym_meters), 200, 0, state_colors[target_state], 0)
                        pos:y(pos:y() + 10)
                    end
                end
            end
        end
    end

    -- Render control bot data

    if attachment_def == e_game_object_type.attachment_turret_robot_dog_capsule then
        pos:y(pos:y() + 10)
        
        local vehicle_pos = vehicle:get_position()
        local nearest_tile = map_data:get_closest_tile_id(vehicle_pos)

        local color_team_control = colors.green
        local text_team_control = "-"
        local text_team_capture = "-"
        local text_capture_progress = "-"

        if nearest_tile ~= -1 then
            local team_control, team_capture, capture_progress = map_data:get_tile_team_status(nearest_tile)

            if team_control ~= -1 then
                text_team_control = team_control

                if team_control ~= vehicle:get_team_id() then
                    color_team_control = colors.red
                end
            end
            
            if team_capture ~= -1 then
                text_team_capture = team_capture
            end

            if team_control ~= team_capture and team_capture ~= -1 then
                text_capture_progress = string.format("%.0f%%", capture_progress * 100)
            end
        end

        update_ui_image(pos:x(), pos:y(), atlas_icons.column_team_control, color_team_control, 0)
        update_ui_text(pos:x() + 12, pos:y(), text_team_control, 200, 0, color_team_control, 0)
        pos:y(pos:y() + 10)
        
        update_ui_image(pos:x(), pos:y(), atlas_icons.column_team_capture, colors.green, 0)
        update_ui_text(pos:x() + 12, pos:y(), text_team_capture, 200, 0, colors.green, 0)
        pos:y(pos:y() + 10)

        update_ui_image(pos:x(), pos:y(), atlas_icons.column_capture_progress, colors.green, 0)
        update_ui_text(pos:x() + 12, pos:y(), text_capture_progress, 200, 0, colors.green, 0)
        pos:y(pos:y() + 10)

       
    end

    bounds:x(80)
    bounds:y(pos:y() - info_pos:y())

    update_ui_pop_clip()
end

function render_notification(screen_w, screen_h)
    local function get_notification_factor(notification)
        local time = g_notification.time - notification.time

        if time < 250 then
            return time / 250
        else
            return 1 - clamp((time - 250 - 2000) / 250, 0, 1)
        end
    end

    local cy = 39
    local cx = screen_w / 2

    local function render_notification(notification, x, y)
        local factor = get_notification_factor(notification)

        if factor > 0 then
            local text_w, text_h = update_ui_get_text_size(notification.text, 1000, 1)

            update_ui_push_offset(x - text_w / 2 - 2, y)
            update_ui_push_clip(0, 0, text_w + 4, math.ceil((text_h + 4) * factor))
            update_ui_rectangle_outline(0, 0, text_w + 4, text_h + 4, notification.col)
            update_ui_text(0, 2, notification.text, text_w + 4, 1, notification.col, 0)
            update_ui_pop_clip()
            update_ui_pop_offset()

            cy = cy + (text_h + 4 + 2)
        end
    end

    if g_notification.notification_vehicle_control_mode.text ~= "" then
        render_notification(g_notification.notification_vehicle_control_mode, cx, cy)
    end

    if g_notification.notification_attachment_control_mode.text ~= "" then
        render_notification(g_notification.notification_attachment_control_mode, cx, cy)
    end
    
    if g_notification.notification_support_order_mode.text ~= "" then
        render_notification(g_notification.notification_support_order_mode, cx, cy)
    end
end

--------------------------------------------------------------------------------
--
-- ATTACHMENT HUDS
--
--------------------------------------------------------------------------------

function render_attachment_hud(screen_w, screen_h, map_data, tick_fraction, vehicle, attachment, local_peer_id)
    local def = attachment:get_definition_index()

    is_render_center = false
    if def == e_game_object_type.attachment_camera_vehicle_control
    then
        -- no special hud for vehicle control camera
    elseif def == e_game_object_type.attachment_camera
    or def == e_game_object_type.attachment_camera_plane
    or def == e_game_object_type.attachment_camera_observation
    or def == e_game_object_type.attachment_turret_carrier_camera
    then
        is_render_center = render_attachment_hud_camera(screen_w, screen_h, map_data, vehicle, attachment)
    elseif def == e_game_object_type.attachment_fuel_tank_plane then
        is_render_center = render_attachment_hud_fuel_tank(screen_w, screen_h, attachment)
    elseif def == e_game_object_type.attachment_turret_15mm
    or def == e_game_object_type.attachment_turret_30mm
    or def == e_game_object_type.attachment_turret_40mm
    or def == e_game_object_type.attachment_turret_heavy_cannon
    or def == e_game_object_type.attachment_turret_battle_cannon
    or def == e_game_object_type.attachment_turret_carrier_main_gun
    or def == e_game_object_type.attachment_turret_droid
    or def == e_game_object_type.attachment_turret_gimbal_30mm
    then
        is_render_center = render_attachment_hud_cannon(screen_w, screen_h, map_data, vehicle, attachment, def)
    elseif def == e_game_object_type.attachment_turret_artillery
    then
        is_render_center = render_attachment_hud_artillery(screen_w, screen_h, map_data, vehicle, attachment)
    elseif def == e_game_object_type.attachment_turret_plane_chaingun
    then
        is_render_center = render_attachment_hud_chaingun(screen_w, screen_h, map_data, tick_fraction, vehicle, attachment)
    elseif def == e_game_object_type.attachment_turret_ciws
    or def == e_game_object_type.attachment_turret_carrier_ciws
    then
        is_render_center = render_attachment_hud_ciws(screen_w, screen_h, map_data, vehicle, attachment)
    elseif def == e_game_object_type.attachment_turret_rocket_pod
    or def == e_game_object_type.attachment_turret_missile
    or def == e_game_object_type.attachment_hardpoint_missile_ir
    or def == e_game_object_type.attachment_hardpoint_missile_laser
    or def == e_game_object_type.attachment_hardpoint_missile_aa
    or def == e_game_object_type.attachment_turret_carrier_missile
    or def == e_game_object_type.attachment_turret_carrier_missile_silo
    then
        is_render_center = render_attachment_hud_missile(screen_w, screen_h, map_data, vehicle, attachment)
    elseif def == e_game_object_type.attachment_hardpoint_missile_tv
    then
        is_render_center = render_attachment_hud_tv_missile(screen_w, screen_h, map_data, vehicle, attachment)
    elseif def == e_game_object_type.attachment_radar_golfball
    then
        is_render_center = render_attachment_hud_radar(screen_w, screen_h, map_data, vehicle, attachment)
    elseif def == e_game_object_type.attachment_sonic_pulse_generator
    then
        is_render_center = render_attachment_hud_sonic_pulse(screen_w, screen_h, map_data, vehicle, attachment)
    elseif def == e_game_object_type.attachment_smoke_launcher_explosive
    or def == e_game_object_type.attachment_smoke_launcher_stream
    then
        is_render_center = render_attachment_hud_flare(screen_w, screen_h, map_data, vehicle, attachment)
    elseif def == e_game_object_type.attachment_hardpoint_bomb_1
    or def == e_game_object_type.attachment_hardpoint_bomb_2
    or def == e_game_object_type.attachment_hardpoint_bomb_3
    then
        is_render_center = render_attachment_hud_bomb(screen_w, screen_h, map_data, vehicle, attachment)
    elseif def == e_game_object_type.attachment_hardpoint_torpedo
    or def == e_game_object_type.attachment_hardpoint_torpedo_noisemaker
    or def == e_game_object_type.attachment_hardpoint_torpedo_decoy
    then
        is_render_center = render_attachment_hud_torpedo(screen_w, screen_h, vehicle, attachment)
    elseif def == e_game_object_type.attachment_turret_carrier_flare_launcher
    or def == e_game_object_type.attachment_flare_launcher
    then
        is_render_center = render_attachment_hud_flare(screen_w, screen_h, attachment)
    elseif def == e_game_object_type.attachment_radar_awacs then
        is_render_center = render_attachment_hud_radar(screen_w, screen_h, map_data, vehicle, attachment)
    elseif def == e_game_object_type.attachment_turret_robot_dog_capsule
    then
        is_render_center = render_attachment_hud_robot_dog(screen_w, screen_h, map_data, vehicle, attachment)
    elseif def == e_game_object_type.attachment_deployable_droid
    then
        is_render_center = render_attachment_hud_deployable_droid(screen_w, screen_h, map_data, vehicle, attachment)
    elseif def == e_game_object_type.attachment_turret_carrier_torpedo then
    elseif def == e_game_object_type.attachment_logistics_container_20mm then
    elseif def == e_game_object_type.attachment_logistics_container_30mm then
    elseif def == e_game_object_type.attachment_logistics_container_40mm then
    elseif def == e_game_object_type.attachment_logistics_container_100mm then
    elseif def == e_game_object_type.attachment_logistics_container_120mm then
    elseif def == e_game_object_type.attachment_logistics_container_fuel then
    elseif def == e_game_object_type.attachment_logistics_container_ir_missile then
    elseif def < e_game_object_type.count then
        update_ui_text(screen_w / 2, 20, update_get_loc(e_loc.unknown_attachment), 200, 0, color8(255, 0, 0, 255), 0)
    end

    return is_render_center
end

function render_attachment_hud_camera(screen_w, screen_h, map_data, vehicle, attachment)
    local hud_pos = vec2(screen_w / 2, screen_h / 2)
    local col = color8(0, 255, 0, 255)

    render_attachment_vision(screen_w, screen_h, map_data, vehicle, attachment)

    local outer_radius = 72
    local inner_radius = outer_radius - 5
    render_circle(hud_pos, inner_radius, 16, col)

    if attachment:get_is_zoom_capable() then
        local zoom_factor = attachment:get_zoom_factor()
        local angle = math.pi * 0.5 * zoom_factor
        update_ui_image_rot(hud_pos:x() + math.cos(angle - math.pi) * outer_radius, hud_pos:y() + math.sin(angle - math.pi) * outer_radius, atlas_icons.hud_zoom_indicator_2, col, angle)
        --update_ui_image_rot(hud_pos:x(), hud_pos:y() - 0.5, atlas_icons.hud_zoom_indicator, col, 0)
        update_ui_rectangle(hud_pos:x() - 1, hud_pos:y(), 3, 1, col)
        update_ui_rectangle(hud_pos:x(), hud_pos:y() - 1, 1, 3, col)

        if zoom_factor > 0.01 then
            render_circle(hud_pos, lerp(inner_radius, inner_radius * 0.9, zoom_factor), 16, col)
        end

        local zoom_power = zoom_factor * 5
        local display_zoom = 2 ^ zoom_power
        update_ui_text(hud_pos:x() + math.cos(math.pi * 0.75) * outer_radius - 200, hud_pos:y() + math.sin(math.pi * 0.75) * outer_radius, string.format("%.2fx", display_zoom), 200, 2, col, 0)
    end

    --local hit_pos = attachment:get_hitscan_position()
    --local dist = vec3_dist(update_get_camera_position(), hit_pos)
    --update_ui_text(hud_pos:x() + math.cos(math.pi * 0.25) * outer_radius, hud_pos:y() + math.sin(math.pi * 0.25) * outer_radius, string.format("%.0f", dist) .. update_get_loc(e_loc.acronym_meters), 200, 0, col, 0)
    
    local range_pos = vec2( (hud_pos:x() + math.cos(math.pi * 0.25) * outer_radius) - 40, (hud_pos:y() + math.sin(math.pi * 0.25) * outer_radius) - 50 )
    render_attachment_range(range_pos, attachment, true)
    render_camera_forward_axis(screen_w, screen_h, vehicle)

    return true
end

function render_attachment_hud_bomb(screen_w, screen_h, map_data, vehicle, attachment) 
    if attachment:get_control_mode() == "manual" then
        local linked_attachments = {}
        
        if attachment:get_is_control_linked() then
            for i = 0, vehicle:get_attachment_count() - 1 do
                local attachment_other = vehicle:get_attachment(i)

                if attachment_other:get() and attachment_other:get_definition_index() == attachment:get_definition_index() and attachment_other:get_control_mode() == "manual" and attachment_other:get_ammo_remaining() > 0 then
                    table.insert(linked_attachments, attachment_other)
                end
            end
        end

        for i = 1, #linked_attachments do
            local predicted_hit_pos = linked_attachments[i]:get_bomb_hit_position()
            local hit_pos_screen = update_world_to_screen(predicted_hit_pos)
        
            -- draw a line from our velocity vector to the CCIP point
            update_ui_line(
                    Variometer.predicted_vector.x,
                    Variometer.predicted_vector.y,
                    hit_pos_screen:x(),
                    hit_pos_screen:y(),
                    color8(0, 255, 0, 255))

            update_ui_image_rot(hit_pos_screen:x(), hit_pos_screen:y(), atlas_icons.hud_impact_marker, color8(0, 255, 0, 255), 0)
        end
    end

    render_attachment_vision(screen_w, screen_h, map_data, vehicle, attachment)

    return false
end

function render_attachment_hud_torpedo(screen_w, screen_h, vehicle, attachment) 
    if attachment:get_control_mode() == "manual" then
        local linked_attachments = {}
         
        if attachment:get_is_control_linked() then
            for i = 0, vehicle:get_attachment_count() - 1 do
                local attachment_other = vehicle:get_attachment(i)

                if attachment_other:get() and attachment_other:get_definition_index() == attachment:get_definition_index() and attachment_other:get_control_mode() == "manual" and attachment_other:get_ammo_remaining() > 0 then
                    table.insert(linked_attachments, attachment_other)
                end
            end
        end

        for i = 1, #linked_attachments do
            local predicted_hit_pos = linked_attachments[i]:get_bomb_hit_position()
            local hit_pos_screen = update_world_to_screen(predicted_hit_pos)
        
            update_ui_image_rot(hit_pos_screen:x(), hit_pos_screen:y(), atlas_icons.hud_impact_marker, color8(0, 255, 0, 255), 0)
        end
    end

    return false
end

function render_attachment_hud_missile(screen_w, screen_h, map_data, vehicle, attachment)
    local hud_pos = vec2(screen_w / 2, screen_h / 2)
    local col = color8(0, 255, 0, 255)
    
    render_attachment_vision(screen_w, screen_h, map_data, vehicle, attachment)
    if attachment:get_definition_index() == e_game_object_type.attachment_turret_missile then
        render_turret_vehicle_direction(screen_w, screen_h, vehicle, attachment, col)
    end

    update_ui_image_rot(hud_pos:x() + 1, hud_pos:y() + 1, atlas_icons.hud_horizon_cursor, col, 0)
    render_atachment_projectile_cooldown(hud_pos, attachment, true, color8(0, 255, 0, 255))

    return false
end

function render_attachment_hud_tv_missile(screen_w, screen_h, map_data, vehicle, attachment, local_peer_id)
    local function render_camera_crosshair(x, y, rad, size, col)
        update_ui_rectangle(x - rad, y - rad, 1, size, col)
        update_ui_rectangle(x - rad, y - rad, size, 1, col)
        update_ui_rectangle(x + rad, y - rad, 1, size, col)
        update_ui_rectangle(x + rad - size, y - rad, size, 1, col)
        update_ui_rectangle(x - rad, y + rad - size, 1, size, col)
        update_ui_rectangle(x - rad, y + rad, size, 1, col)
        update_ui_rectangle(x + rad, y + rad - size, 1, size, col)
        update_ui_rectangle(x + rad - size, y + rad, size + 1, 1, col)
    end
    
    local hud_pos = vec2(screen_w / 2, screen_h / 2)
    local col = color8(0, 255, 0, 255)
    local col_red = color8(255, 0, 0, 255)
    
    local is_viewing_missile = attachment:get_is_viewing_sub_camera()

    if is_viewing_missile then
        render_attachment_vision(screen_w, screen_h, map_data, vehicle, attachment)

        if g_animation_time % 500 > 250 then
            render_camera_crosshair(hud_pos:x(), hud_pos:y(), 48, 16, col)
        end

        render_camera_crosshair(hud_pos:x(), hud_pos:y(), 8, 4, col)

        local vehicle_pos = vehicle:get_position()
        local camera_pos = update_get_camera_position()
        local dist = vec3_dist(vehicle_pos, camera_pos)
        
        update_ui_image(hud_pos:x() - 100, hud_pos:y() + 50, atlas_icons.column_distance, col, 0)
        update_ui_text(hud_pos:x() - 100 + 12, hud_pos:y() + 50, string.format("%.0f", dist) .. update_get_loc(e_loc.acronym_meters), 200, 0, col, 0)
        update_ui_rectangle(hud_pos:x(), hud_pos:y() - 1, 1, 3, col)
        update_ui_rectangle(hud_pos:x() - 1, hud_pos:y(), 3, 1, col)

        if dist > 4000 then
            render_warning_text(hud_pos:x(), hud_pos:y() + 50, update_get_loc(e_loc.upp_range), col_red)
        end

        local hud_size = vec2(230, 140)
        local hud_min = vec2(hud_pos:x() - hud_size:x() / 2, hud_pos:y() - hud_size:y() / 2)
        render_altitude_meter(vec2(hud_min:x() + hud_size:x() - 16, hud_min:y() + (hud_size:y() - 110) / 2), camera_pos:y(), col)

        g_is_render_speed = false
        g_is_render_altitude = false
        g_is_render_fuel = false
        g_is_render_hp = false
        g_is_render_control_mode = false
        g_is_render_compass = true

        if attachment:get_control_mode() == "manual" and attachment:get_is_controlling_peer() then
            render_mouse_flight_axis(hud_pos)
        end

        return true
    else
        if attachment:get_ammo_remaining() > 0 then
            render_attachment_vision(screen_w, screen_h, map_data, vehicle, attachment)
            render_camera_crosshair(hud_pos:x(), hud_pos:y(), 48, 16, col)
            render_camera_crosshair(hud_pos:x(), hud_pos:y(), 8, 4, col)
            update_ui_image_rot(hud_pos:x() + 1, hud_pos:y() + 1, atlas_icons.hud_horizon_cursor, col, 0)

            return true
        else
            update_ui_image_rot(hud_pos:x() + 1, hud_pos:y() + 1, atlas_icons.hud_horizon_cursor, col, 0)
            return false
        end
    end
end

function render_attachment_hud_fuel_tank(screen_w, screen_h, attachment)
    return false
end

function render_attachment_hud_chaingun(screen_w, screen_h, map_data, tick_fraction, vehicle, attachment)
    local hud_pos = vec2(screen_w / 2, screen_h / 2)
    local col = color8(0, 255, 0, 255)
    render_attachment_vision(screen_w, screen_h, map_data, vehicle, attachment)
    
    local gun_funnel_side_dist = 5
    local gun_funnel_forward_dist = 30
    -- update_gun_funnel(tick_fraction, vehicle, gun_funnel_side_dist, gun_funnel_forward_dist)
    -- render_gun_funnel(tick_fraction, vehicle, gun_funnel_side_dist, gun_funnel_forward_dist, color8(0, 255, 0, 255))

    if g_selected_target_type == 1 and g_selected_target_id ~= 0 then
        local selected_target = update_get_map_vehicle_by_id(g_selected_target_id)

        if selected_target:get() then
            local lead_position = attachment:get_gun_lead_position(selected_target:get_position(), selected_target:get_linear_velocity())
            local lead_position_screen, is_clamped = update_world_to_screen(lead_position)

            if is_clamped == false then
                local target_pos_screen, is_target_clamped = update_world_to_screen(selected_target:get_position())

                if is_target_clamped == false then
                    local lead_col = color8(255, 0, 0, 200)
                    update_ui_line(target_pos_screen:x(), target_pos_screen:y(), lead_position_screen:x(), lead_position_screen:y(), lead_col)
                    update_ui_image_rot(lead_position_screen:x(), lead_position_screen:y(), atlas_icons.crosshair, lead_col, 0)
                end
            end
        end
    end

    update_ui_image_rot(hud_pos:x() + 1, hud_pos:y() + 1, atlas_icons.hud_gun_crosshair, col, 0)

    return false
end

function render_attachment_hud_ciws(screen_w, screen_h, map_data, vehicle, attachment)
    local hud_pos = vec2(screen_w / 2, screen_h / 2)
    local col = color8(0, 255, 0, 255)

    render_attachment_vision(screen_w, screen_h, map_data, vehicle, attachment)
    render_attachment_range(hud_pos, attachment)
    render_turret_vehicle_direction(screen_w, screen_h, vehicle, attachment, col)

    if g_selected_target_type == 1 and g_selected_target_id ~= 0 then
        local selected_target = update_get_map_vehicle_by_id(g_selected_target_id)

        if selected_target:get() then
            local lead_position = attachment:get_gun_lead_position(selected_target:get_position(), selected_target:get_linear_velocity())
            local lead_position_screen, is_clamped = update_world_to_screen(lead_position)

            if is_clamped == false then
                local target_pos_screen, is_target_clamped = update_world_to_screen(selected_target:get_position())

                if is_target_clamped == false then
                    local lead_col = color8(255, 0, 0, 200)
                    update_ui_line(target_pos_screen:x(), target_pos_screen:y(), lead_position_screen:x(), lead_position_screen:y(), lead_col)
                    update_ui_image_rot(lead_position_screen:x(), lead_position_screen:y(), atlas_icons.crosshair, lead_col, 0)
                end
            end
        end
    end

    update_ui_image_rot(hud_pos:x() + 1, hud_pos:y() + 1, atlas_icons.hud_gun_crosshair, col, 0)

    if attachment:get_is_zoom_capable() then
        local zoom_factor = attachment:get_zoom_factor()
        local zoom_power = zoom_factor * 3
        local display_zoom = 2 ^ zoom_power
        update_ui_text(hud_pos:x() - 250, hud_pos:y() + 50, string.format("%.2fx", display_zoom), 200, 2, col, 0)
    end

    return false
end

function render_atachment_projectile_cooldown(pos, attachment, is_heavy, col)
    local function bar_arc(pos, angle_from, angle_to, rad_inner, rad_outer, col)
        local step = math.pi / 16

        if angle_from > angle_to then
            local temp = angle_to
            angle_to = angle_from
            angle_from = temp
        end

        update_ui_begin_triangles()

        for angle = angle_from, angle_to, step do
            local angle_prev = angle
            local angle_next = math.min(angle + step, angle_to)
            local p0 = vec2(pos:x() + math.cos(angle_prev) * rad_inner, pos:y() + math.sin(angle_prev) * rad_inner)
            local p1 = vec2(pos:x() + math.cos(angle_prev) * rad_outer, pos:y() + math.sin(angle_prev) * rad_outer)
            local p2 = vec2(pos:x() + math.cos(angle_next) * rad_inner, pos:y() + math.sin(angle_next) * rad_inner)
            local p3 = vec2(pos:x() + math.cos(angle_next) * rad_outer, pos:y() + math.sin(angle_next) * rad_outer)
            update_ui_add_triangle(p0, p2, p1, col)
            update_ui_add_triangle(p1, p2, p3, col)
        end

        update_ui_end_triangles()
    end

    local projectile_cooldown = attachment:get_projectile_cooldown_factor()

    if projectile_cooldown < 1 then
        local bar_factor = 1 - projectile_cooldown
        local rad = 5
        local thickness = 1

        if is_heavy then
            rad = 8
            thickness = 2
        end

        bar_arc(vec2(pos:x(), pos:y() + 1), -math.pi, lerp(-math.pi, 0, bar_factor), rad, rad + thickness, col)
        bar_arc(vec2(pos:x(), pos:y()), 0, lerp(0, math.pi, bar_factor), rad, rad + thickness, col)
    end
end

function render_attachment_hud_cannon(screen_w, screen_h, map_data, vehicle, attachment, def) 
    local hud_pos = vec2(screen_w / 2, screen_h / 2)
    local col = color8(0, 255, 0, 255)
    local def = attachment:get_definition_index()

    render_attachment_vision(screen_w, screen_h, map_data, vehicle, attachment)
    render_attachment_range(hud_pos, attachment)
    render_turret_vehicle_direction(screen_w, screen_h, vehicle, attachment, col)

    update_ui_image_rot(hud_pos:x() + 1, hud_pos:y() + 1, atlas_icons.hud_horizon_cursor, col, 0)

    local is_heavy = def == e_game_object_type.attachment_turret_battle_cannon
                  or def == e_game_object_type.attachment_turret_carrier_main_gun
                  or def == e_game_object_type.attachment_turret_heavy_cannon

    render_atachment_projectile_cooldown(hud_pos, attachment, is_heavy, col)

    if attachment:get_is_zoom_capable() then
        local zoom_factor = attachment:get_zoom_factor()
        local zoom_power = zoom_factor * 3
        local display_zoom = 2 ^ zoom_power
        update_ui_text(hud_pos:x() - 250, hud_pos:y() + 50, string.format("%.2fx", display_zoom), 200, 2, col, 0)
        
        if (def == e_game_object_type.attachment_turret_battle_cannon or def == e_game_object_type.attachment_turret_heavy_cannon) and display_zoom > 1 then
            local projectile_gravity = 50 / 30
            local projectile_speed = 600
            local projectile_velocity = update_get_camera_forward()
            projectile_velocity:x(projectile_velocity:x() * projectile_speed)
            projectile_velocity:y(projectile_velocity:y() * projectile_speed)
            projectile_velocity:z(projectile_velocity:z() * projectile_speed)

            local step_amounts = { 1000, 500, 250, 100 }
--            if def == e_game_object_type.attachment_turret_heavy_cannon then step_amounts = { 800, 400, 200, 100 } end
            local step = step_amounts[math.floor(zoom_power) + 1]

            for i = step, step * 4, step do
                if i > 0 and i <= step_amounts[1] * 2 then
                    local travel_time = math.max(1, i) / (projectile_speed / 30)
                    local drop_position = update_get_camera_position()
                    drop_position:x(drop_position:x() + projectile_velocity:x() * travel_time)
                    drop_position:y(drop_position:y() + projectile_velocity:y() * travel_time - 0.5 * projectile_gravity * travel_time * travel_time)
                    drop_position:z(drop_position:z() + projectile_velocity:z() * travel_time)

                    local screen_pos = update_world_to_screen(drop_position)

                    if screen_pos:y() < hud_pos:y() + 60 then
                        update_ui_line(screen_w / 2 - 3, screen_pos:y(), screen_w / 2 + 2, screen_pos:y(), color8(0, 255, 0, 255))

                        if (i / step) % 2 == 0 then
                            update_ui_text(screen_w / 2 + 4, screen_pos:y() - 5, string.format("%d", i) .. update_get_loc(e_loc.acronym_meters), 64, 0, color8(0, 255, 0, 255), 0)
                        end
                    end
                end
            end
        end
    end

    return false
end

function render_attachment_hud_artillery(screen_w, screen_h, map_data, vehicle, attachment) 
    local hud_pos = vec2(screen_w / 2, screen_h / 2)
    local hud_size = vec2(180, 89)
    local col = color8(0, 255, 0, 255)

    render_turret_vehicle_direction(screen_w, screen_h, vehicle, attachment, col)
    render_attachment_vision(screen_w, screen_h, map_data, vehicle, attachment)

    update_ui_image_rot(hud_pos:x() + 1, hud_pos:y() + 1, atlas_icons.hud_horizon_cursor, col, 0)
    render_atachment_projectile_cooldown(hud_pos, attachment, true, col)

    if attachment:get_is_zoom_capable() then
        local zoom_factor = attachment:get_zoom_factor()
        local zoom_power = zoom_factor * 3
        local display_zoom = 2 ^ zoom_power
        update_ui_text(hud_pos:x() - 250, hud_pos:y() + 50, string.format("%.2fx", display_zoom), 200, 2, col, 0)
    end

    local cam_side = update_get_camera_side()
    local artillery_pos, is_valid_artillery_hit = attachment:get_artillery_hit_position()
    local hit_accuracy = 0

    if is_valid_artillery_hit then
        local hit_pos = attachment:get_hitscan_position()
        local hit_pos_to_artillery_pos = vec3(artillery_pos:x() - hit_pos:x(), artillery_pos:y() - hit_pos:y(), artillery_pos:z() - hit_pos:z())

        local cam_side_xz = vec3_normal(vec3(cam_side:x(), 0, cam_side:z()))

        local artillery_pos_distance = math.abs(vec3_dot(hit_pos_to_artillery_pos, cam_side_xz))
        artillery_pos_distance = math.max(artillery_pos_distance, math.abs(artillery_pos:y() - hit_pos:y()))
        hit_accuracy = (1 - clamp(artillery_pos_distance / 40, 0, 1)) * 100

        local shot_dist = vec3_dist( vehicle:get_position(), artillery_pos )
        update_ui_text(hud_pos:x() + 50, hud_pos:y() + 50, string.format("%.0f", shot_dist) .. update_get_loc(e_loc.acronym_meters), 200, 0, col, 0)
    end

    local roll = math.pi / 2 - math.acos(vec3_dot(cam_side, vec3(0, 1, 0)))

    update_ui_text(hud_pos:x() + hud_size:x() / 2 - 110, hud_pos:y() + hud_size:y() / 2 - 10, "R " .. string.format("%5.2f", math.deg(roll)), 100, 2, col, 0)
    update_ui_text(hud_pos:x() + hud_size:x() / 2 - 110, hud_pos:y() + hud_size:y() / 2 - 20, string.format("%.0f%%", hit_accuracy), 100, 2, col, 0)

    update_ui_line(hud_pos:x() - math.cos(roll) * 30, hud_pos:y() - math.sin(roll) * 30, hud_pos:x() - math.cos(roll) * 15, hud_pos:y() - math.sin(roll) * 15, col)
    update_ui_line(hud_pos:x() + math.cos(roll) * 30, hud_pos:y() + math.sin(roll) * 30, hud_pos:x() + math.cos(roll) * 15, hud_pos:y() + math.sin(roll) * 15, col)

    local is_blink_on = g_animation_time % 500 > 250
    local col_red = color8(255, 0, 0, 255)

    if is_valid_artillery_hit then
        local artillery_pos_screen = update_world_to_screen(artillery_pos)
        update_ui_image_rot(artillery_pos_screen:x(), artillery_pos_screen:y(), atlas_icons.hud_impact_marker, col, 0)
    end

    local cam_forward = update_get_camera_forward()
    cam_forward = vec3_normal(vec3(cam_forward:x(), 0, cam_forward:z()))
    local gun_forward = attachment:get_projectile_spawn_direction()
    local gun_angle = math.acos(clamp(vec3_dot(cam_forward, gun_forward), 0, 1))

    local angle_display_size = 20
    local angle_display_pos = vec2(hud_pos:x() - hud_size:x() * 0.5 + 10, hud_pos:y() + hud_size:y() * 0.5)
    update_ui_line(angle_display_pos:x(), angle_display_pos:y(), angle_display_pos:x() + angle_display_size, angle_display_pos:y(), col)
    update_ui_line(angle_display_pos:x(), angle_display_pos:y(), angle_display_pos:x() + math.cos(-gun_angle) * angle_display_size, angle_display_pos:y() + math.sin(-gun_angle) * angle_display_size, col)
    
    update_ui_line(
        math.floor(angle_display_pos:x() + math.cos(-gun_angle) * angle_display_size), 
        math.floor(angle_display_pos:y() + math.sin(-gun_angle) * angle_display_size), 
        math.floor(angle_display_pos:x() + math.cos(-gun_angle) * angle_display_size - math.cos(-gun_angle + math.pi / 4) * 5), 
        math.floor(angle_display_pos:y() + math.sin(-gun_angle) * angle_display_size - math.sin(-gun_angle + math.pi / 4) * 5),
        col
    )

    update_ui_line(
        math.floor(angle_display_pos:x() + math.cos(-gun_angle) * angle_display_size), 
        math.floor(angle_display_pos:y() + math.sin(-gun_angle) * angle_display_size), 
        math.floor(angle_display_pos:x() + math.cos(-gun_angle) * angle_display_size - math.cos(-gun_angle - math.pi / 4) * 5), 
        math.floor(angle_display_pos:y() + math.sin(-gun_angle) * angle_display_size - math.sin(-gun_angle - math.pi / 4) * 5),
        col
    )

    local angle_step = math.pi / 10
    local steps = gun_angle / angle_step
    local angle_size = angle_display_size * 0.6

    for i = 0, steps do
        local angle_0 = math.min(i * angle_step, gun_angle)
        local angle_1 = math.min(i * angle_step + angle_step, gun_angle)

        update_ui_line(
            math.floor(angle_display_pos:x() + math.cos(-angle_0) * angle_size), 
            math.floor(angle_display_pos:y() + math.sin(-angle_0) * angle_size), 
            math.floor(angle_display_pos:x() + math.cos(-angle_1) * angle_size), 
            math.floor(angle_display_pos:y() + math.sin(-angle_1) * angle_size), 
            col
        )
    end

    update_ui_text(angle_display_pos:x() + angle_display_size, angle_display_pos:y() - 10, string.format("%.1f", gun_angle / math.pi * 180), 200, 0, col, 0)

    return false
end

function render_attachment_hud_flare(screen_w, screen_h, attachment)
    return false
end

function render_attachment_hud_radar(screen_w, screen_h, map_data, vehicle, attachment)
    local hud_pos = vec2(screen_w / 2, screen_h / 2)
    local hud_size = vec2(180, 89)
    local hud_min = vec2(hud_pos:x() - hud_size:x() / 2, hud_pos:y() - hud_size:y() / 2)
    local hud_max = vec2(hud_pos:x() + hud_size:x() / 2, hud_pos:y() + hud_size:y() / 2)
    local col = color8(0, 255, 0, 255)
    local col_red = color8(255, 0, 0, 255)

    local is_disabled = attachment:get_is_radar_disabled()

    if is_disabled then
        render_warning_text(hud_pos:x(), hud_pos:y(), update_get_loc(e_loc.upp_interference), col_red)
        update_ui_image(hud_pos:x() - 7, hud_max:y() - 8, atlas_icons.icon_attachment_16_air_radar, color8(255, 0, 0, 255), 0)
        update_ui_text(hud_pos:x() - 128, hud_max:y() + 8, update_get_loc(e_loc.upp_radar_disabled), 256, 1, color8(255, 0, 0, 255), 0)
    else
        render_attachment_vision(screen_w, screen_h, map_data, vehicle, attachment)

        update_ui_push_clip(hud_min:x(), hud_min:y(), hud_size:x(), hud_size:y())
    
        for i = 0, 2 do
            local factor = ((g_animation_time + 2000 / 3 * i) % 2000) / 2000
            local rad =  hud_size:x() / 8 * factor ^ 0.75

            if rad > 8 then
                render_circle(vec2(hud_pos:x(), hud_max:y() - 1), rad, 16, color8(0, 255, 0, 255 - math.floor(factor ^ 4.0 * 255)))
            end
        end
    
        update_ui_pop_clip()

        update_ui_image(hud_pos:x() - 7, hud_max:y() - 8, atlas_icons.icon_attachment_16_air_radar, col, 0)
        update_ui_text(hud_pos:x() - 128, hud_max:y() + 8, update_get_loc(e_loc.upp_radar_active), 256, 1, col, 0)
    end

    return true
end

function render_attachment_hud_sonic_pulse(screen_w, screen_h, map_data, vehicle, attachment)
    local hud_pos = vec2(screen_w / 2, screen_h / 2)
    local hud_size = vec2(180, 89)
    local hud_min = vec2(hud_pos:x() - hud_size:x() / 2, hud_pos:y() - hud_size:y() / 2)
    local hud_max = vec2(hud_pos:x() + hud_size:x() / 2, hud_pos:y() + hud_size:y() / 2)
    local col = color8(0, 255, 0, 255)

    render_attachment_vision(screen_w, screen_h, map_data, vehicle, attachment)

    return true
end

function render_attachment_hud_robot_dog(screen_w, screen_h, map_data, vehicle, attachment)
    local hud_pos = vec2(screen_w / 2, screen_h / 2)
    local hud_size = vec2(180, 89)
    local hud_min = vec2(hud_pos:x() - hud_size:x() / 2, hud_pos:y() - hud_size:y() / 2)
    local hud_max = vec2(hud_pos:x() + hud_size:x() / 2, hud_pos:y() + hud_size:y() / 2)
    local col = color8(0, 255, 0, 255)
    
    local ammo = attachment:get_ammo_remaining()

    local render_capsule = function(x, y, is_deployed)
        update_ui_push_offset(x, y)
        update_ui_image(0, 0, iff(is_deployed, atlas_icons.hud_capsule_deployed, atlas_icons.hud_capsule_armed), col, 0)
        update_ui_text(8 - 100, 32, iff(is_deployed, update_get_loc(e_loc.upp_empty), update_get_loc(e_loc.upp_armed)), 200, 1, col, 0)
        update_ui_pop_offset()
    end
    
    render_capsule(hud_min:x() + 15, hud_max:y() - 30, ammo < 1)
    render_capsule(hud_max:x() - 30, hud_max:y() - 30, ammo < 1)

    return false
end

function render_attachment_hud_deployable_droid(screen_w, screen_h, map_data, vehicle, attachment)
    local hud_pos = vec2(screen_w / 2, screen_h / 2)
    local hud_size = vec2(180, 89)
    local hud_min = vec2(hud_pos:x() - hud_size:x() / 2, hud_pos:y() - hud_size:y() / 2)
    local hud_max = vec2(hud_pos:x() + hud_size:x() / 2, hud_pos:y() + hud_size:y() / 2)
    local col = color8(0, 255, 0, 255)

    local ammo = attachment:get_ammo_remaining()
    local deploy_factor = attachment:get_target_accuracy()
    local deploy_factor_pivot = 1 - invlerp_clamp(deploy_factor, 0, 0.5)
    local deploy_factor_slide = invlerp_clamp(deploy_factor, 0.5, 0.9)
    local is_deployed = ammo < 1
    local is_deploying = is_deployed == false and deploy_factor > 0

    local deploy_col = iff(is_deployed, color_status_bad, iff(is_deploying, color_status_warning, col))

    update_ui_push_offset(hud_min:x() + 14, hud_max:y() - 22)
    update_ui_rectangle(-4, 0, 1, 22, deploy_col)
    update_ui_rectangle(20, 0, 1, 22, deploy_col)
    update_ui_rectangle(-4, 22, 25, 1, deploy_col)

    update_ui_push_offset(0, -18 * deploy_factor_slide)

    update_ui_rectangle(-1, 0, 1, 20, deploy_col)
    update_ui_rectangle(17, 0, 1, 20, deploy_col)
    update_ui_rectangle(-1, 20, 19, 1, deploy_col)

    if is_deployed == false then
        local function round_to(a, b)
            return math.floor(a / b + 0.5) * b
        end

        local icon_col = iff(is_deployed, color_status_bad, iff(is_deploying, iff(g_animation_time % 500 > 250, color_status_warning, color_empty), col))
        update_ui_image_rot(8, 10, atlas_icons.icon_chassis_16_droid, icon_col, round_to(-math.pi * 0.5 * deploy_factor_pivot, math.pi / 4))
    end

    update_ui_pop_offset()

    update_ui_text(9 - 100, 24, iff(is_deployed, update_get_loc(e_loc.upp_empty), update_get_loc(e_loc.upp_armed)), 200, 1, iff(is_deployed, color_status_bad, col), 0)
    update_ui_pop_offset()

    return false
end

--------------------------------------------------------------------------------
--
-- VEHICLE HUDS
--
--------------------------------------------------------------------------------

function render_ground_hud(screen_w, screen_h, vehicle)
    local hud_size = vec2(230, 140)
    local hud_min = vec2((screen_w - hud_size:x()) / 2, (screen_h - hud_size:y()) / 2)
    local hud_pos = vec2(hud_min:x() + hud_size:x() / 2, hud_min:y() + hud_size:y() / 2)
    local col = color8(0, 255, 0, 255)

    render_airspeed_meter(vec2(hud_min:x(), hud_min:y() + (hud_size:y() - 110) / 2), vehicle, 1, col)
    render_compass(vec2(hud_pos:x(), hud_min:y() + hud_size:y()), col)
    render_fuel_gauge(vec2(hud_min:x() + hud_size:x() - 16, hud_pos:y() + 45 - 50), 50, vehicle, col)
    render_damage_gauge(vec2(hud_min:x() + hud_size:x() - 1, hud_pos:y() + 45 - 50), 50, vehicle, col)
    render_control_mode(vec2(hud_min:x() + hud_size:x() - 16, hud_pos:y() + 45 + 5), vehicle, col)

    local def = vehicle:get_definition_index()

    if g_selected_attachment_index == 0 and def ~= e_game_object_type.chassis_land_wheel_mule then
        local turret_index = iff(def == e_game_object_type.chassis_land_wheel_heavy, 2, 1)
        local turret = get_vehicle_attachment(vehicle:get_id(), turret_index)
        if turret ~= nil then
            -- Don't render for the following since they're not turrets
            local turret_def = turret:get_definition_index()
            if  turret_def >= 0 and turret_def < e_game_object_type.count -- Don't render for unknown turrets
            and turret_def ~= e_game_object_type.attachment_turret_robot_dog_capsule
            and turret_def ~= e_game_object_type.attachment_camera_observation
            and turret_def ~= e_game_object_type.attachment_radar_golfball
            then
                render_vehicle_turret_direction(screen_w, screen_h, vehicle, turret, col)
            end
        end
    end

    if get_is_damage_warning(vehicle) then
        local col_red = color8(255, 0, 0, 255)
        render_warning_text(hud_pos:x(), hud_min:y() - 10, update_get_loc(e_loc.upp_dmg_critical), col_red)
    end
    
    if get_is_fuel_warning(vehicle) then
        render_warning_text(hud_pos:x(), warning_y, "FUEL LOW", col_red)
        warning_y = warning_y - 10
    end
end

function render_turret_hud(screen_w, screen_h, vehicle)
    local hud_size = vec2(230, 140)
    local hud_min = vec2((screen_w - hud_size:x()) / 2, (screen_h - hud_size:y()) / 2)
    local hud_pos = vec2(hud_min:x() + hud_size:x() / 2, hud_min:y() + hud_size:y() / 2)
    local col = color8(0, 255, 0, 255)

    render_compass(vec2(hud_pos:x(), hud_min:y() + hud_size:y()), col)
    render_damage_gauge(vec2(hud_min:x() + hud_size:x() - 1, hud_pos:y() + 45 - 50), 50, vehicle, col)

    if get_is_damage_warning(vehicle) then
        local col_red = color8(255, 0, 0, 255)
        render_warning_text(hud_pos:x(), hud_min:y() - 10, update_get_loc(e_loc.upp_dmg_critical), col_red)
    end
end

function render_flight_hud(screen_w, screen_h, is_render_center, vehicle)
    local hud_size = vec2(230, 140)
    local hud_min = vec2((screen_w - hud_size:x()) / 2, (screen_h - hud_size:y()) / 2)
    local hud_pos = vec2(hud_min:x() + hud_size:x() / 2, hud_min:y() + hud_size:y() / 2)
    local col = color8(0, 255, 0, 255)
    local col_red = color8(255, 0, 0, 255)

    local warning_y = hud_min:y() - 10
    local is_missile_tracking = vehicle:get_is_missile_tracking()
    local is_stall = vehicle:get_position():y() > 2050

    if get_is_damage_warning(vehicle) then
        render_warning_text(hud_pos:x(), warning_y, update_get_loc(e_loc.upp_dmg_critical), col_red)
        warning_y = warning_y - 10
    end
    
    if is_missile_tracking then
        render_warning_text(hud_pos:x(), warning_y, update_get_loc(e_loc.upp_msl_incoming), col_red)
        warning_y = warning_y - 10
    end

    if is_stall then
        render_warning_text(hud_pos:x(), warning_y, update_get_loc(e_loc.upp_stall), col_red)
        warning_y = warning_y - 10
    end
    
    if get_is_fuel_warning(vehicle) then
        render_warning_text(hud_pos:x(), warning_y, "FUEL LOW", col_red)
        warning_y = warning_y - 10
    end

    if g_is_render_speed then
        render_airspeed_meter(vec2(hud_min:x(), hud_min:y() + (hud_size:y() - 110) / 2), vehicle, 10, col)
    end

    if g_is_render_altitude then
        render_altitude_meter(vec2(hud_min:x() + hud_size:x() - 16, hud_min:y() + (hud_size:y() - 110) / 2), vehicle:get_altitude(), col)
    end

    if is_render_center then
        render_artificial_horizion(screen_w, screen_h, hud_pos, vec2(hud_size:x() - 40, hud_size:y()), vehicle, col)
    end

    if g_is_render_compass then
        render_compass(vec2(hud_pos:x(), hud_min:y() + hud_size:y()), col)
    end

    if g_is_render_fuel then
        render_fuel_gauge(vec2(hud_min:x() + hud_size:x() + 30, hud_pos:y() + 45 - 50), 50, vehicle, col)
    end

    if g_is_render_hp then
        render_damage_gauge(vec2(hud_min:x() + hud_size:x() + 45, hud_pos:y() + 45 - 50), 50, vehicle, col)
    end

    if g_is_render_control_mode then
        render_control_mode(vec2(hud_min:x() + hud_size:x() + 30, hud_pos:y() + 45 + 5), vehicle, col)
    end
    
    if vehicle:get_control_mode() == "manual" and vehicle:get_is_controlling_peer() then
        render_mouse_flight_axis(hud_pos)
    end
end

function render_barge_hud(screen_w, screen_h, vehicle)
    local hud_size = vec2(230, 140)
    local hud_min = vec2((screen_w - hud_size:x()) / 2, (screen_h - hud_size:y()) / 2)
    local hud_pos = vec2(hud_min:x() + hud_size:x() / 2, hud_min:y() + hud_size:y() / 2)
    local col = color8(0, 255, 0, 255)
    local col_red = color8(255, 0, 0, 255)

    render_airspeed_meter(vec2(hud_min:x(), hud_min:y() + (hud_size:y() - 110) / 2), vehicle, 1, col)
    render_compass(vec2(hud_pos:x(), hud_min:y() + hud_size:y()), col)
    render_fuel_gauge(vec2(hud_min:x() + hud_size:x() - 16, hud_pos:y() + 45 - 50), 50, vehicle, col)
    render_damage_gauge(vec2(hud_min:x() + hud_size:x() - 1, hud_pos:y() + 45 - 50), 50, vehicle, col)
    render_control_mode(vec2(hud_min:x() + hud_size:x() - 16, hud_pos:y() + 45 + 5), vehicle, col)

    if get_is_damage_warning(vehicle) then
        render_warning_text(hud_pos:x(), hud_min:y() - 10, update_get_loc(e_loc.upp_dmg_critical), col_red)
    end
end

function render_carrier_hud(screen_w, screen_h, vehicle)
    local hud_size = vec2(230, 140)
    local hud_min = vec2((screen_w - hud_size:x()) / 2, (screen_h - hud_size:y()) / 2)
    local hud_pos = vec2(hud_min:x() + hud_size:x() / 2, hud_min:y() + hud_size:y() / 2)
    local col = color8(0, 255, 0, 255)

    if g_is_render_compass then
        render_compass(vec2(hud_pos:x(), hud_min:y() + hud_size:y()), col)
    end
end


--------------------------------------------------------------------------------
--
-- SPECIALIST HUD ELEMENTS
--
--------------------------------------------------------------------------------

-- Render turret direction relative to driver
function render_vehicle_turret_direction(screen_w, screen_h, vehicle, turret, col)
    local turret_def = turret:get_definition_index()
    local attachment_icon_region, attachment_16_icon_region = get_attachment_icons(turret_def)
--  local icon_w, icon_h = update_ui_get_image_size(attachment_icon_region)

    local hud_size = vec2(230, 140) 
    local hud_min = vec2((screen_w - hud_size:x()) / 2, (screen_h - hud_size:y()) / 2)
    local hud_pos = vec2(hud_min:x() + hud_size:x() / 2, hud_min:y() + hud_size:y() / 2)

    local pos_x = hud_min:x() + hud_size:x() - 6
    local pos_y = hud_pos:y() - 30
    
    local vehicle_pos = vehicle:get_position()
    local vehicle_dir = vehicle:get_forward()
    local turret_hit_pos = turret:get_hitscan_position()
    
    local turret_ang = math.atan( turret_hit_pos:x() - vehicle_pos:x(), turret_hit_pos:z() - vehicle_pos:z() )
    local vehicle_ang = math.atan( vehicle_dir:x(), vehicle_dir:z() )
    
    local projectile_cooldown = math.floor(clamp((1 - turret:get_projectile_cooldown_factor()) * 255, 0, 255))
    local turret_col = color8(projectile_cooldown, 255, projectile_cooldown, 255)
    
    update_ui_image_rot( pos_x, pos_y, atlas_icons.hud_ticker_small, col, -(math.pi / 2) )
    
    if turret_def == e_game_object_type.attachment_turret_missile then
        update_ui_image_rot( pos_x, pos_y - 4, attachment_icon_region, turret_col, -(math.pi / 2) )
    elseif turret_def == e_game_object_type.attachment_turret_droid then
        update_ui_image_rot( pos_x, pos_y - 2, attachment_icon_region, turret_col, turret_ang - vehicle_ang )
    else
        local off_x = math.sin(turret_ang - vehicle_ang) * 4
        local off_y = math.cos(turret_ang - vehicle_ang) * 4
        
        update_ui_image_rot( pos_x + off_x, pos_y - off_y, attachment_icon_region, turret_col, turret_ang - vehicle_ang )
    end
end

function render_attachment_range(hud_pos, attachment, is_camera)
    local hit_dist = iff( is_camera, vec3_dist(update_get_camera_position(), attachment:get_hitscan_position()), attachment:get_hitscan_distance() )
    local is_in_range = iff( is_camera, hit_dist <= 9999, attachment:get_is_hitscan_in_range() )
    local col = color8(0, 255, 0, 255)
    local col_red = color8(255, 0, 0, 255)

    if is_in_range then
        update_ui_text(hud_pos:x() + 50, hud_pos:y() + 50, string.format("%.0f", hit_dist) .. update_get_loc(e_loc.acronym_meters), 200, 0, col, 0)
    else
        local text = update_get_loc(e_loc.upp_range)

        if g_animation_time % 1000 <= 500 then
            text = string.format("%.0f", hit_dist) .. update_get_loc(e_loc.acronym_meters)
        end

        local text_w = update_ui_get_text_size(text, 200, 2)
        local pos_x = hud_pos:x() + 80

        if g_animation_time % 500 > 250 then
            update_ui_image(pos_x - text_w - 10, hud_pos:y() + 50, atlas_icons.hud_warning, col_red, 0)
        end

        update_ui_text(pos_x - 200, hud_pos:y() + 50, text, 200, 2, col_red, 0)
    end
end

function render_warning_text(x, y, text, col)
    update_ui_push_offset(x, y)

    if g_animation_time % 250 > 125 then
        local text_w = update_ui_get_text_size(text, 10000, 0)
        update_ui_image(-text_w / 2 - 12, 0, atlas_icons.hud_warning, col, 0)
        update_ui_image(text_w / 2 + 2, 0, atlas_icons.hud_warning, col, 0)
        update_ui_text(-text_w, 0, text, text_w * 2, 1, col, 0)
    end

    update_ui_pop_offset()
end

function render_control_mode(pos, vehicle, col)
    local control_mode = vehicle:get_control_mode()
    local is_blink_on = g_animation_time % 500 > 250
    local col_blink = color8(col:r(), col:g(), col:b(), iff(is_blink_on, col:a(), 0))
    local col_off = color8(0, 0, 0, 0)

    update_ui_text(pos:x() + 2, pos:y() + 1, update_get_loc(e_loc.upp_acronym_auto), 200, 0, iff(control_mode == "auto", col_blink, col), 0)
    update_ui_text(pos:x() + 10, pos:y() + 1, update_get_loc(e_loc.upp_acronym_manual), 200, 0, iff(control_mode == "manual", col_blink, col), 0)
    update_ui_text(pos:x() + 18, pos:y() + 1, update_get_loc(e_loc.upp_acronym_override), 200, 0, iff(control_mode == "override", col_blink, col), 0)
    update_ui_text(pos:x() + 26, pos:y() + 1, "-", 200, 0, iff(control_mode == "off", col_blink, col), 0)

    update_ui_rectangle_outline(pos:x(), pos:y(), 9, 11, iff(control_mode == "auto", col, col_off))
    update_ui_rectangle_outline(pos:x() + 8, pos:y(), 9, 11, iff(control_mode == "manual", col, col_off))
    update_ui_rectangle_outline(pos:x() + 16, pos:y(), 9, 11, iff(control_mode == "override", col, col_off))
    update_ui_rectangle_outline(pos:x() + 24, pos:y(), 9, 11, iff(control_mode == "off", col, col_off))
end

function render_compass(pos, col)
    local width = 120
    update_ui_push_clip(pos:x() - width / 2, pos:y(), width, 10)
    
    local heading = update_get_camera_heading() / math.pi / 2

    local spacing = width / 2
    local total_w = 4 * spacing

    local labels = { update_get_loc(e_loc.upp_compass_n), update_get_loc(e_loc.upp_compass_e), update_get_loc(e_loc.upp_compass_s), update_get_loc(e_loc.upp_compass_w) }

    for i = 0, 3 do
        local x = wrap_range(pos:x() + i * spacing - heading * total_w, pos:x() - total_w / 2, pos:x() + total_w / 2)

        update_ui_text(x - 3, pos:y(), labels[i + 1], 6, 0, col, 0)

        local substeps = 8
        for j = 1, substeps - 1 do
            local subx = wrap_range(x + j * (spacing / substeps), pos:x() - total_w / 2, pos:x() + total_w / 2)

            if j % 2 == 0 then
                update_ui_line(subx, pos:y() + 3, subx, pos:y() + 7, col)
            else
                update_ui_line(subx, pos:y() + 4, subx, pos:y() + 6, col)
            end
        end
    end

    update_ui_pop_clip()

    update_ui_image_rot(pos:x() - 1, pos:y() + 10, atlas_icons.hud_compass_indicator, col, 0)

    local display_heading = math.floor(iff(heading < 0, 360 + heading * 360, heading * 360))
    update_ui_text(pos:x() - 50, pos:y() + 12, string.format("%03.0f", display_heading), 100, 1, col, 0)
end

function render_artificial_horizion(screen_w, screen_h, pos, size, vehicle, col)
    update_ui_push_clip(pos:x() - size:x() / 2, pos:y() - size:y() / 2, size:x(), size:y())

    local scale = 1.5

    local forward = update_get_camera_forward()
    local forward_xz = vec3(forward:x(), 0, forward:z())
    forward_xz = vec3_normal(forward_xz)
    local side_xz = vec3(-forward_xz:z(), 0, forward_xz:x())

    local position = update_get_camera_position()
    local project_dist = 10000
    
    local velocity = vehicle:get_linear_velocity()
    if vehicle:get_linear_speed() > 1 then
        local projected_velocity = vec3(position:x() + velocity:x() * project_dist, position:y() + velocity:y() * project_dist, position:z() + velocity:z() * project_dist)
        local predicted_position = artificial_horizon_to_screen(screen_w, screen_h, pos, scale, update_world_to_screen(projected_velocity))
        update_ui_image_rot(predicted_position:x(), predicted_position:y(), atlas_icons.hud_horizon_cursor, col, 0)
        Variometer.predicted_vector.x = predicted_position:x()
        Variometer.predicted_vector.y = predicted_position:y()
    end

    local roll_pos_a = update_world_to_screen(vec3(position:x() + (forward_xz:x() + side_xz:x()) * project_dist, position:y(), position:z() + (forward_xz:z() + side_xz:z()) * project_dist))
    local roll_pos_b = update_world_to_screen(vec3(position:x() + (forward_xz:x() - side_xz:x()) * project_dist, position:y(), position:z() + (forward_xz:z() - side_xz:z()) * project_dist))
    local roll_normal = vec2_normal(vec2(roll_pos_b:x() - roll_pos_a:x(), roll_pos_b:y() - roll_pos_a:y()))
    local roll = vec2_angle(roll_normal, vec2(1, 0))
    
    local projected_forward = vec3(position:x() + forward_xz:x() * project_dist, position:y(), position:z() + forward_xz:z() * project_dist)
    local horizon = artificial_horizon_to_screen(screen_w, screen_h, pos, scale, update_world_to_screen(projected_forward))
    update_ui_image_rot(horizon:x(), horizon:y(), atlas_icons.hud_horizon_mid, col, roll)

    local angle_step = 10 / 180 * math.pi
    local steps = math.floor(math.pi * 0.5 / angle_step)

    for i = 1, steps do
        projected_forward = vec3(position:x() + forward_xz:x() * project_dist, position:y() + math.tan(i * angle_step) * project_dist, position:z() + forward_xz:z() * project_dist)
        horizon = artificial_horizon_to_screen(screen_w, screen_h, pos, scale, update_world_to_screen(projected_forward))
        
        if i ~= steps then
            update_ui_image_rot(horizon:x(), horizon:y(), atlas_icons.hud_horizon_high, col, roll)
        end

        projected_forward = vec3(position:x() + forward_xz:x() * project_dist, position:y() - math.tan(i * angle_step) * project_dist, position:z() + forward_xz:z() * project_dist)
        horizon = artificial_horizon_to_screen(screen_w, screen_h, pos, scale, update_world_to_screen(projected_forward))
        update_ui_image_rot(horizon:x(), horizon:y(), atlas_icons.hud_horizon_low, col, roll)
    end

    update_ui_pop_clip()
end

function artificial_horizon_to_screen(screen_w, screen_h, render_pos, scale, screen_pos)
    return vec2(render_pos:x() + scale * (screen_pos:x() - screen_w / 2), render_pos:y() + scale * (screen_pos:y() - screen_h / 2))
end

function render_altitude_meter(pos, altitude, col)
    update_ui_image(pos:x(), pos:y(), atlas_icons.hud_bracket, col, 0)
    render_altitude_ticker(vec2(pos:x() + 4, pos:y() + 41), altitude, col)

    update_ui_push_clip(pos:x() + 8, pos:y() + 2, 100, 38)
    render_timeline(vec2(pos:x() + 8, pos:y()), vec2(40, 100), 100, 20, altitude / 100 * 20, 0, col, false)
    update_ui_pop_clip()

    update_ui_push_clip(pos:x() + 8, pos:y() + 59, 100, 39)
    render_timeline(vec2(pos:x() + 8, pos:y()), vec2(40, 100), 100, 20, altitude / 100 * 20, 0, col, false)
    update_ui_pop_clip()

    render_timeline(vec2(pos:x() + 1, pos:y()), vec2(40, 100), 100, 20, altitude / 100 * 20, 2, col, false,
        function(x, y) 
            update_ui_line(x, y, x + 2, y, col) 
        end
    )

    update_ui_text(pos:x(), pos:y() + 101, update_get_loc(e_loc.upp_alt), 200, 0, col, 0)
    Variometer:render(pos, col)

end

function render_airspeed_meter(pos, vehicle, step, col)
    update_ui_image(pos:x(), pos:y(), atlas_icons.hud_bracket, col, 2)
    render_airspeed_ticker(vec2(pos:x() - 25, pos:y() + 41), vehicle, col)

    update_ui_push_clip(pos:x() - 31, pos:y() + 2, 100, 38)
    render_timeline(vec2(pos:x() - 31, pos:y()), vec2(40, 100), step, 12, vehicle:get_linear_speed() / step * 12, 2, col, true)
    update_ui_pop_clip()

    update_ui_push_clip(pos:x() - 31, pos:y() + 59, 100, 39)
    render_timeline(vec2(pos:x() - 31, pos:y()), vec2(40, 100), step, 12, vehicle:get_linear_speed() / step * 12, 2, col, true)
    update_ui_pop_clip()

    render_timeline(vec2(pos:x() + 13, pos:y()), vec2(40, 100), step, 12, vehicle:get_linear_speed() / step * 12, 2, col, true, 
        function(x, y) 
            update_ui_line(x, y, x + 2, y, col) 
        end
    )

    update_ui_text(pos:x() - 1, pos:y() + 101, update_get_loc(e_loc.upp_spd), 200, 0, col, 0)

    local throttle_height = 96
    local throttle_factor = vehicle:get_throttle_factor()
    local throttle_bar_size = math.floor(throttle_factor * throttle_height + 0.5)
    update_ui_rectangle(pos:x() + 17, pos:y() + 100 - throttle_bar_size - 2, 2, throttle_bar_size, col)
    update_ui_rectangle(pos:x() + 16, pos:y() + 100 - throttle_height - 4, 3, 1, col)
    update_ui_rectangle(pos:x() + 16, pos:y() + 100 - 1, 3, 1, col)
end

function render_altitude_ticker(pos, altitude, col)
    update_ui_image(pos:x(), pos:y(), atlas_icons.hud_ticker_large, col, 0)
    render_number_ticker(vec2(pos:x() + 6, pos:y() + 2), vec2(30, 13), altitude, 4, 2, col, false)
end

function render_airspeed_ticker(pos, vehicle, col)
    update_ui_image(pos:x() + 6, pos:y(), atlas_icons.hud_ticker_small, col, 0)
    render_number_ticker(vec2(pos:x() + 14, pos:y() + 2), vec2(30, 13), vehicle:get_linear_speed(), 3, 1, col, false) 
end

function render_number_ticker(pos, size, val, max_digits, digit_precision, col, is_signed)
    local clip_min = vec2(pos:x(), pos:y())
    local clip_max = vec2(pos:x() + size:x(), pos:y() + size:y())
    local char_w = 6;
    local char_h = 10
    local round_to = 10 ^ (digit_precision - 1)
    local display_val = math.min(math.abs(val), round_down(10 ^ max_digits - 1, round_to))

    -- update_ui_rectangle(clip_min:x(), clip_min:y(), size:x(), size:y(), color8(255, 255, 0, 128))
    update_ui_push_clip(clip_min:x(), clip_min:y(), size:x(), size:y())

    local cursor_x = pos:x() + (max_digits + iff(is_signed, 1, 0) - digit_precision) * char_w
    local cursor_y = pos:y() + (size:y() - char_h) / 2 + 1
    
    if is_signed then
        if val < 0 then
            update_ui_text(pos:x(), cursor_y, "-", 200, 0, col, 0)
        else
            update_ui_text(pos:x(), cursor_y, "+", 200, 0, col, 0)
        end
    end

    local factor = display_val % (round_to * 10) / (round_to * 10)
    render_number_ticker_column(vec2(cursor_x, cursor_y), round_to, 10, char_h, factor, "%0"..digit_precision.."d", col)
    
    for i = digit_precision, max_digits - 1 do
        cursor_x = cursor_x - char_w

        local mod = 10 ^ (i + 1)
        local factor = display_val % mod
        local fac_step = 10 ^ i
        local fac_bound = math.floor(factor / fac_step) * fac_step
        local fac_wrap = factor - fac_bound
        local fac_lower = fac_step - (10 ^ (digit_precision - 1))

        fac_wrap = iff(fac_wrap < fac_lower, 0, remap_clamp(fac_wrap, fac_lower, fac_step, 0, fac_step))
        factor = fac_wrap + fac_bound
        factor = factor / mod

        render_number_ticker_column(vec2(cursor_x, cursor_y), 1, 10, char_h, factor, "%d", col)
    end

    update_ui_pop_clip()
end

function render_number_ticker_column(pos, num_incr, num_steps, char_h, factor, format, col)
    local wrap_min = pos:y() - (num_steps / 2) * char_h
    local wrap_max = pos:y() + (num_steps / 2) * char_h

    for i = 0, num_steps - 1 do
        local str = string.format(format, math.floor(num_incr * i))
        local y = wrap_range(pos:y() - char_h * i + num_steps * factor * char_h, wrap_min, wrap_max)
        update_ui_text(pos:x(), y, str, 200, 0, col, 0)
    end
end

function render_timeline(pos, size, num_incr, spacing, offset, text_align, col, is_clamp_zero, callback)
    local num_count = size:y() / spacing

    local range_min = -math.floor(num_count / 2) - 1
    local range_max = math.floor(num_count / 2) + 1

    update_ui_push_clip(pos:x(), pos:y(), size:x(), size:y())

    for i = range_min, range_max do
        local x = pos:x()
        local y = pos:y() + size:y() / 2 - i * spacing + offset % spacing
        
        local val = num_incr * (i + math.floor(offset / spacing))

        if is_clamp_zero == false or val >= 0 then
            if callback == nil then
                local char_h = 10
    
                update_ui_text(x, y - char_h / 2, val, size:x(), text_align, col, 0)
            else
                callback(x, y)
            end
        end
    end

    update_ui_pop_clip()
end

function wrap_range(val, min, max)
    return min + (val - min) % (max - min)
end

function render_fuel_gauge(pos, height, vehicle, col)
    render_gauge(pos, height, vehicle:get_fuel_factor(), update_get_loc(e_loc.upp_fuel), iff(get_is_fuel_warning(vehicle), color8(255, 0, 0, 255), col))
end

function render_damage_gauge(pos, height, vehicle, col)
    render_gauge(pos, height, vehicle:get_hitpoints() / vehicle:get_total_hitpoints(), update_get_loc(e_loc.hp), iff(get_is_damage_warning(vehicle), color8(255, 0, 0, 255), col)) 
end

function render_gauge(pos, height, factor, label, col)
    factor = clamp(factor, 0, 1)

    local bar_size = math.floor(factor * (height - 4) + 0.5)
    update_ui_rectangle(pos:x(), pos:y() + height - bar_size - 2, 2, bar_size, col)
    update_ui_rectangle(pos:x() - 1, pos:y() + height - 1, 4, 1, col)
    update_ui_rectangle(pos:x() - 1, pos:y(), 4, 1, col)

    local segments = 8
    local step = height / segments
    
    for i = 1, segments - 1 do
        if i % 4 == 0 then
            update_ui_rectangle(pos:x() - 1, pos:y() + height - i * step, 3, 1, col)
        elseif i % 2 == 0 then
            update_ui_rectangle(pos:x() - 1, pos:y() + height - i * step, 2, 1, col)
        else
            update_ui_rectangle(pos:x() - 1, pos:y() + height - i * step, 1, 1, col)
        end
    end
    
    update_ui_text(pos:x() + 3, pos:y() + height, label, 200, 0, col, 3)
end

function get_gun_funnel_spawn_pos(tick_fraction, vehicle, side_dist, forward_dist)
    local forward = vehicle:get_forward()
    local side = vehicle:get_side()
    local vehicle_pos = vehicle:get_position()
    return vec3(
        vehicle_pos:x() + forward:x() * forward_dist + side:x() * side_dist,
        vehicle_pos:y() + forward:y() * forward_dist + side:y() * side_dist,
        vehicle_pos:z() + forward:z() * forward_dist + side:z() * side_dist
    )
end

function update_gun_funnel(tick_fraction, vehicle, side_dist, forward_dist)
    local sample_interval_ticks = 1
    local sample_history_ticks = 30

    local projectile_speed = 10

    local tick = update_get_logic_tick()

    if tick - g_gun_funnel_sample_time > sample_interval_ticks then
        g_gun_funnel_sample_time = tick

        local forward = vehicle:get_forward()
        local projectile_vel = vec3(forward:x() * projectile_speed, forward:y() * projectile_speed, forward:z() * projectile_speed)

        local sample_data = {
            time = tick,
            left = {
                start_pos = get_gun_funnel_spawn_pos(tick_fraction, vehicle, side_dist, forward_dist),
                start_vel = projectile_vel
            },
            right = {
                start_pos = get_gun_funnel_spawn_pos(tick_fraction, vehicle, -side_dist, forward_dist),
                start_vel = projectile_vel
            }   
        }

        g_gun_funnel_history[sample_data.time] = sample_data
    end

    local count = 0

    for k, v in pairs(g_gun_funnel_history) do
        local sample_life = tick - v.time

        if sample_life > sample_history_ticks then
           g_gun_funnel_history[k] = nil
        else
            count = count + 1
        end
    end
end

function render_gun_funnel(tick_fraction, vehicle, side_dist, forward_dist, col)
    local projectile_gravity = 0.2 / 30

    local get_bullet_pos = function(time, start_pos, start_vel, gravity)
        local t_sq = time * time

        return vec3(
            start_pos:x() + start_vel:x() * time,
            start_pos:y() + start_vel:y() * time + 0.5 * -projectile_gravity * t_sq,
            start_pos:z() + start_vel:z() * time
        )
    end

    local tick = update_get_logic_tick()

    local prev = {
        time = tick,
        left = {
            start_pos = get_gun_funnel_spawn_pos(tick_fraction, vehicle, side_dist, forward_dist),
            start_vel = vec3(0, 0, 0)
        },
        right = {
            start_pos = get_gun_funnel_spawn_pos(tick_fraction, vehicle, -side_dist, forward_dist),
            start_vel = vec3(0, 0, 0)
        }
    }

    local sort_func = function(a, b) 
        return a > b 
    end

    local render_line = function(a, b, col)
        update_ui_line(
            math.floor(a:x()), 
            math.floor(a:y()), 
            math.floor(b:x()), 
            math.floor(b:y()), 
            col
        )
    end
    
    for _, next in iter_sorted(g_gun_funnel_history, sort_func) do
        if prev then
            local time_prev = tick - prev.time
            local time_next = tick - next.time

            local pos_prev_left = get_bullet_pos(time_prev, prev.left.start_pos, prev.left.start_vel)
            local pos_next_left = get_bullet_pos(time_next, next.left.start_pos, next.left.start_vel)
            local screen_prev_left, is_behind_left_prev = update_world_to_screen(pos_prev_left)
            local screen_next_left, is_behind_left_next = update_world_to_screen(pos_next_left)
            
            if is_behind_left_next == false then
                render_line(screen_prev_left, screen_next_left, col)
            end

            local pos_prev_right = get_bullet_pos(time_prev, prev.right.start_pos, prev.right.start_vel)
            local pos_next_right = get_bullet_pos(time_next, next.right.start_pos, next.right.start_vel)
            local screen_prev_right, is_behind_right_prev = update_world_to_screen(pos_prev_right)
            local screen_next_right, is_behind_right_next = update_world_to_screen(pos_next_right)
            
            if is_behind_right_next == false then
                render_line(screen_prev_right, screen_next_right, col)
            end
        end

        prev = next
    end
end

function render_camera_forward_axis(screen_w, screen_h, vehicle)
    local col = color8(0, 255, 0, 255)
    local x = screen_w / 2 - 0
    local y = screen_h / 3 - 0

    project = function(pos)
        return vec2(math.ceil(pos:x() + x), math.ceil(-pos:y() + y))
    end

    local length = 20
    local arrow_size = 5
    local axis_size = 4

    local arrow_p0 = project(update_camera_local_rotate_inv(vehicle, vec3(0, 0, length)))
    local arrow_p1 = project(update_camera_local_rotate_inv(vehicle, vec3(arrow_size, 0, length - arrow_size)))
    local arrow_p2 = project(update_camera_local_rotate_inv(vehicle, vec3(-arrow_size, 0, length - arrow_size)))
    local axis_y0 = project(update_camera_local_rotate_inv(vehicle, vec3(0, axis_size, 0)))
    local axis_y1 = project(update_camera_local_rotate_inv(vehicle, vec3(0, -axis_size, 0)))

    update_ui_line(x, y, arrow_p0:x(), arrow_p0:y(), col)
    update_ui_line(arrow_p1:x(), arrow_p1:y(), arrow_p0:x(), arrow_p0:y(), col)
    update_ui_line(arrow_p2:x(), arrow_p2:y(), arrow_p0:x(), arrow_p0:y(), col)
    update_ui_line(axis_y0:x(), axis_y0:y(), axis_y1:x(), axis_y1:y(), col)
end

function render_mouse_flight_axis(pos)
    if update_get_active_input_type() == e_active_input.keyboard then 
        local settings = update_get_game_settings()

        if settings.mouse_flight_mode ~= e_mouse_flight_mode.disabled and (settings.ui_show_mouse_joystick_on_hud or settings.mouse_joystick_mode == e_mouse_joystick_mode.offset) then
            local flight_axis = update_get_mouse_flight_axis()
            local invert_x = iff(settings.mouse_flight_inv_x, -1, 1)
            local invert_y = iff(settings.mouse_flight_inv_y, -1, 1)
            flight_axis:x(flight_axis:x() * invert_x)
            flight_axis:y(flight_axis:y() * invert_y)
            
            local max_axis = clamp(math.max(math.abs(flight_axis:x()), math.abs(flight_axis:y())), 0, 1)
            local alpha = clamp((max_axis + 0.1) / 0.2, 0, 1)
            local col_line = color8(255, 255, 255, math.floor(180 * alpha))
            local col_mark = color8(255, 255, 255, math.floor(255 * alpha))
            local rad = 80
            update_ui_line(pos:x() + 1, pos:y() + 1, pos:x() + flight_axis:x() * rad, pos:y() + flight_axis:y() * rad, col_line)
            update_ui_image_rot(pos:x() + 1 + flight_axis:x() * rad, pos:y() + 1 + flight_axis:y() * rad, atlas_icons.hud_target_offscreen_friendly, col_mark, 0)
        end
    end
end

--------------------------------------------------------------------------------
--
-- VEHICLE INFO RENDERING
--
--------------------------------------------------------------------------------

function render_vehicle_info(info_pos, vehicle)
    local pos = vec2(info_pos:x(), info_pos:y())
    local text_align = 0
    local text_col_hi = color8(255, 255, 255, 255)
    local text_col_lo = color8(255, 0, 0, 255)
    local bar_col_hi = color8(0, 128, 255, 255)
    local bar_col_lo = color8(255, 0, 0, 255)
    local back_col = color8(0, 0, 0, 128)

    local fuel_factor = vehicle:get_fuel_factor()
    local alt_factor = remap_clamp(vehicle:get_altitude(), 0, 2000, 0, 1)
    local speed_factor = remap_clamp(vehicle:get_linear_speed(), 0, 100, 0, 1)
    local throttle_factor = vehicle:get_throttle_factor()

    update_ui_text(pos:x(), pos:y() + 60, update_get_loc(e_loc.upp_alt), 60, text_align, iff(alt_factor > 0.25, text_col_hi, text_col_lo), 3)
    pos:x(pos:x() + 10)
    render_gauge_classic(vec2(pos:x(), pos:y()), alt_factor, iff(alt_factor > 0.25, bar_col_hi, bar_col_lo), back_col)
    pos:x(pos:x() + 14)

    update_ui_text(pos:x(), pos:y() + 60, update_get_loc(e_loc.upp_fuel), 60, text_align, iff(fuel_factor > 0.25, text_col_hi, text_col_lo), 3)
    pos:x(pos:x() + 10)
    render_gauge_classic(vec2(pos:x(), pos:y()), fuel_factor, iff(fuel_factor > 0.25, bar_col_hi, bar_col_lo), back_col)
    pos:x(pos:x() + 14)

    update_ui_text(pos:x(), pos:y() + 60, update_get_loc(e_loc.upp_speed), 60, text_align, iff(speed_factor > 0.25, text_col_hi, text_col_lo), 3)
    pos:x(pos:x() + 10)
    render_gauge_classic(vec2(pos:x(), pos:y()), speed_factor, iff(speed_factor > 0.25, bar_col_hi, bar_col_lo), back_col)
    pos:x(pos:x() + 14)

    update_ui_text(pos:x(), pos:y() + 60, update_get_loc(e_loc.upp_throttle), 60, text_align, iff(throttle_factor > 0.25, text_col_hi, text_col_lo), 3)
    pos:x(pos:x() + 10)
    render_gauge_classic(vec2(pos:x(), pos:y()), throttle_factor, iff(throttle_factor > 0.25, bar_col_hi, bar_col_lo), back_col)
    pos:x(pos:x() + 14)
end


--------------------------------------------------------------------------------
--
-- CONNECTING OVERLAY RENDERING
--
--------------------------------------------------------------------------------

function render_connecting_overlay(screen_w, screen_h)
    update_ui_set_back_color(color8(0, 0, 0, 255))
    
    local connecting_text = update_get_loc(e_loc.connecting);
    local dot_count = math.floor(g_animation_time / 250.0) % 4

    for i = 1, dot_count, 1 do
        connecting_text = connecting_text .. "."
    end

    local cx = screen_w / 2 - 40
    local cy = screen_h / 2
    update_ui_text(cx, cy, connecting_text, 100, 0, color_white, 0)

    local anim = g_animation_time * 0.001
    local bound_left = cx
    local bound_right = bound_left + 75
    local left = bound_left + (bound_right - bound_left) * math.abs(math.sin((anim - math.pi / 2) % (math.pi / 2))) ^ 4
    local right = left + (bound_right - left) * math.abs(math.sin(anim % (math.pi / 2)))

    update_ui_rectangle(left, cy + 12, right - left, 1, color_status_ok)
    update_ui_rectangle(bound_right + bound_left - right, cy - 3, right - left, 1, color_status_ok)
end


--------------------------------------------------------------------------------
--
-- ATTACHMENT VISION
--
--------------------------------------------------------------------------------

function render_attachment_vision(screen_w, screen_h, map_data, vehicle, attachment)
    local vehicle_id = vehicle:get_id()
    local vehicle_team = vehicle:get_team_id()
    local vehicle_pos = vehicle:get_position()
    local attachment_def = attachment:get_definition_index()

    local colors = {
        red = color8(255, 0, 0, 255),
        green = color8(0, 255, 0, 255)
    }
    
    local range = 5000
    local range_ships = 10000
    local range_sq = range * range
    local range_ships_sq = range_ships * range_ships
    local safe_zone_min = vec2(100, 40)
    local safe_zone_max = vec2(screen_w - 100, screen_h - 30)

    local target_data = {}
    local target_hovered = nil
    local target_selected = nil
    local nearest_screen_dist_sq = -1
    local target_hover_world_radius = 4

    local is_render_own_team = true --get_is_vision_render_own_team(attachment_def)
    local is_target_lock_behaviour = get_is_vision_target_lock_behaviour(attachment_def)
    local is_target_observation_behaviour = get_is_vision_target_observation_behaviour(attachment_def)
    local is_vision_reveal_targets = get_is_vision_reveal_targets(attachment_def)
    local is_show_target_distance = true --get_is_vision_show_target_distance(attachment_def)

    local laser_consuming_type = attachment:get_weapon_target_consuming_type()
    local laser_id, laser_idx = attachment:get_weapon_target_consuming_id()

    local filter_target = function(v)
        -- Ignore self and docked vehicles
        if v:get_id() ~= vehicle_id and not v:get_is_docked() then
            if (get_is_vision_render_land(attachment_def) and v:get_is_land_target())
            or (get_is_vision_render_air(attachment_def) and v:get_is_air_target())
            or (get_is_vision_render_sea(attachment_def) and get_is_vehicle_sea(v:get_definition_index())) then
                local def = v:get_definition_index()
                if def == e_game_object_type.chassis_land_robot_dog then
                    return false
                elseif is_render_own_team then
                    return true
                elseif v:get_team_id() ~= vehicle_team then
                    return true
                elseif laser_consuming_type == 1 and laser_id == v:get_id() then
                    return true
                end
            end
        end

        return false
    end

    -- get all relevant targets and their data

    for v in iter_vision(map_data, filter_target) do
        local pos = v:get_position()
        local dist_sq = vec3_dist_sq(pos, vehicle_pos)

        local observe_range_sq = iff(get_is_vehicle_sea(v:get_definition_index()), range_ships_sq, range_sq)

        if dist_sq < observe_range_sq then
            local screen_pos, is_clamped = world_to_screen_clamped(pos, safe_zone_min, safe_zone_max)

            local data = {}
            data.screen_pos = screen_pos
            data.is_clamped = is_clamped
            data.vehicle = v
            data.type = 1
            data.id = v:get_id()
            data.team = v:get_team_id()
            data.dist_sq = dist_sq
            data.is_laser_target = laser_consuming_type == data.type and laser_id == data.id
            data.is_observed = v:get_is_observation_revealed()

            table.insert(target_data, data)

            if data.id == g_selected_target_id and data.type == g_selected_target_type then
                target_selected = data
            end

            local is_hoverable = data.is_observed or is_vision_reveal_targets

            if is_hoverable then
                local hover_radius = iff(data.is_observed, iff(is_target_observation_behaviour, 10, 1000), target_hover_world_radius)
                local screen_dist_sq = vec2_dist_sq(screen_pos, vec2(screen_w / 2, screen_h / 2))
                local vehicle_screen_radius = get_object_size_on_screen(screen_w, data.vehicle:get_position(), hover_radius)

                if is_target_observation_behaviour and data.is_observed then
                    vehicle_screen_radius = math.min(vehicle_screen_radius, 50)
                end

                local is_hovering = screen_dist_sq < (vehicle_screen_radius * vehicle_screen_radius)

                if (screen_dist_sq < nearest_screen_dist_sq or nearest_screen_dist_sq < 0) and is_hovering and is_clamped == false then
                    nearest_screen_dist_sq = screen_dist_sq
                    target_hovered = data
                end
            end
        end
    end

    if laser_consuming_type == 2 and laser_id ~= 0 then
        local missile_target = update_get_missile_by_id(laser_id)

        if missile_target:get() then
            local screen_pos, is_clamped = world_to_screen_clamped(missile_target:get_position(), safe_zone_min, safe_zone_max)

            local data = {}
            data.screen_pos = screen_pos
            data.is_clamped = is_clamped
            data.missile = missile_target
            data.type = 2
            data.id = laser_id
            data.team = vehicle:get_team_id()
            data.is_laser_target = true
            data.is_observed = true

            table.insert(target_data, data)
        end
    end

    if g_selected_target_id ~= 0 and target_selected == nil then
        g_selected_target_id = 0
    end

    -- render targets
    local function render_target_vehicle_peers(pos, data, col)
        -- nothing to do in single player or for enemy vehicles
        if not update_get_is_multiplayer() or data.team ~= vehicle_team then return end

        local v = data.vehicle

        -- get all peers connected to the vehicle
        local peers = get_vehicle_controlling_peers(v)

        local cursor_y = pos:y() - 16

        for i = 1, #peers do
            local peer = peers[i]
            local peer_name = peer.name

            local max_text_chars = 10
            local is_clipped = false

            if utf8.len(peer_name) > max_text_chars then
                peer_name = peer_name:sub(1, utf8.offset(peer_name, max_text_chars) - 1)
                is_clipped = true
            end

            local text_render_w, text_render_h = update_ui_get_text_size(peer_name, 200, 0)

            if peer.ctrl then
                update_ui_image((pos:x() - text_render_w / 2) - 12, cursor_y, atlas_icons.column_controlling_peer, col, 0)
            end

            update_ui_text(pos:x() - text_render_w / 2, cursor_y, peer_name, text_render_w, 0, col, 0)

            if is_clipped then
                update_ui_image(pos:x() + text_render_w / 2, cursor_y, atlas_icons.text_ellipsis, col, 0)
            end

            cursor_y = cursor_y - 10
        end
    end

    local function render_target_vehicle_info(pos, data, col)
        if data.is_laser_target then
            -- don't render info
        else
            local def = data.vehicle:get_definition_index()

            -- render right side of marker
            local cursor_y = pos:y() - 4

            local capability_name = ""

            if def ~= e_game_object_type.chassis_carrier and def ~= e_game_object_type.chassis_sea_barge then
                local capabilities = get_vehicle_capability(data.vehicle)
                if #capabilities > 0 then
                    local capability_index = (math.floor( g_animation_time / 1000 ) % (#capabilities)) + 1
                    capability_name = capabilities[capability_index].name_short
                else
                    capability_name = "NONE"
                end
            end

            if data.team == vehicle_team then
                local name, icon, handle = get_chassis_data_by_definition_index(def)
                update_ui_text(pos:x() + 9, cursor_y, handle, 200, 0, col, 0)
                update_ui_image(pos:x() + 26, cursor_y - 4, icon, col, 0)
                cursor_y = cursor_y + 10

                update_ui_text(pos:x() + 9, cursor_y, capability_name, 64, 0, col, 0)
            else
                if data.vehicle:get_is_observation_type_revealed() then
                    local name, icon, handle = get_chassis_data_by_definition_index(def)
                    update_ui_text(pos:x() + 9, cursor_y, handle, 200, 0, col, 0)
                    update_ui_image(pos:x() + 26, cursor_y - 4, icon, col, 0)
                    cursor_y = cursor_y + 10
                elseif data.vehicle:get_is_observation_revealed() then
                    update_ui_text(pos:x() + 9, cursor_y, "***", 200, 0, col, 0)
                    cursor_y = cursor_y + 10
                end
                    
                if data.vehicle:get_is_observation_weapon_revealed() then
                    update_ui_text(pos:x() + 9, cursor_y, capability_name, 64, 0, col, 0)
                    cursor_y = cursor_y + 10
                end
    
                if is_target_observation_behaviour and data.vehicle:get_is_observation_fully_revealed() == false and data.is_observed then
                    local factor = data.vehicle:get_observation_factor()
                    update_ui_text(pos:x() + 9, cursor_y, string.format("%.0f%%", factor * 100), 200, 0, col, 0)
                end
            end

            -- render left side of marker
            cursor_y = pos:y() - 4

            local id_str = ""

            if def == e_game_object_type.chassis_carrier then
                id_str = string.upper( vessel_names[data.team + 1] )
            else
                id_str = update_get_loc(e_loc.upp_id) .. string.format( " %.0f", data.id)
            end

            local id_w = update_ui_get_text_size(id_str, 10000, 1) + 7
            update_ui_text(pos:x() - id_w, cursor_y, id_str, 128, 0, col, 0 )
            cursor_y = cursor_y + 10

            if is_show_target_distance and data.is_observed then
                local dist = math.sqrt(data.dist_sq)
                local dist_str = ""

                if dist < 10000 then
                    dist_str = string.format("%.0f", dist) .. update_get_loc(e_loc.acronym_meters)
                else
                    dist_str = string.format("%.0f", dist / 1000) .. update_get_loc(e_loc.acronym_kilometers)
                end

                local dist_w = update_ui_get_text_size(dist_str, 10000, 1) + 7

                update_ui_text(pos:x() - dist_w, cursor_y, dist_str, 128, 0, col, 0)
            end
        end
    end

    local function render_target_missile_info(pos, data, col)
        if data.is_laser_target then
            -- don't render info
        end
    end

    -- debug
    -- for _, data in pairs(target_data) do
    --     if data.type == 1 then
    --         local vehicle_screen_radius = get_object_size_on_screen(screen_w, data.vehicle:get_position(), 4)

    --         if data.is_clamped == false then
    --             render_circle(data.screen_pos, vehicle_screen_radius, 16, colors.red)
    --         end
    --     end
    -- end

    local vehicle_info_data = nil

    for _, data in pairs(target_data) do
        if data.type == 1 then -- vehicle
            if target_selected == nil or target_selected == data then
                local is_target_locked = is_target_lock_behaviour and g_selected_target_id == data.id and g_selected_target_type == data.type
                local is_friendly = data.team == vehicle_team
                local col = iff(is_friendly, color_friendly, colors.red)
                local is_hovered = data == target_hovered
                local is_render_health = (data == target_selected or (target_selected == nil and data == target_hovered)) and data.is_observed

                if data.is_observed then
                    render_vision_target_vehicle_outline(data.screen_pos, data.vehicle, data.is_clamped, is_target_locked or data.is_laser_target, is_friendly, is_render_health, col)

                    if data.is_clamped == false and (is_hovered or data.is_laser_target) then
                        vehicle_info_data = data
                    end
                elseif is_vision_reveal_targets and is_hovered and data.is_clamped == false then
                    local factor = data.vehicle:get_observation_factor()

                    if factor > 0 then
                        update_ui_push_offset(data.screen_pos:x(), data.screen_pos:y())

                        local rad = 7
                        render_line_segments({ 
                            { vec2(0, -rad), vec2(rad, 0) },
                            { vec2(rad, 0), vec2(0, rad) },
                            { vec2(0, rad), vec2(-rad, 0) },
                            { vec2(-rad, 0), vec2(0, -rad) }
                        }, col, factor)

                        update_ui_pop_offset()
                    end
                end
            end
        elseif data.type == 2 then -- missile
            render_vision_target_missile_outline(data.screen_pos, data.is_clamped, color_friendly)
            render_target_missile_info(data.screen_pos, data, colors.green)
        end
    end

    -- Always draw info on top
    if vehicle_info_data ~= nil then
        render_target_vehicle_info(vehicle_info_data.screen_pos, vehicle_info_data, colors.green)
        render_target_vehicle_peers(vehicle_info_data.screen_pos, vehicle_info_data, colors.green)
    end

    if is_vision_reveal_targets and target_hovered ~= nil and target_hovered.type == 1 and target_hovered.vehicle:get_is_observation_fully_revealed() == false then
        local dist_to_center = vec2_dist(target_hovered.screen_pos, vec2(screen_w / 2, screen_h / 2))
        local dist_factor = 1 - clamp(dist_to_center / 64, 0, 1)
        local vehicle_screen_radius = get_object_size_on_screen(screen_w, target_hovered.vehicle:get_position(), 20)
        local radius_factor = clamp(vehicle_screen_radius / 50, 0, 1)
        
        local observation_factor = dist_factor * radius_factor

        if target_hovered.vehicle:get_is_observation_revealed() == false then
            update_set_observed_vehicle(target_hovered.id, observation_factor)
        elseif is_target_observation_behaviour then
            update_set_observed_vehicle(target_hovered.id, observation_factor)
        end
    end

    if is_target_lock_behaviour then
        update_add_ui_interaction(iff(g_selected_target_id == 0, update_get_loc(e_loc.interaction_lock_target), update_get_loc(e_loc.interaction_clear_target)), e_game_input.toggle_stabilisation_mode)
        toggle_vision_target(target_hovered, vehicle_team)
    end
end

function render_vision_target_vehicle_outline(pos, vehicle, is_clamped, is_target_locked, is_friendly, is_render_health, col)
    local x = math.floor(pos:x() + 1); local y = math.floor(pos:y() + 1)

    if is_render_health then
        local damage_indicator_factor = vehicle:get_damage_indicator_factor()
        col = color8_lerp(col, color_white, damage_indicator_factor)
    end

    local icons = iff(is_friendly, {
        target = atlas_icons.hud_target_friendly,
        target_locked = atlas_icons.hud_target_locked_friendly,
        target_offscreen = atlas_icons.hud_target_offscreen_friendly,
    },{
        target = atlas_icons.hud_target,
        target_locked = atlas_icons.hud_target_locked,
        target_offscreen = atlas_icons.hud_target_offscreen,
    })

    if is_target_locked then
        if g_animation_time % 500 > 250 then
            update_ui_image_rot(x, y, iff(is_clamped, icons.target_offscreen, icons.target_locked), col, 0)
        else
            update_ui_image_rot(x, y, iff(is_clamped, icons.target_offscreen, icons.target), col, 0)
        end
    else
        update_ui_image_rot(x, y, iff(is_clamped, icons.target_offscreen, icons.target), col, 0)
    end

    if is_render_health then
        local hitpoints = vehicle:get_hitpoints()
        local total_hitpoints = vehicle:get_total_hitpoints()

        if total_hitpoints > 0 then
            local hitpoint_factor = hitpoints / total_hitpoints

            if is_clamped then
                local bar_size = math.ceil(5 * hitpoint_factor - 0.01)
                update_ui_rectangle(pos:x() - 2, pos:y() + 4, 5, 1, color8(16, 16, 16, 255))
                update_ui_rectangle(pos:x() - 2, pos:y() + 4, bar_size, 1, col)
            else
                local bar_size = math.ceil(13 * hitpoint_factor - 0.01)
                update_ui_rectangle(pos:x() - 6, pos:y() + 8, 13, 1, color8(16, 16, 16, 255))
                update_ui_rectangle(pos:x() - 6, pos:y() + 8, bar_size, 1, col)
            end
        end
    end
end

function render_vision_target_missile_outline(pos, is_clamped, col)
    local x = math.floor(pos:x() + 1); local y = math.floor(pos:y() + 1)

    update_ui_image_rot(x, y, iff(is_clamped, atlas_icons.hud_target_offscreen, atlas_icons.hud_target_missile), col, 0)
end

-- Render chassis direction relative to turret
function render_turret_vehicle_direction(screen_w, screen_h, vehicle, turret, col)
    local def = vehicle:get_definition_index()
    if def == e_game_object_type.chassis_land_turret then return nil end
    
    local attachment_icon_region, attachment_16_icon_region = get_attachment_icons(turret:get_definition_index())
--  local icon_w, icon_h = update_ui_get_image_size(attachment_icon_region)

    local hud_size = vec2(230, 140) 
    local hud_min = vec2((screen_w - hud_size:x()) / 2, (screen_h - hud_size:y()) / 2)
    local hud_pos = vec2(hud_min:x() + hud_size:x() / 2, hud_min:y() + hud_size:y() / 2)

    local pos_x = hud_min:x() + hud_size:x() - 6
    local pos_y = hud_pos:y() - 30
    
    local turret_ang = update_get_camera_heading()

    local vehicle_dir = vehicle:get_forward()
    local vehicle_ang = math.atan( vehicle_dir:x(), vehicle_dir:z() )
    
    local turret_def = turret:get_definition_index()
    local off_y = iff(turret_def == e_game_object_type.attachment_turret_droid, -2, -4)
    
    update_ui_image_rot( pos_x, pos_y, atlas_icons.hud_ticker_small, col, -(turret_ang - vehicle_ang) - (math.pi / 2) )
    update_ui_image_rot( pos_x, pos_y + off_y, attachment_icon_region, col, 0 )
end

-- toggle between no target and a specific target
function toggle_vision_target(nearest_target, vehicle_team)
    if g_selected_target_id == 0 and nearest_target and nearest_target.is_observed and nearest_target.team ~= vehicle_team then
        if g_is_input_cycle_target_next or g_is_input_cycle_target_prev then
            g_selected_target_id = nearest_target.id
            g_selected_target_type = 1
        end
    elseif g_selected_target_id ~= 0 then
        if g_is_input_cycle_target_next or g_is_input_cycle_target_prev then
            g_selected_target_id = 0
            g_selected_target_type = 0
        end
    end
end

-- cycle visible targets from left to right
function cycle_vision_targets(targets, nearest_target)
    if #targets > 0 then
        table.sort(targets, function(a,b) return a.screen_pos:x() < b.screen_pos:x() end)

        local selected_target_index = -1

        for i = 1, #targets do
            if targets[i].vehicle:get_id() == g_selected_target_id then
                selected_target_index = i - 1
                break
            end
        end

        if g_selected_target_id == 0 and nearest_target then
            if g_is_input_cycle_target_next or g_is_input_cycle_target_prev then
                g_selected_target_id = nearest_target:get_id()
                g_selected_target_type = 1
            end
        else
            if g_is_input_cycle_target_next then
                selected_target_index = (selected_target_index + 1) % #targets
            elseif g_is_input_cycle_target_prev then
                selected_target_index = (selected_target_index - 1) % #targets    
            end

            g_selected_target_id = targets[selected_target_index + 1].vehicle:get_id()
            g_selected_target_type = 1
        end
    else
        if g_is_input_cycle_target_next or g_is_input_cycle_target_prev then
            g_selected_target_id = 0
            g_selected_target_type = 0
        end
    end
end

function get_is_vision_show_target_distance(attachment_def)
    return attachment_def == e_game_object_type.attachment_turret_artillery
        or attachment_def == e_game_object_type.attachment_turret_15mm
        or attachment_def == e_game_object_type.attachment_turret_30mm
        or attachment_def == e_game_object_type.attachment_turret_40mm
        or attachment_def == e_game_object_type.attachment_turret_heavy_cannon
        or attachment_def == e_game_object_type.attachment_turret_battle_cannon
        or attachment_def == e_game_object_type.attachment_turret_carrier_main_gun
        or attachment_def == e_game_object_type.attachment_turret_droid
        or attachment_def == e_game_object_type.attachment_turret_gimbal_30mm
end

function get_is_vision_target_lock_behaviour(attachment_def)
    return attachment_def == e_game_object_type.attachment_turret_rocket_pod
        or attachment_def == e_game_object_type.attachment_hardpoint_missile_ir
        or attachment_def == e_game_object_type.attachment_hardpoint_missile_laser
        or attachment_def == e_game_object_type.attachment_hardpoint_missile_aa
        or attachment_def == e_game_object_type.attachment_hardpoint_bomb_1
        or attachment_def == e_game_object_type.attachment_hardpoint_bomb_2
        or attachment_def == e_game_object_type.attachment_hardpoint_bomb_3
        or attachment_def == e_game_object_type.attachment_turret_plane_chaingun
end

function get_is_vision_render_land(attachment_def)
    return (attachment_def ~= e_game_object_type.attachment_radar_awacs) and (attachment_def ~= e_game_object_type.attachment_hardpoint_missile_aa)
end

function get_is_vision_render_air(attachment_def)
    return true
end

function get_is_vision_render_sea(attachment_def)
    return (attachment_def ~= e_game_object_type.attachment_hardpoint_missile_aa)
end

function get_is_vision_render_own_team(attachment_def)
    return attachment_def == e_game_object_type.attachment_camera_observation
        or attachment_def == e_game_object_type.attachment_camera_plane
        or attachment_def == e_game_object_type.attachment_turret_carrier_camera
        or attachment_def == e_game_object_type.attachment_radar_awacs
end

function get_is_vision_target_observation_behaviour(attachment_def)
    return attachment_def == e_game_object_type.attachment_camera_observation
        or attachment_def == e_game_object_type.attachment_camera_plane
        or attachment_def == e_game_object_type.attachment_turret_carrier_camera
end

function get_is_vision_reveal_targets(attachment_def)
    return attachment_def == e_game_object_type.attachment_camera_observation
        or attachment_def == e_game_object_type.attachment_camera_plane
        or attachment_def == e_game_object_type.attachment_turret_carrier_camera
        or attachment_def == e_game_object_type.attachment_turret_15mm
        or attachment_def == e_game_object_type.attachment_turret_30mm
        or attachment_def == e_game_object_type.attachment_turret_40mm
        or attachment_def == e_game_object_type.attachment_turret_artillery
        or attachment_def == e_game_object_type.attachment_turret_battle_cannon
        or attachment_def == e_game_object_type.attachment_turret_heavy_cannon
        or attachment_def == e_game_object_type.attachment_turret_missile
        or attachment_def == e_game_object_type.attachment_turret_ciws
        or attachment_def == e_game_object_type.attachment_camera
        or attachment_def == e_game_object_type.attachment_turret_droid
        or attachment_def == e_game_object_type.attachment_turret_gimbal_30mm
end


--------------------------------------------------------------------------------
--
-- RENDER HELPER FUNCTIONS
--
--------------------------------------------------------------------------------

function render_gauge_classic(pos, factor, col, back_col)
    local b = pos:y() + 59;
    local t = pos:y() + 1
    t = math.floor(lerp(b, t, clamp(factor, 0.0, 1.0)) + 0.5)

    if back_col then update_ui_rectangle(pos:x(), pos:y(), 13, 60, back_col) end
    update_ui_image(pos:x(), pos:y(), atlas_icons.gauge, color8(255, 255, 255, 255), 0)
    update_ui_rectangle(pos:x() + 7, t, 5, b - t, col)
end

function render_circle(pos, radius, steps, col)
    local step = math.pi * 2 / steps
    
    for i = 0, steps - 1 do
        local angle = i * step
        local angle_next = angle + step
        update_ui_line(
            math.ceil(pos:x() + math.cos(angle) * radius), 
            math.ceil(pos:y() + math.sin(angle) * radius), 
            math.ceil(pos:x() + math.cos(angle_next) * radius),
            math.ceil(pos:y() + math.sin(angle_next) * radius),
            col
        )
    end
end

function render_line_segments(segments, col, factor)
    if #segments > 0 then
        local factor_step = 1 / #segments

        for i = 1, #segments do
            local step_min = factor_step * (i - 1)
            local step_max = factor_step * i
            local segment_factor = remap_clamp(factor, step_min, step_max, 0, 1)

            if segment_factor > 0 then
                local p0 = segments[i][1]
                local p1 = vec2_lerp(p0, segments[i][2], segment_factor)

                render_line_accurate(p0:x(), p0:y(), p1:x(), p1:y(), col)
            else
                return
            end
        end
    end
end

function render_line_accurate(x0, y0, x1, y1, col)
    local dx = x1 - x0
    local dy = y1 - y0
    local step = iff(math.abs(dx) > math.abs(dy), math.abs(dx), math.abs(dy))
    local x = x0
    local y = y0
    dx = dx / step
    dy = dy / step

    for i = 0, step do
        update_ui_rectangle(x, y, 1, 1, col)
        x = x + dx
        y = y + dy
    end
end

function world_to_screen_clamped(pos, clamp_min, clamp_max)
    local screen_pos, is_behind = update_world_to_screen(pos)
    local is_clamped = false
    
    if is_behind then 
        screen_pos = vec2_clamp_to_rect(vec2(-screen_pos:x(), -screen_pos:y()), clamp_min, clamp_max)
        is_clamped = true
    elseif vec2_in_rect(screen_pos, clamp_min, clamp_max) == false then
        screen_pos = vec2_clamp_to_rect(screen_pos, clamp_min, clamp_max) 
        is_clamped = true
    end

    return screen_pos, is_clamped
end

function get_is_attachment_observation_camera_controlled(attachment_def)
    return attachment_def == e_game_object_type.attachment_hardpoint_missile_laser
end

--------------------------------------------------------------------------------
--
-- UTIL
--
--------------------------------------------------------------------------------

function get_object_size_on_screen(screen_w, world_pos, world_radius)
    local camera_fov = update_get_camera_fov()
    local camera_pos = update_get_camera_position()
    local dist_to_camera = vec3_dist(world_pos, camera_pos)
    local screen_radius = world_radius / (math.tan(camera_fov / 2) * dist_to_camera) * (screen_w / 2)
    return screen_radius
end

function vec2_max(a, b)
    return vec2(math.max(a:x(), b:x()), math.max(a:y(), b:y()))
end

function get_control_mode_color(control_mode)
    if control_mode == "off" then
        return color8(255, 0, 0, 255)
    elseif control_mode == "manual" then
        return color8(0, 255, 0, 255)
    else
        return color8(255, 255, 0, 255)
    end
end

function get_control_mode_loc(control_mode)
    if control_mode == "manual" then
        return update_get_loc(e_loc.control_mode_manual)
    elseif control_mode == "auto" then
        return update_get_loc(e_loc.control_mode_auto)
    elseif control_mode == "override" then
        return update_get_loc(e_loc.control_mode_override)
    end

    return update_get_loc(e_loc.control_mode_off)
end

function get_stabilisation_mode_loc(stabilisation_mode)
    if stabilisation_mode == "stabilised" then
        return update_get_loc(e_loc.stabilisation_stabilised)
    elseif stabilisation_mode == "tracking" then
        return update_get_loc(e_loc.stabilisation_tracking)
    end

    return update_get_loc(e_loc.stabilisation_off)
end

function get_vehicle_attachment(vehicle_id, attachment_index)
    local vehicle = update_get_map_vehicle_by_id(vehicle_id)

    if vehicle:get() then
        local attachment = vehicle:get_attachment(attachment_index)

        if attachment:get() then
            return attachment
        end
    end

    return nil
end

function iter_sorted(t, sort_func)
    local sorted_keys = {}

    for k, v in pairs(t) do
        table.insert(sorted_keys, k)
    end

    table.sort(sorted_keys, sort_func)

    local index = 1

    return function()
        if index < #sorted_keys then
            local key = sorted_keys[index]
            index = index + 1

            return key, t[key]
        else
            return nil
        end
    end
end

function iter_vision(map_data, filter)
    local vision_data = map_data:get_vision_data()
    local index = 0

    local skip = function(v)
        return v == nil or v:get() == false or (filter ~= nil and filter(v) == false)
    end

    return function()
        local data = nil

        while index < #vision_data do
            data = vision_data[index + 1]
            index = index + 1

            if skip(data) then
                data = nil
            else
                break
            end
        end

        return data
    end
end

function iter_tiles(filter)
    local tile_count = update_get_tile_count()
    local index = 0

    local skip = function(v)
        return v == nil or v:get() == false or (filter ~= nil and filter(v) == false)
    end

    return function()
        local tile = nil

        while index < tile_count do
            tile = update_get_tile_by_index(index)
            index = index + 1

            if skip(tile) then
                tile = nil
            else
                break
            end
        end

        if tile ~= nil then
            return index, tile
        end
    end
end

function iter_vehicles(filter)
    local vehicle_count = update_get_map_vehicle_count()
    local index = 0

    local skip = function(v)
        return v == nil or v:get() == false or (filter ~= nil and filter(v) == false)
    end

    return function()
        local vehicle = nil

        while index < vehicle_count do
            vehicle = update_get_map_vehicle_by_index(index)
            index = index + 1

            if skip(vehicle) then
                vehicle = nil
            else
                break
            end
        end

        if vehicle ~= nil then
            return index, vehicle
        end
    end
end

function get_is_vehicle_controllable(vehicle)
    return vehicle:get_definition_index() ~= e_game_object_type.chassis_carrier
end

function get_vehicle_attachment_count(vehicle)
    if vehicle:get_definition_index() == e_game_object_type.chassis_carrier then
        return 1
    end

    return vehicle:get_attachment_count()
end

function get_is_damage_warning(vehicle)
    return vehicle:get_hitpoints() / vehicle:get_total_hitpoints() <= 0.25
end

function get_is_fuel_warning(vehicle)
    return vehicle:get_fuel_factor() <= 0.25
end

function get_attachment_display_name(vehicle, attachment)
    local definition_index = attachment:get_definition_index()

    if definition_index > e_game_object_type.count or definition_index < 0 then
       return update_get_loc(e_loc.upp_empty) 
    elseif definition_index == e_game_object_type.attachment_camera_vehicle_control and get_is_vehicle_controllable(vehicle) then
        return update_get_loc(e_loc.upp_vehicle_control)
    end

    local attachment_data = get_attachment_data_by_definition_index(definition_index)
    return attachment_data.name
end

--------------------------------------------------------------------------------
--
-- DEBUG
--
--------------------------------------------------------------------------------

-- function debug_update_print_regions(x, y)
--     local ind = 0
--     for k, v in pairs(atlas_icons) do
--         update_ui_text(x, y + ind * 9, k .. ": " .. v, 300, 0, color8(255, 255, 255, 255), 0)
--         ind = ind + 1
--     end
-- end

-- function debug_update_print_metatable(obj, x, y)
--     local meta = getmetatable(obj)

--     if meta then
--         local ind = 0

--         for k, v in pairs(meta) do
--             update_ui_text(x, y + 10 * ind, k .. " (" .. type(v) .. ")", 300, 0, color8(128, 128, 128, 255), 0)
--             ind = ind + 1

--             if type(v) == "table" then
--                 for kk, vv in pairs(v) do
--                     update_ui_text(x + 20, y + 10 * ind, kk .. " (" .. type(vv) .. ")", 300, 0, color8(128, 128, 128, 255), 0)
--                     ind = ind + 1
--                 end
--             end
--         end
--     else
--         update_ui_text(x, y, "no metatable", 300, 0, color8(128, 128, 128, 255), 0)
--     end
-- end


---
-- HUD Variometer Mod
---

-- class to store arbitrary values with a max tick age
-- this was inspired by the gun funnel history code but isn't related to it now
TimedHistory = {
    ident = 0,
    debug = 0,
    interval = 1,
    ttl = 30,
    ticks_per_sec = 30, -- estimated
    last_tick = 0,
    data = {},
    mean = 0,
    sample_size = 0,
    sample_min = 20000,
    sample_max = 0,
    last_value = 0,

    add_value = function(self, v)
        local tick = update_get_logic_tick()
        local sample_sum = 0
        local sample_count = 0
        local xsample_min = 2000
        local xsample_max = 0
        self.last_value = v
        if self.debug > 0 then
            update_ui_text(
                    10 + 180 * self.ident,
                    30,
                    string.format("%d mean() = %s", self.ident, self.mean),
                    300, 0, color8(255, 128, 128, 255), 0)
        end
        if tick - self.last_tick > self.interval then
            local sample = { time = tick, value = v }
            self.data[tick] = sample
            self.last_tick = tick
            -- trim off the oldest items
            for k, val in pairs(self.data) do
                if self.debug > 0 then
                    update_ui_text(
                            10 + 180 * self.ident,
                            50 + 10 * sample_count,
                            string.format("%d value = %s", self.ident, val.value),
                            300, 0, color8(255, 128, 128, 255), 0)
                end
                if tick - val.time > (self.ttl * self.ticks_per_sec) then
                    self.data[k] = nil
                else
                    if val.value > 0 then
                        sample_sum = sample_sum + val.value
                        sample_count = sample_count + 1
                        if val.value > xsample_max then
                            xsample_max = val.value
                        end
                        if val.value < xsample_min then
                            xsample_min = val.value
                        end

                    end
                end
            end

            self.sample_max = xsample_max
            self.sample_min = xsample_min

            if sample_count > 0 then
                self.mean = sample_sum / sample_count
            end
            self.sample_size = sample_count
        end
    end,
}
function TimedHistory:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

VarTimedHistory = TimedHistory:new()

Variometer = {
    alt = VarTimedHistory:new{ttl=1, ident=0, data={}},
    fuel = VarTimedHistory:new{ttl=30, ident=1, data={}},
    predicted_vector = {x=0, y=0},

    update = function(self, v)
        local pe, err = pcall(function() self._update(self, v) end)
        if pe then
            --
        else
            update_ui_text(5, 40, string.format("err in _update() = %s", err), 300, 0, color8(255, 128, 128, 255), 0)
        end
    end,

    _update = function(self, vehicle)
        self.alt:add_value(vehicle:get_altitude())
        self.fuel:add_value(vehicle:get_fuel_factor())
    end,

    fuel_burnrate = function(self)  -- % per sec
        return (self.fuel.sample_max - self.fuel.sample_min) / self.fuel.ticks_per_sec
    end,

    render = function(self, pos, col)
        local pe, err = pcall(function() self._render(self, pos, col) end)
        if pe then
            --
        else
            update_ui_text(5, 50, string.format("err in _render() = %s", err), 300, 0, color8(255, 128, 128, 255), 0)
        end
    end,

    _render = function(self, pos, col)
        -- render rate of climb
        local d_alt = self.alt.last_value - self.alt.mean -- m/s

        local d_alt_col = col
        local d_alt_bar_col = col
        local col_yellow = color8(255, 255, 0, 255)
        local col_warn = color8(255, 64, 64, 255)
        local col_stall = color8(64, 64, 255, 255)

        if d_alt < 0 then
            d_alt_col = col_yellow
        end
        update_ui_text(pos:x(), pos:y() + 110, string.format("%2.0f~", d_alt), 200, 0, d_alt_col, 0)

        -- clamp the bars
        if d_alt > 51 then
            d_alt = 51
        end
        if d_alt < -50 then
            d_alt = -50
        end

        -- set warning colors
        -- warn about terrain if < 5 sec before impact
        if d_alt < 0 then
            if (self.alt.last_value + (d_alt * 5)) < 0 then
                d_alt_bar_col = col_warn
            end
        end
        -- warn about stall if < 5 sec before 2000
        if d_alt > 0 then
            if (self.alt.last_value + (d_alt * 5)) > 2000 then
                d_alt_bar_col = col_stall
            end
        end

        -- render the variometer bars
        if d_alt < 0 then
            update_ui_rectangle(
                    pos:x() -8,
                    pos:y() + 52,
                    2, d_alt * -1, d_alt_bar_col)
        else
            update_ui_rectangle(
                    pos:x() -8,
                    pos:y() + 52 - (d_alt),
                    2, d_alt , d_alt_bar_col)
        end
        -- mid bar
        update_ui_rectangle(
                pos:x() -10,
                pos:y() + 50,
                5, 2, col)

        -- render fuel updates
        local fuel_number_col = col
        if self.fuel.last_value < 0.5 then
            fuel_number_col = color8(255, 255, 0, 255)
        end
        if self.fuel.last_value < 0.25 then
            fuel_number_col = color8(255, 0, 0, 255)
        end

        local fuel_count = self.fuel.last_value
        local fuel_per_min = self:fuel_burnrate() * 60
        local mins_remaining = fuel_count / fuel_per_min

        -- total %
        update_ui_text(
                pos:x() - 38,
                pos:y() + 140,
                string.format("%2.1f %s", fuel_count * 100, "%"),
                64, 0, fuel_number_col, 0)

        -- only render fuel estimates when we have proper data
        local fuel_use_per_min = "--- %/m"
        local fuel_time_mins = "--- mins"

        if self.fuel.sample_size > 30 then
            fuel_use_per_min = string.format("%2.1f %s/m", fuel_per_min * 100, "%")
            fuel_time_mins = string.format("%3.0f mins", mins_remaining)
        end
        -- % / min
        update_ui_text(
                pos:x() - 32,
                pos:y() + 150,
                fuel_use_per_min,
                64, 0, col, 0)
        -- time
        update_ui_text(
                pos:x() - 32,
                pos:y() + 160,
                fuel_time_mins,
                200, 0, fuel_number_col, 0)

    end,
}
