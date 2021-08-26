g_tab_map = {
    tab_title = e_loc.upp_map,
    render = nil,
    input_event = nil,
    input_pointer = nil,
    input_scroll = nil,
    is_overlay = false,

    camera_pos_x = 81438,
    camera_pos_y = 91753,
    camera_size = 256 * 1024,
    camera_size_max = 256 * 1024,
    camera_size_min = 1024,
    cursor_pos_x = 0,
    cursor_pos_y = 0,
    is_drag_pan_map = false,
    hovered_id = 0,
    hovered_type = 0,
    dragged_id = 0,
    dragged_type = 0,
    is_map_pos_initialised = false,

    selected_facility_id = 0,
    selected_facility_item = -1,
    selected_facility_queue_item = -1,
    selected_barge_id = 0,
    selected_panel = 0,
}

g_tab_stock = {
    tab_title = e_loc.upp_stock,
    render = nil,
    input_event = nil,
    input_pointer = nil,
    input_scroll = nil,
    is_overlay = false,

    selected_item = -1,
}

g_tab_barges = {
    tab_title = e_loc.upp_barges,
    render = nil,
    input_event = nil,
    input_pointer = nil,
    input_scroll = nil,
    is_overlay = false,

    selected_item = -1,
}

g_tabs = {
    [0] = g_tab_stock,
    [1] = g_tab_map,
    [2] = g_tab_barges,
    stock = 0,
    map = 1,
    barges = 2,
}

g_screens = {
    menu = 0,
    active_tab = 1,
}

g_focused_screen = g_screens.menu
g_active_tab = g_tabs.stock
g_hovered_tab = -1

g_link_types = {
    tile = 0,
    carrier = 1,
    barge = 2
}

g_map_colors = {
    barge = color8(0, 255, 64, 255),
    factory = color8(255, 128, 0, 255),
    carrier = color8(0, 64, 255, 255),
    inactive = color_grey_dark,
    progress = color_status_bad,
}

g_animation_time = 0

g_input = {}
g_input_axis = { x = 0, y = 0, z = 0, w = 0 }
g_input_repeat_rate = 3
g_input_repeat_delay = 15

g_ui = nil
g_is_pointer_hovered = false
g_pointer_pos_x = 0
g_pointer_pos_y = 0
g_pointer_pos_x_prev = 0
g_pointer_pos_y_prev = 0
g_is_pointer_pressed = false
g_pointer_scroll = 0
g_is_mouse_mode = false


--------------------------------------------------------------------------------
--
-- BEGIN
--
--------------------------------------------------------------------------------

function parse()
    g_focused_screen = parse_s32("", g_focused_screen)
    g_active_tab = parse_s32("active_tab", g_active_tab)
    g_tab_map.is_map_pos_initialised = parse_bool("is_map_init", g_tab_map.is_map_pos_initialised)
    g_tab_map.camera_pos_x = parse_f32("map_x", g_tab_map.camera_pos_x)
    g_tab_map.camera_pos_y = parse_f32("map_y", g_tab_map.camera_pos_y)
    g_tab_map.camera_size = parse_f32("map_size", g_tab_map.camera_size)
    g_tab_map.cursor_pos_x = parse_f32("", g_tab_map.cursor_pos_x)
    g_tab_map.cursor_pos_y = parse_f32("", g_tab_map.cursor_pos_y)
    g_tab_map.selected_facility_id = parse_s32("", g_tab_map.selected_facility_id)
    g_tab_map.selected_facility_item = parse_s32("", g_tab_map.selected_facility_item)
    g_tab_map.selected_facility_queue_item = parse_s32("", g_tab_map.selected_facility_queue_item)
    g_tab_map.selected_panel = parse_s32("", g_tab_map.selected_panel)
    g_tab_stock.selected_item = parse_s32("", g_tab_stock.selected_item)
    g_tab_barges.selected_item = parse_s32("", g_tab_barges.selected_item)
end

function begin()
    begin_load()
    begin_load_inventory_data()
    g_ui = lib_imgui:create_ui()

    g_tab_map.render = tab_map_render
    g_tab_map.input_event = tab_map_input_event
    g_tab_map.input_pointer = tab_map_input_pointer
    g_tab_map.input_scroll = tab_map_input_scroll

    g_tab_stock.render = tab_stock_render
    g_tab_stock.input_event = tab_stock_input_event
    g_tab_stock.input_pointer = tab_stock_input_pointer
    g_tab_stock.input_scroll = tab_stock_input_scroll

    g_tab_barges.render = tab_barges_render
    g_tab_barges.input_event = tab_barges_input_event
    g_tab_barges.input_pointer = tab_barges_input_pointer
    g_tab_barges.input_scroll = tab_barges_input_scroll

    local screen_name = begin_get_screen_name()

    if screen_name == "screen_inv_r_large" then
        g_active_tab = g_tabs.map
    end
end


--------------------------------------------------------------------------------
--
-- UPDATE
--
--------------------------------------------------------------------------------

function update(screen_w, screen_h, ticks) 
    g_is_mouse_mode = update_get_active_input_type() == e_active_input.keyboard
    g_animation_time = g_animation_time + ticks

    local vehicle = update_get_screen_vehicle()
    if vehicle:get() == false then return end
    
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    update_interaction_ui()

    local is_hoverable = g_focused_screen == g_screens.menu or g_tabs[g_active_tab].is_overlay == false

    if g_is_mouse_mode and g_is_pointer_hovered and is_hoverable and update_get_screen_state_active() then
        if g_pointer_pos_y > 15 then
            g_focused_screen = g_screens.active_tab
        else
            g_focused_screen = g_screens.menu
        end
    end

    update_ui_rectangle(0, 0, screen_w, 14, color_black)
    update_ui_line(0, 14, screen_w, 14, iff(is_hoverable, iff(g_focused_screen == g_screens.active_tab, color_white, color_highlight), color_grey_dark))
    
    local cx = 10

    g_hovered_tab = -1

    for i = 0, #g_tabs do
        local tab_name = update_get_loc(g_tabs[i].tab_title)
        local tx = cx
        local ty = 4
        local tw = update_ui_get_text_size(tab_name, 10000, 1) + 8
        local th = 11

        local is_hovered = g_is_mouse_mode and g_is_pointer_hovered and point_in_rect(tx, ty, tw, th, g_pointer_pos_x, g_pointer_pos_y) and is_hoverable

        if is_hovered then
            g_hovered_tab = i
        end

        render_tab(tx, ty, tw, tab_name, get_tab_colors(g_active_tab == i and g_focused_screen == g_screens.active_tab, g_active_tab == i, is_hovered, is_hoverable == false))
        cx = cx + tw + 1
    end

    update_ui_push_clip(0, 15, screen_w, screen_h - 15)

    g_ui:begin_ui()
    g_tabs[g_active_tab].render(screen_w, screen_h, 0, 15, screen_w, screen_h - 15, g_focused_screen == g_screens.active_tab, vehicle)
    g_ui:end_ui()

    update_ui_pop_clip()

    render_currency_display(screen_w - 10, 5, g_tab_map.selected_facility_id ~= 0 and g_tab_map.selected_facility_item ~= -1)

    g_pointer_scroll = 0
    g_pointer_pos_x_prev = g_pointer_pos_x
    g_pointer_pos_y_prev = g_pointer_pos_y
end

function set_active_tab(tab)
    if g_active_tab ~= tab then
        g_active_tab = tab
        
        if g_tabs[tab] ~= nil and g_tabs[tab].begin ~= nil then
            g_tabs[tab].begin()
        end
    end
end

function update_interaction_ui()
    if update_get_active_input_type() == e_active_input.gamepad then
        if g_focused_screen == g_screens.active_tab then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)
        elseif g_focused_screen == g_screens.menu then
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_lr)
            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
        end
    elseif g_hovered_tab ~= -1 then
        update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
    end

    if g_focused_screen == g_screens.active_tab then
        if g_active_tab == g_tabs.map then
            if g_tab_map.selected_facility_id == 0 then
                update_add_ui_interaction_special(update_get_loc(e_loc.interaction_pan), e_ui_interaction_special.map_pan)
                update_add_ui_interaction_special(update_get_loc(e_loc.interaction_zoom), e_ui_interaction_special.map_zoom)
    
                if g_tab_map.dragged_id == 0 and g_tab_map.hovered_id ~= 0 then
                    if g_tab_map.hovered_type == g_link_types.tile then
                        local tile = update_get_tile_by_id(g_tab_map.hovered_id)
    
                        if tile:get() and tile:get_team_control() == update_get_screen_team_id() then
                            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
                        end
                    elseif g_tab_map.hovered_type == g_link_types.barge then
                        local barge = update_get_map_vehicle_by_id(g_tab_map.hovered_id)

                        if barge:get() and barge:get_team() == update_get_screen_team_id() then
                            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
                        end
                    end
                end
            end
        end
    end
end


--------------------------------------------------------------------------------
--
-- INPUT
--
--------------------------------------------------------------------------------

function get_input(event)
    if g_input[event] == nil then 
        g_input[event] = { 
            is_pressed = false, 
            repeat_counter = -g_input_repeat_delay
        } 
    end

    return g_input[event]
end

function input_event(event, action)
    if event == e_input.pointer_1 then
        g_is_pointer_pressed = action == e_input_action.press
    end

    if g_focused_screen == g_screens.menu then
        if event == e_input.back then
            if action == e_input_action.press then
                exit_screen()
            end
        elseif event == e_input.left then
            if action == e_input_action.press then
                set_active_tab((g_active_tab + #g_tabs) % (#g_tabs + 1))
            end
        elseif event == e_input.right then
            if action == e_input_action.press then
                set_active_tab((g_active_tab + 1) % (#g_tabs + 1))
            end
        elseif event == e_input.action_a then
            if action == e_input_action.press then
                g_focused_screen = g_screens.active_tab
            end
        elseif event == e_input.pointer_1 then
            if g_hovered_tab ~= -1 then
                set_active_tab(g_hovered_tab)
            end
        end
    elseif g_focused_screen == g_screens.active_tab then
        if g_tabs[g_active_tab].input_event(event, action) then
            if g_is_mouse_mode then
                exit_screen()
            else
                g_focused_screen = g_screens.menu
            end
        end
    end
end

function exit_screen()
    g_focused_screen = g_screens.menu
    g_hovered_tab = -1
    update_set_screen_state_exit()
end

function input_pointer(is_hovered, x, y)
    g_is_pointer_hovered = is_hovered
    
    g_pointer_pos_x = x
    g_pointer_pos_y = y
        
    g_tabs[g_active_tab].input_pointer(is_hovered, x, y)
end

function input_scroll(dy)
    g_pointer_scroll = g_pointer_scroll + dy
    g_tabs[g_active_tab].input_scroll(dy)
end

function input_axis(x, y, z, w)
    g_input_axis.x = x
    g_input_axis.y = y
    g_input_axis.z = z
    g_input_axis.w = w
    
    if update_get_is_vr() then
        input_scroll(w)
    end
end

--------------------------------------------------------------------------------
--
-- BARGE DISPLAY
--
--------------------------------------------------------------------------------

function tab_barges_render(screen_w, screen_h, x, y, w, h, is_tab_active, screen_vehicle)
    local ui = g_ui
    g_tab_barges.is_overlay = false
    update_ui_push_offset(x, y)

    local vehicle_team = screen_vehicle:get_team()
    local vehicle_filter = function(v)
        return v:get_definition_index() == e_game_object_type.chassis_sea_barge and v:get_team() == vehicle_team
    end

    local barges = {}
    for _, barge in iter_vehicles(vehicle_filter) do
        table.insert(barges, barge)
    end

    ui:begin_window("##barges", 5, 0, w - 10, h, nil, is_tab_active and g_tab_barges.selected_item == -1, 1)
        local selected_item = imgui_barge_table(ui, barges)
        ui:divider(0, 3)
        ui:divider(0, 10)

        if selected_item ~= -1 and barges[selected_item] ~= nil then
            g_tab_barges.selected_item = barges[selected_item]:get_id()
        end
    ui:end_window()

    local selected_barge = update_get_map_vehicle_by_id(g_tab_barges.selected_item)

    if selected_barge:get() then
        g_tab_barges.is_overlay = true
        update_ui_rectangle(0, 0, screen_w, screen_h, color8(0, 0, 0, 200))

        update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)

        local display_id = selected_barge:get_id() % 1000
        local window = ui:begin_window(update_get_loc(e_loc.upp_barge_id).. " " .. display_id .. "##selectedbarge", 60, 5, w - 120, h - 20, atlas_icons.column_distance, is_tab_active, 2)
            local inventory_capacity = selected_barge:get_inventory_capacity()
            local inventory_weight = selected_barge:get_inventory_weight()

            ui:header(update_get_loc(e_loc.upp_inventory))

            window.label_bias = 0.1
            ui:stat(atlas_icons.column_weight, inventory_weight .. "/" .. inventory_capacity, iff(inventory_weight < inventory_capacity, color_status_ok, color_status_bad))
            window.label_bias = 0.5

            ui:header(update_get_loc(e_loc.upp_actions))

            if ui:list_item(update_get_loc(e_loc.upp_show_on_map), true) then
                g_tab_barges.selected_item = -1

                local barge_pos_xz = selected_barge:get_position_xz()
                g_tab_map.camera_pos_x = barge_pos_xz:x()
                g_tab_map.camera_pos_y = barge_pos_xz:y()
                g_tab_map.camera_size = 4096
                set_active_tab(g_tabs.map)
            end

            local action, destination_id, destination_type = selected_barge:get_barge_state_data()
            local pos_xz = get_node_pos_xz(destination_id, destination_type)

            if ui:list_item(update_get_loc(e_loc.upp_show_destination), true, pos_xz ~= nil) then
                if pos_xz ~= nil then
                    g_tab_barges.selected_item = -1

                    local barge_pos_xz = selected_barge:get_position_xz()
                    g_tab_map.camera_pos_x = pos_xz:x()
                    g_tab_map.camera_pos_y = pos_xz:y()
                    g_tab_map.camera_size = 4096
                    set_active_tab(g_tabs.map)
                end
            end

            if ui:list_item(update_get_loc(e_loc.upp_inventory), true) then
                g_tab_barges.selected_item = -1

                g_tab_map.selected_barge_id = selected_barge:get_id()
                set_active_tab(g_tabs.map)
            end
        ui:end_window()
    else
        g_tab_barges.selected_item = -1
        
        if is_tab_active then
            if #barges > 0 then
                update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)
                update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
            end
        end
    end

    update_ui_pop_offset()
end

function tab_barges_input_event(input, action)
    if input == e_input.back and action == e_input_action.press then
        if g_tab_barges.selected_item ~= -1 then
            g_tab_barges.selected_item = -1
        else
            return true
        end
    end

    g_ui:input_event(input, action)
    return false
end

function tab_barges_input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
end

function tab_barges_input_scroll(dy)
    g_ui:input_scroll(dy)
end

function imgui_barge_table(ui, barges)
    local window = ui:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = ui:get_region()
    local selected_item = -1

    local column_widths = { 30, 94, 60, 40 }
    local column_margins = { 5, 2, 2, 2 }

    local header_columns = {
        { w=column_widths[1], margin=column_margins[1], value=update_get_loc(e_loc.upp_id) },
        { w=column_widths[2], margin=column_margins[2], value=atlas_icons.hud_warning },
        { w=column_widths[3], margin=column_margins[3], value=atlas_icons.column_transit },
        { w=column_widths[4], margin=column_margins[4], value=atlas_icons.column_distance },
    }
    imgui_table_header(ui, header_columns)
        
    for k, barge in pairs(barges) do
        local get_action_text = function(action_type, destination_type)
            if action_type == e_barge_action.load then
                return update_get_loc(e_loc.upp_load_stock)
            elseif action_type == e_barge_action.unload then
                return update_get_loc(e_loc.upp_unload)
            elseif action_type == e_barge_action.load_carrier_stock then
                return iff(destination_type == g_link_types.carrier, update_get_loc(e_loc.collect_surplus), update_get_loc(e_loc.collect_order))
            elseif action_type == e_barge_action.unload_carrier_stock then
                return update_get_loc(e_loc.upp_deliver_order)
            end
    
            return "---"
        end
    
        local action, destination_id, destination_type = barge:get_barge_state_data()
        local dist_to_target = 0
        local waypoint = barge:get_waypoint(0)
        local text_action = get_action_text(action, destination_type)
        local text_destination = "---"
        local text_dist = "---"
        local col_destination = color_grey_dark
    
        if waypoint:get() then
            local waypoint_pos_xz = waypoint:get_position_xz()
            local barge_pos_xz = barge:get_position_xz()
    
            dist_to_target = vec2_dist(waypoint_pos_xz, barge_pos_xz)
        end
    
        if destination_id ~= 0 then
            local label, col = get_node_data(destination_id, destination_type)
    
            if label ~= nil then
                text_destination = get_action_text(action, destination_type)
                text_destination = label
                col_destination = col
            end
        else
            text_action = update_get_loc(e_loc.upp_idle)
        end

        if dist_to_target > 0 then
            text_dist = string.format("%.0fm", math.min(99999, dist_to_target))
        end

        local columns = { 
            { w=column_widths[1], margin=column_margins[1], value=tostring(barge:get_id() % 1000) },
            { w=column_widths[2], margin=column_margins[2], value=text_action },
            { w=column_widths[3], margin=column_margins[3], value=text_destination, col=col_destination },
            { w=column_widths[4], margin=column_margins[4], value=text_dist }
        }

        local is_action = imgui_table_entry(ui, columns, true)

        if is_action then
            selected_item = k
        end
    end

    return selected_item
end


--------------------------------------------------------------------------------
--
-- MAP DISPLAY
--
--------------------------------------------------------------------------------

function tab_map_render(screen_w, screen_h, x, y, w, h, is_tab_active, screen_vehicle)
    if g_tab_map.is_map_pos_initialised == false then
        g_tab_map.is_map_pos_initialised = true
        focus_world()
    end

    update_map_cursor_state(screen_w, screen_h)
    g_tab_map.is_overlay = false
    
    update_ui_push_clip(x, y, w, h)
    render_map_details(screen_vehicle, screen_w, screen_h, is_tab_active and g_tab_map.selected_facility_id == 0)
    update_ui_pop_clip()

    render_map_ui(screen_w, screen_h, x, y, w, h, screen_vehicle, is_tab_active)
end

function render_map_details(screen_vehicle, screen_w, screen_h, is_tab_active)
    update_ui_rectangle(0, 0, screen_w, screen_w, color8(5, 5, 5, 255))
    update_set_screen_map_position_scale(g_tab_map.camera_pos_x, g_tab_map.camera_pos_y, g_tab_map.camera_size)

    if is_tab_active then
        g_tab_map.camera_pos_x = g_tab_map.camera_pos_x + (g_input_axis.x * g_tab_map.camera_size * 0.01)
        g_tab_map.camera_pos_y = g_tab_map.camera_pos_y + (g_input_axis.y * g_tab_map.camera_size * 0.01)
        input_map_zoom_camera(1 - (g_input_axis.w * 0.1))

        if g_is_mouse_mode then
            if g_tab_map.is_drag_pan_map then
                g_tab_map.camera_pos_x = g_tab_map.camera_pos_x - ((g_pointer_pos_x - g_pointer_pos_x_prev) * g_tab_map.camera_size * 0.005)
                g_tab_map.camera_pos_y = g_tab_map.camera_pos_y + ((g_pointer_pos_y - g_pointer_pos_y_prev) * g_tab_map.camera_size * 0.005)
            end
        end
    else
        g_tab_map.is_drag_pan_map = false
    end

    local vehicle_team = screen_vehicle:get_team()

    local vehicle_filter = function(v)
        local def = v:get_definition_index()
        local team = v:get_team()
        return team == vehicle_team and (def == e_game_object_type.chassis_sea_barge or def == e_game_object_type.chassis_carrier)
    end

    local is_render_islands = (g_tab_map.camera_size < (64 * 1024))
    update_set_screen_background_is_render_islands(is_render_islands)

    for _, vehicle in iter_vehicles(vehicle_filter) do
        local waypoint_count = vehicle:get_waypoint_count()

        local pos_prev = vehicle:get_position_xz()

        for i = 0, waypoint_count do
            local waypoint_data = vehicle:get_waypoint(i)

            if waypoint_data:get() then
                local waypoint_pos = waypoint_data:get_position_xz()

                local s0x, s0y = get_screen_from_world(pos_prev:x(), pos_prev:y(), g_tab_map.camera_pos_x, g_tab_map.camera_pos_y, g_tab_map.camera_size, screen_w, screen_h)
                
                local s1x, s1y = get_screen_from_world(waypoint_pos:x(), waypoint_pos:y(), g_tab_map.camera_pos_x, g_tab_map.camera_pos_y, g_tab_map.camera_size, screen_w, screen_h)

                update_ui_line(s0x, s0y, s1x, s1y, color_grey_dark)

                pos_prev = waypoint_pos
            end
        end
    end

    for _, link in iter_resource_links() do
        render_resource_link(link, screen_w, screen_h)
    end

    local is_collapse_icons = g_tab_map.camera_size > g_tab_map.camera_size_max * 0.4
    local team_color = update_get_team_color(vehicle_team)
    local tile_color = color8(16, 16, 16, 255)

    for _, tile in iter_tiles() do 
        local tile_position = tile:get_position_xz()
        
        local screen_pos_x, screen_pos_y = get_screen_from_world(tile_position:x(), tile_position:y(), g_tab_map.camera_pos_x, g_tab_map.camera_pos_y, g_tab_map.camera_size, screen_w, screen_h)
        
        local tile_icon_color = g_map_colors.inactive

        if tile:get_team_control() == vehicle_team then
            tile_icon_color = g_map_colors.factory
        end

        local category_data = g_item_categories[tile:get_facility_category()]
        
        local tile_col = iff(is_tile_hovered(tile) or is_tile_dragged(tile), color_white, tile_icon_color)
        
        if is_collapse_icons then
            update_ui_rectangle(screen_pos_x - 1, screen_pos_y - 1, 2, 2, tile_col)
        else
            local name = tile:get_name()
            local name_factor = clamp(invlerp(g_tab_map.camera_size,  g_tab_map.camera_size_min, g_tab_map.camera_size_max * 0.35), 0, 1)
            update_ui_text(screen_pos_x - 100, screen_pos_y - 16, name, 200, 1, color8_lerp(color_black, color_empty, name_factor), 0)

            update_ui_rectangle(screen_pos_x - 5, screen_pos_y - 4, 10, 8, color_black)
            update_ui_rectangle(screen_pos_x - 4, screen_pos_y - 5, 8, 10, color_black)
            update_ui_image(screen_pos_x - 4, screen_pos_y - 4, category_data.icon, tile_col, 0)
        end
        
        if category_data.index ~= 0 and tile:get_team_control() == vehicle_team then
            local production_factor = tile:get_facility_production_factor()
            local queue_count = tile:get_facility_production_queue_count()
            
            if queue_count > 0 then
                if is_collapse_icons then
                    if g_animation_time % 30 > 15 then
                        update_ui_rectangle(screen_pos_x - 1, screen_pos_y - 1, 2, 2, g_map_colors.progress)
                    end
                else
                    update_ui_rectangle(screen_pos_x - 4, screen_pos_y + 5, 8, 2, color_black)
                    update_ui_rectangle(screen_pos_x - 4, screen_pos_y + 5, 8 * production_factor, 2, g_map_colors.progress)
                end
            end
        end
    end

    for _, vehicle in iter_vehicles(vehicle_filter) do
        local vehicle_def = vehicle:get_definition_index()
        
        local vehicle_position = vehicle:get_position_xz()
        local screen_pos_x, screen_pos_y = get_screen_from_world(vehicle_position:x(), vehicle_position:y(), g_tab_map.camera_pos_x, g_tab_map.camera_pos_y, g_tab_map.camera_size, screen_w, screen_h)
        
        local region_vehicle_icon, icon_offset = get_icon_data_by_definition_index(vehicle_def)
      
        if vehicle_def == e_game_object_type.chassis_sea_barge then
            local vehicle_col = iff(is_vehicle_hovered(vehicle) or is_vehicle_dragged(vehicle), color_white, g_map_colors.barge)

            if is_collapse_icons then
                update_ui_rectangle(screen_pos_x - 1, screen_pos_y - 1, 2, 2, vehicle_col)
            else
                update_ui_image(screen_pos_x - icon_offset, screen_pos_y - icon_offset, region_vehicle_icon, vehicle_col, 0)
            end

            local transfer_item = vehicle:get_barge_transfer_item()

            if g_item_data[transfer_item] ~= nil then
                if is_collapse_icons then
                    if g_animation_time % 30 > 15 then
                        update_ui_rectangle(screen_pos_x - 1, screen_pos_y - 1, 2, 2, g_map_colors.progress)
                    end
                else
                    update_ui_rectangle(screen_pos_x - 4, screen_pos_y + 3, 8, 2, color_black)
                    update_ui_rectangle(screen_pos_x - 4, screen_pos_y + 3, 8 * get_barge_transfer_progress(vehicle), 2, g_map_colors.progress)
                end
            end
        elseif vehicle_def == e_game_object_type.chassis_carrier then
            local vehicle_col = iff(is_vehicle_hovered(vehicle) or is_vehicle_dragged(vehicle), color_white, g_map_colors.carrier)
            
            if is_collapse_icons then
                update_ui_rectangle(screen_pos_x - 2, screen_pos_y - 2, 4, 4, vehicle_col)
            else
                update_ui_image(screen_pos_x - icon_offset, screen_pos_y - icon_offset, region_vehicle_icon, vehicle_col, 0)
            end
        end
    end

    if g_tab_map.dragged_id ~= 0 then
        local drag_start = get_resource_node_position(g_tab_map.dragged_id, g_tab_map.dragged_type)

        if drag_start then
            local screen_drag_x, screen_drag_y = get_screen_from_world(drag_start:x(), drag_start:y(), g_tab_map.camera_pos_x, g_tab_map.camera_pos_y, g_tab_map.camera_size, screen_w, screen_h)

            update_ui_line(screen_drag_x, screen_drag_y, g_tab_map.cursor_pos_x, g_tab_map.cursor_pos_y, color_white)
        end
    end

    if is_tab_active then
        if g_is_mouse_mode == false then
            update_ui_image(screen_w / 2 - 5, screen_h / 2 - 5, atlas_icons.map_icon_crosshair, iff(g_tab_map.hovered_id ~= 0, color_black, color_white), 0)
        end
        
        if g_is_mouse_mode == false or g_tab_map.is_drag_pan_map == false then
            update_map_hovered(screen_w, screen_h, screen_vehicle)
        end
    else
        clear_hover()
        clear_drag()
    end
end

function render_map_ui(screen_w, screen_h, x, y, w, h, screen_vehicle, is_tab_active)
    local ui = g_ui

    if is_tab_active then
        if g_tab_map.selected_barge_id ~= 0 then
            g_tab_map.is_overlay = true
            update_ui_rectangle(0, 0, screen_w, screen_h, color8(0, 0, 0, 200))
            
            update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)

            local selected_barge = update_get_map_vehicle_by_id(g_tab_map.selected_barge_id)

            if selected_barge:get() and selected_barge:get_team() == screen_vehicle:get_team() then
                local display_id = g_tab_map.selected_barge_id % 1000
                ui:begin_window(update_get_loc(e_loc.upp_barge_id).." " .. display_id .. "##barge", x + 15, y + 5, w - 30, h - 15, atlas_icons.column_stock, is_tab_active, 2)
                    local region_w, region_h = ui:get_region()
                    render_barge_inventory_status(0, 0, region_w, 22, selected_barge)
                    
                    ui:spacer(22)

                    imgui_barge_inventory_table(ui, selected_barge, false)
                    ui:divider(0, 3)
                    ui:divider(0, 10)
                ui:end_window()
            else
                g_tab_map.selected_barge_id = 0
            end
        elseif g_tab_map.selected_facility_id ~= 0 then
            g_tab_map.is_overlay = true
            update_ui_rectangle(0, 0, screen_w, screen_h, color8(0, 0, 0, 200))

            update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)

            local facility_tile = update_get_tile_by_id(g_tab_map.selected_facility_id)

            if facility_tile:get() and facility_tile:get_team_control() == screen_vehicle:get_team() then
                local category_data = g_item_categories[facility_tile:get_facility_category()]
                
                if category_data.index ~= 0 then
                    local left_w = w - 75
                    local right_w = w - left_w

                    local is_windows_active = is_tab_active and g_tab_map.selected_facility_item == -1 and g_tab_map.selected_facility_queue_item == -1

                    if is_windows_active and g_is_mouse_mode and g_is_pointer_hovered then
                        if g_pointer_pos_x > left_w then
                            g_tab_map.selected_panel = 1
                        else
                            g_tab_map.selected_panel = 0
                        end
                    end

                    local window = ui:begin_window(category_data.name .. "##facility", 5, y, left_w - 5, h - 5, category_data.icon, is_windows_active and g_tab_map.selected_panel == 0, 2)

                        if ui:list_item(update_get_loc(e_loc.upp_queue), true) then
                            g_tab_map.selected_panel = 1
                        end

                        local items_unlocked = {}
                        local items_locked = {}
                        local team_data = update_get_team(screen_vehicle:get_team())

                        if team_data:get() then
                            for i = 1, category_data.item_count do
                                local item = category_data.items[i]

                                if update_get_resource_item_hidden_facility_production(item.index) == false then
                                    if team_data:get_is_blueprint_unlocked(item.index) then
                                        table.insert(items_unlocked, item)
                                    else
                                        table.insert(items_locked, item)
                                    end
                                end
                            end
                        end

                        local column_widths = { 13, 122, -1 }
                        local column_margins = { 5, 2, 2 }

                        if #items_unlocked > 0 then
                            imgui_table_header(ui, {
                                { w=column_widths[1] + column_widths[2], margin=column_margins[1], value=update_get_loc(e_loc.upp_blueprints) },
                                { w=column_widths[3], margin=column_margins[3], value=atlas_icons.column_stock }
                            })

                            for i = 1, #items_unlocked do
                                local item_count = math.min(facility_tile:get_facility_inventory_count(items_unlocked[i].index), 99999)

                                local columns = {
                                    { w=column_widths[1], margin=column_margins[1], value=atlas_icons.column_stock, col=color_grey_mid, is_border=false },
                                    { w=column_widths[2], margin=column_margins[2], value=items_unlocked[i].name },
                                    { w=column_widths[3], margin=column_margins[3], value=tostring(item_count), col=iff(item_count > 0, color_status_ok, color_status_bad) }
                                }

                                local is_action = imgui_table_entry(ui, columns, true)

                                if is_action then
                                    g_tab_map.selected_facility_item = items_unlocked[i].index
                                end
                            end
                        end

                        if #items_locked > 0 then
                            imgui_table_header(ui, {
                                { w=column_widths[1] + column_widths[2], margin=column_margins[1], value=update_get_loc(e_loc.upp_locked) },
                                { w=column_widths[3], margin=column_margins[3], value=atlas_icons.column_stock }
                            })

                            for i = 1, #items_locked do
                                local item_count = math.min(facility_tile:get_facility_inventory_count(items_locked[i].index), 99999)

                                local columns = {
                                    { w=column_widths[1], margin=column_margins[1], value=atlas_icons.column_locked, col=color_status_bad, is_border=false },
                                    { w=column_widths[2], margin=column_margins[2], value=items_locked[i].name, col=color_status_bad },
                                    { w=column_widths[3], margin=column_margins[3], value=tostring(item_count), col=color_grey_dark }
                                }

                                imgui_table_entry(ui, columns, false)
                            end
                        end

                        ui:spacer(5)

                    ui:end_window()
                    
                    ui:begin_window(update_get_loc(e_loc.upp_status).."##facilitystatus", left_w, y, right_w - 5, 35, atlas_icons.map_icon_factory, false, 1)
                        local region_w, region_h = ui:get_region()
                        render_map_facility_queue(5, 3, region_w - 10, region_h, facility_tile)
                    ui:end_window()

                    ui:begin_window(update_get_loc(e_loc.upp_queue).."##facilityqueue", left_w, y + 24, right_w - 5, h - 29, atlas_icons.column_pending, is_windows_active and g_tab_map.selected_panel == 1, 2)
                        local queue_count = facility_tile:get_facility_production_queue_count()

                        for i = 0, queue_count - 1 do
                            local item_type, item_count = facility_tile:get_facility_production_queue_item(i)
                            local item_data = g_item_data[item_type]

                            item_count = math.min(item_count, 99999)

                            if item_data ~= nil then
                                if imgui_item_button(ui, item_data, "x" .. item_count, true) then
                                    g_tab_map.selected_facility_queue_item = i
                                end

                                if i == 0 then
                                    ui:divider(0, 2)
                                end
                            end
                        end

                        ui:spacer(1)
                    ui:end_window()

                    if g_tab_map.selected_facility_queue_item ~= -1 then
                        update_ui_rectangle(0, 0, screen_w, screen_h, color8(0, 0, 0, 200))
                        local item_type, item_count = facility_tile:get_facility_production_queue_item(g_tab_map.selected_facility_queue_item)
                        local item_data = g_item_data[item_type]

                        if item_data ~= nil then
                            local window = ui:begin_window(item_data.name .. "##queueitem", 30, y + 10, w - 60, h - 30, atlas_icons.column_pending, true, 2)
                                imgui_item_description(ui, screen_vehicle, item_data, false)

                                imgui_table_header(ui, {
                                    { w=134, margin=5, value=update_get_loc(e_loc.upp_queue) },
                                    { w=10, margin=0, value=atlas_icons.column_stock },
                                    { w=-1, margin=0, value="x" .. item_count }
                                })

                                ui:spacer(1)

                                local result = ui:button_group({ "X", "-1", "-10", "-100", "-1000" }, true)
                                local remove_count = 0

                                if result == 0 then
                                    remove_count = item_count
                                elseif result == 1 then
                                    remove_count = 1
                                elseif result == 2 then
                                    remove_count = 10
                                elseif result == 3 then
                                    remove_count = 100
                                elseif result == 4 then
                                    remove_count = 1000
                                end

                                if remove_count > 0 then
                                    facility_tile:set_facility_remove_production_queue_item(g_tab_map.selected_facility_queue_item, math.min(remove_count, item_count))

                                    if remove_count >= item_count then
                                        g_tab_map.selected_facility_queue_item = -1
                                    end
                                end
                            ui:end_window()
                        else
                            g_tab_map.selected_facility_queue_item = -1
                        end
                    end

                    if g_tab_map.selected_facility_item ~= -1 then
                        update_ui_rectangle(0, 0, screen_w, screen_h, color8(0, 0, 0, 200))
                        local item = g_item_data[g_tab_map.selected_facility_item]

                        if item ~= nil then
                            local window = ui:begin_window(item.name .. "##facilityitem", 30, y + 10, w - 60, h - 30, atlas_icons.column_stock, true, 2)
                                imgui_item_description(ui, screen_vehicle, item, false)
                                
                                local production_count = facility_tile:get_facility_production_queue_item_type(item.index)
                                
                                imgui_table_header(ui, {
                                    { w=134, margin=5, value=update_get_loc(e_loc.upp_queue) },
                                    { w=10, margin=0, value=atlas_icons.column_stock },
                                    { w=-1, margin=0, value="x" .. production_count }
                                })

                                ui:spacer(1)
                                
                                local result = ui:button_group({ "+1", "+10", "+100", "+1000" }, true)

                                if result == 0 then
                                    facility_tile:set_facility_add_production_queue_item(item.index, 1)
                                elseif result == 1 then
                                    facility_tile:set_facility_add_production_queue_item(item.index, 10)
                                elseif result == 2 then
                                    facility_tile:set_facility_add_production_queue_item(item.index, 100)
                                elseif result == 3 then
                                    facility_tile:set_facility_add_production_queue_item(item.index, 1000)
                                end
                            ui:end_window()
                        else
                            g_tab_map.selected_facility_item = -1
                        end
                    end
                else
                    ui:begin_window(category_data.name .. "##warehouse", x + 15, y + 5, w - 30, h - 15, category_data.icon, is_tab_active, 2)
                        imgui_facility_inventory_table(ui, facility_tile)
                        ui:divider(0, 3)
                        ui:divider(0, 10)
                    ui:end_window()
                end
            else
                g_tab_map.selected_facility_id = 0
            end
        else
            local zoom_factor = invlerp(g_tab_map.camera_size, g_tab_map.camera_size_min, g_tab_map.camera_size_max)
            local world_x, world_y = get_world_from_screen(g_tab_map.cursor_pos_x, g_tab_map.cursor_pos_y, g_tab_map.camera_pos_x, g_tab_map.camera_pos_y,g_tab_map.camera_size, screen_w, screen_h)

            update_ui_text(10, screen_h - 13, 
                string.format("X:%-6.0f ", world_x) .. 
                string.format("Y:%-6.0f ", world_y) .. 
                string.format("Z:%.2f", zoom_factor),
                w - 10, 0, color_grey_dark, 0
            )

            if g_tab_map.hovered_id ~= 0 then
                local tooltip_w = 128
                local tooltip_h = get_node_tooltip_h(tooltip_w, g_tab_map.hovered_id, g_tab_map.hovered_type)
                render_tooltip(x + 10, y, w - 20, h - 10, g_tab_map.cursor_pos_x, g_tab_map.cursor_pos_y, tooltip_w, tooltip_h, 10, function(w, h) render_node_tooltip(w, h, g_tab_map.hovered_id, g_tab_map.hovered_type) end)
            end
        end
    end
end

function render_barge_inventory_status(x, y, w, h, barge)
    update_ui_push_offset(x, y)

    local left_w = 85
    local right_w = w - left_w

    local inventory_capacity = math.min(barge:get_inventory_capacity(), 99999)
    local inventory_weight = math.min(barge:get_inventory_weight(), 99999)

    update_ui_push_offset(5, 2)
    update_ui_image(0, 0, atlas_icons.column_weight, color_grey_dark, 0)
    update_ui_text(10, 0, inventory_weight .. "/" .. inventory_capacity, 100, 0, iff(inventory_weight < inventory_capacity, color_status_ok, color_status_bad), 0)
    update_ui_image(0, 9, atlas_icons.column_stock, color_grey_dark, 0)
    update_ui_text(10, 9, get_barge_inventory_item_count(barge), 100, 0, color_grey_dark, 0)
    update_ui_pop_offset()

    update_ui_line(left_w, 0, left_w, h, color_white)

    local transfer_item = barge:get_barge_transfer_item()
    local item_data = g_item_data[transfer_item]
    
    if item_data ~= nil then
        update_ui_push_offset(left_w, 0)

        local border = 5
        local transfer_progress = get_barge_transfer_progress(barge)
        local icon_start, icon_end = get_barge_transfer_icons(barge)

        local bar_w = right_w - border * 2 - 20 * 2
        local bar_h = 10

        update_ui_push_offset(border + 20, (h - bar_h) / 2)
        
        render_arrow(0, 0, bar_w, bar_h, 4, bar_h, 0, color_grey_dark)

        update_ui_push_clip(0, 0, math.floor(bar_w * transfer_progress + 0.5), bar_h)
        render_arrow(0, 0, bar_w, bar_h, 4, bar_h, 0, g_map_colors.progress)
        update_ui_pop_clip()

        update_ui_pop_offset()

        -- update_ui_rectangle_outline(border, 2, 18, 18, color_grey_dark)
        update_ui_image_rot(border + 9, 11, icon_start, color_grey_dark, 0)
        -- update_ui_rectangle_outline(right_w - border - 18, 2, 18, 18, color_grey_dark)
        update_ui_image_rot(right_w - border - 18 + 9, 11, icon_end, color_grey_dark, 0)
        
        render_button_bg(right_w / 2 - 9, 2, 18, 18, color8(8, 8, 8, 128))
        update_ui_image(right_w / 2 - 8, 3, item_data.icon, color_white, 0)

        update_ui_pop_offset()
    else
        update_ui_text(left_w, h / 2 - 4, "---", right_w, 1, color_grey_dark, 0)
    end

    update_ui_line(0, h, w, h, color_white)

    update_ui_pop_offset()
end

function render_map_facility_queue(x, y, w, h, tile)
    update_ui_push_offset(x, y)
    update_ui_push_clip(0, 0, w, h)

    local cy = 0
    local queue_count = tile:get_facility_production_queue_count()
    local is_refitting = tile:get_facility_is_refit()
    local production_factor = tile:get_facility_production_factor()
    
    update_ui_rectangle(0, cy, w, 3, color_grey_dark)
    update_ui_rectangle(0, cy, w * production_factor, 3, g_map_colors.progress)
    cy = cy + 4

    if is_refitting then
        update_ui_text(0, cy + 3, update_get_loc(e_loc.upp_refitting), w, 0, color_white, 0)
    elseif queue_count > 0 then
        local item_type, item_count = tile:get_facility_production_queue_item(0)
        local item_data = g_item_data[item_type]
        item_count = math.min(item_count, 99999)

        update_ui_image(0, cy, item_data.icon, color_white, 0)
        update_ui_text(18, cy + 3, "x", 20, 0, iff(is_selected, color_highlight, color_grey_dark), 0)
        update_ui_text(26, cy + 3, item_count, 30, 0, iff(is_selected, color_highlight, color_status_ok), 0)
    else
        update_ui_text(0, cy + 3, update_get_loc(e_loc.upp_idle), w, 0, color_grey_dark, 0)
    end

    update_ui_pop_clip()
    update_ui_pop_offset()
end

function get_node_tooltip_h(tooltip_w, id, type)
    if type == g_link_types.tile then
        local tile = update_get_tile_by_id(id)
        local category_data = g_item_categories[tile:get_facility_category()]

        if tile:get() then
            local is_player_tile = tile:get_team_control() == update_get_screen_team_id()

            if category_data.index ~= 0 then                
                if is_player_tile == false then
                    local unlocks = get_tile_blueprint_unlocks(tile)

                    if #unlocks > 0 then
                        local cx = 18
                        local cy = 13

                        for i = 1, #unlocks do
                            cx = cx + 16

                            if cx + 16 > tooltip_w - 5 then
                                cx = 18
                                cy = cy + 16
                            end
                        end

                        return cy + 18
                    end
                end
            end
        end
    end

    return 23
end

function render_node_tooltip(w, h, id, type)
    local name, color = get_node_data(id, type)

    if type == g_link_types.carrier then
        update_ui_image(2, h / 2 - 8, atlas_icons.icon_chassis_16_carrier, color, 0)
        update_ui_text(18, h / 2 - 4, name, 200, 0, color_white, 0)
    elseif type == g_link_types.barge then
        local barge = update_get_map_vehicle_by_id(id)

        if barge:get() then
            local cy = 3
            update_ui_image(2, h / 2 - 8, atlas_icons.icon_chassis_16_barge, color, 0)
            update_ui_text(18, cy, name, 200, 0, color_white, 0)
            update_ui_image(w - 13, cy, atlas_icons.column_transit, color_highlight, 0)

            cy = cy + 10

            local capacity = barge:get_inventory_capacity()
            local weight = barge:get_inventory_weight()
            update_ui_image(18, cy, atlas_icons.column_weight, color_grey_dark, 0)
            update_ui_text(31, cy, string.format("%.0f%%", (weight / capacity) * 100), 200, 0, color_grey_dark, 0)

            local bar_w = w - 60 - 15
            update_ui_rectangle(60, cy + 3, bar_w, 3, color_grey_dark)
            update_ui_rectangle(60, cy + 3, bar_w * get_barge_transfer_progress(barge), 3, g_map_colors.progress)
            update_ui_image(w - 12, cy, atlas_icons.column_stock, color_grey_dark, 0)
        end
    elseif type == g_link_types.tile then
        local tile = update_get_tile_by_id(id)
        local category_data = g_item_categories[tile:get_facility_category()]

        if tile:get() then
            local is_player_tile = tile:get_team_control() == update_get_screen_team_id()

            if category_data.index == 0 then
                if is_player_tile then
                    update_ui_image(5, h / 2 - 4, category_data.icon, g_map_colors.factory, 0)
                    update_ui_text(18, h / 2 - 4, category_data.name, 200, 0, color_white, 0)
                    update_ui_image(w - 13, h / 2 - 4, atlas_icons.column_transit, color_highlight, 0)
                else
                    update_ui_image(5, h / 2 - 4, category_data.icon, color_grey_dark, 0)
                    update_ui_text(18, h / 2 - 4, category_data.name, 200, 0, color_grey_dark, 0)
                end
            else
                if is_player_tile then
                    local cy = 3

                    update_ui_image(5, cy, category_data.icon, g_map_colors.factory, 0)
                    update_ui_text(18, cy, category_data.name, 200, 0, color_white, 0)
                    update_ui_image(w - 13, cy, atlas_icons.column_transit, color_highlight, 0)

                    cy = cy + 10

                    local production_factor = tile:get_facility_production_factor()
                    local queue_count = tile:get_facility_production_queue_count()
                    local pending_item_count = 0

                    for i = 0, queue_count - 1 do
                        local item_type, item_count = tile:get_facility_production_queue_item(i)
                        pending_item_count = pending_item_count + item_count
                    end

                    pending_item_count = math.min(pending_item_count, 99999)

                    update_ui_image(5, cy, atlas_icons.column_stock, color_grey_dark, 0)
                    update_ui_text(18, cy, pending_item_count, 200, 0, color_grey_dark, 0)

                    local bar_w = w - 50 - 15
                    update_ui_rectangle(50, cy + 3, bar_w, 3, color_grey_dark)
                    update_ui_rectangle(50, cy + 3, bar_w * production_factor, 3, g_map_colors.progress)

                    if tile:get_facility_is_refit() then
                        update_ui_image(w - 12, cy, atlas_icons.column_time, color_grey_dark, 0)
                    else
                        update_ui_image(w - 12, cy, atlas_icons.column_stock, color_grey_dark, 0)
                    end
                else
                    local unlocks = get_tile_blueprint_unlocks(tile)

                    if #unlocks > 0 then
                        local cy = 3
                        update_ui_image(5, cy, category_data.icon, color_grey_dark, 0)
                        update_ui_text(18, cy, category_data.name, 200, 0, color_grey_dark, 0)

                        cy = cy + 10
                        update_ui_image(8, cy + 4, atlas_icons.icon_tree_next, color_grey_dark, 0)

                        local cx = 18

                        for i = 1, #unlocks do
                            if g_animation_time % 40 > 20 then
                                update_ui_image(cx, cy, unlocks[i].icon, color_button_bg_inactive, 0)
                                update_ui_image(cx + 4, cy + 3, atlas_icons.column_locked, color_status_bad, 0)
                            else
                                update_ui_image(cx, cy, unlocks[i].icon, color_grey_mid, 0)
                            end

                            cx = cx + 16

                            if cx + 16 > w - 5 then
                                cx = 18
                                cy = cy + 16
                            end
                        end
                    else
                        local cy = h / 2 - 4
                        update_ui_image(5, cy, category_data.icon, color_grey_dark, 0)
                        update_ui_text(18, cy, category_data.name, 200, 0, color_grey_dark, 0)
                    end
                end
            end
        end
    end
end

function get_tile_blueprint_unlocks(tile)
    local team = update_get_team(update_get_screen_team_id())
    local blueprint_count = tile:get_blueprint_unlock_count()
    local unlocks = {}

    for i = 0, blueprint_count - 1 do
        local item = tile:get_blueprint_unlock(i)
        local item_data = g_item_data[item]

        if item_data ~= nil and team:get() and update_get_resource_item_hidden_facility_production(item) == false and team:get_is_blueprint_unlocked(item) == false then
            table.insert(unlocks, item_data)
        end
    end

    return unlocks
end

function update_map_cursor_state(screen_w, screen_h)
    if update_get_is_focus_local() == false then return end
    
    if update_get_active_input_type() == e_active_input.keyboard then
        g_tab_map.cursor_pos_x = g_pointer_pos_x
        g_tab_map.cursor_pos_y = g_pointer_pos_y
    else
        g_tab_map.cursor_pos_x = screen_w / 2
        g_tab_map.cursor_pos_y = screen_h / 2
    end
end

function input_map_zoom_camera(factor)
    g_tab_map.camera_size = g_tab_map.camera_size * factor
    g_tab_map.camera_size = math.min(g_tab_map.camera_size, g_tab_map.camera_size_max)
    g_tab_map.camera_size = math.max(g_tab_map.camera_size, g_tab_map.camera_size_min)
end

function update_map_hovered(screen_w, screen_h)
    local vehicle_radius_sq = 5 ^ 2
    local tile_radius_sq = 5 ^ 2
    local min_hover_dist_sq = 256 ^ 2
    clear_hover()

    local tile_filter = function(t)
        return true
    end

    for _, tile in iter_tiles(tile_filter) do
        local tile_pos_xz = tile:get_position_xz()
        local screen_x, screen_y = get_screen_from_world(tile_pos_xz:x(), tile_pos_xz:y(), g_tab_map.camera_pos_x, g_tab_map.camera_pos_y, g_tab_map.camera_size, screen_w, screen_h)
        local dist_sq = vec2_dist_sq(vec2(screen_x, screen_y), vec2(g_tab_map.cursor_pos_x, g_tab_map.cursor_pos_y))
        
        if dist_sq < min_hover_dist_sq and dist_sq < tile_radius_sq then
            min_hover_dist_sq = dist_sq
            g_tab_map.hovered_id = tile:get_id()
            g_tab_map.hovered_type = g_link_types.tile
        end
    end

    local vehicle_filter = function(v)
        local def = v:get_definition_index()
        return v:get_team() == update_get_screen_team_id() and (def == e_game_object_type.chassis_sea_barge or def == e_game_object_type.chassis_carrier)
    end

    for _, vehicle in iter_vehicles(vehicle_filter) do
        local vehicle_pos_xz = vehicle:get_position_xz()
        local screen_x, screen_y = get_screen_from_world(vehicle_pos_xz:x(), vehicle_pos_xz:y(), g_tab_map.camera_pos_x, g_tab_map.camera_pos_y, g_tab_map.camera_size, screen_w, screen_h)
        local dist_sq = vec2_dist_sq(vec2(screen_x, screen_y), vec2(g_tab_map.cursor_pos_x, g_tab_map.cursor_pos_y))
        
        if dist_sq < min_hover_dist_sq and dist_sq < vehicle_radius_sq then
            min_hover_dist_sq = dist_sq
            g_tab_map.hovered_id = vehicle:get_id()
            g_tab_map.hovered_type = iff(vehicle:get_definition_index() == e_game_object_type.chassis_carrier, g_link_types.carrier, g_link_types.barge)
        end
    end
end

function get_node_data(id, type)
    if id ~= 0 then
        if type == g_link_types.barge then
            return update_get_loc(e_loc.upp_barge), g_map_colors.barge, atlas_icons.icon_chassis_16_barge
        elseif type == g_link_types.carrier then
            return update_get_loc(e_loc.upp_carrier), g_map_colors.carrier, atlas_icons.icon_chassis_16_carrier
        elseif type == g_link_types.tile then
            local tile = update_get_tile_by_id(id)
            local category_data = g_item_categories[tile:get_facility_category()]

            return category_data.name, g_map_colors.factory, category_data.icon
        end
    end

    return nil
end

function get_node_pos_xz(id, type)
    if id ~= 0 then
        if type == g_link_types.barge or type == g_link_types.carrier then
            local vehicle = update_get_map_vehicle_by_id(id)
            if vehicle:get() then return vehicle:get_position_xz() end
        elseif type == g_link_types.tile then
            local tile = update_get_tile_by_id(id)
            if tile:get() then return tile:get_position_xz() end
        end
    end

    return nil
end

function tab_map_input_event(input, action)
    g_ui:input_event(input, action)

    if action == e_input_action.press then
        if input == e_input.action_a or input == e_input.pointer_1 then
            if g_tab_map.dragged_id == 0 and g_tab_map.hovered_id ~= 0 then
                if g_tab_map.hovered_type == g_link_types.tile then
                    local tile = update_get_tile_by_id(g_tab_map.hovered_id)

                    if tile:get() and tile:get_team_control() == update_get_screen_team_id() then
                        g_tab_map.dragged_id = g_tab_map.hovered_id
                        g_tab_map.dragged_type = g_tab_map.hovered_type
                    end
                else
                    g_tab_map.dragged_id = g_tab_map.hovered_id
                    g_tab_map.dragged_type = g_tab_map.hovered_type
                end
            elseif input == e_input.pointer_1 then
                g_tab_map.is_drag_pan_map = true
            end
        elseif input == e_input.back then
            if g_tab_map.selected_barge_id ~= 0 then
                g_tab_map.selected_barge_id = 0
            elseif g_tab_map.selected_facility_id ~= 0 then
                if g_tab_map.selected_facility_queue_item ~= -1 then
                    g_tab_map.selected_facility_queue_item = -1
                elseif g_tab_map.selected_facility_item ~= -1 then
                    g_tab_map.selected_facility_item = -1
                elseif g_is_mouse_mode then
                    g_tab_map.selected_panel = 0
                    g_tab_map.selected_facility_id = 0
                else
                    if g_tab_map.selected_panel == 1 then
                        g_tab_map.selected_panel = 0
                    else
                        g_tab_map.selected_facility_id = 0
                    end
                end
            else
                return true
            end
        end
    elseif action == e_input_action.release then 
        if input == e_input.action_a or input == e_input.pointer_1 then
            if input == e_input.pointer_1 then
                g_tab_map.is_drag_pan_map = false
            end

            if g_tab_map.dragged_id ~= 0 then
                if g_tab_map.hovered_id ~= 0 and (g_tab_map.hovered_id ~= g_tab_map.dragged_id or g_tab_map.hovered_type ~= g_tab_map.dragged_type) then
                    create_resource_link(g_tab_map.dragged_id, g_tab_map.hovered_id, g_tab_map.dragged_type, g_tab_map.hovered_type)
                elseif g_tab_map.dragged_id == g_tab_map.hovered_id and g_tab_map.dragged_type == g_tab_map.hovered_type then
                    if g_tab_map.dragged_type == g_link_types.tile then
                        local tile = update_get_tile_by_id(g_tab_map.hovered_id)
                    
                        if tile:get() and tile:get_team_control() == update_get_screen_team_id() then
                            g_tab_map.selected_facility_id = g_tab_map.hovered_id
                        end
                    elseif g_tab_map.dragged_type == g_link_types.barge then
                        local barge = update_get_map_vehicle_by_id(g_tab_map.hovered_id)

                        if barge:get() and barge:get_team() == update_get_screen_team_id() then
                            g_tab_map.selected_barge_id = g_tab_map.hovered_id
                        end
                    end
                end
            end

            clear_drag()
        end
    end

    return false
end

function tab_map_input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
end

function tab_map_input_scroll(dy)
    if g_is_pointer_hovered and g_tab_map.is_overlay == false then
        input_map_zoom_camera(1 - dy * 0.15)
    end

    g_ui:input_scroll(dy)
end

function is_vehicle_hovered(v)
    return v:get_id() == g_tab_map.hovered_id and (g_tab_map.hovered_type == g_link_types.barge or g_tab_map.hovered_type == g_link_types.carrier)
end

function is_tile_hovered(t)
    return t:get_id() == g_tab_map.hovered_id and g_tab_map.hovered_type == g_link_types.tile
end

function is_vehicle_dragged(v)
    return v:get_id() == g_tab_map.dragged_id and (g_tab_map.dragged_type == g_link_types.barge or g_tab_map.dragged_type == g_link_types.carrier)
end

function is_tile_dragged(t)
    return t:get_id() == g_tab_map.dragged_id and g_tab_map.dragged_type == g_link_types.tile
end

function clear_hover()
    g_tab_map.hovered_id = 0
    g_tab_map.hovered_type = 0
end

function clear_drag()
    g_tab_map.dragged_id = 0
    g_tab_map.dragged_type = 0
end

function create_resource_link(start_id, end_id, start_type, end_type)
    update_create_resource_link(start_id, end_id, start_type, end_type)
end

function render_resource_link(link, screen_w, screen_h)
    local start_pos_xz = get_resource_node_position(link:get_node_id_start(), link:get_node_type_start())
    local end_pos_xz = get_resource_node_position(link:get_node_id_end(), link:get_node_type_end())
    
    if start_pos_xz ~= nil and end_pos_xz ~= nil then
        local start_id = link:get_node_id_start()
        local start_type = link:get_node_type_start()
        local col = g_map_colors.inactive 

        if start_type == g_link_types.carrier then
            col = g_map_colors.carrier
        elseif start_type == g_link_types.barge then
            col = g_map_colors.barge
        elseif start_type == g_link_types.tile then
            local tile = update_get_tile_by_id(start_id)

            if tile:get() == false or tile:get_team_control() ~= update_get_screen_team_id() then
                col = g_map_colors.inactive
            else
                col = g_map_colors.factory
            end
        end

        if start_id == g_tab_map.hovered_id and start_type == g_tab_map.hovered_type then
            col = color_white
        end

        local start_screen_x, start_screen_y = get_screen_from_world(start_pos_xz:x(), start_pos_xz:y(), g_tab_map.camera_pos_x, g_tab_map.camera_pos_y, g_tab_map.camera_size, screen_w, screen_h)

        local end_screen_x, end_screen_y = get_screen_from_world(end_pos_xz:x(), end_pos_xz:y(), g_tab_map.camera_pos_x, g_tab_map.camera_pos_y, g_tab_map.camera_size, screen_w, screen_h)

        local offset = math.floor((g_animation_time * 0.4) % 7)

        local x0, y0, x1, y1 = clip_line_to_rect(start_screen_x, start_screen_y, end_screen_x, end_screen_y, 0, 0, screen_w, screen_h)

        if x0 ~= nil then
            render_dashed_line(vec2(x0, y0), vec2(x1, y1), offset, 4, 7, col)
        end
    end
end

function get_resource_node_position(id, type)
    if type == g_link_types.barge or type == g_link_types.carrier then
        local vehicle = update_get_map_vehicle_by_id(id)

        if vehicle:get() then
            return vehicle:get_position_xz()
        end
    elseif type == g_link_types.tile then
        local tile = update_get_tile_by_id(id)

        if tile:get() then
            return tile:get_position_xz()
        end
    end

    return nil
end

function render_dashed_line(p0, p1, offset, length, spacing, col)
    local x0 = p0:x()
    local y0 = p0:y()
    local x1 = p1:x()
    local y1 = p1:y()
    local dx = math.abs(x1 - x0)
    local sx = iff(x0 < x1, 1, -1)
    local dy = -math.abs(y1 - y0)
    local sy = iff(y0 < y1, 1, -1)
    local err = dx + dy

    local pixel_index = 0
    local max_iterations = 256

    while max_iterations > 0 do
        if ((pixel_index - offset) % spacing) < length then
            update_ui_rectangle(x0, y0, 1, 1, col)
        end

        if math.abs(x0 - x1) < 1 and math.abs(y0 - y1) < 1 then break end
        
        local e2 = 2 * err
        
        if e2 >= dy then
            err = err + dy
            x0 = x0 + sx
        end
        if e2 <= dx then
            err = err + dx
            y0 = y0 + sy
        end

        pixel_index = pixel_index + 1
        max_iterations = max_iterations - 1
    end
end


--------------------------------------------------------------------------------
--
-- INVENTORY DISPLAY
--
--------------------------------------------------------------------------------

function tab_stock_render(screen_w, screen_h, x, y, w, h, is_tab_active, screen_vehicle)
    local ui = g_ui
    update_ui_push_offset(x, y)

    g_tab_stock.is_overlay = false
    render_inventory_stats(0, 0, w, 10, screen_vehicle)

    local window = ui:begin_window("##inventory", 5, 10, w - 10, h - 10, nil, is_tab_active and g_tab_stock.selected_item == -1, 1)
        local selected_item, selected_row, selected_col, sx, sy, sw, sh = imgui_vehicle_inventory_table(ui, screen_vehicle)
        ui:divider(0, 3)
        ui:divider(0, 10)
    
        if selected_item ~= -1 then
            g_tab_stock.selected_item = selected_item
        end

        if is_tab_active and selected_row ~= -1 and selected_col > 1 then
            local region_w, region_h = ui:get_region()
            
            sx = sx + sw / 2

            if g_is_mouse_mode and g_is_pointer_hovered then
                sx = g_pointer_pos_x - 5
            end

            local tooltip_text = { update_get_loc(e_loc.item_name), update_get_loc(e_loc.in_warehouses), update_get_loc(e_loc.pending_order), update_get_loc(e_loc.carrier_stock) }
            local text = tooltip_text[selected_col]
            local text_w, text_h = update_ui_get_text_size(text, 100, 1)

            local function callback_render_tooltip(w, h) 
                update_ui_text(2, 1, text, w - 2, 1, color_grey_mid, 0)
            end

            render_tooltip(0, window.view_y, region_w - 5, region_h, sx, sy + sh / 2, text_w + 4, text_h + 2, sh / 2 + 4, callback_render_tooltip, color_button_bg_inactive)
        end
    ui:end_window()
    
    if is_tab_active then
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)

        if g_tab_stock.selected_item == -1 then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
        else
            update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)
        end
    end

    if g_tab_stock.selected_item ~= -1 then
        local item_data = g_item_data[g_tab_stock.selected_item]

        if item_data == nil then
            g_tab_stock.selected_item = -1
        else
            g_tab_stock.is_overlay = true
            update_ui_rectangle(0, 0, w, h, color8(0, 0, 0, 200))

            local window = ui:begin_window(item_data.name .. "##item", 30, 10, w - 60, h - 25, atlas_icons.column_stock, is_tab_active, 2)
                imgui_item_description(ui, screen_vehicle, item_data, true)
                ui:header(update_get_loc(e_loc.upp_order))
                
                local order_amount_prev = screen_vehicle:get_inventory_order(item_data.index)
                local order_amount = order_amount_prev
                order_amount = ui:selector(update_get_loc(e_loc.quantity), order_amount, -99999, 99999, 1, "%+d")

                local button_action = ui:button_group({ "X", "-100", "-10", "+10", "+100" }, true)

                if button_action == 0 then
                    order_amount = 0
                elseif button_action == 1 then
                    order_amount = order_amount - 100
                elseif button_action == 2 then
                    order_amount = order_amount - 10
                elseif button_action == 3 then
                    order_amount = order_amount + 10
                elseif button_action == 4 then
                    order_amount = order_amount + 100
                end

                order_amount = clamp(order_amount, -99999, 99999)

                if order_amount_prev ~= order_amount then
                    screen_vehicle:set_inventory_order(item_data.index, order_amount - order_amount_prev)
                end
            ui:end_window()
        end
    end
    update_ui_pop_offset()
end

function render_inventory_stats(x, y, w, h, vehicle)
    update_ui_push_offset(x, y)
    update_ui_push_clip(0, 0, w, h)

    local col = iff(g_focused_screen == g_screens.inventory, color_grey_dark, color_grey_dark)

    local cursor_x = 10
    update_ui_image(cursor_x, 0, atlas_icons.column_weight, col, 0)
    cursor_x = cursor_x + 10

    local capacity = vehicle:get_inventory_capacity()
    local weight = vehicle:get_inventory_weight()
    local used_space = weight / capacity * 100

    update_ui_text(cursor_x, 0, string.format("%.1f%%", used_space), w - cursor_x, 0, col, 0)
    update_ui_text(cursor_x, 0, weight .. "/" .. capacity .. update_get_loc(e_loc.upp_kg), w - cursor_x - 10, 2, col, 0)

    update_ui_line(0, h - 1, w, h - 1, col)

    update_ui_pop_clip()
    update_ui_pop_offset()
end

function tab_stock_input_event(input, action)
    g_ui:input_event(input, action)

    if input == e_input.back and action == e_input_action.press then
        if g_tab_stock.selected_item ~= -1 then
            g_tab_stock.selected_item = -1
        else
            return true
        end
    end

    return false
end

function tab_stock_input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
end

function tab_stock_input_scroll(dy)
    g_ui:input_scroll(dy)
end

function imgui_item_description(ui, vehicle, item_data, is_inventory)
    local window = ui:get_window()
    local region_w, region_h = ui:get_region()
    ui:spacer(2)

    update_ui_rectangle_outline(window.cx + 4, window.cy - 1, 18, 18, color_grey_dark)
    update_ui_image(window.cx + 5, window.cy, item_data.icon, color_white, 0)

    local text_h = update_ui_text(window.cx + 25, window.cy, item_data.desc, region_w - 30, 0, color_grey_dark, 0)
    window.cy = window.cy + math.max(text_h, 17)

    ui:spacer(2)

    local icon_w = region_w / 3
    local cx = window.cx
    local cy = window.cy

    update_ui_image(math.floor(cx + 5), cy, atlas_icons.column_weight, color_grey_dark, 0)
    update_ui_text(math.floor(cx + 15), cy, item_data.mass, math.floor(icon_w) - 15, 0, color_grey_dark, 0)
    cx = cx + icon_w

    update_ui_image(math.floor(cx + 5), cy, atlas_icons.column_time, color_grey_dark, 0)
    update_ui_text(math.floor(cx + 15), cy, item_data.time .. "s", math.floor(icon_w) - 15, 0, color_grey_dark, 0)
    cx = cx + icon_w

    if is_inventory then
        local facility_production_counts = vehicle:get_inventory_production_counts()
        local warehouse_count = clamp(facility_production_counts[item_data.index] or 0, -99999, 99999)

        local col = color_status_bad

        if warehouse_count > 0 then
            col = color_status_ok
        end

        update_ui_image(math.floor(cx + 5), cy, atlas_icons.column_warehouse, col, 0)
        update_ui_text(math.floor(cx + 15), cy, warehouse_count, math.floor(icon_w) - 15, 0, col, 0)
    else
        local team = update_get_team(update_get_screen_team_id())
        local col = color_status_bad

        if team:get() and team:get_currency() >= item_data.cost then
            col = color_status_ok
        end

        update_ui_image(math.floor(cx + 5), cy, atlas_icons.column_currency, col, 0)
        update_ui_text(math.floor(cx + 15), cy, item_data.cost, math.floor(icon_w) - 15, 0, col, 0)
    end

    ui:spacer(10)
end

--------------------------------------------------------------------------------
--
-- RENDER HELPERS
--
--------------------------------------------------------------------------------

function render_text_trim(x, y, str, width, color) 
--    local max_len = math.floor(width / 6)
--    if str:len() > max_len then
--        update_ui_text(x, y, str:sub(1, max_len - 1), -1, 0, color, 0)
--        update_ui_image(x + max_len * 6 - 6, y, atlas_icons.text_ellipsis, color, 0)
--    else
--        update_ui_text(x, y, str, -1, 0, color, 0)
--    end

-- Disabled for now due to UTF8
    update_ui_text(x, y, str, -1, 0, color, 0)
end

function get_barge_transfer_progress(barge)
    local transfer_item = barge:get_barge_transfer_item()
                    
    local item_data = g_item_data[transfer_item]
                    
    if item_data ~= nil then
        local transfer_start_tick = barge:get_barge_transfer_start_tick()
        local tick = update_get_logic_tick()
        return clamp((tick - transfer_start_tick) / (item_data.transfer_duration * 30), 0, 1)
    end

    return 0
end

function get_barge_transfer_icons(barge)
    local action, destination_id, destination_type = barge:get_barge_state_data()
    local node_name, node_col, node_icon = get_node_data(destination_id, destination_type)

    if action == e_barge_action.load or action == e_barge_action.load_carrier_stock then
        return node_icon, atlas_icons.icon_chassis_16_barge 
    elseif action == e_barge_action.unload or action == e_barge_action.unload_carrier_stock then
        return atlas_icons.icon_chassis_16_barge, node_icon
    end

    return atlas_icons.icon_chassis_16_barge, atlas_icons.icon_chassis_16_barge
end

function get_barge_transfer_status(barge)
    local action, destination_id, destination_type = barge:get_barge_state_data()

    if action == e_barge_action.load then
        return update_get_loc(e_loc.loading_stock).."..."
    elseif action == e_barge_action.unload then
        return update_get_loc(e_loc.unloading_stock).."..."
    elseif action == e_barge_action.load_carrier_stock then
        return iff(destination_type == g_link_types.carrier, update_get_loc(e_loc.loading_surplus).."...", update_get_loc(e_loc.loading_order).."...")
    elseif action == e_barge_action.unload_carrier_stock then
        return update_get_loc(e_loc.unloading_order).."..."
    end

    return update_get_loc(e_loc.loading).."..."
end

function get_barge_inventory_item_count(barge)
    local item_count = 0

    for i = 0, update_get_resource_inventory_item_count() - 1 do
        item_count = item_count + barge:get_inventory_count_by_item_index(i)
    end

    return item_count
end

function render_arrow(x, y, w, h, thickness, length, dir, col)
    update_ui_push_offset(x, y)

    if dir == 1 then
        update_ui_rectangle((w - thickness) / 2, length, thickness, h - length, col)
        render_triangle(0, length, w / 2, 0, w, length, col)
    elseif dir == 2 then
        update_ui_rectangle(length, (h - thickness) / 2, w - length, thickness, col)
        render_triangle(length, 0, length, h, 0, h / 2, col)
    elseif dir == 3 then
        update_ui_rectangle((w - thickness) / 2, 0, thickness, h - length, col)
        render_triangle(0, h - length, w, h - length, w / 2, h, col)
    else
        update_ui_rectangle(0, (h - thickness) / 2, w - length, thickness, col)
        render_triangle(w - length, 0, w, h / 2, w - length, h, col)
    end

    update_ui_pop_offset()
end

function render_triangle(x0, y0, x1, y1, x2, y2, col)
    update_ui_begin_triangles()
    update_ui_add_triangle(vec2(x0, y0), vec2(x1, y1), vec2(x2, y2), col)
    update_ui_end_triangles()
end

function render_currency_display(x, y, is_active)
    local currency = 0
    local team = update_get_team(update_get_screen_team_id())

    if team:get() then
        currency = team:get_currency()
    end

    local col = iff(is_active, iff(currency > 0, color_status_ok, color_status_bad), color_grey_dark)
    local text_w, text_h = update_ui_get_text_size(tostring(currency), 100, 2)

    update_ui_push_offset(x, y)
    update_ui_image(-text_w - 9, 0, atlas_icons.column_currency, col, 0)
    update_ui_text(-100, 0, tostring(currency), 100, 2, col, 0)
    update_ui_pop_offset()
end


--------------------------------------------------------------------------------
--
-- UTILITY FUNCTIONS
--
--------------------------------------------------------------------------------

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

function iter_resource_links()
    local link_count = update_get_resource_link_count()
    local index = 0

    return function()
        local link = nil

        while (link == nil or link:get() == false) and index < link_count do
            link = update_get_resource_link_by_index(index)
            index = index + 1
        end

        if link ~= nil then
            return index, link
        end
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
        g_tab_map.camera_pos_x = (min_x + max_x) / 2
        g_tab_map.camera_pos_y = (min_z + max_z) / 2
        g_tab_map.camera_size = math.max(max_x - min_x, max_z - min_z) * 1.5
    end
end
