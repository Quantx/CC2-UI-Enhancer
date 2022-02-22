g_region_icon = 0
g_ui = {}

function begin()
    begin_load()
    g_region_icon = begin_get_ui_region_index("microprose")
    g_ui = lib_imgui:create_ui()
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end
    
    update_interaction_ui()

    local ui = g_ui
    local back_col = color8(255, 255, 255, 5)

    ui:begin_ui()

    ui:begin_window("##preview", 15, 15, screen_w - 30, 110, atlas_icons.column_profile, false)
    
    local w, h = ui:get_region()

    local icons = {
        male = {
            head = atlas_icons.male_head,
            head_side = atlas_icons.male_head_side,
            hair = {
                [0] = { front = atlas_icons.male_a, side = atlas_icons.male_a_side },
                [1] = { front = atlas_icons.male_b, side = atlas_icons.male_b_side },
                [2] = { front = atlas_icons.male_c, side = atlas_icons.male_c_side },
                [3] = { front = atlas_icons.male_d, side = atlas_icons.male_d_side },
                [4] = nil,
                [5] = { front = atlas_icons.male_f, side = atlas_icons.male_f_side },
                [6] = { front = atlas_icons.male_g, side = atlas_icons.male_g_side },
                [7] = { front = atlas_icons.male_h, side = atlas_icons.male_h_side },
            },
            facial = {
                [0] = { front = atlas_icons.facialhair_a, side = atlas_icons.facialhair_a_side },
                [1] = { front = atlas_icons.facialhair_b, side = atlas_icons.facialhair_b_side },
                [2] = { front = atlas_icons.facialhair_c, side = atlas_icons.facialhair_c_side },
                [3] = { front = atlas_icons.facialhair_d, side = atlas_icons.facialhair_d_side },
                [4] = { front = atlas_icons.facialhair_e, side = atlas_icons.facialhair_e_side },
                [5] = { front = atlas_icons.facialhair_f, side = atlas_icons.facialhair_f_side },
                [6] = { front = atlas_icons.facialhair_g, side = atlas_icons.facialhair_g_side },
                [7] = { front = atlas_icons.facialhair_h, side = atlas_icons.facialhair_h_side },
            }
        },
        female = {
            head = atlas_icons.female_head,
            head_side = atlas_icons.female_head_side,
            hair = {
                [0] = { front = atlas_icons.female_a, side = atlas_icons.female_a_side },
                [1] = { front = atlas_icons.female_b, side = atlas_icons.female_b_side },
                [2] = { front = atlas_icons.female_c, side = atlas_icons.female_c_side },
                [3] = { front = atlas_icons.female_d, side = atlas_icons.female_d_side },
                [4] = { front = atlas_icons.female_e, side = atlas_icons.female_e_side },
                [5] = { front = atlas_icons.female_f, side = atlas_icons.female_f_side },
                [6] = { front = atlas_icons.female_g, side = atlas_icons.female_g_side },
                [7] = { front = atlas_icons.female_h, side = atlas_icons.female_h_side },
            },
            facial = {}
        }
    }

    local settings = update_get_game_settings()
    local icon_set = iff(settings.character_gender == 0, icons.male, icons.female)
    
    -- render front

    update_ui_push_offset(w / 2 - 64 - 10, h / 2 - 32)
    update_ui_rectangle(-5, -5, 74, 74, back_col)
    update_ui_image(0, 0, icon_set.head, gamma_correct(settings.character_skin_color), 0)

    if icon_set.hair[settings.character_hair_type] then
        update_ui_image(0, 0, icon_set.hair[settings.character_hair_type].front, gamma_correct(settings.character_hair_color), 0)
    end

    if icon_set.facial[settings.character_facial_hair_type] then
        update_ui_image(0, 0, icon_set.facial[settings.character_facial_hair_type].front, gamma_correct(settings.character_hair_color), 0)
    end

    update_ui_pop_offset()

    -- render side

    update_ui_push_offset(w / 2 + 10, h / 2 - 32)
    update_ui_rectangle(-5, -5, 74, 74, back_col)
    update_ui_image(0, 0, icon_set.head_side, gamma_correct(settings.character_skin_color), 0)
    
    if icon_set.hair[settings.character_hair_type] then
        update_ui_image(0, 0, icon_set.hair[settings.character_hair_type].side, gamma_correct(settings.character_hair_color), 0)
    end

    if icon_set.facial[settings.character_facial_hair_type] then
        update_ui_image(0, 0, icon_set.facial[settings.character_facial_hair_type].side, gamma_correct(settings.character_hair_color), 0)
    end

    update_ui_pop_offset()

    ui:end_window()

    imgui_character_options(g_ui, 15, 130, screen_w - 30, 110, true)

    ui:end_ui()

    imgui_menu_focus_overlay(ui, screen_w, screen_h, update_get_loc(e_loc.upp_profile), ticks)
end

function update_interaction_ui()
    update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)
end

function input_event(event, action)
    if action == e_input_action.release then
        if event == e_input.back then
            update_set_screen_state_exit()
        else
            g_ui:input_event(event, action)
        end
    else
        g_ui:input_event(event, action)
    end
end

function input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
end

function input_axis(x, y, z, w)
end
