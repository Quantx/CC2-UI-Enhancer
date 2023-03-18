
g_colors = {
    backlight_default = color8(0, 2, 10, 255),
    glow_default = color8(64, 204, 255, 255),
    island_low_default = color8(0, 32, 64, 255),
    island_high_default = color8(0, 255, 255, 255),
    base_layer_default = color8(0, 5, 5, 255),
    grid_1_default = color8(0, 123, 201, 255),
    grid_2_default = color8(0, 26, 52, 128),
    holo = color8(0, 255, 255, 255),
    good = color8(0, 128, 255, 255),
    bad = color_status_bad
}

g_map_x = 0
g_map_z = 0
g_map_size = 2000
g_map_x_offset = 0
g_map_z_offset = 0
g_map_size_offset = 0
g_cursor_pos_prev_x = -1
g_cursor_pos_prev_y = -1
g_cursor_pos_next_x = -1
g_cursor_pos_next_y = -1
g_cursor_pos_x = -1
g_cursor_pos_y = -1
g_is_show_cursor = false
g_is_show_bearing = false
g_drag_pos_world_x = -1
g_drag_pos_world_y = -1

g_button_mode = 0
g_is_map_pos_initialised = false
g_is_render_holomap = true
g_is_render_holomap_tiles = true
g_is_render_holomap_vehicles = true
g_is_render_holomap_missiles = true
g_is_render_holomap_grids = true
g_is_render_holomap_backlight = true
g_is_render_team_capture = true
g_is_override_holomap_island_color = false

g_holomap_override_island_color_low = g_colors.island_low_default
g_holomap_override_island_color_high = g_colors.island_high_default
g_holomap_override_base_layer_color = g_colors.base_layer_default
g_holomap_backlight_color = g_colors.backlight_default
g_holomap_glow_color = g_colors.glow_default
g_holomap_grid_1_color = g_colors.grid_1_default
g_holomap_grid_2_color = g_colors.grid_2_default

g_blend_tick = 0
g_prev_pos_x = 0
g_prev_pos_y = 0
g_prev_size = (64 * 1024)
g_next_pos_x = 0
g_next_pos_y = 0
g_next_size = (64 * 1024)

g_is_pointer_hovered = false
g_pointer_pos_x = 0
g_pointer_pos_y = 0
g_pointer_pos_x_prev = 0
g_pointer_pos_y_prev = 0
g_is_pointer_pressed = false
g_is_mouse_mode = false

g_is_dismiss_pressed = false
g_animation_time = 0
g_dismiss_counter = 0
g_dismiss_duration = 20
g_notification_time = 0

g_focus_mode = 0
g_screen_w = 0
g_screen_h = 0

function parse()
    g_prev_pos_x = g_next_pos_x
    g_prev_pos_y = g_next_pos_y
    g_prev_size = g_next_size
    g_blend_tick = 0
    
    g_is_map_pos_initialised = parse_bool("is_map_init", g_is_map_pos_initialised)
    g_next_pos_x = parse_f32("map_x", g_next_pos_x)
    g_next_pos_y = parse_f32("map_y", g_next_pos_y)
    g_next_size = parse_f32("map_size", g_next_size)

    g_cursor_pos_prev_x = g_cursor_pos_next_x
    g_cursor_pos_prev_y = g_cursor_pos_next_y
    g_cursor_pos_next_x = parse_f32("", g_cursor_pos_next_x)
    g_cursor_pos_next_y = parse_f32("", g_cursor_pos_next_y)
    g_is_show_cursor = parse_bool("", g_is_show_cursor)
    g_drag_pos_world_x = parse_f32("", g_drag_pos_world_x)
    g_drag_pos_world_y = parse_f32("", g_drag_pos_world_y)
    g_is_show_bearing = parse_bool("", g_is_show_bearing)
end

function begin()
    g_ui = lib_imgui:create_ui()
    begin_load()
    begin_load_inventory_data()
end

function update(screen_w, screen_h, ticks) 
    g_screen_w = screen_w
    g_screen_h = screen_h
    g_is_mouse_mode = update_get_active_input_type() == e_active_input.keyboard
    g_animation_time = g_animation_time + ticks

    local screen_vehicle = update_get_screen_vehicle()

    if g_focus_mode ~= 0 then
        if g_focus_mode == 1 then
            focus_carrier()
        elseif g_focus_mode == 2 then
            focus_world()
        end

        g_focus_mode = 0
    end

    local function step(a, b, c)
        return a + clamp(b - a, -c, c)
    end

    if g_map_size_offset > 0 then
        g_map_x_offset = lerp(g_map_x_offset, 0, 0.15)
        g_map_z_offset = lerp(g_map_z_offset, 0, 0.15)
        
        if math.abs(g_map_x_offset) < 1000 then
            g_map_size_offset = step(g_map_size_offset, 0, 4000)
        end
    else
        g_map_size_offset = step(g_map_size_offset, 0, 4000)

        if math.abs(g_map_size_offset) < 1000 then
            g_map_x_offset = lerp(g_map_x_offset, 0, 0.15)
            g_map_z_offset = lerp(g_map_z_offset, 0, 0.15)
        end
    end

    if g_is_show_bearing == false then
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_pan), e_ui_interaction_special.map_pan)
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_zoom), e_ui_interaction_special.map_zoom)

        if update_get_is_notification_holomap_set() == false then
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_bearing), e_ui_interaction_special.interact_a_no_alt)
        end
    end

    if g_is_map_pos_initialised == false then
        g_is_map_pos_initialised = true
        focus_world()
    end

    if update_get_is_focus_local() then
        g_next_pos_x = g_map_x
        g_next_pos_y = g_map_z
        g_next_size = g_map_size

        if g_is_mouse_mode then
            g_cursor_pos_next_x = g_pointer_pos_x
            g_cursor_pos_next_y = g_pointer_pos_y
        else
            g_cursor_pos_next_x = screen_w / 2
            g_cursor_pos_next_y = screen_h / 2
        end

        g_is_show_cursor = true
    else
        g_blend_tick = g_blend_tick + 1
        local blend_factor = clamp(g_blend_tick / 10.0, 0.0, 1.0)
        g_map_x = lerp(g_prev_pos_x, g_next_pos_x, blend_factor)
        g_map_z = lerp(g_prev_pos_y, g_next_pos_y, blend_factor)
        g_map_size = lerp(g_prev_size, g_next_size, blend_factor)
        g_cursor_pos_x = lerp(g_cursor_pos_prev_x, g_cursor_pos_next_x, blend_factor)
        g_cursor_pos_y = lerp(g_cursor_pos_prev_y, g_cursor_pos_next_y, blend_factor)
    end
    
    if g_is_mouse_mode and update_get_is_notification_holomap_set() == false then
        if g_is_pointer_pressed then
            local pointer_dx, pointer_dy = get_world_delta_from_screen(g_pointer_pos_x - g_pointer_pos_x_prev, g_pointer_pos_y - g_pointer_pos_y_prev, g_map_size, screen_w, screen_h, 2.6 / 1.6)

            g_map_x = g_map_x - pointer_dx
            g_map_z = g_map_z - pointer_dy
        end
    end

    update_set_screen_background_type(g_button_mode + 1)
    update_set_screen_background_is_render_islands(false)
    update_set_screen_map_position_scale(g_map_x + g_map_x_offset, g_map_z + g_map_z_offset, g_map_size + g_map_size_offset)
    g_is_render_holomap_tiles = true
    g_is_render_holomap_vehicles = true
    g_is_render_holomap_missiles = true
    g_is_render_holomap_grids = true
    g_is_render_holomap_backlight = true
    g_is_render_team_capture = true
    g_is_override_holomap_island_color = false
    g_holomap_override_island_color_low = g_colors.island_low_default
    g_holomap_override_island_color_high = g_colors.island_high_default
    g_holomap_override_base_layer_color = g_colors.base_layer_default
    g_holomap_backlight_color = g_colors.backlight_default
    g_holomap_glow_color = g_colors.glow_default
    g_holomap_grid_1_color = g_colors.grid_1_default
    g_holomap_grid_2_color = g_colors.grid_2_default

    update_ui_rectangle(0, 0, screen_w, screen_h, color8(0, 0, 0, 220))

    if update_get_is_notification_holomap_set() then
        g_is_show_bearing = false
        g_notification_time = g_notification_time + 1

        update_set_screen_background_type(0)
        update_set_screen_background_is_render_islands(false)
        
        local notification = update_get_notification_holomap()
        local notification_col = get_notification_color(notification)

        g_holomap_backlight_color = color8(notification_col:r(), notification_col:g(), notification_col:b(), 10)
        g_holomap_glow_color = notification_col

        local border_col = notification_col
        local border_padding = 8
        local border_thickness = 4
        local border_w = 32
        local border_h = 24

        update_ui_rectangle(border_padding, border_padding, border_w, border_thickness, border_col)
        update_ui_rectangle(border_padding, border_padding, border_thickness, border_h, border_col)
        update_ui_rectangle(screen_w - border_padding - border_w, border_padding, border_w, border_thickness, border_col)
        update_ui_rectangle(screen_w - border_padding - border_thickness, border_padding, border_thickness, border_h, border_col)
        update_ui_rectangle(border_padding, screen_h - border_padding - border_thickness, border_w, border_thickness, border_col)
        update_ui_rectangle(border_padding, screen_h - border_padding - border_h, border_thickness, border_h, border_col)
        update_ui_rectangle(screen_w - border_padding - border_w, screen_h - border_padding - border_thickness, border_w, border_thickness, border_col)
        update_ui_rectangle(screen_w - border_padding - border_thickness, screen_h - border_padding - border_h, border_thickness, border_h, border_col)

        if notification:get() then
            render_notification_display(screen_w, screen_h, notification)
        end

        local is_dismiss = g_is_dismiss_pressed or (g_is_pointer_pressed and g_is_pointer_hovered and g_is_mouse_mode)
        
        if g_notification_time >= 30 then
            local color_dismiss = color_white
            update_ui_push_offset(screen_w / 2, screen_h - 34)

            if is_dismiss then
                local dismiss_factor = clamp(g_dismiss_counter / g_dismiss_duration, 0, 1)
                update_ui_rectangle(-30, -2, 60 * dismiss_factor, 13, color_dismiss)
            end

            update_ui_rectangle_outline(-30, -2, 60, 13, iff(is_dismiss, color_dismiss, iff(g_animation_time % 20 > 10, color_white, color_black)))
            update_ui_text(-30, 0, update_get_loc(e_loc.upp_dismiss), 60, 1, iff(is_dismiss, color_dismiss, color_white), 0)
            update_ui_pop_offset()
        end

        if is_dismiss then
            g_dismiss_counter = g_dismiss_counter + 1
        else
            g_dismiss_counter = 0
        end

        if g_dismiss_counter > g_dismiss_duration then
            g_dismiss_counter = 0
            g_is_dismiss_pressed = false
            g_is_pointer_pressed = false
            update_map_dismiss_notification()
        end
    else
        g_dismiss_counter = 0
        g_notification_time = 0

        local island_count = update_get_tile_count()

        if g_map_size < 80000 then
            -- render island names and icons

            for i = 0, island_count - 1, 1 do 
                local island = update_get_tile_by_index(i)

                if island:get() then
                    local island_color = update_get_team_color(island:get_team_control())
                    local island_position = island:get_position_xz()
                    local island_name = island:get_name()
                    local island_size = island:get_size()
                    local screen_pos_x, screen_pos_y = get_screen_from_world(island_position:x(), island_position:y(), g_map_x + g_map_x_offset, g_map_z + g_map_z_offset, g_map_size + 
                    g_map_size_offset, screen_w, screen_h, 2.6 / 1.6)
                    local _, name_pos_y = get_screen_from_world(island_position:x(), island_position:y() + island_size:y() / 2, g_map_x + g_map_x_offset, g_map_z + g_map_z_offset, g_map_size + 
                    g_map_size_offset, screen_w, screen_h, 2.6 / 1.6)
             
                    local name_pos_y = math.min(screen_pos_y - 27, name_pos_y)

                    update_ui_text(screen_pos_x - 100, name_pos_y, island_name, 200, 1, island_color, 0)

                    local difficulty_level = island:get_difficulty_level()
                    local icon_w = 6
                    local icon_spacing = 2
                    local icon_count = difficulty_level + 2
                    local total_w = icon_w * icon_count + icon_spacing * (icon_count - 1)
                    local icon_y = name_pos_y + 10
                    local icon_x = screen_pos_x - total_w / 2

                    local icon_index = 0
                    local category_data = g_item_categories[island:get_facility_category()]
                    update_ui_image(icon_x + (icon_w + icon_spacing) * icon_index, icon_y, category_data.icon, island_color, 0)
                    icon_index = icon_index + 2

                    for i = 0, difficulty_level - 1 do
                        update_ui_image(icon_x + (icon_w + icon_spacing) * icon_index, icon_y, atlas_icons.column_difficulty, island_color, 0)
                        icon_index = icon_index + 1
                    end
                end
            end
        end

        if update_get_is_focus_local() then
            if g_is_show_bearing == false then
                g_drag_pos_world_x, g_drag_pos_world_y = get_world_from_screen(g_cursor_pos_next_x, g_cursor_pos_next_y, g_map_x + g_map_x_offset, g_map_z + g_map_z_offset, g_map_size + 
                g_map_size_offset, screen_w, screen_h, 2.6 / 1.6)
            end
        end
    end

    if update_get_is_notification_holomap_set() == false then
        local cursor_x = iff(update_get_is_focus_local(), g_cursor_pos_next_x, g_cursor_pos_x)
        local cursor_y = iff(update_get_is_focus_local(), g_cursor_pos_next_y, g_cursor_pos_y)
        local cursor_world_x, cursor_world_y = get_world_from_screen(cursor_x, cursor_y, g_map_x + g_map_x_offset, g_map_z + g_map_z_offset, g_map_size + g_map_size_offset, screen_w, screen_h, 2.6 / 1.6)

        local cx = 20
        local cy = screen_h - 20
        local icon_col = color_white
        local text_col = color_grey_mid

        if g_is_show_bearing then
            local drag_x, drag_y = get_screen_from_world(g_drag_pos_world_x, g_drag_pos_world_y, g_map_x + g_map_x_offset, g_map_z + g_map_z_offset, g_map_size + 
            g_map_size_offset, screen_w, screen_h, 2.6 / 1.6)

            local team_col = update_get_team_color(update_get_screen_team_id())

            update_ui_circle(drag_x, drag_y, 2, 4, team_col)
            update_ui_line(drag_x, drag_y, cursor_x, cursor_y, team_col)

            local dist_screen = vec2_dist(vec2(drag_x, drag_y), vec2(cursor_x, cursor_y))
            local angle = math.atan(cursor_y - drag_y, cursor_x - drag_x)
            local bearing = 90 + angle / math.pi * 180
            if bearing < 0 then bearing = bearing + 360 end

            if dist_screen > 5 then
                local function rotate(x, y, a)
                    local s = math.sin(a)
                    local c = math.cos(a)
                    return x * c - y * s, x * s + y * c
                end

                local rad = 10

                if dist_screen > rad then
                    local step =  math.pi / 180 * 20
                    local bearing_rad =  bearing / 180 * math.pi

                    update_ui_push_offset(drag_x, drag_y)
                    update_ui_begin_triangles()

                    for a = 0, bearing_rad, step do
                        local a_next = math.min(bearing_rad, a + step)
                        local p0 = vec2(rotate(0, -rad, a))
                        local p1 = vec2(rotate(0, -rad, a_next))
                        update_ui_add_triangle(vec2(0, 0), p0, p1, mult_alpha(team_col, 0.1))
                        update_ui_line(math.floor(p0:x()), math.floor(p0:y()), math.floor(p1:x()), math.floor(p1:y()), team_col)
                    end

                    update_ui_end_triangles()
                    update_ui_pop_offset()
                end

                update_ui_push_offset(cursor_x, cursor_y)
                update_ui_begin_triangles()
                update_ui_add_triangle(vec2(rotate(0, 0, angle)), vec2(rotate(-10, -4, angle)), vec2(rotate(-10, 4, angle)), team_col)
                update_ui_end_triangles()
                update_ui_pop_offset()
            end

            update_ui_image(cx, cy, atlas_icons.column_angle, icon_col, 0)
            update_ui_text(cx + 15, cy, string.format("%.0f deg", bearing), 100, 0, text_col, 0)
            cy = cy - 10

            local dist = vec2_dist(vec2(g_drag_pos_world_x, g_drag_pos_world_y), vec2(cursor_world_x, cursor_world_y))

            if dist < 10000 then
                update_ui_image(cx, cy, atlas_icons.column_distance, icon_col, 0)
                update_ui_text(cx + 15, cy, string.format("%.0f ", dist) .. update_get_loc(e_loc.acronym_meters), 100, 0, text_col, 0)
            else
                update_ui_image(cx, cy, atlas_icons.column_distance, icon_col, 0)
                update_ui_text(cx + 15, cy, string.format("%.2f ", dist / 1000) .. update_get_loc(e_loc.acronym_kilometers), 100, 0, text_col, 0)
            end
    
            cy = cy - 10
        else
            if update_get_is_focus_local() == false and g_is_show_cursor then
                render_cursor(clamp(g_cursor_pos_x, 0, screen_w), clamp(g_cursor_pos_y, 0, screen_h))
            elseif g_is_mouse_mode == false then
                render_cursor(screen_w / 2, screen_h / 2)
            end
        end

        update_ui_text(cx, cy, "Y", 100, 0, icon_col, 0)
        update_ui_text(cx + 15, cy, string.format("%.0f", cursor_world_y), 100, 0, text_col, 0)
        cy = cy - 10

        update_ui_text(cx, cy, "X", 100, 0, icon_col, 0)
        update_ui_text(cx + 15, cy, string.format("%.0f", cursor_world_x), 100, 0, text_col, 0)
        cy = cy - 10
    end

    g_pointer_pos_x_prev = g_pointer_pos_x
    g_pointer_pos_y_prev = g_pointer_pos_y
end

function input_event(event, action)
    if event == e_input.action_a then
        g_is_dismiss_pressed = action == e_input_action.press

        if update_get_is_notification_holomap_set() == false then
            g_is_show_bearing = action == e_input_action.press
        end
    elseif event == e_input.pointer_1 then
        g_is_pointer_pressed = action == e_input_action.press
    elseif event == e_input.back then
        g_is_pointer_pressed = false
        g_is_show_cursor = false
        g_is_show_bearing = false
        update_set_screen_state_exit()
    end
end

function input_axis(x, y, z, w)
    if update_get_is_notification_holomap_set() == false then
        g_map_x = g_map_x + x * g_map_size * 0.02
        g_map_z = g_map_z + y * g_map_size * 0.02

        if update_get_active_input_type() == e_active_input.keyboard then
            map_zoom(1.0 - w * 0.1, g_screen_w, g_screen_h, g_screen_w / 2, g_screen_h / 2)
        else
            map_zoom(1.0 - w * 0.1, g_screen_w, g_screen_h)
        end
    end
end

function input_pointer(is_hovered, x, y)
    g_is_pointer_hovered = is_hovered
    
    g_pointer_pos_x = x
    g_pointer_pos_y = y
end

function input_scroll(dy)
    if update_get_is_notification_holomap_set() == false then
        if g_is_mouse_mode then
            map_zoom(1 - dy * 0.15, g_screen_w, g_screen_h)
        end
    end
end

function on_set_focus_mode(mode)
    g_focus_mode = mode
end

function map_zoom(amount, screen_w, screen_h, zoom_x, zoom_y)
    local cursor_x = zoom_x or g_cursor_pos_next_x
    local cursor_y = zoom_y or g_cursor_pos_next_y
    local cursor_prev_x, cursor_prev_y = get_world_from_screen(cursor_x, cursor_y, g_map_x + g_map_x_offset, g_map_z + g_map_z_offset, g_map_size + g_map_size_offset, screen_w, screen_h, 2.6 / 1.6)

    g_map_size = g_map_size * amount
    g_map_size = math.max(500, math.min(g_map_size, 200000))

    local cursor_next_x, cursor_next_y = get_world_from_screen(cursor_x, cursor_y, g_map_x + g_map_x_offset, g_map_z + g_map_z_offset, g_map_size + g_map_size_offset, screen_w, screen_h, 2.6 / 1.6)
    local dx = cursor_next_x - cursor_prev_x
    local dy = cursor_next_y - cursor_prev_y
    g_map_x = g_map_x - dx
    g_map_z = g_map_z - dy
end

function render_cursor(x, y)
    local col = color_white
    local col_grid = color8(128, 255, 255, 8)

    update_ui_push_offset(x, y)

    local thickness = 2
    local size = 1000
    local border = 10
    update_ui_rectangle(-thickness / 2, border, thickness, size, col_grid)
    update_ui_rectangle(-thickness / 2, -size - border, thickness, size, col_grid)
    update_ui_rectangle(border, -thickness / 2, size, thickness, col_grid)
    update_ui_rectangle(-size - border, -thickness / 2, size, thickness, col_grid)

    thickness = 2
    size = 6
    border = 2
    update_ui_rectangle(-thickness / 2, border, thickness, size, col)
    update_ui_rectangle(-thickness / 2, -size - border, thickness, size, col)
    update_ui_rectangle(border, -thickness / 2, size, thickness, col)
    update_ui_rectangle(-size - border, -thickness / 2, size, thickness, col)
    update_ui_pop_offset() 
end

function render_notification_display(screen_w, screen_h, notification)
    local notification_type = notification:get_type()
    local notification_color = get_notification_color(notification)
    local text_col = notification_color

    -- g_is_render_holomap_grids = false

    if notification_type == e_map_notification_type.island_captured then
        local tile = update_get_tile_by_id(notification:get_tile_id())
        render_notification_tile(screen_w, screen_h, update_get_loc(e_loc.upp_island_captured), text_col, tile)

        g_is_render_holomap_vehicles = false
        g_is_render_holomap_missiles = false
        g_is_render_team_capture = false
        g_is_override_holomap_island_color = true
        g_holomap_override_island_color_low = g_colors.island_low_default
        g_holomap_override_island_color_high = g_colors.good
        g_holomap_override_base_layer_color = g_colors.base_layer_default
        g_holomap_glow_color = color8(64, 128, 255, 255)
    elseif notification_type == e_map_notification_type.island_lost then
        local tile = update_get_tile_by_id(notification:get_tile_id())
        render_notification_tile(screen_w, screen_h, update_get_loc(e_loc.upp_island_lost), text_col, tile)

        g_is_render_holomap_vehicles = false
        g_is_render_holomap_missiles = false
        g_is_render_team_capture = false
        g_is_override_holomap_island_color = true
        g_holomap_override_island_color_low = color8(32, 0, 0, 255)
        g_holomap_override_island_color_high = color8(255, 32, 0, 255)
        g_holomap_override_base_layer_color = color8(5, 1, 0, 255)
        g_holomap_backlight_color = color8(255, 0, 0, 10)
        g_holomap_grid_1_color = color8(128, 32, 0, 255)
        g_holomap_grid_2_color = color8(100, 0, 0, 128)
        g_holomap_glow_color = color8(255, 16, 8, 255)
    elseif notification_type == e_map_notification_type.blueprint_unlocked then
        render_notification_blueprint(screen_w, screen_h, notification:get_blueprints(), text_col)

        g_is_render_holomap_vehicles = false
        g_is_render_holomap_missiles = false
        g_is_render_team_capture = false
        g_is_render_holomap_tiles = false
        -- g_is_render_holomap_grids = false

        g_holomap_grid_1_color = mult_alpha(text_col, 0.1)
        g_holomap_grid_2_color = mult_alpha(text_col, 0.05)
    end
end

function render_notification_blueprint(screen_w, screen_h, blueprints, text_col)
    if #blueprints > 0 then
        local label = iff(#blueprints == 1, update_get_loc(e_loc.upp_blueprint_unlocked), update_get_loc(e_loc.upp_blueprints_unlocked))
        local item_spacing = 5
        local item_h = 18
        local rows_per_column = 6
        local columns = math.ceil(#blueprints / rows_per_column)
        local rows = iff(#blueprints <= rows_per_column, #blueprints, math.floor((#blueprints - 1) / columns) + 1)

        local display_h = 30 + rows * (item_h + item_spacing)
        local cy = (screen_h - display_h) / 2
        
        update_ui_text_scale(0, cy, label, screen_w, 1, text_col, 0, 3)
        cy = cy + 30 + item_spacing

        local function render_item_data(x, y, w, item)
            update_ui_push_offset(x, y)
            update_ui_rectangle_outline(0, 0, 18, 18, text_col)
            update_ui_image(1, 1, item.icon, color_white, 0)
            update_ui_text(22, 4, item.name, w - 22, 0, color_white, 0)

            update_ui_pop_offset()
        end

        local column_width = 120
        local column_spacing = 5
        local column_items = {}

        local function render_columns(items)
            if #items > 0 then
                local total_column_width = #items * (column_width + column_spacing) - column_spacing
                
                for i = 1, #items do
                    local cx = (screen_w - total_column_width) / 2 + (i - 1) * (column_width + column_spacing)
                    render_item_data(cx, cy, column_width, items[i])
                end

                cy = cy + item_h + item_spacing
            end
        end

        for i = 1, #blueprints do
            table.insert(column_items, g_item_data[blueprints[i]])

            if #column_items == columns then
                render_columns(column_items)
                column_items = {}
            end
        end

        render_columns(column_items)
    end
end

function render_notification_tile(screen_w, screen_h, label, text_col, tile)
    if tile:get() then
        local tile_size = tile:get_size()
        local tile_pos = tile:get_position_xz()
        local tile_rect_size = 128
        local map_size_for_tile = screen_h / tile_rect_size * tile_size:y()

        local cy = (screen_h - tile_rect_size) / 2 - 20
        cy = cy + update_ui_text_scale(0, cy, label, screen_w, 1, text_col, 0, 3)
        
        update_set_screen_map_position_scale(tile_pos:x(), tile_pos:y(), map_size_for_tile)

        cy = (screen_h + tile_rect_size) / 2 - 10
        cy = cy + update_ui_text(0, cy, tile:get_name(), screen_w, 1, text_col, 0)

        local difficulty_level = tile:get_difficulty_level()
        local icon_w = 6
        local icon_spacing = 2
        local total_w = icon_w * difficulty_level + icon_spacing * (difficulty_level - 1)

        for i = 0, difficulty_level - 1 do
            update_ui_image(screen_w / 2 - total_w / 2 + (icon_w + icon_spacing) * i, cy, atlas_icons.column_difficulty, text_col, 0)
        end
        cy = cy + 10

        local facility_type = tile:get_facility_category()
        local facility_data = g_item_categories[facility_type]
        update_ui_image((screen_w - update_ui_get_text_size(facility_data.name, 10000, 0)) / 2 - 8, cy, facility_data.icon, text_col, 0)
        cy = cy + update_ui_text(8, cy, facility_data.name, screen_w, 1, text_col, 0)
    else
        update_ui_text_scale(0, screen_h / 2 - 15, label, screen_w, 1, text_col, 0, 3)
    end
end

function get_notification_color(notification)
    local color = g_colors.holo

    if notification:get() then
        local type = notification:get_type()

        if type == e_map_notification_type.island_captured then
            color = g_colors.good
        elseif type == e_map_notification_type.island_lost then
            color = g_colors.bad
        elseif type == e_map_notification_type.blueprint_unlocked then
            color = color8(16, 255, 128, 255)
        end
    end

    return iff(g_notification_time < 30 and g_notification_time % 10 < 5, color_white, color)
end

function focus_carrier()
    local screen_vehicle = update_get_screen_vehicle()

    if screen_vehicle:get() then
        local pos_xz = screen_vehicle:get_position_xz()
        transition_to_map_pos(pos_xz:x(), pos_xz:y(), 5000)
    end
end

function focus_world()
    local tile_count = update_get_tile_count()

    local function min(a, b)
        if a == nil then return b end
        return math.min(a, b)
    end

    local function max(a, b)
        if a == nil then return b end
        return math.max(a, b)
    end

    local min_x = nil
    local min_z = nil
    local max_x = nil
    local max_z = nil

    for i = 0, tile_count - 1 do
        local tile = update_get_tile_by_index(i)

        if tile:get() then
            local tile_pos_xz = tile:get_position_xz()
            local tile_size = tile:get_size()
            
            min_x = min(min_x, tile_pos_xz:x() - tile_size:x() / 2)
            min_z = min(min_z, tile_pos_xz:y() - tile_size:y() / 2)
            max_x = max(max_x, tile_pos_xz:x() + tile_size:x() / 2)
            max_z = max(max_z, tile_pos_xz:y() + tile_size:y() / 2)
        end
    end

    if min_x ~= nil then
        local target_x = (min_x + max_x) / 2
        local target_z = (min_z + max_z) / 2
        local target_size = math.max(max_x - min_x, max_z - min_z) * 1.5

        transition_to_map_pos(target_x, target_z, target_size)
    end
end

function transition_to_map_pos(x, z, size)
    g_map_x_offset = (g_map_x + g_map_x_offset) - x
    g_map_z_offset = (g_map_z + g_map_z_offset) - z
    g_map_size_offset = (g_map_size + g_map_size_offset) - size
    g_map_x = x
    g_map_z = z
    g_map_size = size
    g_next_pos_x = g_map_x
    g_next_pos_y = g_map_z
    g_next_size = g_map_size
end