g_tab_map = {
    tab_title = "",
    render = nil,
    begin = nil,
    input_event = nil,
    input_pointer = nil,
    input_scroll = nil,
    is_overlay = false,

    is_map_pos_initialised = false,
    camera_pos_x = 81438,
    camera_pos_y = 91753,
    camera_size = 256 * 1024,
    camera_size_min = 1024,
    camera_size_max = 256 * 1024,
}

g_tab_game = {
    tab_title = "",
    render = nil,
    begin = nil,
    input_event = nil,
    input_pointer = nil,
    input_scroll = nil,
    is_overlay = false,

    ui_container = nil,
    screen_index = 0,
    confirm_save_slot = nil,
    confirm_load_slot = nil,
}

g_tab_options = {
    tab_title = "",
    render = nil,
    begin = nil,
    input_event = nil,
    input_pointer = nil,
    input_scroll = nil,
    is_overlay = false,

    selected_panel = 0,
    hovered_panel = 0,
    ui_container = nil    
}

g_tab_multiplayer = {
    tab_title = "",
    render = nil,
    begin = nil,
    input_event = nil,
    input_pointer = nil,
    input_scroll = nil,
    is_overlay = false,
    toast_time = nil,
    toast_text = "",
    toast_col = color_status_ok,
    selected_peer_id = 0,
    
    screen_index = 0,
    ui_container = nil    
}

g_tab_manual = {
    tab_title = "",
    render = nil,
    begin = nil,
    input_event = nil,
    input_pointer = nil,
    input_scroll = nil,
    is_overlay = false,

    selected_panel = 0,
    hovered_panel = 0,
    selected_page = 1,
    ui_container = nil,

    highlighted_section = {
        section_tag_pending = "",
        section_key = 0,
        content_key = 0,
        timer = 0,
        scroll_to_section = 0,
    }
}

g_tabs = {
    [0] = g_tab_map,
    [1] = g_tab_manual,
    [2] = g_tab_multiplayer,
    [3] = g_tab_game,
    [4] = g_tab_options,
    map = 0,
    manual = 1,
    multiplayer = 2,
    game = 3,
    options = 4,
}

g_screens = {
    menu = 0,
    active_tab = 1,
}

g_focused_screen = g_screens.menu
g_hovered_screen = g_screens.menu
g_active_tab = g_tabs.map
g_hovered_tab = -1
g_input_axis = { x = 0, y = 0, z = 0, w = 0 }

g_text = {
    ["save_name"] = "savename",
}

g_edit_text = nil
g_text_blink_time = 0
g_keyboard_state = 0

g_is_pointer_hovered = false
g_pointer_pos_x = 0
g_pointer_pos_y = 0
g_pointer_pos_x_prev = 0
g_pointer_pos_y_prev = 0
g_is_pointer_pressed = false
g_pointer_scroll = 0
g_is_mouse_mode = false

g_animation_time = 0
g_tut_is_help_tab_selected = false

function begin()
    begin_load()
    reset()

    g_tab_map.render = tab_map_render
    g_tab_map.input_event = tab_map_input_event
    g_tab_map.input_pointer = tab_map_input_pointer
    g_tab_map.input_scroll = tab_map_input_scroll
    g_tab_map.tab_title = update_get_loc(e_loc.upp_map)

    g_tab_game.render = tab_game_render
    g_tab_game.begin = tab_game_begin
    g_tab_game.input_event = tab_game_input_event
    g_tab_game.input_pointer = tab_game_input_pointer
    g_tab_game.input_scroll = tab_game_input_scroll
    g_tab_game.tab_title = update_get_loc(e_loc.upp_game)
    g_tab_game.ui_container = lib_imgui:create_ui()

    g_tab_options.render = tab_options_render
    g_tab_options.input_event = tab_options_input_event
    g_tab_options.input_pointer = tab_options_input_pointer
    g_tab_options.input_scroll = tab_options_input_scroll
    g_tab_options.tab_title = update_get_loc(e_loc.upp_options)
    g_tab_options.ui_container = lib_imgui:create_ui()

    g_tab_multiplayer.begin = tab_multiplayer_begin
    g_tab_multiplayer.render = tab_multiplayer_render
    g_tab_multiplayer.input_event = tab_multiplayer_input_event
    g_tab_multiplayer.input_pointer = tab_multiplayer_input_pointer
    g_tab_multiplayer.input_scroll = tab_multiplayer_input_scroll
    g_tab_multiplayer.tab_title = update_get_loc(e_loc.upp_multiplayer)
    g_tab_multiplayer.ui_container = lib_imgui:create_ui()

    g_tab_manual.render = tab_manual_render
    g_tab_manual.input_event = tab_manual_input_event
    g_tab_manual.input_pointer = tab_manual_input_pointer
    g_tab_manual.input_scroll = tab_manual_input_scroll
    g_tab_manual.tab_title = update_get_loc(e_loc.upp_manual)
    g_tab_manual.ui_container = lib_imgui:create_ui()
end

function reset()
    g_tab_map.is_map_pos_initialised = false
end

function update(screen_w, screen_h, delta_time)
    g_tab_map.tab_title = update_get_loc(e_loc.upp_map)
    g_tab_game.tab_title = update_get_loc(e_loc.upp_game)
    g_tab_options.tab_title = update_get_loc(e_loc.upp_options)
    g_tab_multiplayer.tab_title = update_get_loc(e_loc.upp_multiplayer)
    g_tab_manual.tab_title = update_get_loc(e_loc.upp_manual)

    g_is_mouse_mode = g_is_pointer_hovered and update_get_active_input_type() == e_active_input.keyboard
    g_animation_time = g_animation_time + delta_time
    g_text_blink_time = g_text_blink_time + delta_time

    if update_get_active_input_type() == e_active_input.keyboard then
        g_tut_is_help_tab_selected = g_active_tab == g_tabs.manual
    else
        g_tut_is_help_tab_selected = g_focused_screen == g_screens.active_tab and g_active_tab == g_tabs.manual
    end

    update_interaction_ui()

    local rebinding_keyboard = update_get_rebinding_keyboard()
    local rebinding_gamepad = update_get_rebinding_gamepad()
    local is_hoverable = g_focused_screen == g_screens.menu or g_tabs[g_active_tab].is_overlay == false

    if rebinding_keyboard ~= -1 or rebinding_gamepad ~= -1 then
        g_focused_screen = g_screens.active_tab
        is_hoverable = false
    elseif g_is_mouse_mode and g_is_pointer_hovered and is_hoverable then
        if g_pointer_pos_y > 15 then
            g_hovered_screen = g_screens.active_tab
        else
            g_hovered_screen = g_screens.menu
        end
    end

    update_ui_rectangle(0, 0, screen_w, 14, color_black)
    update_ui_line(0, 14, screen_w, 14, iff(is_hoverable, iff(g_focused_screen == g_screens.active_tab, color_white, color_highlight), color_grey_dark))
    
    local cx = 10

    g_hovered_tab = -1

    for i = 0, #g_tabs do
        if get_is_tab_visible(i) then
            local tx = cx
            local ty = 4
            local tw = update_ui_get_text_size(g_tabs[i].tab_title, 10000, 0) + 8
            local th = 11

            local is_hovered = g_is_mouse_mode and g_is_pointer_hovered and point_in_rect(tx, ty, tw, th, g_pointer_pos_x, g_pointer_pos_y) and is_hoverable

            if is_hovered then
                g_hovered_tab = i
            end

            render_tab(tx, ty, tw, g_tabs[i].tab_title, get_tab_colors(g_active_tab == i and g_focused_screen == g_screens.active_tab, g_active_tab == i, is_hovered, is_hoverable == false))
            cx = cx + tw + 1
        end
    end

    update_ui_push_clip(0, 15, screen_w, screen_h - 15)
    g_tabs[g_active_tab].render(screen_w, screen_h, 0, 15, screen_w, screen_h - 15, delta_time, g_focused_screen == g_screens.active_tab)
    update_ui_pop_clip()

    update_set_is_text_input_mode(get_is_text_input_mode())

    g_pointer_scroll = 0
    g_pointer_pos_x_prev = g_pointer_pos_x
    g_pointer_pos_y_prev = g_pointer_pos_y
end

function update_interaction_ui()
    if get_is_text_input_mode() == false then
        if g_focused_screen == g_screens.active_tab then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_close), e_game_input.pause)
            update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)
        else
            update_add_ui_interaction(update_get_loc(e_loc.interaction_close), e_game_input.pause)
            update_add_ui_interaction(update_get_loc(e_loc.interaction_close), e_game_input.back)
        end
    end

    if get_is_text_input_mode() then
        update_add_ui_interaction(update_get_loc(e_loc.interaction_confirm), e_game_input.text_enter)
        
        if update_get_active_input_type() == e_active_input.keyboard then
            update_add_ui_interaction("", e_game_input.back)
        else
            update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_all)
            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
        end
    elseif update_get_active_input_type() == e_active_input.gamepad then
        if g_focused_screen == g_screens.active_tab then
            if g_active_tab == g_tabs.options then
                update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)
            elseif g_active_tab == g_tabs.game then
                update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)
            end
        elseif g_focused_screen == g_screens.menu then
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_lr)
            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
        end
    elseif g_hovered_tab ~= -1 then
        update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
    end

    if g_focused_screen == g_screens.active_tab then
        if g_active_tab == g_tabs.map then
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_pan), e_ui_interaction_special.map_pan)
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_zoom), e_ui_interaction_special.map_zoom)
        end
    end
end

function set_active_tab(tab)
    if g_active_tab ~= tab then
        g_active_tab = tab
        
        if g_tabs[tab] ~= nil and g_tabs[tab].begin ~= nil then
            g_tabs[tab].begin()
        end
    end
end

function previous_tab()
    local i = 0

    repeat
        set_active_tab((g_active_tab + #g_tabs) % (#g_tabs + 1))
        i = i + 1
    until get_is_tab_visible(g_active_tab) or i > #g_tabs
end

function next_tab()
    local i = 0

    repeat
        set_active_tab((g_active_tab + 1) % (#g_tabs + 1))
        i = i + 1
    until get_is_tab_visible(g_active_tab) or i > #g_tabs
end

function render_button(x, y, w, text, is_highlighted, is_pressed)
    update_ui_push_offset(x, y)

    local col = iff(is_pressed, color_white, iff(is_highlighted, color_highlight, color_grey_dark))
    update_ui_rectangle(0, 0, w, 10, col)
    update_ui_text(12, 1, text, w, 0, color_black, 0)

    update_ui_pop_offset()
end

function input_event(event, action)
    if event == e_input.pointer_1 then
        g_is_pointer_pressed = action == e_input_action.press
    end

    if event == e_input.pointer_1 then
        g_focused_screen = g_hovered_screen
    end

    if g_edit_text ~= nil and update_get_active_input_type() == e_active_input.keyboard and event ~= e_input.pointer_1 and event ~= e_input.text_backspace and event ~= e_input.text_enter then
        return
    end

    if g_focused_screen == g_screens.menu then
        if event == e_input.left then
            if action == e_input_action.press then
                previous_tab()
            end
        elseif event == e_input.right then
            if action == e_input_action.press then
                next_tab()
            end
        elseif event == e_input.action_a then
            if action == e_input_action.press then
                g_focused_screen = g_screens.active_tab
            end
        elseif event == e_input.pointer_1 then
            if g_hovered_tab ~= -1 then
                set_active_tab(g_hovered_tab)
            end
        elseif event == e_input.back then
            if action == e_input_action.press then
                update_exit_pause_menu()
            end
        end
    elseif g_focused_screen == g_screens.active_tab then
        if g_tabs[g_active_tab].input_event(event, action) then
            g_focused_screen = g_screens.menu
        end
    end
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
end

function input_text(text)
    if g_edit_text ~= nil then
        g_text[g_edit_text] = g_text[g_edit_text] .. text
        g_text[g_edit_text] = clamp_str(g_text[g_edit_text], 128)
        g_text_blink_time = 0
    end
end

function on_close_pause_menu()
    g_tab_game.screen_index = 0
    g_tab_game.confirm_save_slot = nil
    g_tab_game.confirm_load_slot = nil
end


--------------------------------------------------------------------------------
--
-- TAB MAP
--
--------------------------------------------------------------------------------

function tab_map_render(screen_w, screen_h, x, y, w, h, delta_time, is_active)
    update_set_screen_background_type(1)

    if g_tab_map.is_map_pos_initialised == false then
        g_tab_map.is_map_pos_initialised = true
        focus_world()
    end

    if is_active then
        local speed_multiplier = delta_time / 30

        g_tab_map.camera_pos_x = g_tab_map.camera_pos_x + g_input_axis.x * g_tab_map.camera_size * 0.01 * speed_multiplier
        g_tab_map.camera_pos_y = g_tab_map.camera_pos_y + g_input_axis.y * g_tab_map.camera_size * 0.01 * speed_multiplier
        tab_map_zoom(1 - (g_input_axis.w * 0.1 * speed_multiplier))
        
        if g_is_mouse_mode then
            tab_map_zoom(1 - g_pointer_scroll * 0.15)

            local pointer_dx = g_pointer_pos_x - g_pointer_pos_x_prev
            local pointer_dy = g_pointer_pos_y - g_pointer_pos_y_prev

            if g_is_pointer_pressed then
                g_tab_map.camera_pos_x = g_tab_map.camera_pos_x - pointer_dx * g_tab_map.camera_size * 0.005 * speed_multiplier
                g_tab_map.camera_pos_y = g_tab_map.camera_pos_y + pointer_dy * g_tab_map.camera_size * 0.005 * speed_multiplier
            end
        end
    end

    update_set_screen_map_position_scale(g_tab_map.camera_pos_x, g_tab_map.camera_pos_y, g_tab_map.camera_size)

    local function world_to_screen(x, y)
        return get_screen_from_world(x, y, g_tab_map.camera_pos_x, g_tab_map.camera_pos_y, g_tab_map.camera_size, screen_w, screen_h)
    end

    local is_render_islands = (g_tab_map.camera_size < (64 * 1024))
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

    -- render vehicles

    local function filter_vehicles(v)
        local def = v:get_definition_index()
        return v:get_is_docked() == false and def ~= e_game_object_type.drydock and def ~= e_game_object_type.chassis_spaceship and v:get_is_observation_revealed()
    end

    for _, vehicle in iter_vehicles(filter_vehicles) do
        local icon_region, icon_offset = get_icon_data_by_definition_index(vehicle:get_definition_index())
        local team_color = update_get_team_color(vehicle:get_team_id())
        local position_xz = vehicle:get_position()
        local screen_x, screen_y = world_to_screen(position_xz:x(), position_xz:z())

        if vehicle:get_is_visible() then
            update_ui_image(screen_x - icon_offset, screen_y - icon_offset, icon_region, team_color, 0)
        else
            local last_known_position_xz, is_last_known_position_set = vehicle:get_vision_last_known_position_xz()

            if is_last_known_position_set then
                local screen_x, screen_y = world_to_screen(last_known_position_xz:x(), last_known_position_xz:y())
                update_ui_image(screen_x - 2, screen_y - 2, atlas_icons.map_icon_last_known_pos, team_color, 0)
            end
        end
    end

    -- render ui

    update_ui_push_offset(x, y)

    if is_active then
        local zoom_factor = invlerp(g_tab_map.camera_size, g_tab_map.camera_size_min, g_tab_map.camera_size_max)

        update_ui_text(10, h - 20, 
            string.format("x:%-6.0f ", g_tab_map.camera_pos_x) .. 
            string.format("y:%-6.0f ",g_tab_map.camera_pos_y) .. 
            string.format("z:%.2f", zoom_factor),
            w - 10, 0, color_grey_dark, 0
        )
    end

    update_ui_pop_offset()
end

function tab_map_zoom(amount)
    g_tab_map.camera_size = g_tab_map.camera_size * amount
    g_tab_map.camera_size = math.min(g_tab_map.camera_size, g_tab_map.camera_size_max)
    g_tab_map.camera_size = math.max(g_tab_map.camera_size, g_tab_map.camera_size_min)
end

function tab_map_input_event(event, action)
    if action == e_input_action.press then
        if event == e_input.back then
            return true
        end
    end
    
    return false
end

function tab_map_input_pointer(is_hovered, x, y)
end

function tab_map_input_scroll(dy)
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



--------------------------------------------------------------------------------
--
-- TAB GAME
--
--------------------------------------------------------------------------------

function tab_game_begin()
    g_tab_game.screen_index = 0
end

function tab_game_render(screen_w, screen_h, x, y, w, h, delta_time, is_tab_active)
    update_set_screen_background_type(0)
    update_ui_push_offset(x, y)

    local ui = g_tab_game.ui_container
    g_tab_game.is_overlay = false

    ui:begin_ui(delta_time)

    local is_active = is_tab_active and g_edit_text == nil
    local is_mouse_active = g_is_mouse_mode and g_is_pointer_hovered and g_hovered_screen == g_screens.active_tab

    if g_tab_game.screen_index == 0 then
        ui:begin_window("##main", 5, 5, w - 10, h - 15, atlas_icons.column_pending, is_active or is_mouse_active, 0, true, is_active)
        
        if ui:list_item(update_get_loc(e_loc.upp_return_to_bridge), true, update_get_is_respawn_menu_option_available()) then
            update_ui_event("character_return_to_bridge")
            update_exit_pause_menu()
        end

        ui:divider()

        if ui:list_item(update_get_loc(e_loc.upp_save), true, update_get_is_save_game_available()) then
            g_tab_game.screen_index = 2
        end
    
        if ui:list_item(update_get_loc(e_loc.upp_load), true) then
            g_tab_game.screen_index = 1
        end
    
        ui:divider()
    
        if ui:list_item(update_get_loc(e_loc.upp_quit), true) then
            reset()
            update_ui_event("quit_to_menu")
        end
    
        if ui:list_item(update_get_loc(e_loc.upp_quit_to_desktop), true) then
            update_ui_event("quit_game")
        end
    
        ui:divider()
    
        if ui:list_item(update_get_loc(e_loc.upp_report_issue), true) then
            update_ui_event("open_feedback_website")
        end

        ui:end_window()
    elseif g_tab_game.screen_index == 1 then
        ui:begin_window(update_get_loc(e_loc.upp_load_game), 5, 5, w - 10, h - 15, atlas_icons.column_load, is_active and g_tab_game.confirm_load_slot == nil)
            
        ui:header(update_get_loc(e_loc.upp_save_slots))

        local save_slots = update_get_save_slots()
        table.sort(save_slots, function(a, b) return a.time > b.time end)

        for i, v in ipairs(save_slots) do
            if ui:save_slot(i, v.display_name, v.save_name, v.time) then
                if #v.save_name > 0 then
                    g_tab_game.confirm_load_slot = v
                end
            end
        end

        ui:end_window()

        if g_tab_game.confirm_load_slot ~= nil then
            g_tab_game.is_overlay = true
            update_ui_rectangle(0, 0, w, h, color8(0, 0, 0, 200))

            ui:begin_window(update_get_loc(e_loc.upp_confirm).."##confirm_load", 60, 60, w - 120, h - 135, nil, is_active, 2)
            
            if ui:button(update_get_loc(e_loc.upp_cancel), true, 1) then
                g_tab_game.confirm_load_slot = nil
            end

            if ui:button(update_get_loc(e_loc.upp_confirm), true, 1) then
                update_ui_event("load_game", g_tab_game.confirm_load_slot.slot_index)
                g_tab_game.confirm_load_slot = nil
            end

            ui:end_window()
        end
    elseif g_tab_game.screen_index == 2 then
        ui:begin_window(update_get_loc(e_loc.upp_save_game), 5, 5, w - 10, h - 15, atlas_icons.column_save, is_active and g_tab_game.confirm_save_slot == nil)
            
        ui:header(update_get_loc(e_loc.upp_save_slots))

        local save_slots = update_get_save_slots()
        table.sort(save_slots, function(a, b) return a.time > b.time end)

        for i, v in ipairs(save_slots) do
            if ui:save_slot(i, v.display_name, v.save_name, v.time) then
                g_tab_game.confirm_save_slot = v

                if #v.save_name > 0 then
                    g_text.save_name = v.display_name
                else
                    g_text.save_name = update_string_from_epoch(update_get_time_since_epoch(), "%H:%M:%S %d/%m/%Y")
                end
            end
        end

        ui:end_window()

        if g_tab_game.confirm_save_slot ~= nil then
            g_tab_game.is_overlay = true
            update_ui_rectangle(0, 0, w, h, color8(0, 0, 0, 200))

            ui.window_col_active = iff(#g_tab_game.confirm_save_slot.save_name > 0, color_status_bad, color_white)
            ui:begin_window(iff(#g_tab_game.confirm_save_slot.save_name > 0, update_get_loc(e_loc.upp_overwrite_save).."?", update_get_loc(e_loc.upp_confirm)) .. "##confirm_save", 60, 40, w - 120, h - 100, nil, is_active, 2)
            ui:header(update_get_loc(e_loc.upp_save_name))
            ui.window_col_active = color_white

            if ui:textbox(g_text.save_name) then
                g_edit_text = "save_name"
            end

            ui:divider()

            if ui:button(update_get_loc(e_loc.upp_cancel), true, 1) then
                g_tab_game.confirm_save_slot = nil
            end

            if ui:button(update_get_loc(e_loc.upp_confirm), true, 1) then
                update_ui_event("save_game", g_tab_game.confirm_save_slot.slot_index, g_text.save_name)
                g_tab_game.confirm_save_slot = nil
            end

            ui:end_window()
        end
    end

    if g_edit_text then
        g_tab_game.is_overlay = true
        update_ui_rectangle(0, 0, w, h, color8(0, 0, 0, 200))

        local display_text = g_text[g_edit_text] .. iff(math.floor(g_text_blink_time / 1000 * 30) % 20 > 10, "$[1]|", "$[2]|")
        local border = 32
        local text_w, text_h = update_ui_get_text_size(display_text, screen_w - border * 2, 1)

        update_ui_push_offset(0, -20)
        update_ui_set_text_color(1, color_empty)
        update_ui_set_text_color(2, color_highlight)
        update_ui_rectangle_outline(border - 6, screen_h / 2 - 5 - text_h - 2, screen_w - border * 2 + 12, text_h + 4, color_button_bg_inactive)
        update_ui_text(border, screen_h / 2 - 5 - text_h, display_text, screen_w - border * 2, 1, color_white, 0)

        ui:begin_window("##keyboard", 0, screen_h / 2, screen_w, screen_h, nil, true, 1)
        
        local is_done = false
        g_keyboard_state, g_text[g_edit_text], is_done = ui:keyboard(g_keyboard_state, g_text[g_edit_text])
        
        if is_done then
            g_edit_text = nil
        end

        ui:end_window()
        update_ui_pop_offset()
    end

    ui:end_ui()
    update_ui_pop_offset()
end

function tab_game_input_event(event, action)
    if action == e_input_action.press then
        if event == e_input.back then
            if g_edit_text ~= nil then
                g_edit_text = nil
            elseif g_tab_game.confirm_save_slot ~= nil then
                g_tab_game.confirm_save_slot = nil
            elseif g_tab_game.confirm_load_slot ~= nil then
                g_tab_game.confirm_load_slot = nil
            elseif g_tab_game.screen_index ~= 0 then
                g_tab_game.screen_index = 0
            else
                return true
            end
        else
            g_tab_game.ui_container:input_event(event, action)
        end
    elseif action == e_input_action.release then
        g_tab_game.ui_container:input_event(event, action)
    end
    
    return false
end

function tab_game_input_pointer(is_hovered, x, y)
    g_tab_game.ui_container:input_pointer(is_hovered, x, y)
end

function tab_game_input_scroll(dy)
    g_tab_game.ui_container:input_scroll(dy)
end


--------------------------------------------------------------------------------
--
-- TAB OPTIONS
--
--------------------------------------------------------------------------------

function tab_options_render(screen_w, screen_h, x, y, w, h, delta_time, is_active)
    update_set_screen_background_type(0)
    update_ui_push_offset(x, y)

    local ui = g_tab_options.ui_container
    local lx = 5
    local lw = 64
    local lh = h - 15
    local rx = lx + lw + 5
    local rw = w - rx - lx

    local rebinding_keyboard = update_get_rebinding_keyboard()
    local rebinding_gamepad = update_get_rebinding_gamepad()

    if rebinding_keyboard ~= -1 or rebinding_gamepad ~= -1 then
        g_tab_options.selected_panel = 1
    elseif g_is_mouse_mode and g_is_pointer_hovered and ui:get_is_scroll_drag() == false then
        if g_pointer_pos_x < lx + lw + 2 then
            g_tab_options.hovered_panel = 0
        else
            g_tab_options.hovered_panel = 1
        end
    end

    local is_mouse_active = g_is_mouse_mode and g_is_pointer_hovered and g_hovered_screen == g_screens.active_tab
    local is_panel_0_selected = is_active and g_tab_options.selected_panel == 0
    local is_panel_1_selected = is_active and g_tab_options.selected_panel == 1

    if is_mouse_active then
        is_panel_0_selected = g_tab_options.hovered_panel == 0
        is_panel_1_selected = g_tab_options.hovered_panel == 1
    end

    local is_panel_0_highlight = is_active and g_tab_options.selected_panel == 0
    local is_panel_1_highlight = is_active and g_tab_options.selected_panel == 1

    ui:begin_ui(delta_time)

    local win_main = ui:begin_window("##main", lx, 5, lw, lh, atlas_icons.column_pending, is_panel_0_selected, 0, true, is_panel_0_highlight)
    ui:list_item(update_get_loc(e_loc.upp_graphics))
    ui:list_item(update_get_loc(e_loc.upp_audio))
    ui:list_item(update_get_loc(e_loc.upp_ui))

    if update_get_is_vr() == false then
        ui:list_item(update_get_loc(e_loc.upp_settings_gameplay))
    end

    if update_get_is_vr() then
        ui:list_item(update_get_loc(e_loc.upp_vr))
    else
        ui:list_item(update_get_loc(e_loc.upp_keyboard))
        ui:list_item(update_get_loc(e_loc.upp_mouse))
        ui:list_item(update_get_loc(e_loc.upp_gamepad))
    end
    ui:end_window()
    
    imgui_options_menu(ui, rx, 5, rw, lh, is_panel_1_selected, win_main.selected_index_y, is_panel_1_highlight)

    ui:end_ui()
    update_ui_pop_offset()
end

function tab_options_input_event(event, action)
    if action == e_input_action.press then
        if event == e_input.pointer_1 then
            g_tab_options.selected_panel = g_tab_options.hovered_panel
        end

        if event == e_input.back then
            if g_tab_options.selected_panel == 1 then
                g_tab_options.selected_panel = 0
            else
                return true
            end
        elseif event == e_input.action_a and g_tab_options.selected_panel == 0 then
            g_tab_options.selected_panel = 1
        else
            g_tab_options.ui_container:input_event(event, action)
        end
    elseif action == e_input_action.release then
        g_tab_options.ui_container:input_event(event, action)
    end

    return false
end

function tab_options_input_pointer(is_hovered, x, y)
    g_tab_options.ui_container:input_pointer(is_hovered, x, y)
end

function tab_options_input_scroll(dy)
    g_tab_options.ui_container:input_scroll(dy)
end


--------------------------------------------------------------------------------
--
-- TAB MULTIPLAYER
--
--------------------------------------------------------------------------------

function tab_multiplayer_begin()
    g_tab_multiplayer.screen_index = 0
    g_tab_multiplayer.selected_peer_id = 0
end

function tab_multiplayer_render(screen_w, screen_h, x, y, w, h, delta_time, is_active)
    update_set_screen_background_type(0)
    update_ui_push_offset(x, y)

    local ui = g_tab_multiplayer.ui_container

    ui:begin_ui(delta_time)

    local is_mouse_active = g_is_mouse_mode and g_is_pointer_hovered and g_hovered_screen == g_screens.active_tab

    if g_tab_multiplayer.screen_index == 0 then
        local is_window_active = (is_active or is_mouse_active) and g_tab_multiplayer.selected_peer_id == 0
        local win_main = ui:begin_window("##main",  10, 5, w - 20, h - 15, atlas_icons.column_pending, is_window_active, 0, true, is_active and g_tab_multiplayer.selected_peer_id == 0)

        if ui:list_item(update_get_loc(e_loc.upp_public_invite), true) then
            g_tab_multiplayer.screen_index = 1            
        end

        local column_widths = { 25, 175, 33 }
        local column_margins = { 5, 5, 5 }
    
        local header_columns = {
            { w=column_widths[1], margin=column_margins[1], value=atlas_icons.column_controlling_peer },
            { w=column_widths[2], margin=column_margins[2], value=atlas_icons.column_profile },
            { w=column_widths[3], margin=column_margins[3], value=atlas_icons.column_team_control },
        }
        imgui_table_header(ui, header_columns)
    
        local peer_count = update_get_peer_count()
    
        for i = 0, peer_count - 1 do
            local name = update_get_peer_name(i)
            local team = update_get_peer_team(i)
            local id = update_get_peer_id(i)
            local team_col = update_get_team_color(team)
    
            local columns = { 
                { w=column_widths[1], margin=column_margins[1], value=tostring(id) },
                { w=column_widths[2], margin=column_margins[2], value=name },
                { w=column_widths[3], margin=column_margins[3], value=function(w, h) 
                    update_ui_image(0, 3, atlas_icons.column_team_control, iff(is_window_active, team_col, color_grey_dark), 0)  
                    update_ui_text(8, 3, tostring(team), w, 0, iff(is_window_active, team_col, color_grey_dark), 0)
                end },
            }
    
            if imgui_table_entry(ui, columns, update_get_is_hosting_game()) then
                g_tab_multiplayer.selected_peer_id = id
            end
        end

        ui:divider(0, 0)
        ui:divider(3, 5)
        ui:end_window()

        if g_tab_multiplayer.selected_peer_id ~= 0 then
            local peer_index = get_peer_index_by_id(g_tab_multiplayer.selected_peer_id)

            if peer_index ~= -1 then
                local name = update_get_peer_name(peer_index)

                local win_peer = ui:begin_window(name .. "##peer",  40, 40, w - 80, h - 80, atlas_icons.column_pending, is_active or is_mouse_active, 2, true, is_active)

                ui:header(update_get_loc(e_loc.upp_actions))

                if ui:list_item(update_get_loc(e_loc.upp_kick_player)) then
                    update_ui_event("host_kick_player", g_tab_multiplayer.selected_peer_id)
                end

                ui:end_window()
            else
                g_tab_multiplayer.selected_peer_id = 0
            end
        end
    elseif g_tab_multiplayer.screen_index == 1 then
        local win_main = ui:begin_window(update_get_loc(e_loc.upp_public_invite).."##main",  10, 5, w - 20, h - 15, atlas_icons.column_pending, is_active or is_mouse_active, 0, true, is_active)
        
        if update_get_is_hosting_game() then
            ui:header(update_get_loc(e_loc.upp_invite_code))
            ui:text_basic(update_get_loc(e_loc.invite_code_desc), color_grey_dark)
    
            local connect_token = update_get_host_connect_token()
            local obscured_token = connect_token:sub(1, 3) .. "***********" .. connect_token:sub(#connect_token - 2)
    
            ui:spacer(3)
            ui:text_basic(obscured_token, color_grey_mid, nil, 1)
            ui:spacer(4)
            
            local button_action = ui:button_group({ update_get_loc(e_loc.copy_code), update_get_loc(e_loc.regenerate_code) }, true)
    
            if button_action == 0 then
                update_ui_event("copy_to_clipboard", connect_token)
                g_tab_multiplayer.toast_time = g_animation_time
                g_tab_multiplayer.toast_text = update_get_loc(e_loc.copied_to_clipboard)
                g_tab_multiplayer.toast_col = color_status_ok
            elseif button_action == 1 then
                update_ui_event("regenerate_host_token")
                g_tab_multiplayer.toast_time = g_animation_time
                g_tab_multiplayer.toast_text = update_get_loc(e_loc.regenerated_invite_code)
                g_tab_multiplayer.toast_col = color_status_warning
            end
    
            ui:spacer(5)
        end

        ui:end_window()

        if g_tab_multiplayer.toast_time ~= nil and g_animation_time - g_tab_multiplayer.toast_time < 1500 then
            local anim_factor = (g_animation_time - g_tab_multiplayer.toast_time) / 1500
            
            if anim_factor < 0.1 then
                anim_factor = anim_factor / 0.1
            elseif anim_factor > 0.9 then
                anim_factor = 1 - (anim_factor - 0.9) / 0.1
            else
                anim_factor = 1
            end
    
            update_ui_push_offset(15, h - 31)
            update_ui_push_clip(0, 0, w - 30, math.floor(16 * anim_factor + 0.5))
            update_ui_rectangle(0, 0, w - 30, 16, color_black)
            update_ui_rectangle_outline(0, 0, w - 30, 16, g_tab_multiplayer.toast_col)
            update_ui_text(0, 4, g_tab_multiplayer.toast_text, w - 30, 1, g_tab_multiplayer.toast_col, 0)
            update_ui_pop_clip()
            update_ui_pop_offset()
        end
    end

    ui:end_ui()
    update_ui_pop_offset()
end

function tab_multiplayer_input_event(event, action)
    if action == e_input_action.press then
        if event == e_input.back then
            if g_tab_multiplayer.screen_index == 1 then
                g_tab_multiplayer.screen_index = 0
            elseif g_tab_multiplayer.selected_peer_id ~= 0 then
                g_tab_multiplayer.selected_peer_id = 0
            else
                return true
            end
        else
            g_tab_multiplayer.ui_container:input_event(event, action)
        end
    elseif action == e_input_action.release then
        g_tab_multiplayer.ui_container:input_event(event, action)
    end

    return false
end

function tab_multiplayer_input_pointer(is_hovered, x, y)
    g_tab_multiplayer.ui_container:input_pointer(is_hovered, x, y)
end

function tab_multiplayer_input_scroll(dy)
    g_tab_multiplayer.ui_container:input_scroll(dy)
end


--------------------------------------------------------------------------------
--
-- TAB MANUAL
--
--------------------------------------------------------------------------------

function tab_manual_render(screen_w, screen_h, x, y, w, h, delta_time, is_active)
    update_set_screen_background_type(0)
    update_ui_push_offset(x, y)

    g_tab_manual.highlighted_section.timer = math.max(g_tab_manual.highlighted_section.timer - delta_time, 0)

    local ui = g_tab_manual.ui_container
    local lx = 5
    local lw = 82
    local lh = h - 15
    local rx = lx + lw + 5
    local rw = w - rx - lx

    if g_is_mouse_mode and g_is_pointer_hovered and ui:get_is_scroll_drag() == false then
        if g_pointer_pos_x < lx + lw + 2 then
            g_tab_manual.hovered_panel = 0
        else
            g_tab_manual.hovered_panel = 1
        end
    end

    ui:begin_ui(delta_time)

    local manual_sections = {
        { 
            title = update_get_loc(e_loc.upp_game_objectives),
            content = {
                { "h", update_get_loc(e_loc.upp_objectives) },
                update_get_loc(e_loc.manual_game_objectives_objectives_1),
                update_get_loc(e_loc.manual_game_objectives_objectives_2),
                update_get_loc(e_loc.manual_game_objectives_objectives_3),
                { "h", update_get_loc(e_loc.upp_capturing_islands) },
                update_get_loc(e_loc.manual_game_objectives_capturing_1),
                update_get_loc(e_loc.manual_game_objectives_capturing_2),
                update_get_loc(e_loc.manual_game_objectives_capturing_3)
            }
        },
        { 
            title = update_get_loc(e_loc.upp_helm),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                { update_get_loc(e_loc.manual_helm_overview), tag="helm" },

                { "h", update_get_loc(e_loc.upp_screens) },
                { "s", update_get_loc(e_loc.propulsion), update_get_loc(e_loc.manual_helm_screens_propulsion), tag="helm_screen_propulsion" },
                { "s", update_get_loc(e_loc.compass), update_get_loc(e_loc.manual_helm_screens_compass), tag="helm_screen_compass" },
                { "s", update_get_loc(e_loc.depth_sonar), update_get_loc(e_loc.manual_helm_screens_depth_sonar), tag="helm_screen_depth_radar" },
                { "s", update_get_loc(e_loc.navigation), update_get_loc(e_loc.manual_helm_screens_navigation), tag="helm_screen_navigation" },

                { "h", update_get_loc(e_loc.upp_buttons) },
                { "b", atlas_icons.help_button_green, update_get_loc(e_loc.engine_start), update_get_loc(e_loc.manual_helm_buttons_engine_start), tag="helm_button_engine_on" },
                { "b", atlas_icons.help_button_red, update_get_loc(e_loc.engine_stop), update_get_loc(e_loc.manual_helm_buttons_engine_stop), tag="helm_button_engine_off" },
                { "b", atlas_icons.help_button_grey, update_get_loc(e_loc.side_thrusters), update_get_loc(e_loc.manual_helm_buttons_side_thrusters), tag="helm_button_side_thrusters" },
                { "b", atlas_icons.help_button_grey, update_get_loc(e_loc.reverse), update_get_loc(e_loc.manual_helm_buttons_reverse), tag="helm_button_reverse_gear" },
                { "b", atlas_icons.help_button_switch, update_get_loc(e_loc.steering_lock), update_get_loc(e_loc.manual_helm_buttons_steering_lock), tag="helm_button_steering_lock" },
                { "b", atlas_icons.help_button_switch, update_get_loc(e_loc.maintain_heading), update_get_loc(e_loc.manual_helm_buttons_maintain_heading), tag="helm_button_maintain_heading" },
                { "b", atlas_icons.help_button_switch, update_get_loc(e_loc.navigation_lights), update_get_loc(e_loc.manual_helm_buttons_navigation_lights), tag="helm_button_nav_lights" },
                { "b", atlas_icons.help_button_switch, update_get_loc(e_loc.headlights), update_get_loc(e_loc.manual_helm_buttons_headlights), tag="helm_button_headlights" },
                { "b", atlas_icons.help_button_grey_small, update_get_loc(e_loc.headlights_up).."/"..update_get_loc(e_loc.headlights_down), update_get_loc(e_loc.manual_helm_buttons_headlights_up_down), tag="helm_button_headlights_ud" },
                { "b", atlas_icons.help_button_red, update_get_loc(e_loc.activate), update_get_loc(e_loc.manual_helm_buttons_activate), tag="helm_button_alarm_on" },
                { "b", atlas_icons.help_button_grey, update_get_loc(e_loc.silence), update_get_loc(e_loc.manual_helm_buttons_silence), tag="helm_button_alarm_off" },
            }
        },
        { 
            title = update_get_loc(e_loc.upp_defensive_weapons),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_defensive_weapons_overview_1),
                update_get_loc(e_loc.manual_defensive_weapons_overview_2),

                { "h", update_get_loc(e_loc.upp_aa_missiles) },
                update_get_loc(e_loc.manual_defensive_weapons_aa_missile_1),
                update_get_loc(e_loc.manual_defensive_weapons_aa_missile_2),

                { "h", update_get_loc(e_loc.upp_ciws_guns)},
                update_get_loc(e_loc.manual_defensive_weapons_ciws_guns_1),
                update_get_loc(e_loc.manual_defensive_weapons_ciws_guns_2),

                { "h", update_get_loc(e_loc.upp_screens) },
                { "s", update_get_loc(e_loc.aa_status), update_get_loc(e_loc.manual_defensive_weapons_screens_aa), tag="def_wep_screen_aa_status" },
                { "s", update_get_loc(e_loc.ciws_status), update_get_loc(e_loc.manual_defensive_weapons_screens_ciws), tag="def_wep_screen_ciws_status" },

                { "h", update_get_loc(e_loc.upp_buttons) },
                { "b", atlas_icons.help_button_covered, update_get_loc(e_loc.aa_armed).." (x2)", update_get_loc(e_loc.manual_defensive_weapons_buttons_aa), tag="def_wep_button_aa_armed" },
                { "b", atlas_icons.help_button_grey, update_get_loc(e_loc.missile_fire).." (x2)", update_get_loc(e_loc.manual_defensive_weapons_buttons_missile), tag="def_wep_button_missile_fire" },
                { "b", atlas_icons.help_button_covered, update_get_loc(e_loc.ciws_armed).." (x4)", update_get_loc(e_loc.manual_defensive_weapons_buttons_ciws), tag="def_wep_button_ciws_armed" },
            }
        },
        { 
            title = update_get_loc(e_loc.upp_support_weapons),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_support_weapons_overview_1),
                update_get_loc(e_loc.manual_support_weapons_overview_2),
                update_get_loc(e_loc.manual_support_weapons_overview_3),
                
                { "h", update_get_loc(e_loc.upp_screens) },
                { "s", update_get_loc(e_loc.support_weapons), update_get_loc(e_loc.manual_support_weapons_screens_support_weapons), tag="sup_wep_screen_support" },
                { "s", update_get_loc(e_loc.viewing_scope), update_get_loc(e_loc.manual_support_weapons_screens_viewing_scope), tag="sup_wep_screen_scope" },

                { "h", update_get_loc(e_loc.upp_buttons) },
                { "b", atlas_icons.help_button_covered, update_get_loc(e_loc.cruise_missile_armed), update_get_loc(e_loc.manual_support_weapons_buttons_missile), tag="sup_wep_button_msl_armed" },
                { "b", atlas_icons.help_button_covered, update_get_loc(e_loc.main_gun_armed), update_get_loc(e_loc.manual_support_weapons_buttons_main_gun), tag="sup_wep_button_gun_armed" },
                { "b", atlas_icons.help_button_covered, update_get_loc(e_loc.flare_launcher_armed), update_get_loc(e_loc.manual_support_weapons_buttons_flare), tag="sup_wep_button_flare_armed" },
                { "b", atlas_icons.help_button_red, update_get_loc(e_loc.flare_fire), update_get_loc(e_loc.manual_support_weapons_buttons_flare_fire), tag="sup_wep_button_flare_fire" },
            }
        },
        { 
            title = update_get_loc(e_loc.upp_naval_weapons),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_naval_weapons_overview_1),
                update_get_loc(e_loc.manual_naval_weapons_overview_2),

                { "h", update_get_loc(e_loc.upp_torpedo) },
                update_get_loc(e_loc.manual_naval_weapons_torpedo_1),
                update_get_loc(e_loc.manual_naval_weapons_torpedo_2),
                
                { "h", update_get_loc(e_loc.upp_torpedo_noisemaker) },
                update_get_loc(e_loc.manual_naval_weapons_noisemaker_1),
                update_get_loc(e_loc.manual_naval_weapons_noisemaker_2),

                { "h", update_get_loc(e_loc.upp_torpedo_decoy) },
                update_get_loc(e_loc.manual_naval_weapons_decoy_1),
                update_get_loc(e_loc.manual_naval_weapons_decoy_2),

                { "h", update_get_loc(e_loc.upp_screens) },
                { "s", update_get_loc(e_loc.air_sea_radar), update_get_loc(e_loc.manual_naval_weapons_screens_air_sea_radar), tag="nav_wep_screen_radar" },

                { "h", update_get_loc(e_loc.upp_buttons) },
                { "b", atlas_icons.help_button_covered, update_get_loc(e_loc.torpedo_armed), update_get_loc(e_loc.manual_naval_weapons_buttons_torpedo_armed), tag="nav_wep_button_torp_armed" },
                { "b", atlas_icons.help_button_grey_small, update_get_loc(e_loc.activation_delay), update_get_loc(e_loc.manual_naval_weapons_buttons_activation_delay), tag="nav_wep_button_delay_ud" },
                { "b", atlas_icons.help_button_grey_small, update_get_loc(e_loc.bearing), update_get_loc(e_loc.manual_naval_weapons_buttons_bearing), tag="nav_wep_button_bearing_ud" },
                { "b", atlas_icons.help_button_red, update_get_loc(e_loc.launch_torpedo).." (x4)", update_get_loc(e_loc.manual_naval_weapons_buttons_launch_torpedo), tag="nav_wep_button_torp_launch" },
                { "b", atlas_icons.help_button_grey_small, update_get_loc(e_loc.load_torpedo).." (x4)", update_get_loc(e_loc.manual_naval_weapons_buttons_load_torpedo), tag="nav_wep_button_torp_load" },
                { "b", atlas_icons.help_button_grey_small, update_get_loc(e_loc.load_noisemaker).." (x4)", update_get_loc(e_loc.manual_naval_weapons_buttons_load_noisemaker), tag="nav_wep_button_noise_load" },
                { "b", atlas_icons.help_button_covered, update_get_loc(e_loc.countermeasure_armed), update_get_loc(e_loc.manual_naval_weapons_buttons_countermeasure_armed), tag="nav_wep_button_count_armed" },
                { "b", atlas_icons.help_button_red, update_get_loc(e_loc.launch_countermeasure), update_get_loc(e_loc.manual_naval_weapons_buttons_launch_countermeasure), tag="nav_wep_button_count_launch" },
            }
        },
        { 
            title = update_get_loc(e_loc.upp_power),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_power_overview_1),
                update_get_loc(e_loc.manual_power_overview_2),
                update_get_loc(e_loc.manual_power_overview_3),

                { "h", update_get_loc(e_loc.upp_screens) },
                { "s", update_get_loc(e_loc.power), update_get_loc(e_loc.manual_power_screens), tag="power_screen_power" },
                { "ic", atlas_icons.help_icon_indicator, color_status_ok, update_get_loc(e_loc.fully_powered) },
                { "ic", atlas_icons.help_icon_indicator, color_status_warning, update_get_loc(e_loc.sharing_power) },
                { "ic", atlas_icons.help_icon_indicator, color_status_bad, update_get_loc(e_loc.no_power) },
                { "ic", atlas_icons.help_icon_indicator, color_grey_dark, update_get_loc(e_loc.disabled) },

                { "h", update_get_loc(e_loc.upp_buttons) },
                { "b", atlas_icons.help_button_switch, update_get_loc(e_loc.breaker_main), update_get_loc(e_loc.manual_power_buttons_main), tag="power_button_main" },
                { "b", atlas_icons.help_button_switch, update_get_loc(e_loc.breaker_repair), update_get_loc(e_loc.manual_power_buttons_repair), tag="power_button_repairs" },
                { "b", atlas_icons.help_button_switch, update_get_loc(e_loc.breaker_propulsion), update_get_loc(e_loc.manual_power_buttons_propulsion), tag="power_button_propulsion" },
                { "b", atlas_icons.help_button_switch, update_get_loc(e_loc.breaker_weapons), update_get_loc(e_loc.manual_power_buttons_weapons), tag="power_button_weapons" },
                { "b", atlas_icons.help_button_switch, update_get_loc(e_loc.breaker_radar), update_get_loc(e_loc.manual_power_buttons_radar), tag="power_button_radar" },
                { "b", atlas_icons.help_button_switch, update_get_loc(e_loc.breaker_lift), update_get_loc(e_loc.manual_power_buttons_lift), tag="power_button_lift" },
            }
        },
        { 
            title = update_get_loc(e_loc.upp_repair),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_repair_overview_1),
                update_get_loc(e_loc.manual_repair_overview_2),
                update_get_loc(e_loc.manual_repair_overview_3),

                { "h", update_get_loc(e_loc.upp_hull_damage) },
                update_get_loc(e_loc.manual_repair_hull_damage_1),
                update_get_loc(e_loc.manual_repair_hull_damage_2),
                update_get_loc(e_loc.manual_repair_hull_damage_3),

                { "h", update_get_loc(e_loc.upp_repairing) },
                update_get_loc(e_loc.manual_repair_repairing_1),
                update_get_loc(e_loc.manual_repair_repairing_2),

                { "h", update_get_loc(e_loc.upp_screens) },
                { "s", update_get_loc(e_loc.damage_repair), update_get_loc(e_loc.manual_repair_screens), tag="repair_screen_repair" },
            }
        },
        { 
            title = update_get_loc(e_loc.upp_vehicle_loadout),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_vehicle_loadout_overview_1),
                update_get_loc(e_loc.manual_vehicle_loadout_overview_2),
                update_get_loc(e_loc.manual_vehicle_loadout_overview_3),

                { "h", update_get_loc(e_loc.upp_attachments) },
                update_get_loc(e_loc.manual_vehicle_loadout_attachments_1),
                update_get_loc(e_loc.manual_vehicle_loadout_attachments_2),

                { "h", update_get_loc(e_loc.upp_chassis) },
                update_get_loc(e_loc.manual_vehicle_loadout_chassis_1),
                update_get_loc(e_loc.manual_vehicle_loadout_chassis_2),

                { "h", update_get_loc(e_loc.upp_screens) },
                { "s", update_get_loc(e_loc.screen_vehicle_loadout), update_get_loc(e_loc.manual_vehicle_loadout_screens), tag="veh_load_screen_loadout" },
            }
        },
        { 
            title = update_get_loc(e_loc.upp_vehicle_control),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_vehicle_control_overview),

                { "h", update_get_loc(e_loc.upp_waypoints) },
                update_get_loc(e_loc.manual_vehicle_control_waypoints_1),
                update_get_loc(e_loc.manual_vehicle_control_waypoints_2),
                update_get_loc(e_loc.manual_vehicle_control_waypoints_3),
                update_get_loc(e_loc.manual_vehicle_control_waypoints_4),
                update_get_loc(e_loc.manual_vehicle_control_waypoints_5),

                { "h", update_get_loc(e_loc.upp_map_menus) },
                update_get_loc(e_loc.manual_vehicle_control_map_menus_1),
                update_get_loc(e_loc.manual_vehicle_control_map_menus_2),
                update_get_loc(e_loc.manual_vehicle_control_map_menus_3),
                update_get_loc(e_loc.manual_vehicle_control_map_menus_4),

                { "h", update_get_loc(e_loc.upp_screens) },
                { "s", update_get_loc(e_loc.vehicle_control), update_get_loc(e_loc.manual_vehicle_control_screens_vehicle_control), tag="veh_con_screen_vehicle_control" },
                { "s", update_get_loc(e_loc.screen_air_traffic), update_get_loc(e_loc.manual_vehicle_control_screens_air_traffic), tag="veh_con_screen_air_traffic" },

                { "h", update_get_loc(e_loc.upp_buttons) },
                { "b", atlas_icons.help_button_grey_small, update_get_loc(e_loc.deploy_s1_s8), update_get_loc(e_loc.manual_vehicle_control_buttons_s), tag="veh_con_button_deploy_land" },
                { "b", atlas_icons.help_button_grey_small, update_get_loc(e_loc.deploy_a1_a8), update_get_loc(e_loc.manual_vehicle_control_buttons_a), tag="veh_con_button_deploy_air" },

                { "h", update_get_loc(e_loc.upp_map_key) },
                { "ic16", atlas_icons.map_icon_waypoint, color8(0, 255, 255, 8), update_get_loc(e_loc.vehicle_waypoint) },
                { "ic16", atlas_icons.map_icon_loop, color8(0, 255, 255, 8), update_get_loc(e_loc.loop_waypoint) },
                { "ic16", atlas_icons.icon_deploy_vehicle, color_status_ok, update_get_loc(e_loc.deploy_waypoint) },
                { "ic16", atlas_icons.icon_attack_type_airlift, color_status_ok, update_get_loc(e_loc.airlift_waypoint) },
                { "d" },
                { "ic16", atlas_icons.map_icon_island, color_friendly, update_get_loc(e_loc.island) },
                { "ic16", atlas_icons.column_difficulty, color_friendly, update_get_loc(e_loc.island_difficulty) },
                { "ic16", atlas_icons.map_icon_command_center, color_friendly, update_get_loc(e_loc.command_center) },
                { "d" },
                { "ic16", atlas_icons.map_icon_carrier, color_friendly, update_get_loc(e_loc.carrier) },
                { "ic16", atlas_icons.map_icon_surface, color_friendly, update_get_loc(e_loc.surface_vehicle) },
                { "ic16", atlas_icons.map_icon_surface_capture, color_friendly, update_get_loc(e_loc.surface_vehicle_with_virus_bots) },
                { "ic16", atlas_icons.map_icon_air, color_friendly, update_get_loc(e_loc.air_vehicle) },
                { "ic16", atlas_icons.map_icon_ship, color_friendly, update_get_loc(e_loc.ship) },
                { "ic16", atlas_icons.map_icon_barge, color_friendly, update_get_loc(e_loc.barge) },
                { "ic16", atlas_icons.map_icon_turret, color_friendly, update_get_loc(e_loc.turret) },
                { "ic16", atlas_icons.map_icon_robot_dog, color_friendly, update_get_loc(e_loc.virus_bot) },
                { "d" },
                { "ic16", atlas_icons.map_icon_missile_outline, color8(0, 255, 0, 255), update_get_loc(e_loc.missile) },
                { "ic16", atlas_icons.map_icon_torpedo, color8(64, 64, 255, 255), update_get_loc(e_loc.torpedo) },
                { "ic16", atlas_icons.map_icon_torpedo_decoy, color8(64, 64, 255, 255), update_get_loc(e_loc.torpedo_decoy) },
                { "d" },
                { "ic16", atlas_icons.map_icon_low_ammo, color8(255, 0, 0, 255), update_get_loc(e_loc.low_ammo) },
                { "ic16", atlas_icons.map_icon_low_fuel, color8(255, 0, 0, 255), update_get_loc(e_loc.low_fuel) },
                { "ic16", atlas_icons.map_icon_visible, color_enemy, update_get_loc(e_loc.visible_to_enemy) },
                { "ic16", atlas_icons.map_icon_last_known_pos, color_enemy, update_get_loc(e_loc.last_known_position) },
                { "d" },
                { "ic16", atlas_icons.icon_attack_type_any, color_enemy, update_get_loc(e_loc.attack_any_weapon) },
                { "ic16", atlas_icons.icon_attack_type_bomb_single, color_enemy, update_get_loc(e_loc.attack_bomb_single) },
                { "ic16", atlas_icons.icon_attack_type_bomb_double, color_enemy, update_get_loc(e_loc.attack_bomb_double) },
                { "ic16", atlas_icons.icon_attack_type_gun, color_enemy, update_get_loc(e_loc.attack_gun) },
                { "ic16", atlas_icons.icon_attack_type_missile_single, color_enemy, update_get_loc(e_loc.attack_missile_single) },
                { "ic16", atlas_icons.icon_attack_type_missile_double, color_enemy, update_get_loc(e_loc.attack_missile_double) },
                { "ic16", atlas_icons.icon_attack_type_rockets, color_enemy, update_get_loc(e_loc.attack_rockets) },
                { "ic16", atlas_icons.icon_attack_type_torpedo_single, color_enemy, update_get_loc(e_loc.attack_torpedo_single) },
            }
        },
        { 
            title = update_get_loc(e_loc.upp_vehicle_operation),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_vehicle_operation_overview_1),
                update_get_loc(e_loc.manual_vehicle_operation_overview_2),

                { "h", update_get_loc(e_loc.upp_vehicles) },
                update_get_loc(e_loc.manual_vehicle_operation_vehicles_1),
                update_get_loc(e_loc.manual_vehicle_operation_vehicles_2),
                update_get_loc(e_loc.manual_vehicle_operation_vehicles_3),
                update_get_loc(e_loc.manual_vehicle_operation_vehicles_4),

                { "h", update_get_loc(e_loc.upp_attachments) },
                update_get_loc(e_loc.manual_vehicle_operation_attachments_1),
                update_get_loc(e_loc.manual_vehicle_operation_attachments_2),
                update_get_loc(e_loc.manual_vehicle_operation_attachments_3),

                { "h", update_get_loc(e_loc.upp_multiplayer) },
                update_get_loc(e_loc.manual_vehicle_operation_multiplayer_1),
                update_get_loc(e_loc.manual_vehicle_operation_multiplayer_2),
                update_get_loc(e_loc.manual_vehicle_operation_multiplayer_3),
            }
        },
        { 
            title = update_get_loc(e_loc.upp_inventory),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_inventory_overview_1),
         
                { "h", update_get_loc(e_loc.upp_screens) },
                { "s", update_get_loc(e_loc.inventory_logistics), update_get_loc(e_loc.manual_inventory_screens_1), tag="inventory_screen_inventory" },

                { "h", update_get_loc(e_loc.upp_tab_stock) },
                update_get_loc(e_loc.manual_inventory_tab_stock_1),
                update_get_loc(e_loc.manual_inventory_tab_stock_2),

                { "h", update_get_loc(e_loc.upp_tab_map) },
                update_get_loc(e_loc.manual_inventory_tab_map_1),
                update_get_loc(e_loc.manual_inventory_tab_map_2),
                update_get_loc(e_loc.manual_inventory_tab_map_3),
                update_get_loc(e_loc.manual_inventory_tab_map_4),
                update_get_loc(e_loc.manual_inventory_tab_map_5),
                update_get_loc(e_loc.manual_inventory_tab_map_6),

                { "h", update_get_loc(e_loc.upp_tab_barges) },
                update_get_loc(e_loc.manual_inventory_tab_barges_1),
                update_get_loc(e_loc.manual_inventory_tab_barges_2),

                { "h", update_get_loc(e_loc.upp_map_key) },
                { "ic16", atlas_icons.map_icon_barge, color8(0, 255, 64, 255), update_get_loc(e_loc.barge) },
                { "ic16", atlas_icons.map_icon_carrier, color8(0, 64, 255, 255),update_get_loc(e_loc.carrier) },
                { "d" },
                { "ic16", atlas_icons.map_icon_warehouse, color8(255, 128, 0, 255), update_get_loc(e_loc.warehouse) },
                { "ic16", atlas_icons.map_icon_factory_barge, color8(255, 128, 0, 255), update_get_loc(e_loc.factory_barge) },
                { "ic16", atlas_icons.map_icon_factory_chassis_air, color8(255, 128, 0, 255), update_get_loc(e_loc.factory_air_chassis) },
                { "ic16", atlas_icons.map_icon_factory_chassis_land, color8(255, 128, 0, 255), update_get_loc(e_loc.factory_surface_chassis) },
                { "ic16", atlas_icons.map_icon_factory_fuel, color8(255, 128, 0, 255), update_get_loc(e_loc.factory_fuel) },
                { "ic16", atlas_icons.map_icon_factory_small_munitions, color8(255, 128, 0, 255), update_get_loc(e_loc.factory_small_munitions) },
                { "ic16", atlas_icons.map_icon_factory_large_munitions, color8(255, 128, 0, 255), update_get_loc(e_loc.factory_large_munitions) },
                { "ic16", atlas_icons.map_icon_factory_turrets, color8(255, 128, 0, 255), update_get_loc(e_loc.factory_turrets) },
                { "ic16", atlas_icons.map_icon_factory_utility, color8(255, 128, 0, 255), update_get_loc(e_loc.factory_utility) },
            }
        },
        {
            title = update_get_loc(e_loc.upp_logistics),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_logistics_overview_1),

                { "h", update_get_loc(e_loc.upp_factories) },
                update_get_loc(e_loc.manual_logistics_factories_1),

                { "h", update_get_loc(e_loc.upp_warehouses) },
                {  update_get_loc(e_loc.manual_logistics_warehouses_1) },
                update_get_loc(e_loc.manual_logistics_warehouses_2),

                { "h", update_get_loc(e_loc.upp_blueprints) },
                update_get_loc(e_loc.manual_logistics_blueprints_1),
                update_get_loc(e_loc.manual_logistics_blueprints_2),

                { "h", update_get_loc(e_loc.upp_barges) },
                update_get_loc(e_loc.manual_logistics_barges_1),
                update_get_loc(e_loc.manual_logistics_barges_2),
                update_get_loc(e_loc.manual_logistics_barges_3),
            }
        },
        { 
            title = update_get_loc(e_loc.upp_delivery_log),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_delivery_log_overview_1),
                update_get_loc(e_loc.manual_delivery_log_overview_2),

                { "h", update_get_loc(e_loc.upp_screens) },
                { "s", update_get_loc(e_loc.delivery_log), update_get_loc(e_loc.manual_delivery_log_screens_1), tag="ship_log_screen_delivery" },
            }
        },
        { 
            title = update_get_loc(e_loc.upp_ship_log),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_ship_log_overview_1),
                update_get_loc(e_loc.manual_ship_log_overview_2),
                update_get_loc(e_loc.manual_ship_log_overview_3),

                { "h", update_get_loc(e_loc.upp_screens) },
                { "s", update_get_loc(e_loc.ship_log), update_get_loc(e_loc.manual_ship_log_screens_1), tag="ship_log_screen_log" },
            }
        },
        { 
            title = update_get_loc(e_loc.upp_currency_report),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_currency_report_overview_1),
                update_get_loc(e_loc.manual_currency_report_overview_2),
                update_get_loc(e_loc.manual_currency_report_overview_3),
                update_get_loc(e_loc.manual_currency_report_overview_4),

                { "h", update_get_loc(e_loc.upp_screens) },
                { "s", update_get_loc(e_loc.currency_report), update_get_loc(e_loc.manual_currency_report_screens_1), tag="ship_log_screen_currency" },
            }
        },
        { 
            title = update_get_loc(e_loc.upp_cctv),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                update_get_loc(e_loc.manual_cctv_overview_1),
                update_get_loc(e_loc.manual_cctv_overview_2),

                { "h", update_get_loc(e_loc.upp_screens) },
                { "s", update_get_loc(e_loc.upp_cctv), update_get_loc(e_loc.manual_cctv_screens_1), tag="cctv_screen" },
            }
        },
        { 
            title = update_get_loc(e_loc.upp_holomap),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                { update_get_loc(e_loc.manual_holomap_overview_1), tag="holomap_screen_map" },
                update_get_loc(e_loc.manual_holomap_overview_2),

                { "h", update_get_loc(e_loc.upp_notifications) },
                update_get_loc(e_loc.manual_holomap_notifications_1),
                update_get_loc(e_loc.manual_holomap_notifications_2),

                { "h", update_get_loc(e_loc.upp_buttons) },
                { "b", atlas_icons.help_button_switch, update_get_loc(e_loc.on_off), update_get_loc(e_loc.manual_holomap_buttons_on_off), tag="holomap_button_on_off" },
                { "b", atlas_icons.help_button_blue, update_get_loc(e_loc.focus_carrier), update_get_loc(e_loc.manual_holomap_buttons_focus_carrier), tag="holomap_button_focus_carrier" },
                { "b", atlas_icons.help_button_blue, update_get_loc(e_loc.focus_world), update_get_loc(e_loc.manual_holomap_buttons_focus_world), tag="holomap_button_focus_world" },
                { "b", atlas_icons.help_button_grey, update_get_loc(e_loc.holomap_mode_cartographic), update_get_loc(e_loc.manual_holomap_buttons_cartographic), tag="holomap_button_map_mode_0" },
                { "b", atlas_icons.help_button_grey, update_get_loc(e_loc.holomap_mode_wind), update_get_loc(e_loc.manual_holomap_buttons_wind), tag="holomap_button_map_mode_1" },
                { "b", atlas_icons.help_button_grey, update_get_loc(e_loc.holomap_mode_precipitation), update_get_loc(e_loc.manual_holomap_buttons_precipitation), tag="holomap_button_map_mode_2" },
                { "b", atlas_icons.help_button_grey, update_get_loc(e_loc.holomap_mode_fog), update_get_loc(e_loc.manual_holomap_buttons_fog), tag="holomap_button_map_mode_3" },
                { "b", atlas_icons.help_button_grey, update_get_loc(e_loc.holomap_mode_ocean_current), update_get_loc(e_loc.manual_holomap_buttons_ocean_current), tag="holomap_button_map_mode_4" },
                { "b", atlas_icons.help_button_grey, update_get_loc(e_loc.holomap_mode_ocean_depth), update_get_loc(e_loc.manual_holomap_buttons_ocean_depth), tag="holomap_button_map_mode_5" },
            }
        },
        { 
            title = update_get_loc(e_loc.upp_self_destruct),
            content = {
                { "h", update_get_loc(e_loc.upp_overview) },
                { update_get_loc(e_loc.manual_self_destruct_overview_1), tag="self_destruct" },
                "",
                { "tc", color_status_bad, update_get_loc(e_loc.upp_warning) },
                { "tc", color_status_bad, update_get_loc(e_loc.manual_self_destruct_overview_2) },
            }
        },
    }

    local function find_section(tag)
        for section_key, section in pairs(manual_sections) do
            for content_key, content in pairs(section.content) do
                if type(content) == "table" and content.tag ~= nil then
                    if content.tag == tag then
                        return section_key, content_key
                    end
                end
            end
        end

        MM_LOG("Failed to find manual content with tag " .. tag)
        return nil
    end

    if g_tab_manual.selected_panel == 1 then
        ui:input_scroll_gamepad(g_input_axis.w)
        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_scroll), e_ui_interaction_special.gamepad_scroll)
    end

    local is_mouse_active = g_is_mouse_mode and g_is_pointer_hovered and g_hovered_screen == g_screens.active_tab
    local is_panel_0_selected = is_active and g_tab_manual.selected_panel == 0
    local is_panel_1_selected = is_active and g_tab_manual.selected_panel == 1

    if is_mouse_active then
        is_panel_0_selected = g_tab_manual.hovered_panel == 0
        is_panel_1_selected = g_tab_manual.hovered_panel == 1
    end

    local is_panel_0_highlight = is_active and g_tab_manual.selected_panel == 0
    local is_panel_1_highlight = is_active and g_tab_manual.selected_panel == 1

    local win_main = ui:begin_window(update_get_loc(e_loc.upp_contents).."##main", lx, 5, lw, lh, atlas_icons.column_pending, is_panel_0_selected, 0, true, is_panel_0_highlight)
        for k, v in pairs(manual_sections) do
            local item_y = win_main.cy
            ui:list_item_wrap(v.title)

            if g_tab_manual.highlighted_section.scroll_to_section > 0 then
                if k == g_tab_manual.selected_page then
                    ui:set_item_selected()
                    ui:set_scroll(item_y)
                end
            elseif ui:is_item_selected() then
                g_tab_manual.selected_page = k
            end
        end
    ui:end_window()

    local section = manual_sections[g_tab_manual.selected_page]

    if section then
        local highlighted_content_y = nil
        local highlighted_content_h = nil

        local content_win = ui:begin_window(section.title, rx, 5, rw, lh, nil, is_panel_1_selected, 0, true, is_panel_1_highlight)
            local prev_item_type = ""

            for k, v in pairs(section.content) do
                prev_item_type = type(v)

                local highlight_factor = 0

                if g_tab_manual.selected_page == g_tab_manual.highlighted_section.section_key and k == g_tab_manual.highlighted_section.content_key then
                    highlighted_content_y = content_win.cy
                    highlight_factor = math.min(g_tab_manual.highlighted_section.timer, 1000) / 1000
                end

                if type(v) == "string" then
                    if prev_item_type == "string" then ui:spacer(5) end
                    ui:text_basic(v)
                elseif type(v) == "number" then
                    ui:image(v, 3)
                elseif type(v) == "table" then
                    local element_type = v[1]

                    if element_type == "h" then
                        if k > 1 then ui:spacer(5) end
                        ui:header(v[2])
                    elseif element_type == "d" then
                        ui:divider()
                    elseif element_type == "b" then
                        imgui_help_label_desc(ui, v[2], v[3], v[4], nil, highlight_factor)
                    elseif element_type == "s" then
                        imgui_help_label_desc(ui, atlas_icons.help_screen, v[2], v[3], nil, highlight_factor)
                    elseif element_type == "i" then
                        imgui_help_label(ui, v[2], v[3], nil, nil, nil, highlight_factor)
                    elseif element_type == "ic" then
                        imgui_help_label(ui, v[2], v[4], v[3], nil, nil, highlight_factor)
                    elseif element_type == "ic16" then
                        imgui_help_label(ui, v[2], v[4], v[3], 16, 16, highlight_factor)
                    elseif element_type == "tc" then
                        if prev_item_type == "string" then ui:spacer(5) end
                        imgui_help_paragraph(ui, v[3], v[2], highlight_factor)
                        prev_item_type = "string"
                    else
                        if prev_item_type == "string" then ui:spacer(5) end
                        imgui_help_paragraph(ui, v[1], nil, highlight_factor)
                        prev_item_type = "string"
                    end
                end

                if g_tab_manual.selected_page == g_tab_manual.highlighted_section.section_key and k == g_tab_manual.highlighted_section.content_key then
                    highlighted_content_h = content_win.cy - highlighted_content_y
                end
            end

            ui:divider(5, 0)
            ui:divider(3, 10)

            if highlighted_content_y ~= nil and g_tab_manual.highlighted_section.scroll_to_section > 0 then
                ui:set_scroll(highlighted_content_y + highlighted_content_h / 2 + 10)
            end
        ui:end_window()
    else
        g_tab_manual.selected_page = 1
    end

    g_tab_manual.highlighted_section.scroll_to_section = math.max(g_tab_manual.highlighted_section.scroll_to_section - 1, 0)

    if g_tab_manual.highlighted_section.section_tag_pending ~= "" then
        g_tab_manual.highlighted_section.section_key, g_tab_manual.highlighted_section.content_key = find_section(g_tab_manual.highlighted_section.section_tag_pending)    

        if g_tab_manual.highlighted_section.section_key ~= nil and g_tab_manual.highlighted_section.content_key ~= nil then
            g_tab_manual.highlighted_section.timer = 2000    
            g_tab_manual.selected_page = g_tab_manual.highlighted_section.section_key
            g_tab_manual.highlighted_section.scroll_to_section = 2
            g_tab_manual.selected_panel = 1
        end

        g_tab_manual.highlighted_section.section_tag_pending = ""
    end

    ui:end_ui()
    update_ui_pop_offset()
end

function tab_manual_input_event(event, action)
    if action == e_input_action.press then
        if event == e_input.pointer_1 then
            g_tab_manual.selected_panel = g_tab_manual.hovered_panel
        end

        if event == e_input.back then
            if g_tab_manual.selected_panel == 1 then
                g_tab_manual.selected_panel = 0
            else
                return true
            end
        elseif event == e_input.action_a and g_tab_manual.selected_panel == 0 then
            g_tab_manual.selected_panel = 1
        else
            g_tab_manual.ui_container:input_event(event, action)
        end
    elseif action == e_input_action.release then
        g_tab_manual.ui_container:input_event(event, action)
    end

    return false
end

function tab_manual_input_pointer(is_hovered, x, y)
    g_tab_manual.ui_container:input_pointer(is_hovered, x, y)
end

function tab_manual_input_scroll(dy)
    g_tab_manual.ui_container:input_scroll(dy)
end

function on_highlight_manual_section(section_tag)
    g_focused_screen = g_screens.active_tab
    set_active_tab(g_tabs.manual)
    g_tab_manual.highlighted_section.section_tag_pending = section_tag
end


--------------------------------------------------------------------------------
--
-- UTILITY FUNCTIONS
--
--------------------------------------------------------------------------------

function get_is_tab_visible(tab)
    if tab == g_tabs.multiplayer then
        return update_get_is_multiplayer()
    end

    return true
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
            vehicle = update_get_vehicle_by_index(index)
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

function imgui_help_label_desc(ui, icon, label, desc, col, highlight_factor)
    local window = ui:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = ui:get_region()

    local power = 2.2

    if col == nil then
        col = color_white
    else
        power = 1
    end

    col = iff(highlight_factor > 0, color8_lerp(col, get_color_highlight(true), highlight_factor), col)

    local icon_w, icon_h = update_ui_get_image_size(icon)
    local cx = x + 5
    local cy = y
    update_ui_image_power(cx, y, icon, col, 0, power)
    cx = cx + icon_w + 2

    local text_col = iff(highlight_factor > 0, color8_lerp(color_grey_mid, get_color_highlight(), highlight_factor), color_grey_mid)

    local text_y = cy + icon_h / 2 - 5
    local text_h = update_ui_text(cx, cy + icon_h / 2 - 5, label, w - cx - 5, 0, text_col, 0)
    cy = math.max(cy + icon_h, text_y + text_h) + 2

    text_col = iff(highlight_factor > 0, color8_lerp(color_grey_dark, get_color_highlight(), highlight_factor), color_grey_dark)

    text_h = update_ui_text(cx, cy, desc, w - cx - 5, 0, text_col, 0)
    cy = cy + text_h + 2

    window.cy = cy
end

function imgui_help_label(ui, icon, label, col, rect_w, rect_h, highlight_factor)
    local window = ui:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = ui:get_region()

    local power = 2.2

    if col == nil then
        col = color_white
    else
        power = 1
    end

    col = iff(highlight_factor > 0, color8_lerp(col, get_color_highlight(true), highlight_factor), col)

    local icon_w, icon_h = update_ui_get_image_size(icon)
    rect_w = rect_w or icon_w
    rect_h = rect_h or icon_h
    
    local cx = x + 5
    local cy = y
    update_ui_image_power(cx + (rect_w - icon_w) / 2, y + (rect_h - icon_h) / 2, icon, col, 0, power)
    cx = cx + rect_w + 2

    local text_col = iff(highlight_factor > 0, color8_lerp(color_grey_dark, get_color_highlight(), highlight_factor), color_grey_dark)
    
    local text_y = cy + rect_h / 2 - 5
    local text_h = update_ui_text(cx, text_y, label, w - cx - 5, 0, text_col, 0)
    cy = math.max(cy + rect_h, text_y + text_h) + 2

    window.cy = cy
end

function imgui_help_paragraph(ui, text, col, highlight_factor)
    if highlight_factor > 0 then
        col = col or color_grey_dark
        col = color8_lerp(col, get_color_highlight(), highlight_factor)
    end

    ui:text_basic(text, col, col)
end

function get_color_highlight(is_icon)
    if is_icon then
        return pulse(0.01, color_black, color_white)
    end

    return pulse(0.01, color_black, color_highlight)
end

function pulse(rate, col1, col2)
    local factor = math.sin(g_animation_time * rate) * 0.5 + 0.5
    return color8_lerp(col1, col2, factor)
end

function get_peer_index_by_id(id)
    local peer_count = update_get_peer_count()

    for i = 0, peer_count - 1 do
        if id == update_get_peer_id(i) then
            return i
        end
    end
    
    return -1
end

function get_is_text_input_mode()
    return g_edit_text ~= nil
end