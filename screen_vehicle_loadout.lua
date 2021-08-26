g_screen_index = 0
g_selected_bay_index = 0
g_selected_attachment_index = 0
g_selected_option_index = 0
g_animation_time = 0
g_no_stock_counter = 1000

g_attachment_combo_scroll = -1
g_chassis_combo_scroll = -1

g_ui = nil

function get_bay_name(index)
    if index >= 8 then
        return update_get_loc(e_loc.upp_acronym_air) .. (index - 7)
    else
        return update_get_loc(e_loc.upp_acronym_surface) .. (index + 1)
    end

    return update_get_loc(e_loc.upp_acronym_surface) .. "1"
end

function get_selected_chassis_options(bay_index)
    local selection_options = {}
    local is_ground = g_selected_bay_index < 8

    if is_ground then
        return {
            { region=atlas_icons.icon_attachment_16_none, type=-1 },
            { region=atlas_icons.icon_chassis_16_wheel_small, type=e_game_object_type.chassis_land_wheel_light },
            { region=atlas_icons.icon_chassis_16_wheel_medium, type=e_game_object_type.chassis_land_wheel_medium },
            { region=atlas_icons.icon_chassis_16_wheel_large, type=e_game_object_type.chassis_land_wheel_heavy }
        }
    else
        return {
            { region=atlas_icons.icon_attachment_16_none, type=-1 },
            { region=atlas_icons.icon_chassis_16_wing_small, type=e_game_object_type.chassis_air_wing_light },
            { region=atlas_icons.icon_chassis_16_wing_large, type=e_game_object_type.chassis_air_wing_heavy },
            { region=atlas_icons.icon_chassis_16_rotor_small, type=e_game_object_type.chassis_air_rotor_light },
            { region=atlas_icons.icon_chassis_16_rotor_large, type=e_game_object_type.chassis_air_rotor_heavy }
        }
    end

    return {}
end

function get_selected_vehicle_attachment_options(attachment_type)
    local attachment_options = {
        { region=atlas_icons.icon_attachment_16_none, type=-1 }
    }

    local option_count = update_get_attachment_option_count(attachment_type)

    for i = 0, option_count - 1 do
        local attachment_definition = update_get_attachment_option(attachment_type, i)

        if attachment_definition > -1 and update_get_attachment_option_hidden(attachment_definition) == false then
            local attachment_data = get_attachment_data_by_definition_index(attachment_definition)

            table.insert(attachment_options, {
                region = attachment_data.icon16,
                type = attachment_definition
            })
        end
    end

    return attachment_options
end

function parse()
    g_screen_index = parse_s32("", g_screen_index)
    g_selected_bay_index = parse_s32("", g_selected_bay_index)
    g_selected_attachment_index = parse_s32("", g_selected_attachment_index)
    g_selected_option_index = parse_s32("", g_selected_option_index)
end

function begin()
    begin_load()
    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    if g_no_stock_counter < 1000 then
        g_no_stock_counter = g_no_stock_counter + 1
    end

    g_animation_time = g_animation_time + ticks

    local this_vehicle = update_get_screen_vehicle()
    if this_vehicle:get() == false then return end

    local ui = g_ui

    ui:begin_ui()

    if g_screen_index == 0 then
        local window = ui:begin_window("##bay", 0, 0, screen_w, screen_h, nil, true, 1)
        local region_w, region_h = ui:get_region()

        update_ui_rectangle(0, 0, region_w, 14, color_white)
        update_ui_rectangle(region_w / 2, 0, 1, region_h, color_white)
        update_ui_text(2, 4, update_get_loc(e_loc.upp_surface), 60, 1, color_black, 0)
        update_ui_text(66, 4, update_get_loc(e_loc.upp_air), 60, 1, color_black, 0)

        window.cy = window.cy + 15
        local selected_bay_index, is_pressed = imgui_carrier_docking_bays(ui, this_vehicle, 4, 10, g_animation_time)

        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_all)

        if selected_bay_index ~= -1 then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
        end

        if is_pressed and selected_bay_index ~= -1 then
            g_screen_index = 1
            g_selected_bay_index = selected_bay_index
        end

        ui:end_window()
    else
        update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)

         -- title

        update_ui_rectangle(0, 0, screen_w, 14, color_white)
        update_ui_text(0, 4, get_bay_name(g_selected_bay_index), screen_w, 1, color_black, 0)

        -- dividers

        update_ui_rectangle(0, 92, screen_w, 1, color_white)

        local attached_vehicle = update_get_map_vehicle_by_id(this_vehicle:get_attached_vehicle_id(g_selected_bay_index))
        local is_show_attachment_selector = false

        if g_screen_index == 1 then
            -- vehicle loadout
            
            g_selected_option_index = 0

            if attached_vehicle:get() then
                update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_all)

                local vehicle_definition_index = attached_vehicle:get_definition_index()
                local vehicle_attachment_count = attached_vehicle:get_attachment_count()
                local vehicle_definition_name, vehicle_definition_icon, vehicle_definition_handle = get_chassis_data_by_definition_index(vehicle_definition_index)

                update_ui_rectangle(63, 14, 1, 78, color_white)

                local total_hitpoints, armour, mass = update_get_definition_vehicle_stats(vehicle_definition_index)
                local cy = 16

                update_ui_image(4, cy, atlas_icons.column_difficulty, color_grey_mid, 0)
                update_ui_text(13, cy, armour, 64, 0, color_grey_dark, 0)
                cy = cy + 10

                update_ui_image(4, cy, atlas_icons.column_weight, color_grey_mid, 0)
                update_ui_text(13, cy, mass .. update_get_loc(e_loc.upp_kg), 64, 0, color_grey_dark, 0)
                cy = cy + 11

                update_ui_rectangle(0, cy, 63, 1, color_grey_dark)
                cy = cy + 4

                update_ui_image(4, cy, atlas_icons.icon_health, color_white, 0)
                update_ui_text(13, cy, string.format("%.0f%%", attached_vehicle:get_repair_factor() * 100), 64, 0, color_status_ok, 0)
                cy = cy + 10

                update_ui_image(4, cy, atlas_icons.icon_fuel, color_white, 0)
                update_ui_text(13, cy, string.format("%.0f%%", attached_vehicle:get_fuel_factor() * 100), 64, 0, color_status_ok, 0)
                cy = cy + 10

                update_ui_image(4, cy, atlas_icons.icon_ammo, color_white, 0)
                update_ui_text(13, cy, string.format("%.0f%%", attached_vehicle:get_ammo_factor() * 100), 64, 0, color_status_ok, 0)

                local window = ui:begin_window("##vehicle", screen_w / 2, 14, screen_w / 2, screen_h - 14, nil, true, 1)
                    local region_w, region_h = ui:get_region()

                    if ui:button(vehicle_definition_name, true, 1) then
                        g_screen_index = 3
                    end

                    window.cy = window.cy - 1
                    g_selected_attachment_index, is_pressed = imgui_vehicle_chassis_loadout(ui, attached_vehicle)
                    
                    if is_pressed then
                        g_screen_index = 2
                    end
                ui:end_window()
                
                is_show_attachment_selector = window.selected_index_y > 0

                -- update selected option to match current selection

                if is_show_attachment_selector then
                    local attachment = attached_vehicle:get_attachment(g_selected_attachment_index)

                    if attachment:get() then
                        local attachment_definition = attachment:get_definition_index()
                        local attachment_type = attached_vehicle:get_attachment_type(g_selected_attachment_index)
                        local selection_options = get_selected_vehicle_attachment_options(attachment_type)

                        for i = 1, #selection_options do
                            if attachment_definition == selection_options[i].type then
                                g_selected_option_index = i - 1
                                break
                            end
                        end
                    end
                else
                    local selection_options = get_selected_chassis_options(g_selected_bay_index)

                    for i = 1, #selection_options do
                        if vehicle_definition_index == selection_options[i].type then
                            g_selected_option_index = i - 1
                            break
                        end
                    end
                end
            else
                ui:begin_window("##vehicle", 0, 14, screen_w, screen_h - 14, nil, true, 1)
                    if ui:button(update_get_loc(e_loc.upp_select_chassis), true, 1) then
                        g_screen_index = 3
                    end
                ui:end_window()
            end

            if is_show_attachment_selector then
                render_screen_attachment(screen_w, screen_h, this_vehicle, attached_vehicle, false)
            else
                render_screen_chassis(screen_w, screen_h, this_vehicle, false)
            end
        elseif g_screen_index == 2 then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_cancel), e_game_input.back)
            render_screen_attachment(screen_w, screen_h, this_vehicle, attached_vehicle, true)
        elseif g_screen_index == 3 then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_cancel), e_game_input.back)
            render_screen_chassis(screen_w, screen_h, this_vehicle, true)
        end
    end

    ui:end_ui()
end

function input_event(event, action)
    g_ui:input_event(event, action)

    if action == e_input_action.press then
        if g_screen_index == 0 then
            if event == e_input.back then
                update_set_screen_state_exit()
            end
        elseif g_screen_index == 1 then
            if event == e_input.back then
                g_screen_index = 0
            end
        elseif g_screen_index == 2 then
            if event == e_input.back then
                g_screen_index = 1
            end
        elseif g_screen_index == 3 then
            if event == e_input.back then
                g_screen_index = 1
            end
        end
    end
end

function input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
end

function input_scroll(dy)
    g_ui:input_scroll(dy)
end

function input_axis(x, y, z, w)
end

function render_screen_attachment(screen_w, screen_h, this_vehicle, attached_vehicle, is_active)   
    local ui = g_ui

    if attached_vehicle:get() then
        if g_selected_attachment_index ~= -1 then
            local attachment_type = attached_vehicle:get_attachment_type(g_selected_attachment_index)
            local selection_options = get_selected_vehicle_attachment_options(attachment_type)

            local function render_attachment_option(item, is_active, is_selected)
                render_button_bg(1, 0, 16, 25, iff(is_active, iff(is_selected, color_highlight, color_button_bg), color_button_bg_inactive), 1)
                update_ui_image(1, 0, item.region, iff(is_active, iff(is_selected, color_white, color_black), color_black), 0)

                if item ~= selection_options[1] then
                    if update_get_resource_item_for_definition(item.type) ~= -1 then
                        update_ui_text(1, 16, this_vehicle:get_inventory_count_by_definition_index(item.type), 16, 1, color_black, 0)
                    else
                        local ammo_type = update_get_attachment_ammo_item_type(item.type)

                        if ammo_type ~= -1 then
                            update_ui_text(1, 16, this_vehicle:get_inventory_count_by_item_index(ammo_type), 16, 1, color_black, 0)
                        end
                    end
                end
            end

            if is_active then
                if selection_options[g_selected_option_index + 1] ~= nil and selection_options[g_selected_option_index + 1].type > -1 then
                    render_ui_attachment_definition_description(4, 17, screen_w - 8, screen_h, this_vehicle, selection_options[g_selected_option_index + 1].type)
                else
                    update_ui_text(4, 17, update_get_loc(e_loc.upp_clear), 60, 0, color_white, 0)
                end
            else
                g_attachment_combo_scroll = -1
            end

            ui:begin_window(update_get_loc(e_loc.attachment).."##attachment", 0, 95, screen_w, screen_h - 95, nil, is_active, 1)
                g_selected_option_index, g_attachment_combo_scroll, is_pressed = imgui_combo_custom(ui, g_selected_option_index, selection_options, 18, 25, g_attachment_combo_scroll, render_attachment_option)

                if is_pressed then  
                    local definition_index = selection_options[g_selected_option_index + 1].type
                    local inventory_item_type = update_get_resource_item_for_definition(definition_index)

                    if g_selected_option_index == 0 then
                        this_vehicle:set_attached_vehicle_attachment(g_selected_bay_index, g_selected_attachment_index, -1)
                        g_screen_index = 1
                    elseif inventory_item_type == -1 or this_vehicle:get_inventory_count_by_definition_index(definition_index) > 0 then
                        this_vehicle:set_attached_vehicle_attachment(g_selected_bay_index, g_selected_attachment_index, selection_options[g_selected_option_index + 1].type)
                        g_screen_index = 1
                    else
                        g_no_stock_counter = 0
                    end
                end
            ui:end_window()
        end

        render_no_stock_indicator(4, 79, screen_w - 8)
    end
end

function render_screen_chassis(screen_w, screen_h, this_vehicle, is_active)
    local ui = g_ui
    local selection_options = get_selected_chassis_options(g_selected_bay_index)

    local function render_chassis_option(item, is_active, is_selected)
        render_button_bg(1, 0, 16, 25, iff(is_active, iff(is_selected, color_highlight, color_button_bg), color_button_bg_inactive), 1)
        update_ui_image(1, 0, item.region, iff(is_active, iff(is_selected, color_white, color_black), color_black), 0)

        if item ~= selection_options[1] then
            update_ui_text(1, 16, this_vehicle:get_inventory_count_by_definition_index(item.type), 16, 1, color_black, 0)
        end
    end

    if is_active then
        if selection_options[g_selected_option_index + 1].type > -1 then
            render_ui_chassis_definition_description(4, 17, this_vehicle, selection_options[g_selected_option_index + 1].type)
        else
            update_ui_text(4, 17, update_get_loc(e_loc.upp_clear), 60, 0, color_white, 0)
        end
    else
        g_chassis_combo_scroll = -1
    end

    ui:begin_window(update_get_loc(e_loc.chassis).."##chassis", 0, 95, screen_w, screen_h - 95, nil, is_active, 1)
        g_selected_option_index, g_chassis_combo_scroll, is_pressed = imgui_combo_custom(ui, g_selected_option_index, selection_options, 18, 25, g_chassis_combo_scroll, render_chassis_option)

        if is_pressed then

            local definition_index = selection_options[g_selected_option_index + 1].type
            local inventory_item_type = update_get_resource_item_for_definition(definition_index)

            if g_selected_option_index == 0 then
                this_vehicle:set_attached_vehicle_chassis(g_selected_bay_index, selection_options[g_selected_option_index + 1].type)
                g_screen_index = 1
            elseif inventory_item_type == -1 or this_vehicle:get_inventory_count_by_definition_index(definition_index) > 0 then
                this_vehicle:set_attached_vehicle_chassis(g_selected_bay_index, selection_options[g_selected_option_index + 1].type)
                g_screen_index = 1
            else
                g_no_stock_counter = 0
            end
        end
    ui:end_window()

    render_no_stock_indicator(4, 79, screen_w - 8)
end

function render_ui_attachment_definition_description(x, y, w, h, vehicle, index)
    local attachment_data = get_attachment_data_by_definition_index(index)
    update_ui_push_offset(x, y)
    
    local inventory_item_type = update_get_resource_item_for_definition(index)
    local is_in_stock = true
    local cy = 0

    if inventory_item_type ~= -1 then
        local inventory_count = vehicle:get_inventory_count_by_definition_index(index)

        update_ui_text(w - 20, cy, "x" .. inventory_count, 20, 2, iff(inventory_count > 0, color_status_ok, color_status_bad), 0)
        cy = cy + update_ui_text(0, cy, attachment_data.name, w - 20, 0, color_white, 0) + 2

        is_in_stock = inventory_count > 0
    else
        cy = cy + update_ui_text(0, cy, attachment_data.name, 120, 0, color_white, 0) + 2
    end

    local ammo_type = update_get_attachment_ammo_item_type(index)

    if ammo_type ~= -1 then
        local ammo_count = vehicle:get_inventory_count_by_item_index(ammo_type)
        update_ui_image(0, cy, atlas_icons.icon_ammo, iff(is_in_stock, color_white, color_grey_dark), 0)
        update_ui_text(10, cy, ammo_count, w - 10, 0, iff(is_in_stock, iff(ammo_count > 0, color_status_ok, color_status_bad), color_grey_dark), 0)
    end

    update_ui_pop_offset()
end

function render_no_stock_indicator(x, y, w)
    if g_no_stock_counter < 30 then
        update_ui_push_offset(x, y)

        update_ui_rectangle(0, 0, w, 12, color_status_bad)
        update_ui_text(0, 2, update_get_loc(e_loc.upp_out_of_stock), w, 1, color_black, 0)

        update_ui_pop_offset()
    end
end