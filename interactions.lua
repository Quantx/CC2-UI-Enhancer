g_interactions = {
    interactions = {},
    interactions_ordered = {},

    get_interaction_by_input = function(self, input)
        for i = 1, #self.interactions do
            if self.interactions[i].input == input then return self.interactions[i] end
        end

        return nil
    end,

    get_interaction_by_special = function(self, special, text_or_index)
        local index = 0

        for i = 1, #self.interactions do
            if self.interactions[i].special == special then
                if text_or_index == nil then
                    return self.interactions[i]
                elseif type(text_or_index) == "string" and self.interactions[i].text == text_or_index then
                    return self.interactions[i]
                elseif type(text_or_index) =="number" and index == text_or_index then
                    return self.interactions[i]
                end

                index = index + 1
            end
        end

        return nil
    end,

    add_interaction = function(self, text, input, special, internal_index)
        if get_is_input_valid(input, special) == false then
            return
        end
        
        local interaction = nil
        local special_override = nil

        if input < e_game_input.count then
            interaction = self:get_interaction_by_input(input)
        elseif special < e_ui_interaction_special.count then
            -- try to merge gamepad navigation interactions together

            if special == e_ui_interaction_special.gamepad_dpad_ud then
                interaction = self:get_interaction_by_special(e_ui_interaction_special.gamepad_dpad_lr, text)
            elseif special == e_ui_interaction_special.gamepad_dpad_lr then
                interaction = self:get_interaction_by_special(e_ui_interaction_special.gamepad_dpad_ud, text)
            end

            if interaction then
                special_override = e_ui_interaction_special.gamepad_dpad_all
            elseif get_is_special_interaction_type_multiline(special) then
                interaction = self:get_interaction_by_special(special, internal_index)
            else
                interaction = self:get_interaction_by_special(special)
            end
        end

        if interaction == nil then
            interaction = {
                text = text,
                text_prev = text,
                input = input,
                special = special,
                special_override = nil,
                is_visible = true,
                anim_factor = 0,
                anim_factor_text = 0,
                y = nil,
            }

            table.insert(self.interactions, interaction)
        end

        interaction.text = text
        interaction.is_visible = #text > 0
        interaction.special_override = special_override

        local is_ordered = false

        for _, v in ipairs(self.interactions_ordered) do
            if v == interaction then
                is_ordered = true
                break
            end
        end

        if is_ordered == false then
            table.insert(self.interactions_ordered, interaction)
        end
    end,

    update = function(self, delta_time)
        -- refresh ordering

        for _, v in ipairs(self.interactions) do
            if v.is_visible == false then
                table.insert(self.interactions_ordered, v) 
            end
        end

        self.interactions = self.interactions_ordered
        self.interactions_ordered = {}

        -- update transitions

        local cy = 0
        local lerp_factor = 0.02
        local fade_duration_millis = 250
        local text_char_duration_millis = 30

        local indices_remove = {}

        for i = 1, #self.interactions do
            local interaction = self.interactions[i]

            if interaction.text_prev ~= interaction.text then
                interaction.anim_factor_text = 0
            end

            interaction.text_prev = interaction.text
            interaction.order_index = -1

            if interaction.y == nil then
                interaction.y = cy
            else
                interaction.y = lerp(interaction.y, cy, 1 - math.exp(-lerp_factor * delta_time))
            end

            local text_anim_duration = #interaction.text * text_char_duration_millis

            if interaction.is_visible then
                interaction.is_visible = false

                if interaction.anim_factor < 1 then
                    interaction.anim_factor = math.min(interaction.anim_factor + delta_time / fade_duration_millis, 1)
                elseif interaction.anim_factor_text < 1 then
                    interaction.anim_factor_text = math.min(interaction.anim_factor_text + delta_time / text_anim_duration, 1)
                end
            else
                if interaction.anim_factor_text > 0 then
                    interaction.anim_factor_text = math.max(interaction.anim_factor_text - delta_time / text_anim_duration, 0)
                elseif interaction.anim_factor > 0 then
                    interaction.anim_factor = math.max(interaction.anim_factor - delta_time / fade_duration_millis, 0)
                else
                    table.insert(indices_remove, i)
                end
            end

            if interaction.anim_factor > 0 then
                cy = cy + 1
            end
        end

        for i = #indices_remove, 1, -1 do
            table.remove(self.interactions, indices_remove[i])
        end
    end,
}

g_subtitles = {
    text = "",
    text_pending = nil,
    anim_fade = 0,
    anim_word = 0,

    set_text = function(self, text)
        self.text_pending = text
    end,

    update = function(self, delta_time)
        local fade_duration_millis = 250
        local clear_duration_millis = 1500
        local word_fade_duration_millis = 250

        if self.text_pending == self.text then
            self.text_pending = nil
        end

        if self.text_pending == nil then
            if #self.text > 0 then
                self.anim_fade = 1
                self.anim_word = self.anim_word + delta_time / word_fade_duration_millis
            end
        elseif self.text_pending ~= self.text then
            self.anim_word = 1000
            
            if #self.text == 0 then
                self.anim_fade = 0
                self.anim_word = 0
                self.text = self.text_pending
                self.text_pending = nil
            else
                if self.anim_fade > 0 then
                    local fade_duration = iff(#self.text_pending > 0, fade_duration_millis, clear_duration_millis)
                    self.anim_fade = math.max(self.anim_fade - delta_time / fade_duration, 0)
                else
                    self.text = self.text_pending
                    self.anim_word = 0
                    self.text_pending = nil
                end
            end
        end
    end,
}

g_objectives = {
    objectives = {},
    sound_cooldown = 0,

    get_objective = function(self, id)
        for _, obj in ipairs(self.objectives) do
            if obj.id == id then return obj end
        end

        return nil
    end,

    add_objective = function(self, id, text, is_complete, progress, display_type)
        local objective = self:get_objective(id)

        if objective == nil and is_complete == false then
            objective = {
                id = id,
                text = text,
                is_complete = is_complete,
                is_visible = true,
                anim_text = 0,
                anim_fade = 0,
                anim_complete = 0,
                anim_detail = 0,
                progress = progress,
                display_type = display_type,
                state_change_factor = 1,
                is_trigger_complete_sound = false,
                x = nil,
                y = nil,
            }

            table.insert(self.objectives, objective)
        end

        if objective then
            objective.is_visible = true
            
            if is_complete == false then
                objective.text = text
                objective.progress = progress
                objective.display_type = display_type
                objective.is_trigger_complete_sound = false
            end
            
            if objective.is_complete ~= is_complete and is_complete then
                objective.is_trigger_complete_sound = true
            end

            objective.is_complete = is_complete
        end
    end,

    update = function(self, delta_time)
        if self.sound_cooldown > delta_time then
            self.sound_cooldown = self.sound_cooldown - delta_time
        else
            self.sound_cooldown = 0
        end

        local indices_remove = {}
        local fade_duration_millis = 200
        local text_char_duration_millis = 8
        local complete_duration = 1000
        local state_change_duration = 500
        local detail_duration_in = 500
        local detail_duration_out = 100
        local is_any_objective_changing_state = false

        for i = 1, #self.objectives do
            if self.objectives[i].is_complete then
                is_any_objective_changing_state = true
                break
            end
        end

        for i = 1, #self.objectives do
            local objective = self.objectives[i]
            local text_anim_duration = text_char_duration_millis * #objective.text
            local is_visible = objective.is_visible and objective.is_complete == false
            
            if is_visible then
                objective.anim_complete = 0

                if is_any_objective_changing_state == false then
                    if objective.anim_fade < 1 then
                        objective.anim_fade = math.min(objective.anim_fade + delta_time / fade_duration_millis, 1)
                    elseif objective.anim_text < 1 then
                        objective.anim_text = math.min(objective.anim_text + delta_time / text_anim_duration, 1)
                    elseif objective.state_change_factor > 0 then
                        objective.state_change_factor = math.max(objective.state_change_factor - delta_time / state_change_duration, 0)
                    elseif objective.anim_detail < 1 then
                        objective.anim_detail = math.min(objective.anim_detail + delta_time / detail_duration_in, 1)
                    end
                end
            else
                if objective.anim_detail > 0 then
                    objective.anim_detail = math.max(objective.anim_detail - delta_time / detail_duration_out, 0)
                end
                
                if objective.is_complete and objective.state_change_factor < 1 then
                    objective.state_change_factor = math.min(objective.state_change_factor + delta_time / state_change_duration, 1)
                elseif objective.is_complete and objective.anim_complete < 1 then
                    if self.sound_cooldown <= 0 and objective.is_trigger_complete_sound then
                        update_play_sound(e_audio_effect_type.telemetry_2_radar)
                        self.sound_cooldown = 500
                        objective.is_trigger_complete_sound = false
                    end 

                    objective.anim_complete = math.min(objective.anim_complete + delta_time / complete_duration, 1)
                elseif objective.anim_text > 0 then
                    objective.anim_text = math.max(objective.anim_text - delta_time / text_anim_duration, 0)
                elseif objective.anim_fade > 0 then
                    objective.anim_fade = math.max(objective.anim_fade - delta_time / fade_duration_millis, 0)
                else
                    table.insert(indices_remove, i)
                end
            end

            objective.is_visible = false
        end

        for i = #indices_remove, 1, -1 do
            table.remove(self.objectives, indices_remove[i])
        end
    end,
}

g_voice_chat = {
    peers = {},

    get_peer = function(self, id)
        for _, peer in ipairs(self.peers) do
            if peer.id == id then return peer end
        end

        return nil
    end,

    add_peer = function(self, id, name, is_transmitting)
        local peer = self:get_peer(id)

        if peer == nil and is_transmitting and #self.peers < 6 then
            peer = {
                id = id,
                name = name,
                is_transmitting = is_transmitting,
                cooldown = 0,
                anim_fade = 0,
                is_visible = true,
                y = nil,
            }

            table.insert(self.peers, peer)
        end

        if peer then
            peer.is_transmitting = is_transmitting
            peer.is_visible = true
            peer.cooldown = 0
        end
    end,

    update = function(self, delta_time)
        local indices_remove = {}
        local lerp_factor = 0.02
        local cooldown_duration = 2000

        for i = 1, #self.peers do
            local peer = self.peers[i]
            local is_visible = peer.is_visible
            
            if peer.y == nil then
                peer.y = i
            else
                peer.y = lerp(peer.y, i, 1 - math.exp(-lerp_factor * delta_time))
            end

            if is_visible then
                if peer.anim_fade < 1 then
                    peer.anim_fade = math.min(peer.anim_fade + delta_time / 100, 1)
                end
            else
                if peer.cooldown < cooldown_duration then
                    peer.cooldown = peer.cooldown + delta_time
                elseif peer.anim_fade > 0 then
                    peer.anim_fade = math.max(peer.anim_fade - delta_time / 100, 0)
                else
                    table.insert(indices_remove, i)
                end
            end

            peer.is_visible = false
        end

        for i = #indices_remove, 1, -1 do
            table.remove(self.peers, indices_remove[i])
        end
    end,
}

g_message_box = {
    is_visible = false,
    type = e_message_box_type.none,
    anim_fade = 0,
    anim_text = 0,
    anim_key = 0,
    anim_delay = 0,
    anim_appear = 0,
    input_cooldown = 0,
    text = "",
    title = "",
    title_col = color_white,

    update = function(self, delta_time)
        local type = update_get_message_box_type()
        is_visible = false

        if type ~= e_message_box_type.none then
            if self.type ~= type then
                self:set_type(type)
            end
            
            is_visible = true
        end

        if self.is_visible ~= is_visible then
            self.is_visible = is_visible

            if self.is_visible then
                self.is_good_ending = is_good_ending
                self.input_cooldown = 250
                self.anim_key = 0
                self.anim_text = 0
                self.anim_delay = 0
                self.anim_appear = 0
            end
        end

        local fade_in_duration_millis = 500
        local fade_out_duration_millis = 500
        local text_duration_millis = update_ui_get_text_size(self.text, 10000, 0) * 3
        local delay_duration_millis = 1000
        local appear_duration = 500
        local key_duration_millis = 500
        local is_block_input = false

        if self.is_visible then
            if self.anim_appear < 1 then
                self.anim_appear = math.min(self.anim_appear + delta_time / appear_duration, 1)
                is_block_input = true
            elseif self.anim_delay < 1 then
                self.anim_delay = math.min(self.anim_delay + delta_time / delay_duration_millis, 1)
                is_block_input = true
            elseif self.anim_fade < 1 then
                self.anim_fade = math.min(self.anim_fade + delta_time / fade_in_duration_millis, 1)
                is_block_input = true
            elseif self.anim_text < 1 then
                self.anim_text = math.min(self.anim_text + delta_time / text_duration_millis, 1)
                is_block_input = true
            elseif self.input_cooldown > 0 then
                self.input_cooldown = math.max(self.input_cooldown - delta_time, 0)
                is_block_input = true
            elseif self.anim_key < 1 then
                self.anim_key = math.min(self.anim_key + delta_time / key_duration_millis, 1)
            end
        else
            self.input_cooldown = 0
            self.anim_key = 1
            self.anim_text = 0

            if self.anim_fade > 0 then
                self.anim_fade = math.max(self.anim_fade - delta_time / fade_out_duration_millis, 0)
            elseif self.anim_appear > 0 then
                self.anim_appear = math.max(self.anim_appear - delta_time / appear_duration, 0)
            end
        end

        update_set_is_block_input(is_block_input)
    end,

    set_type = function(self, type)
        self.type = type
        self.text = "unknown message"
        self.title = "unknown message"
        self.title_col = color_white

        if type == e_message_box_type.tutorial_end_good then
            self.title = update_get_loc(e_loc.tut_complete_title)
            self.text = update_get_loc(e_loc.tut_complete_message_line_1) .. "\n\n" .. update_get_loc(e_loc.tut_complete_message_line_2) .. "\n\n" .. update_get_loc(e_loc.tut_complete_message_line_3)
            self.title_col = color_status_ok
        end
    end,
}

g_tooltip = {
    sx = 0,
    sy = 0,
    text = "",
    is_visible = false,
    anim_factor = 0,
}

g_is_render_crosshair = false
g_crosshair_color = color_white
g_is_transmitting_voice = false
g_voice_anim_factor = 0
g_time_since_voice = 5000
g_screen_border = 5
g_animation_time = 0

g_back_width = 0
g_back_height = 0

g_ui_scale = 1

function begin()
    begin_load()
end

function update(screen_w, screen_h, delta_time)
    g_animation_time = g_animation_time + delta_time

    g_interactions:update(delta_time)
    g_subtitles:update(delta_time)
    g_objectives:update(delta_time)
    g_voice_chat:update(delta_time)
    g_message_box:update(delta_time)

    g_ui_scale = update_get_ui_scale()

    local ui_screen_w = screen_w / g_ui_scale
    local ui_screen_h = screen_h / g_ui_scale

    update_ui_push_scale(g_ui_scale)

    if update_get_is_show_controls() then
        render_interactions(ui_screen_w, ui_screen_h, delta_time)
    end

    if update_get_is_show_subtitles() then
        render_subtitles(ui_screen_w, ui_screen_h, delta_time)
    end

    render_voice_chat(ui_screen_w, ui_screen_h, delta_time)
    render_objectives(ui_screen_w, ui_screen_h, delta_time)
    update_ui_pop_scale()

    if update_get_is_show_tooltips() then
        render_tooltip(screen_w, screen_h, delta_time)
    end

    if g_is_render_crosshair and g_message_box.is_visible == false then
        render_crosshair(screen_w, screen_h)
    end

    update_ui_push_scale(g_ui_scale)
    render_message_box(ui_screen_w, ui_screen_h, delta_time)
    update_ui_pop_scale()

    -- test_voice_chat(delta_time)
    -- test_objectives(delta_time)
    -- test_subtitles(delta_time)
end

function test_voice_chat(delta_time)
    g_time_voice_chat = (g_time_voice_chat or 0) + delta_time
    local time = g_time_voice_chat % 16000

    g_voice_chat_test_xmit1 = iff(g_voice_chat_test_xmit1 == nil, true, g_voice_chat_test_xmit1)
    g_voice_chat_test_xmit2 = iff(g_voice_chat_test_xmit2 == nil, true, g_voice_chat_test_xmit2)
    g_voice_chat_test_xmit3 = iff(g_voice_chat_test_xmit3 == nil, true, g_voice_chat_test_xmit3)

    if math.floor(time) % 10 == 0 and math.random(0, 1) == 0 then g_voice_chat_test_xmit1 = not g_voice_chat_test_xmit1 end
    if math.floor(time) % 25 == 0 and math.random(0, 1) == 0 then g_voice_chat_test_xmit2 = not g_voice_chat_test_xmit2 end
    if math.floor(time) % 50 == 0 and math.random(0, 1) == 0 then g_voice_chat_test_xmit3 = not g_voice_chat_test_xmit3 end

    if time < 5000 then
        g_voice_chat:add_peer(1, "peername2withalongname", g_voice_chat_test_xmit1)
    elseif time < 10000 then
        g_voice_chat:add_peer(1, "peername2withalongname", g_voice_chat_test_xmit3)
        g_voice_chat:add_peer(2, "PEERNAME2", g_voice_chat_test_xmit1)
    elseif time < 12000 then
        g_voice_chat:add_peer(3, "peername3", g_voice_chat_test_xmit2)
        g_voice_chat:add_peer(2, "PEERNAME2", g_voice_chat_test_xmit3)
        g_voice_chat:add_peer(4, "AnotherPeer", g_voice_chat_test_xmit1)
    elseif time < 15000 then
        g_voice_chat:add_peer(3, "peername3", g_voice_chat_test_xmit1)
        g_voice_chat:add_peer(5, "peer 5", g_voice_chat_test_xmit2)
    end
end

function test_objectives(delta_time)
    g_time_objectives = (g_time_objectives or 0) + delta_time
    local time = g_time_objectives % 20000

    if time < 5000 then
        g_objectives:add_objective(0, "get in vehicle control seat and then use vehicle button", false, -1, 0)
        g_objectives:add_objective(1, "open pause menu", false, -1, 2)
    elseif time < 10000 then
        g_objectives:add_objective(0, "get in vehicle control seat and then use vehicle button", true, -1, 0)
        g_objectives:add_objective(1, "open pause menu", false, -1, 2)
    elseif time < 18000 then
        g_objectives:add_objective(2, "capture enemy island using seal and virus bots", false, -1, 1)
        g_objectives:add_objective(1, "open pause menu", true, -1, 2)
    else
        g_objectives:add_objective(2, "capture enemy island using seal and virus bots", true, -1, 1)
    end
end

function test_subtitles(delta_time)
    g_time_subtitles = (g_time_subtitles or 0) + delta_time
    local time = g_time_subtitles % 12000

    if time < 5000 then
        g_subtitles:set_text("Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do eiusmod")
    elseif time < 10000 then
        g_subtitles:set_text("tempor incididunt ut labore et dolore magna aliqua")
    else
        g_subtitles:set_text("")
    end
end

function on_add_interaction(text, input, special)
    if update_get_message_box_type() == e_message_box_type.none then
        if get_is_special_interaction_type_multiline(special) then
            -- split interactions with multiline formatting into separate interactions;
            -- first split by line breaks, then ensure lines don't exceed max length

            local max_line_length = 160
            local lines = get_text_lines(text)
            local lines_clipped = {}
            
            for i = 1, #lines do
                local line = lines[i]
                local words = get_words_from_string(line)
                local built_line = ""

                for j = 1, #words do
                    local built_line_temp = built_line

                    if built_line_temp == "" then 
                        built_line_temp = words[j]
                    else 
                        built_line_temp = built_line_temp .. " " .. words[j]
                    end

                    if update_ui_get_text_size(built_line_temp, 10000, 0) > max_line_length then
                        if #built_line > 0 and update_ui_get_text_size(built_line, 10000, 0) <= max_line_length then
                            table.insert(lines_clipped, built_line)
                        end

                        local word = words[j]

                        while update_ui_get_text_size(word, 10000, 0) > max_line_length do
                            local word_length = utf8.len(word)
                            local char_offset = utf8.offset(word, 0, math.min(max_line_length, word_length - 1))
                            local clipped_word = string.sub(word, 0, char_offset - 1)
                            table.insert(lines_clipped, clipped_word)
                            word = string.sub(word, utf8.offset(word, 0, char_offset))
                        end

                        built_line = word
                    else
                        built_line = built_line_temp
                    end
                end

                if #built_line > 0 then
                    table.insert(lines_clipped, built_line)
                end
            end

            local index = 0

            for i = #lines_clipped, 1, -1 do
                g_interactions:add_interaction(lines_clipped[i], input, special, index)
                index = index + 1
            end
        else
            g_interactions:add_interaction(text, input, special)
        end
    end
end

function on_set_subtitle(text)
    g_subtitles:set_text(text)
end

function on_add_objective(id, text, is_complete, progress, display_type)
    if update_get_message_box_type() == e_message_box_type.none then
        g_objectives:add_objective(id, text, is_complete, progress, display_type)
    end
end

function on_add_peer_voice_transmit(peer_id, peer_name, is_transmitting)
    g_voice_chat:add_peer(peer_id, peer_name, is_transmitting)
end

function on_set_highlighted_object(text, sx, sy)
    if #text > 0 then
        if text ~= g_tooltip.text then
            g_tooltip.anim_text = 0
        end

        g_tooltip.text = text
        g_tooltip.sx = sx
        g_tooltip.sy = sy
        g_tooltip.is_visible = true
    end
end

function on_set_is_render_crosshair(is_render, col)
    g_is_render_crosshair = is_render
    g_crosshair_color = col
end


--------------------------------------------------------------------------------
--
-- CROSSHAIR
--
--------------------------------------------------------------------------------

function render_crosshair(screen_w, screen_h)
    local cx = math.floor(screen_w / 2)
    local cy = math.floor(screen_h / 2)
    local icon_w, icon_h = update_ui_get_image_size(atlas_icons.crosshair)

    update_ui_push_alpha(200)
    update_ui_image(cx - math.floor(icon_w / 2), cy - math.floor(icon_h / 2), atlas_icons.crosshair, g_crosshair_color, 0)
    update_ui_pop_alpha()
end


--------------------------------------------------------------------------------
--
-- INTERACTION CONTROLS UI
--
--------------------------------------------------------------------------------

function render_interactions(screen_w, screen_h, delta_time)
    update_ui_push_offset(g_screen_border, screen_h - g_screen_border)
    
    g_time = g_time or 0
    g_time = g_time + delta_time

    update_ui_rectangle(0, -math.floor(g_back_height + 0.5), math.floor(g_back_width + 0.5), math.floor(g_back_height + 0.5), color_black)

    local border = 5
    local spacing = 2

    local target_back_width = 0
    local target_back_height = 0

    for k, v in ipairs(g_interactions.interactions) do
        local cy = math.floor(border + v.y * (10 + spacing) + 0.5)
        local cx = border
        local display_text = clip_string(v.text, v.anim_factor_text, true)
        
        local icon_data = get_input_icons(v.input, v.special_override or v.special)
        
        update_ui_push_alpha(math.floor(255 * v.anim_factor))
        local icon_w = render_interaction_icon_data(cx, -cy - 10, icon_data, display_text, color_white)
        update_ui_pop_alpha()

        target_back_width = math.max(target_back_width, cx + border + icon_w)
        target_back_height = math.max(target_back_height, cy + 10 + border)
    end

    if target_back_width == 0 then
        target_back_width = g_back_width
    end

    g_back_width = target_back_width
    g_back_height = lerp(g_back_height, target_back_height, 1 - math.exp(-0.05 * delta_time))

    update_ui_pop_offset()
end

function render_interaction_icon_data(x, y, icon_data, display_text, text_col)
    local color_shadow = color8(0, 0, 0, 200)

    update_ui_push_offset(x, y)
    local cx = 0
    local cy = 0

    if #icon_data > 0 then
        for i = 1, #icon_data do
            local icon = icon_data[i]
            local icon_col = icon.icon_col or color_white

            if icon.text_col then
                text_col = icon.text_col
            end

            if icon.delim then
                update_ui_text(cx + 2, cy + 1, icon.delim, 10, 0, color_shadow, 0)
                update_ui_text(cx + 1, cy + 0, icon.delim, 10, 0, color_grey_dark, 0)
                cx = cx + 7
            elseif icon.icon then
                if icon_col ~= color_empty then
                    update_ui_image(cx + 1, cy + 1, icon.icon, color_shadow, 0)
                    update_ui_image(cx, cy + 0, icon.icon, icon_col, 0)
                end
                
                cx = cx + (icon.icon_w or 10)
            elseif icon.text then
                imgui_render_key_icon(cx + 1, cy + 1, icon.text, false, color_black)
                cx = cx + imgui_render_key_icon(cx, cy + 0, icon.text)
            end
        end

        if #display_text > 0 then
            cx = cx + 5
            update_ui_text(cx + 1, cy + 1, display_text, 400, 0, color_shadow, 0)
            update_ui_text(cx, cy + 0, display_text, 400, 0, text_col, 0)
            cx = cx + update_ui_get_text_size(display_text, 10000, 0)
        end
    end

    update_ui_pop_offset()

    return cx, cy
end

function get_is_input_valid(game_input, special_input)
    local icons = get_input_icons(game_input, special_input)
    return #icons > 0
end

function get_input_icons(game_input, special_input)
    local icon_datas = {}
    local display_inputs = get_display_inputs(game_input, special_input)

    local display_input_prev = {}

    for _, v in ipairs(display_inputs) do
        local icon_data = nil
        
        if v.input and v.input < e_game_input.count then
            icon_data = get_game_input_icon(v.input)
        elseif v.special and v.special < e_ui_interaction_special.count then
            icon_data = get_special_input_icon(v.special)
        end

        if icon_data ~= nil then
            if #icon_datas > 0 then
                if special_input == e_ui_interaction_special.map_drag and update_get_active_input_type() == e_active_input.gamepad then
                    table.insert(icon_datas, { delim = "+"} )
                elseif v.input == e_game_input.select_attachment_9 and display_input_prev.input == e_game_input.select_attachment_1 then
                    table.insert(icon_datas, { delim = "-"} )
                else
                    table.insert(icon_datas, { delim = "/" })
                end
            end

            table.insert(icon_datas, icon_data)
        end

        display_input_prev = v
    end

    return icon_datas
end

function get_special_input_icon(special_input)
    local color_info = color8(32, 32, 32, 255)
    local color_info_desc = color8(5, 5, 5, 255)

    local icons_gamepad = {
        [e_ui_interaction_special.gamepad_dpad_all] = { icon = atlas_icons.gamepad_icon_special_dpad_all },
        [e_ui_interaction_special.gamepad_dpad_ud] = { icon = atlas_icons.gamepad_icon_special_dpad_ud },
        [e_ui_interaction_special.gamepad_dpad_lr] = { icon = atlas_icons.gamepad_icon_special_dpad_lr },
        [e_ui_interaction_special.map_pan] = { icon = atlas_icons.gamepad_icon_special_ls },
        [e_ui_interaction_special.map_zoom] = { icon = atlas_icons.gamepad_icon_special_rs_ud },
        [e_ui_interaction_special.info] = { icon = atlas_icons.column_pending, icon_col = color_empty, icon_w = -5, text_col = color_info },
        [e_ui_interaction_special.info_desc] = { icon = atlas_icons.column_pending, icon_col = color_empty, icon_w = -5, text_col = color_info_desc },
        [e_ui_interaction_special.air_yaw] = { icon = atlas_icons.gamepad_icon_special_rs_lr },
        [e_ui_interaction_special.air_pitch] = { icon = atlas_icons.gamepad_icon_special_ls_ud },
        [e_ui_interaction_special.air_roll] = { icon = atlas_icons.gamepad_icon_special_ls_lr },
        [e_ui_interaction_special.air_throttle] = { icon = atlas_icons.gamepad_icon_special_rs_ud },
        [e_ui_interaction_special.vehicle_zoom] = { icon = atlas_icons.gamepad_icon_special_ls_ud },
        [e_ui_interaction_special.land_steer] = { icon = atlas_icons.gamepad_icon_special_ls_lr },
        [e_ui_interaction_special.land_throttle] = { icon = atlas_icons.gamepad_icon_special_ls_ud },
        [e_ui_interaction_special.gamepad_scroll] = { icon = atlas_icons.gamepad_icon_special_rs_ud },
        [e_ui_interaction_special.cancel_rebind] = { icon = atlas_icons.gamepad_icon_start },
        [e_ui_interaction_special.map_drag] = { icon = atlas_icons.gamepad_icon_special_ls },
    }

    local icons_keyboard = {
        [e_ui_interaction_special.mouse_wheel] = { icon = atlas_icons.mouse_icon_special_scroll },
        [e_ui_interaction_special.map_pan] = { icon = atlas_icons.mouse_icon_special_drag },
        [e_ui_interaction_special.map_zoom] = { icon = atlas_icons.mouse_icon_special_scroll },
        [e_ui_interaction_special.info] = { icon = atlas_icons.column_pending, icon_col = color_empty, icon_w = -5, text_col = color_info },
        [e_ui_interaction_special.info_desc] = { icon = atlas_icons.column_pending, icon_col = color_empty, icon_w = -5, text_col = color_info_desc },
        [e_ui_interaction_special.vehicle_zoom] = { icon = atlas_icons.mouse_icon_special_scroll },
        [e_ui_interaction_special.cancel_rebind] = { text = update_get_key_name(259) },
        [e_ui_interaction_special.map_drag] = { icon = atlas_icons.mouse_icon_special_drag },
    }

    if update_get_active_input_type() == e_active_input.gamepad then
        if icons_gamepad[special_input] ~= nil then
            return icons_gamepad[special_input]
        end
    else
        if icons_keyboard[special_input] ~= nil then
            return icons_keyboard[special_input]
        end
    end

    return nil
end

function get_game_input_icon(game_input)
    if update_get_active_input_type() == e_active_input.gamepad then
        local button, axis = get_bindings_gamepad(game_input)

        if button ~= -1 then
            local icon, icon_col = get_gamepad_button_icon(button)
            return { icon = icon, icon_col = icon_col }
        elseif axis ~= -1 then
            local icon, icon_col = get_gamepad_axis_icon(axis)
            return { icon = icon, icon_col = icon_col }
        end
    else
        local key, pointer = get_bindings_keyboard(game_input)

        if key ~= -1 then
            return { text = update_get_key_name(key) }
        elseif pointer ~= -1 then
            local icon, icon_col = get_pointer_icon(pointer)
            return { icon = icon, icon_col = icon_col }
        end
    end

    return nil
end

function get_display_inputs(game_input, special_input)
    if update_get_active_input_type() == e_active_input.gamepad then
        if game_input == e_game_input.interact_a then
            return { { input = e_game_input.interact_a }, { input = e_game_input.interact_a_alt } }
        elseif game_input == e_game_input.select_attachment_next or game_input == e_game_input.select_attachment_prev then
            return { { input = e_game_input.select_attachment_next}, { input = e_game_input.select_attachment_prev } }
        elseif special_input == e_ui_interaction_special.pause then
            return { { input = e_game_input.pause} }
        elseif special_input == e_ui_interaction_special.map_drag then
            return { { special = e_ui_interaction_special.map_drag }, { input = e_game_input.interact_a} }
        end
    else
        if game_input == e_game_input.interact_a then
            return { { input = e_game_input.interact_a }, { input = e_game_input.interact_a_alt } }
        elseif game_input == e_game_input.select_attachment_next then
            return { { input = e_game_input.select_attachment_next}, { input = e_game_input.select_attachment_prev } }
        elseif game_input == e_game_input.select_attachment_1 then
            return { { input = e_game_input.select_attachment_1}, { input = e_game_input.select_attachment_9 } }
        elseif special_input == e_ui_interaction_special.map_zoom then
            return { { special = e_ui_interaction_special.map_zoom }, { input = e_game_input.look_up }, { input = e_game_input.look_down } }
        elseif special_input == e_ui_interaction_special.map_pan then
            return { { special = e_ui_interaction_special.map_pan }, { input = e_game_input.dpad_up }, { input = e_game_input.dpad_left }, { input = e_game_input.dpad_down }, { input = e_game_input.dpad_right } }
        elseif special_input == e_ui_interaction_special.air_yaw then
            return { { input = e_game_input.look_left }, { input = e_game_input.look_right } }
        elseif special_input == e_ui_interaction_special.air_pitch then
            return { { input = e_game_input.move_up }, { input = e_game_input.move_down } }
        elseif special_input == e_ui_interaction_special.air_roll then
            return { { input = e_game_input.move_left }, { input = e_game_input.move_right } }
        elseif special_input == e_ui_interaction_special.air_throttle then
            return { { input = e_game_input.look_up }, { input = e_game_input.look_down } }
        elseif special_input == e_ui_interaction_special.vehicle_zoom then
            return { { special = e_ui_interaction_special.vehicle_zoom }, { input = e_game_input.move_up }, { input = e_game_input.move_down } }
        elseif special_input == e_ui_interaction_special.land_steer then
            return { { input = e_game_input.move_left }, { input = e_game_input.move_right } }
        elseif special_input == e_ui_interaction_special.land_throttle then
            return { { input = e_game_input.move_up }, { input = e_game_input.move_down } }
        elseif special_input == e_ui_interaction_special.pause then
            return iff(update_get_keyboard_back_opens_pause(), { { input = e_game_input.pause}, { input = e_game_input.back } }, { { input = e_game_input.pause } })
        end
    end

    return { { input = game_input, special = special_input } }
end


--------------------------------------------------------------------------------
--
-- VOICE CHAT ICON
--
--------------------------------------------------------------------------------

function render_voice_chat(screen_w, screen_h, delta_time)
    -- player voice chat icon
    
    if g_is_transmitting_voice then
        g_time_since_voice = 0
    else
        g_time_since_voice = g_time_since_voice + delta_time
    end

    if g_time_since_voice > 3000 then
        g_voice_anim_factor = math.max(g_voice_anim_factor - delta_time / 100, 0)
    else
        g_voice_anim_factor = math.min(g_voice_anim_factor + delta_time / 100, 1)
    end

    local border = 2
    local screen_border = g_screen_border
    local bg_size = 16 + 2 * border

    if g_voice_anim_factor > 0 then
        if update_get_is_show_voice_chat_self() then
            update_ui_push_offset(screen_w - screen_border - bg_size, screen_h - screen_border - bg_size)
            update_ui_push_clip(0, 0, bg_size, math.floor(bg_size * g_voice_anim_factor + 0.5))
            update_ui_rectangle(0, 0, bg_size, bg_size, color_black)
            update_ui_image(border, border, atlas_icons.hud_audio, iff(g_is_transmitting_voice, color_status_ok, color_grey_dark), 0)
            update_ui_pop_clip()
            update_ui_pop_offset()
        end
    end

    -- other players' voice chat icons

    if update_get_is_show_voice_chat_others() then
        local max_text_chars = 12
        update_ui_push_offset(screen_w - screen_border, screen_border + border)

        for _, peer in ipairs(g_voice_chat.peers) do
            local display_name = peer.name
            local is_clipped = false

            if utf8.len(display_name) > max_text_chars then
                display_name = display_name:sub(1, utf8.offset(display_name, max_text_chars) - 1)
                is_clipped = true
            end

            local text_render_w, text_render_h = update_ui_get_text_size(display_name, 10000, 0)

            local ellipsis_w = 6
            local spacing = 4
            local audio_icon_w = 9
            local total_w = audio_icon_w + spacing + text_render_w + iff(is_clipped, ellipsis_w, 0) + 2 * border
            local cy = (peer.y - 1) * (10 + 2 * border)
            local cx = -total_w + border

            update_ui_push_clip(math.floor(cx - border), math.floor(cy - border), total_w, math.floor((10 + 2 * border) * peer.anim_fade + 0.5))
            update_ui_rectangle(cx - border, cy - border, total_w, 10 + 2 * border, color_black)

            update_ui_image(cx, cy, atlas_icons.hud_audio_small, iff(peer.is_transmitting and peer.cooldown == 0, color_status_ok, color_grey_dark), 0)
            update_ui_text(cx + audio_icon_w + spacing, cy, display_name, 10000, 0, color_white, 0)

            if is_clipped then
                update_ui_image(-ellipsis_w - border, cy, atlas_icons.text_ellipsis, color_white, 0)
            end
            
            update_ui_pop_clip()
        end

        update_ui_pop_offset()
    end
end

--------------------------------------------------------------------------------
--
-- TUTORIAL OBJECTIVE UI
--
--------------------------------------------------------------------------------

function render_objectives(screen_w, screen_h, delta_time)
    local cy_top_left = g_screen_border
    local cy_center = screen_h / 2 + 10

    local function lerp_snap(a, b, c)
        local min_step = 1
        delta = math.abs((b - a) * c)
        
        if delta < min_step then
            delta = min_step
        end
        
        return a + clamp(b - a, -delta, delta)
    end

    for _, obj in ipairs(g_objectives.objectives) do
        local display_text = clip_string(obj.text, obj.anim_text, true)
        local full_text_w, full_text_h = update_ui_get_text_size(obj.text, 200, 0)
        local text_w, text_h = update_ui_get_text_size(display_text, 200, 0)
        text_h = math.max(text_h, 10)

        local is_center = obj.state_change_factor > 0
        local target_x = g_screen_border
        local target_y = cy_top_left

        if is_center then
            target_x = (screen_w - full_text_w) / 2 - 8
            target_y = cy_center
        end

        if obj.x == nil then
            obj.x = target_x
        else
            obj.x = lerp_snap(obj.x, target_x, 0.15)
        end

        if obj.y == nil then
            obj.y = target_y
        else
            obj.y = lerp_snap(obj.y, target_y, 0.15)
        end

        update_ui_push_offset(math.floor(obj.x), math.floor(obj.y))
        update_ui_push_alpha(math.floor(255 * obj.anim_fade))
        
        local cy = 0
        local bg_height = text_h + 4
        local bg_width = text_w + 20

        if obj.is_complete and obj.anim_complete < 0.8 and obj.state_change_factor > 0.9 then
            if math.floor(obj.anim_complete * 1000) % 200 < 100 then
                update_ui_rectangle(0, cy, bg_width, bg_height, color_status_ok)    
            end
        else
            update_ui_rectangle(0, cy, bg_width, bg_height, color_black)    
        end

        cy = cy + 2
        update_ui_rectangle_outline(2, cy, 10, 10, color_grey_mid)

        if obj.is_complete then
            update_ui_rectangle(4, cy + 2, 6, 6, color_status_ok)
        end

        update_ui_text(18, cy + 1, display_text, 200, 0, color_black, 0)
        update_ui_text(17, cy, display_text, 200, 0, iff(obj.is_complete and obj.anim_complete > 0.8, color_grey_dark, color_white), 0)
        cy = cy + text_h

        local display_w, display_h = get_objective_display_size(obj)

        if display_h > 0 then
            if display_w < 0 then display_w = text_w end
            local bg_w = display_w + 20

            update_ui_push_clip(0, cy + 2, 10000, math.ceil((display_h + 4) * obj.anim_detail))
            update_ui_rectangle(0, cy + 2, bg_w, display_h + 4, color_black)
            update_ui_push_offset(17, cy + 4)
            render_objective_extra_detail(obj, display_w, display_h)
            update_ui_pop_offset()
            update_ui_pop_clip()

            cy = cy + math.floor((display_h + 2) * obj.anim_detail)
        end

        update_ui_pop_alpha()
        update_ui_pop_offset()

        cy = cy + 4

        if is_center then
            cy_center = cy_center + cy
        else
            cy_top_left = cy_top_left + cy
        end
    end
end

function render_objective_extra_detail(obj, w, h)
    local cy = 0

    if obj.progress >= 0 and obj.is_complete == false then
        update_ui_rectangle(0, cy, w, 2, color_grey_dark)
        update_ui_rectangle(0, cy, math.floor(w * obj.progress + 0.5), 2, color_status_ok)
        cy = cy + 2
    end

    if obj.display_type == e_objective_display_type.capture_island then
        update_ui_image(4, cy, atlas_icons.map_icon_surface, color_friendly, 0)
        update_ui_text(18, cy, update_get_loc(e_loc.upp_seal), 200, 0, color_grey_mid, 0)
        cy = cy + 12

        update_ui_image(0, cy, atlas_icons.icon_attachment_16_turret_robots, color_white, 0)
        update_ui_text(18, cy + 4, update_get_loc(e_loc.upp_control_bots), 200, 0, color_grey_mid, 0)
        cy = cy + 16
    elseif obj.display_type == e_objective_display_type.open_pause_menu then
        local icon_data = get_input_icons(-1, e_ui_interaction_special.pause)
        render_interaction_icon_data(0, cy, icon_data, update_get_loc(e_loc.interaction_pause), color_grey_mid)
    end
end

function get_objective_display_size(obj)
    local width = -1
    local height = 0

    if obj.progress >= 0 and obj.is_complete == false then
        height = height + 2
    end

    if obj.display_type == e_objective_display_type.capture_island then
        width = 80
        height = height + 28
    elseif obj.display_type == e_objective_display_type.open_pause_menu then
        height = height + 10
    end

    return width, height
end

--------------------------------------------------------------------------------
--
-- SUBTITLES
--
--------------------------------------------------------------------------------

function render_subtitles(screen_w, screen_h, delta_time)
    update_ui_push_alpha(math.floor(255 * g_subtitles.anim_fade))
    
    local margin = 128
    local text_w = math.floor((screen_w - margin * 2) / 2) * 2
    text_w = math.max(text_w, 256)

    local words = get_words_from_string(g_subtitles.text)
    local display_text = ""

    local word_fade_count = 4
    local word_fade_start = math.floor(g_subtitles.anim_word) - word_fade_count
    local word_fade_end = word_fade_start + word_fade_count
    local current_color_index = -1

    for i = 1, #words do
        if i > 1 then
            display_text = display_text .. " "
        end

        local word_index = i - 1
        local color_index = -1

        if word_index < word_fade_start then
            color_index = -1
        elseif word_index < word_fade_end then
            color_index = word_index - word_fade_start + 1
        else
            color_index = 0
        end

        if color_index ~= current_color_index then
            current_color_index = color_index
            display_text = display_text .. "$[" .. color_index .. "]"
        end

        display_text = display_text .. words[i]
    end
    
    local text_render_w, text_render_h = update_ui_get_text_size(display_text, text_w, 1)
    update_ui_set_text_color(0, color8(0, 0, 0, 0))

    -- render shadow

    for i = 1, word_fade_count do
        local alpha = clamp((g_subtitles.anim_word - (i + word_fade_start)) / word_fade_count, 0, 1)
        update_ui_set_text_color(i, color8(0, 0, 0, math.floor(alpha * 255)))
    end

    update_ui_text((screen_w - text_w) / 2 + 1, screen_h - g_screen_border - text_render_h + 1, display_text, text_w, 1, color_black, 0)

    -- render text

    for i = 1, word_fade_count do
        local alpha = clamp((g_subtitles.anim_word - (i + word_fade_start)) / word_fade_count, 0, 1)
        update_ui_set_text_color(i, color8(255, 255, 255, math.floor(alpha * 255)))
    end
    
    update_ui_text((screen_w - text_w) / 2, screen_h - g_screen_border - text_render_h, display_text, text_w, 1, color_white, 0)

    update_ui_pop_alpha()
end

function get_words_from_string(str)
    local words = {}

    for match in string.gmatch(str, "([^%s]+)") do
        table.insert(words, match)
    end

    return words
end

--------------------------------------------------------------------------------
--
-- INTERACTION CONTROLS UI
--
--------------------------------------------------------------------------------

function render_message_box(screen_w, screen_h, delta_time)
    local w = 320
    local text_render_w, text_render_h = update_ui_get_text_size(g_message_box.text, w - 10, 0)
    local h = text_render_h + 30 + 25

    if g_message_box.anim_appear > 0 then
        local bg_height = math.ceil(lerp(25, h, g_message_box.anim_fade))
        local bg_width = math.ceil(lerp(0, w, g_message_box.anim_appear ^ 2))

        update_ui_push_offset((screen_w - w) / 2, (screen_h - bg_height) / 2)
        update_ui_push_clip((w - bg_width) / 2, 0, bg_width, bg_height)
        update_ui_rectangle(0, 0, w, h, color_black)

        update_ui_set_text_color(0, color_white)
        update_ui_set_text_color(1, color8(255, 10, 10, 255))
        update_ui_set_text_color(2, color8(20, 50, 255, 255))
        update_ui_set_text_color(3, color8(255, 128, 0, 255))

        update_ui_text_scale(0, 5, g_message_box.title, w, 1, g_message_box.title_col, 0, 2)
        
        update_ui_push_clip(0, 28, w, math.ceil((text_render_h + 2) * g_message_box.anim_text))
        update_ui_text(5, 30, g_message_box.text, w - 10, 0, color_white, 0)
        update_ui_pop_clip()

        if g_message_box.anim_key > 0 then
            local display_text = clip_string(update_get_loc(e_loc.upp_press_any_key), g_message_box.anim_key, true)

            if g_message_box.anim_key < 1 or math.floor(g_animation_time) % 500 < 250 then
                update_ui_text(0, h - 12, display_text, w, 1, color_status_ok, 0)
            else
                update_ui_text(0, h - 12, display_text, w, 1, color_white, 0)
            end
        end

        update_ui_pop_clip()
        update_ui_pop_offset()
    end
end

--------------------------------------------------------------------------------
--
-- INTERACTION CONTROLS UI
--
--------------------------------------------------------------------------------

function render_tooltip(screen_w, screen_h, delta_time)
    if g_tooltip.is_visible then
        local anim_duration = 250

        if g_tooltip.anim_factor < 1 then
            g_tooltip.anim_factor = math.min(g_tooltip.anim_factor + delta_time / anim_duration, 1)
        end
    else
        g_tooltip.anim_factor = 0
    end

    if g_tooltip.is_visible then
        local aspect = screen_w / screen_h
        local sx = math.floor(remap(g_tooltip.sx, -aspect, aspect, 0, screen_w) + 0.5)
        local sy = math.floor(remap(g_tooltip.sy, 1, -1, 0, screen_h) + 0.5)
        local display_text = g_tooltip.text

        local scale = g_ui_scale
        local border = 3 * scale
        local text_h = 10 * scale
        local bg_width = update_ui_get_text_size(display_text, 10000, 1) * scale + border * 2
        local bg_height = text_h + border * 2
        local arrow_w = 6 * scale
        local arrow_h = 4 * scale
        local bg_col = color8(0, 0, 0, 255)
        local arrow_col = bg_col
        local text_col = color_white
        local offset = 20
        local arrow_edge = -1

        update_ui_push_alpha(math.floor(g_tooltip.anim_factor * 255))

        if arrow_edge > 0 then
            update_ui_push_offset(sx - bg_width / 2, sy + offset)
            update_ui_begin_triangles()
            update_ui_add_triangle(vec2(bg_width / 2, 0), vec2(bg_width / 2 - arrow_w / 2, arrow_h), vec2(bg_width / 2 + arrow_w / 2, arrow_h), arrow_col)
            update_ui_end_triangles()
            update_ui_push_offset(0, arrow_h)
        else
            update_ui_push_offset(sx - bg_width / 2, sy - offset)
            update_ui_begin_triangles()
            update_ui_add_triangle(vec2(bg_width / 2, 0), vec2(bg_width / 2 + arrow_w / 2, -arrow_h), vec2(bg_width / 2 - arrow_w / 2, -arrow_h), arrow_col)
            update_ui_end_triangles()
            update_ui_push_offset(0, -arrow_h - bg_height)
        end
        
        update_ui_rectangle(0, 0, bg_width, bg_height, bg_col)
        update_ui_text_scale(scale, border + scale, display_text, bg_width, 1, color_black, 0, scale)
        update_ui_text_scale(0, border, display_text, bg_width, 1, text_col, 0, scale)

        update_ui_pop_offset()
        update_ui_pop_offset()

        update_ui_pop_alpha()
    end

    g_tooltip.is_visible = false
end

--------------------------------------------------------------------------------
--
-- UTILITY FUNCTIONS
--
--------------------------------------------------------------------------------

function clip_string(str, factor, is_randomise_last_char)

    local clip_index = math.floor(utf8.len(str) * factor + 0.5)
    clip_index = utf8.offset(str, clip_index + 1) - 1

    local substr = str:sub(1, clip_index)

    if is_randomise_last_char then
        local chars = { "%", "$", "#", "&", "@", "|" }
        local rand_char = chars[math.random(1, #chars)]

        if utf8.len(substr) > 0 and factor < 1 then
            substr = str:sub(1, utf8.offset(substr, -1) - 1) .. rand_char
        end
    end

    return substr
end

function get_text_lines(str)
    local lines = {}

    for s in str:gmatch("[^\r\n]+") do
        table.insert(lines, s)
    end

    return lines
end

function get_bindings_gamepad(game_input)
    return update_get_input_binding_gamepad_button(game_input), update_get_input_binding_gamepad_axis(game_input)
end

function get_bindings_keyboard(game_input)
    return update_get_input_binding_keyboard_key(game_input), update_get_input_binding_keyboard_pointer(game_input)
end

function get_is_special_interaction_type_multiline(special)
    return special == e_ui_interaction_special.info
        or special == e_ui_interaction_special.info_desc
end