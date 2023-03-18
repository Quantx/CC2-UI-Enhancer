lib_imgui = {
    create_ui = function(self)
        local o = {}
        setmetatable(o, self)
        self.__index = self

        o.windows = {}
        o.window_stack = {}
        o.region_stack = {}
        o.delta_time = 1
        o.mouse_x = 0
        o.mouse_y = 0
        o.is_mouse_hovered = false
        o.animation_timer = 0
        o.window_col_active = color_white
        o.window_col_inactive = color_grey_dark

        o.is_select_next = false
        o.is_select_prev = false
        o.input_left = false
        o.input_right = false
        o.input_action = false
        o.input_pointer_1 = false
        o.input_text_enter = false
        o.input_text_backspace = false
        o.input_text_space = false
        o.input_text_shift = false
        
        o.is_select_next_held = false
        o.is_select_prev_held = false
        o.input_left_held = false
        o.input_right_held = false
        o.input_action_held = false
        o.input_pointer_1_held = false
        o.input_text_enter_held = false
        o.input_text_backspace_held = false
        o.input_text_space_held = false
        o.input_text_shift_held = false
        
        o.is_select_next_repeat = false
        o.is_select_next_repeat_time = 0
        o.is_select_prev_repeat = false
        o.is_select_prev_repeat_time = 0
        o.input_left_repeat = false
        o.input_left_repeat_time = 0
        o.input_right_repeat = false
        o.input_right_repeat_time = 0
        o.input_action_repeat = false
        o.input_action_repeat_time = 0
        o.input_pointer_1_repeat = false
        o.input_pointer_1_repeat_time = 0
        o.input_text_enter_repeat = false
        o.input_text_enter_repeat_time = 0
        o.input_text_backspace_repeat = false
        o.input_text_backspace_repeat_time = 0
        o.input_text_space_repeat = false
        o.input_text_space_repeat_time = 0

        o.input_scroll_dy = 0
        o.input_scroll_gamepad_dy = 0

        return o
    end,

    begin_ui = function(self, delta_time)
        self.window_stack = {}
        self.region_stack = {}
        self.delta_time = 1

        if delta_time ~= nil then
            self.delta_time = delta_time / (1000 / 30)
        end
        
        self.animation_timer = self.animation_timer + 1
        self.window_col_active = color_white
        self.window_col_inactive = color_grey_dark

        local function clear_released_input(is_held, input)
            return is_held and update_get_screen_input(input)
        end

        self.is_select_next_held = clear_released_input(self.is_select_next_held, e_input.down)
        self.is_select_prev_held = clear_released_input(self.is_select_prev_held, e_input.up)
        self.input_left_held = clear_released_input(self.input_left_held, e_input.left)
        self.input_right_held = clear_released_input(self.input_right_held, e_input.right)
        self.input_action_held = clear_released_input(self.input_action_held, e_input.action_a)
        self.input_pointer_1_held = clear_released_input(self.input_pointer_1_held, e_input.pointer_1)
        self.input_text_enter_held = clear_released_input(self.input_text_enter_held, e_input.text_enter)
        self.input_text_backspace_held = clear_released_input(self.input_text_backspace_held, e_input.text_backspace)
        self.input_text_space_held = clear_released_input(self.input_text_space_held, e_input.text_space)
        self.input_text_shift_held = clear_released_input(self.input_text_shift_held, e_input.text_shift)

        local function update_repeat(is_held, is_repeat, repeat_time)
            local repeat_delay = 10
            local repeat_rates = { 5, 5, 4, 4, 3, 3, 2 }

            if is_held then
                local repeat_time_prev = repeat_time
                repeat_time = repeat_time + self.delta_time

                if math.floor(repeat_time_prev) ~= repeat_delay and math.floor(repeat_time) == repeat_delay then
                    is_repeat = true
                else
                    local delay_time = repeat_time - repeat_delay
                    local delay_time_prev = delay_time - self.delta_time
                    local total_time = 0
                    
                    for i = 1, #repeat_rates do
                        total_time = total_time + repeat_rates[i]

                        if math.floor(delay_time_prev) ~= total_time and math.floor(delay_time) == total_time then
                            is_repeat = true
                        end
                    end

                    if delay_time > total_time then
                        delay_time = delay_time - total_time
                        delay_time_prev = delay_time_prev - total_time

                        if math.floor(delay_time_prev) % repeat_rates[#repeat_rates] ~= 0 and math.floor(delay_time) % repeat_rates[#repeat_rates] == 0 then
                            is_repeat = true
                        end
                    end
                end
            else
                repeat_time = 0
            end

            return is_repeat, repeat_time
        end

        self.is_select_next_repeat, self.is_select_next_repeat_time = update_repeat(self.is_select_next_held, self.is_select_next_repeat, self.is_select_next_repeat_time)
        self.is_select_prev_repeat, self.is_select_prev_repeat_time = update_repeat(self.is_select_prev_held, self.is_select_prev_repeat, self.is_select_prev_repeat_time)
        self.input_left_repeat, self.input_left_repeat_time = update_repeat(self.input_left_held, self.input_left_repeat, self.input_left_repeat_time)
        self.input_right_repeat, self.input_right_repeat_time = update_repeat(self.input_right_held, self.input_right_repeat, self.input_right_repeat_time)
        self.input_action_repeat, self.input_action_repeat_time = update_repeat(self.input_action_held, self.input_action_repeat, self.input_action_repeat_time)
        self.input_pointer_1_repeat, self.input_pointer_1_repeat_time = update_repeat(self.input_pointer_1_held, self.input_pointer_1_repeat, self.input_pointer_1_repeat_time)
        self.input_text_enter_repeat, self.input_text_enter_repeat_time = update_repeat(self.input_text_enter_held, self.input_text_enter_repeat, self.input_text_enter_repeat_time)
        self.input_text_backspace_repeat, self.input_text_backspace_repeat_time = update_repeat(self.input_text_backspace_held, self.input_text_backspace_repeat, self.input_text_backspace_repeat_time)
        self.input_text_space_repeat, self.input_text_space_repeat_time = update_repeat(self.input_text_space_held, self.input_text_space_repeat, self.input_text_space_repeat_time)
    end,

    end_ui = function(self)
        self.is_select_next = false
        self.is_select_prev = false
        self.input_left = false
        self.input_right = false
        self.input_action = false
        self.input_pointer_1 = false
        self.input_text_enter = false
        self.input_text_backspace = false
        self.input_text_space = false
        self.input_text_shift = false
        
        self.is_select_next_repeat = false
        self.is_select_prev_repeat = false
        self.input_left_repeat = false
        self.input_right_repeat = false
        self.input_action_repeat = false
        self.input_pointer_1_repeat = false
        self.input_text_enter_repeat = false
        self.input_text_backspace_repeat = false
        self.input_text_space_repeat = false

        self.input_scroll_dy = 0
        self.input_scroll_gamepad_dy = 0        
    end,

    input_event = function(self, event, action)
        if action == e_input_action.press then
            if event == e_input.down then
                self.is_select_next = true
                self.is_select_next_held = true
            elseif event == e_input.up then
                self.is_select_prev = true
                self.is_select_prev_held = true
            elseif event == e_input.left then
                self.input_left = true
                self.input_left_held = true
            elseif event == e_input.right then
                self.input_right = true
                self.input_right_held = true
            elseif event == e_input.action_a then
                self.input_action = true
                self.input_action_held = true
            elseif event == e_input.pointer_1 then
                self.input_pointer_1 = true
                self.input_pointer_1_held = true
            elseif event == e_input.text_enter then
                self.input_text_enter = true
                self.input_text_enter_held = true
            elseif event == e_input.text_backspace then
                self.input_text_backspace = true
                self.input_text_backspace_held = true
            elseif event == e_input.text_space then
                self.input_text_space = true
                self.input_text_space_held = true
            elseif event == e_input.text_shift then
                self.input_text_shift = true
                self.input_text_shift_held = true
            end
        elseif action == e_input_action.release then
            if event == e_input.down then
                self.is_select_next_held = false
            elseif event == e_input.up then
                self.is_select_prev_held = false
            elseif event == e_input.left then
                self.input_left_held = false
            elseif event == e_input.right then
                self.input_right_held = false
            elseif event == e_input.action_a then
                self.input_action_held = false
            elseif event == e_input.pointer_1 then
                self.input_pointer_1_held = false
            elseif event == e_input.text_enter then
                self.input_text_enter_held = false
            elseif event == e_input.text_backspace then
                self.input_text_backspace_held = false
             elseif event == e_input.text_space then
                self.input_text_space_held = false
            elseif event == e_input.text_shift then
                self.input_text_shift_held = false
            end
        end
    end,

    input_pointer = function(self, is_hovered, x, y)
        self.is_mouse_hovered = is_hovered
        self.mouse_x = x
        self.mouse_y = y
    end,

    input_scroll = function(self, dy)
        self.input_scroll_dy = self.input_scroll_dy + dy
    end,

    input_scroll_gamepad = function(self, dy)
        self.input_scroll_gamepad_dy = self.input_scroll_gamepad_dy + dy
    end,

    push_region = function(self, width, height)
        table.insert(self.region_stack, { w = width, h = height })
    end,

    pop_region = function(self)
        self.region_stack[#self.region_stack] = nil
    end,

    get_region = function(self)
        if #self.region_stack > 0 then
            local region = self.region_stack[#self.region_stack]
            return region.w, region.h
        end

        return 0, 0
    end,

    push_window = function(self, window)
        table.insert(self.window_stack, window)
    end,

    pop_window = function(self)
        self.window_stack[#self.window_stack] = nil
    end,

    get_window = function(self)
        if #self.window_stack > 0 then
            return self.window_stack[#self.window_stack]
        end
    end,

    get_create_window = function(self, title)
        if self.windows[title] == nil then
            self.windows[title] = { 
                cx = 0, 
                cy = 0, 
                is_active = false,
                selected_index_y = 0,
                selected_index_x = 0,
                selected_y = 0,
                index_y = 0,
                index_x = 0,
                view_y = 0,
                scroll_y = 0,
                is_scroll_to_selected = false,
                label_bias = 0.5,
                is_nav_row = false,
                is_selected_row_changed = false,
                is_selection_enabled = true,
                offset_count = 0,
                is_scrollbar_visible = false,
                scroll_h_prev = 0,
                content_h_prev = 0,
                scroll_drag_off_y = 0,
                is_scroll_drag = false,
            }
        end

        return self.windows[title]
    end,

    get_is_scroll_drag = function(self)
        for _, v in pairs(self.windows) do
            if v.is_scroll_drag then
                return update_get_screen_input(e_input.pointer_1)
            end
        end

        return false
    end,

    selectable = function(self, h)
        local window = self:get_window()
        local item_index_y = window.index_y
        local item_index_x = window.index_x

        if window.selected_index_y == window.index_y then
            window.selected_y = window.cy + (h or 0) / 2
        end

        if window.is_nav_row then
            window.index_x = window.index_x + 1
        else
            window.index_y = window.index_y + 1
        end

        local is_selected = window.selected_index_y == item_index_y

        if window.is_nav_row then
            is_selected = is_selected and window.selected_index_x == item_index_x
        end

        return is_selected and window.is_selection_enabled
    end,

    hoverable = function(self, x, y, w, h, is_select_on_hover)
        local window = self:get_window()
        local item_index_y = window.index_y
        local item_index_x = window.index_x
        local is_hovered = false

        self:selectable(h)

        if self.is_mouse_hovered and update_get_active_input_type() == e_active_input.keyboard then
            if self:is_hovered(x, y, w, h) then
                is_hovered = true

                if (self.input_pointer_1 or is_select_on_hover) and window.is_active then
                    window.selected_index_y = item_index_y

                    if window.is_nav_row then
                        window.selected_index_x = item_index_x
                    end
                end
            end
        end

        local is_selected = window.selected_index_y == item_index_y and window.is_selection_enabled

        if window.is_nav_row then
            is_selected = is_selected and window.selected_index_x == item_index_x
        end

        return is_hovered, (is_selected and window.is_selection_enabled)
    end,

    is_hovered = function(self, x, y, w, h)
        local window = self:get_window()
        local offset_x, offset_y = update_ui_get_offset()
        local local_mouse_x = self.mouse_x - offset_x
        local local_mouse_y = self.mouse_y - offset_y
        
        if local_mouse_x >= x and local_mouse_y >= y and local_mouse_x < x + w and local_mouse_y < y + h then
            return window.is_selection_enabled and window.is_scroll_drag == false
        end

        return false
    end,

    get_is_item_selected = function(self)
        local window = self:get_window()

        if window.selected_index_y == window.index_y - 1 and (window.is_nav_row == false or window.selected_index_x == window.index_x - 1) and window.is_selection_enabled then
            return true
        end

        return false
    end,

    --------------------------------------------------------------------------------
    --
    -- UI ELEMENTS
    --
    --------------------------------------------------------------------------------

    begin_window = function(self, title, x, y, w, h, icon, is_active, win_type, is_selection_enabled, is_col_active, align)
        if w == nil or h == nil then
            w, h = self:get_region()
        end

        local find_pos = title:find("##")
        local display_name = title
        local window_id = title

        if find_pos ~= nil then
            display_name = title:sub(0, find_pos - 1)
            window_id = title:sub(find_pos)
        end

        local window = self:get_create_window(window_id)
        local scroll_h = window.cy
        local selected_y = window.selected_y

        if type(h) == "table" then
            local constraints = h
            h = scroll_h + iff(win_type == 1, 0, 12)

            if constraints.min ~= nil then h = math.max(h, constraints.min) end
            if constraints.max ~= nil then h = math.min(h, constraints.max) end
        end

        if align ~= nil then
            x = x - w * align[1]
            y = y - h * align[2]
        end

        if is_active then
            if self.is_mouse_hovered and update_get_active_input_type() == e_active_input.keyboard then
                window.scroll_y = window.scroll_y - self.input_scroll_dy * 12
            elseif update_get_active_input_type() == e_active_input.gamepad then
                window.scroll_y = window.scroll_y - self.input_scroll_gamepad_dy * 7 * self.delta_time
            end
        end
        
        if window.is_scroll_to_selected then
            window.is_scroll_to_selected = false
            window.scroll_y = selected_y
        end

        window.is_selection_enabled = iff(is_selection_enabled == nil, true, is_selection_enabled)
        window.is_selected_row_changed = false

        if window.is_selection_enabled == false then
            window.selected_index_y = 0
            window.selected_index_x = 0
        end

        local selectable_item_count_y = window.index_y

        if selectable_item_count_y > 0 then
            if window.selected_index_y + 1 > window.index_y then
                window.selected_index_y = 0
                window.is_scroll_to_selected = true
                window.is_selected_row_changed = true
            elseif window.selected_index_y < 0 then
                window.selected_index_y = window.index_y - 1
                window.is_scroll_to_selected = true
                window.is_selected_row_changed = true
            end
        end

        win_type = win_type or 0

        window.cx = 0
        window.cy = 1
        window.is_active = is_active
        window.index_y = 0
        window.selected_y = 0
        window.label_bias = 0.5
        window.is_nav_row = false
        window.offset_count = 0

        self:push_window(window)

        if is_active and selectable_item_count_y > 0 then
            if self.is_select_next or self.is_select_next_repeat then
                self.is_select_next = false
                self.is_select_next_repeat = false

                if window.is_selection_enabled then
                    window.selected_index_y = window.selected_index_y + 1
                    window.is_scroll_to_selected = true
                    window.is_selected_row_changed = true
                end
            end

            if self.is_select_prev or self.is_select_prev_repeat then
                self.is_select_prev = false
                self.is_select_prev_repeat = false

                if window.is_selection_enabled then
                    window.selected_index_y = window.selected_index_y - 1
                    window.is_scroll_to_selected = true
                    window.is_selected_row_changed = true
                end
            end
        end

        local col = iff(is_active, self.window_col_active, self.window_col_inactive)

        if is_col_active ~= nil then
            col = iff(is_col_active, self.window_col_active, self.window_col_inactive)
        end

        update_ui_push_offset(x, y)
        window.offset_count = window.offset_count + 1

        local content_w = w
        local content_h = h

        if win_type == 0 or win_type == 2 then
            if win_type == 2 then
                update_ui_rectangle(0, 0, w, h, color_black)
            end

            update_ui_rectangle_outline(0, 0, w, h, col)
            update_ui_rectangle(0, 0, w, 11, col)
            update_ui_text(0, 2, display_name, math.floor(w / 2) * 2, 1, color_black, 0)

            if icon ~= nil then
                update_ui_image(2, 1, icon, color_black, 0)
            end

            update_ui_push_offset(1, 11)
            window.offset_count = window.offset_count + 1
        end

        local content_w = w - iff(win_type == 1, 0, 2)
        local content_h = h - iff(win_type == 1, 0, 12)

        -- mouse drag scroll

        if update_get_screen_input(e_input.pointer_1) == false or is_active == false or update_get_active_input_type() ~= e_active_input.keyboard then
            window.is_scroll_drag = false
        elseif window.is_scroll_drag then
            local offset_x, offset_y = update_ui_get_offset()
            local local_mouse_y = self.mouse_y - offset_y
            local scroll_factor = (local_mouse_y - window.scroll_drag_off_y) / content_h
            window.scroll_y = scroll_h * scroll_factor + content_h / 2
        end

        window.scroll_y = clamp(window.scroll_y, content_h / 2, scroll_h - content_h / 2)
        local view_y = clamp(window.scroll_y - content_h / 2, 0, scroll_h - content_h)

        window.scroll_h_prev = scroll_h
        window.content_h_prev = content_h
        
        window.view_y = lerp(window.view_y, view_y, 1 - math.exp(-0.5 * self.delta_time))
        window.is_scrollbar_visible = false

        if scroll_h > content_h then
            content_w = content_w - 5

            local bar_x = content_w
            local bar_y = math.floor(view_y / scroll_h * content_h + 0.5)
            local bar_w = 5
            local bar_h = math.floor(content_h / scroll_h * content_h + 0.5)

            local offset_x, offset_y = update_ui_get_offset()
            local local_mouse_x = self.mouse_x - offset_x
            local local_mouse_y = self.mouse_y - offset_y
            local hover_x = local_mouse_x - bar_x
            local hover_y = local_mouse_y - bar_y
            local is_hovered = hover_x >= 0 and hover_y >= 0 and hover_x < bar_w and hover_y < bar_h and update_get_active_input_type() == e_active_input.keyboard

            if is_hovered and self.input_pointer_1 then
                if window.is_scroll_drag == false then
                    window.is_scroll_drag = true
                    window.scroll_drag_off_y = hover_y
                    self.input_pointer_1 = false
                end
            end

            update_ui_rectangle(bar_x, 0, bar_w, content_h, color_grey_dark)

            if window.is_scroll_drag then
                update_ui_rectangle_outline(bar_x, bar_y, bar_w, bar_h, iff(is_active, color_highlight, color_grey_dark))
            else
                update_ui_rectangle(bar_x, bar_y, bar_w, bar_h, iff(is_active, iff(is_hovered, color_highlight, color_grey_mid), color_grey_dark))
            end

            if is_active and self.is_mouse_hovered then
                update_add_ui_interaction_special(update_get_loc(e_loc.interaction_scroll), e_ui_interaction_special.mouse_wheel)
            end

            window.is_scrollbar_visible = true
        end

        update_ui_push_clip(0, 0, content_w, content_h)
        update_ui_push_offset(0, -math.floor(window.view_y))
        window.offset_count = window.offset_count + 1
        
        self:push_region(content_w, content_h)

        return window
    end,

    end_window = function(self)
        self:pop_region()
        update_ui_pop_clip()

        local window = self:get_window()

        for i = 0, window.offset_count - 1 do
            update_ui_pop_offset()
        end

        self:pop_window()
    end,
    
    begin_window_dialog = function(self, title, cx, cy, w, max_h, icon, is_active)
        return self:begin_window(title, cx, cy, w, { max=max_h }, icon, is_active, 2, true, nil, { 0.5, 0.5 })
    end,

    end_window_dialog = function(self, text_no, text_yes)
        local action_index = self:button_group({ text_no, text_yes }, { true, true })
        self:end_window()
        return action_index
    end,

    reset_scroll = function(self)
        local window = self:get_window()

        if window ~= nil then
            window.scroll_y = 0
            window.view_y = 0
        end
    end,

    set_scroll = function(self, y)
        local window = self:get_window()

        if window ~= nil then
            window.scroll_y = y
            window.view_y = y

            window.scroll_y = clamp(window.scroll_y, window.content_h_prev / 2, window.scroll_h_prev - window.content_h_prev / 2)
            window.view_y = clamp(window.scroll_y - window.content_h_prev / 2, 0, window.scroll_h_prev - window.content_h_prev)
        end
    end,

    is_item_selected = function(self)
        local window = self:get_window()
        return window ~= nil and window.selected_index_y == window.index_y - 1
    end,

    set_item_selected = function(self)
        local window = self:get_window()
        window.selected_index_y = window.index_y - 1

        if window.is_nav_row then
            window.selected_index_x = window.index_x - 1
        end
    end,
    
    begin_nav_row = function(self)
        local window = self:get_window()
        window.index_x = 0
        window.is_nav_row = true
        window.cx = 0
    end,

    end_nav_row = function(self, row_h)
        local window = self:get_window()
        local is_active = window.is_active
        local is_row_selected = window.selected_index_y == window.index_y and window.is_selection_enabled
        
        if is_row_selected and is_active then
            if self.input_right or self.input_right_repeat then
                window.selected_index_x = window.selected_index_x + 1
                self.input_right = false
                self.input_right_repeat = false
            elseif self.input_left or self.input_left_repeat then
                window.selected_index_x = window.selected_index_x - 1
                self.input_left = false
                self.input_left_repeat = false
            end

            if window.selected_index_x < 0 then
                if window.is_selected_row_changed then
                    window.selected_index_x = 0
                else
                    window.selected_index_x = math.max(window.index_x - 1, 0)
                end
            elseif window.selected_index_x >= window.index_x then
                if window.is_selected_row_changed then
                    window.selected_index_x = math.max(window.index_x - 1, 0)
                else
                    window.selected_index_x = 0
                end
            end

            window.is_selected_row_changed = false
        end

        window.index_x = 0
        window.is_nav_row = false
        window.cx = 0
        window.index_y = window.index_y + 1

        window.cy = window.cy + row_h
    end,

    example_nav_row = function(self, item_count)
        self:begin_nav_row()

        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = window.is_active
        local is_row_selected = window.selected_index_y == window.index_y and window.is_selection_enabled

        for i = 1, item_count do
            local is_hovered, is_selected = self:hoverable(x, y, 15, 10, false)
            update_ui_rectangle(x, y, 15, 10, iff(is_row_selected, color_grey_mid, color_grey_dark))
            update_ui_rectangle(x + 2, y + 2, 5, 5, iff(is_selected, color_status_ok, iff(is_hovered, color_status_bad, color_empty)))

            x = x + 20
        end

        self:end_nav_row(12)
    end,

    slider = function(self, label, value, min, max, step)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = window.is_active
        local is_hovered, is_selected = self:hoverable(x, y, w, 12, true)
        
        if step == nil then
            step = (max - min) / 10
        end

        local label_w = math.floor(w * window.label_bias)
        local slider_w = w - label_w - 2

        local text_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)
        local slider_col = iff(is_active, iff(is_selected, color_highlight, color_grey_mid), color_grey_dark)
        local border_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)

        local text_h = update_ui_text(x + 5, y + 1, label, label_w - 5, 0, text_col, 0)
        update_ui_rectangle_outline(x + label_w, y + 1, slider_w, 9, border_col)

        local factor = invlerp(value, min, max)
        update_ui_rectangle(x + label_w + 1, y + 2, math.floor((slider_w - 2) * factor + 0.5), 7, slider_col)

        window.cy = window.cy + text_h + 2

        if is_selected and is_active then
            local is_slider_hovered = self:is_hovered(x + label_w, y, slider_w, 12)
            local is_clicked = is_hovered and self.input_pointer_1 and is_slider_hovered

            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_select), e_ui_interaction_special.gamepad_dpad_lr)
            
            if is_slider_hovered and update_get_active_input_type() == e_active_input.keyboard then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
            end

            if is_clicked then
                local offset_x, offset_y = update_ui_get_offset()
                local local_mouse_x = self.mouse_x - offset_x - (x + label_w)
                value = remap_clamp(local_mouse_x, 0, slider_w, min, max)
                value = math.floor(value / step + 0.5) * step
            end

            if self.input_left then
                value = math.max(value - step, min)
            elseif self.input_right then
                value = math.min(value + step, max)
            end
        end

        return value
    end,

    header = function(self, label)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        
        update_ui_rectangle(x, y, w, 12, color_grey_dark)
        update_ui_text(x + 5, y + 2, label, w - 5, 0, color_black, 0)

        window.cy = window.cy + 13
    end,

    checkbox = function(self, label, value, is_radio)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = window.is_active

        local label_w = math.floor(w * window.label_bias)
        local check_w = 9
        local text_w, text_h = update_ui_get_text_size(label, label_w - 5, 0)
        local is_hovered, is_selected = self:hoverable(x, y, w, text_h + 2, true)
        
        local text_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)
        local check_col = iff(is_active, iff(is_selected, color_highlight, color_highlight), color_grey_dark)
        local border_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)

        local text_h = update_ui_text(x + 5, y + 1, label, label_w - 5, 0, text_col, 0)

        if value then
            if is_radio then
                update_ui_rectangle(x + label_w + 2, y + 3, check_w - 4, 5, check_col)
            else
                update_ui_line(x + label_w, y + 1, x + label_w + check_w, y + 10, check_col)
                update_ui_line(x + label_w, y + 10, x + label_w + check_w, y + 1, check_col)
            end
        end  

        update_ui_rectangle_outline(x + label_w, y + 1, check_w, 9, border_col)

        window.cy = window.cy + text_h + 2

        local is_modified = false

        if is_selected and is_active then
            local is_check_hovered = self:is_hovered(x + label_w, y, check_w, 12)
            local is_clicked = is_hovered and self.input_pointer_1 and is_check_hovered

            if is_check_hovered or update_get_active_input_type() == e_active_input.gamepad then
                update_add_ui_interaction(iff(is_radio, update_get_loc(e_loc.interaction_select), iff(value, update_get_loc(e_loc.interaction_disable), update_get_loc(e_loc.interaction_enable))), e_game_input.interact_a)
            end

            if self.input_action or is_clicked then
                is_modified = true
                value = not value
            end
        end

        return value, is_modified
    end,

    list_item = function(self, label, is_select_on_hover, is_enabled)
        is_enabled = iff(is_enabled == nil, true, is_enabled)

        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = is_enabled and window.is_active
        local is_action = false
        is_select_on_hover = is_select_on_hover or false
        local is_hovered, is_selected = self:hoverable(x, y, w, 13, is_select_on_hover)

        local text_col = iff(is_active, iff(is_selected, color_white, iff(is_hovered and is_select_on_hover == false, color_white, color_black)), color_black)
        local back_col = iff(is_active, iff(is_selected, color_highlight, color_button_bg), iff(is_selected, color_grey_dark, color_button_bg_inactive))

        render_button_bg(x + 1, y, w - 2, 12, back_col)
        update_ui_push_clip(x + 1, y, w - 10, 12)
        update_ui_text(x + 5, y + 2, label, 999999, 0, text_col, 0)
        update_ui_pop_clip()

        if is_active then
            if is_hovered or (update_get_active_input_type() == e_active_input.gamepad and is_selected) then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
            end
        end

        if is_selected then
            update_ui_image(x + w - 7, y + 3, atlas_icons.text_back, text_col, 2)

            if is_active then
                local is_clicked = is_hovered and self.input_pointer_1
      
                if self.input_action or is_clicked then
                    is_action = true
                    self.input_action = false
                    self.input_pointer_1 = false
                end
            end
        end

        window.cy = window.cy + 13

        return is_action
    end,

    list_item_wrap = function(self, label, is_select_on_hover, is_enabled)
        is_enabled = iff(is_enabled == nil, true, is_enabled)

        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = is_enabled and window.is_active
        local is_action = false
        is_select_on_hover = is_select_on_hover or false

        local text_w, text_h = update_ui_get_text_size(label, w - 20, 0)
        local is_hovered, is_selected = self:hoverable(x, y, w, text_h + 4, is_select_on_hover)

        local text_col = iff(is_active, iff(is_selected, color_white, iff(is_hovered and is_select_on_hover == false, color_white, color_black)), color_black)
        local back_col = iff(is_active, iff(is_selected, color_highlight, color_button_bg), iff(is_selected, color_grey_dark, color_button_bg_inactive))

        render_button_bg(x + 1, y, w - 2, text_h + 2, back_col)
        update_ui_text(x + 5, y + 2, label, w - 20, 0, text_col, 0)

        if is_active then
            if is_hovered or (update_get_active_input_type() == e_active_input.gamepad and is_selected) then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
            end
        end

        if is_selected then
            update_ui_image(x + w - 7, y + text_h / 2 - 3, atlas_icons.text_back, text_col, 2)

            if is_active then
                local is_clicked = is_hovered and self.input_pointer_1
      
                if self.input_action or is_clicked then
                    is_action = true
                    self.input_action = false
                    self.input_pointer_1 = false
                end
            end
        end

        window.cy = window.cy + text_h + 4

        return is_action
    end,

    button = function(self, label, is_enabled, align)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_hovered, is_selected = self:hoverable(x, y, w, 14, true)
        local is_active = is_enabled and window.is_active
        local is_action = false
        
        local label_w = math.floor(w * window.label_bias)
        local bw = w - label_w - 2
        local bh = 13
        local bx = x + label_w
        local by = y

        if align == 1 then
            bx = x + 1
            bw = w - 2
        elseif align == 2 then
            bx = x + 1
            bw = label_w - 2
        end

        if is_enabled == false then
            local text_col = iff(is_active, iff(is_selected, color_white, color_black), iff(is_selected, color_grey_dark, color_grey_dark))
            local back_col = iff(is_active, iff(is_selected, color_white, color_button_bg_inactive), iff(is_selected, color_grey_mid, color_button_bg_inactive))

            render_button_bg_outline(bx, y, bw, bh, back_col)
            update_ui_text(bx, by + 2, label, math.floor(bw / 2) * 2, 1, text_col, 0)
        else
            local text_col = iff(is_active, iff(is_selected, iff(self.input_action_held or self.input_pointer_1_held, color_white, color_white), color_black), color_black)
            local back_col = iff(is_active, iff(is_selected, iff(self.input_action_held or self.input_pointer_1_held, color_highlight, color_highlight), color_button_bg), iff(is_selected, color_grey_dark, color_button_bg_inactive))

            render_button_bg(bx, by, bw, bh, back_col)
            update_ui_text(bx, by + 2, label, math.floor(bw / 2) * 2, 1, text_col, 0)
        end

        if is_selected and is_active then
            local is_button_hovered = self:is_hovered(bx, by, bw, bh)
            local is_clicked = is_hovered and self.input_pointer_1 and is_button_hovered

            if is_button_hovered or update_get_active_input_type() == e_active_input.gamepad then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
            end

            if self.input_action or is_clicked then
                is_action = true
                self.input_action = false
                self.input_pointer_1 = false
            end
        end

        window.cy = window.cy + 14

        return is_action
    end,

    button_group = function(self, labels, is_enabled)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = is_enabled and window.is_active
        local button_action = -1

        local spacing = 2
        local bx = x + 5
        local by = y
        local bw = math.floor((w - (#labels - 1) * spacing - 10) / #labels)
        local bh = 13

        self:begin_nav_row()

        local is_row_selected = window.selected_index_y == window.index_y and window.is_selection_enabled

        if is_active and is_row_selected then
            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_lr)
        end

        local button_index = 0

        for i = 1, #labels do
            if #labels[i] > 0 then
                local is_hovered, is_selected = self:hoverable(bx, by, bw, bh, true)

                if is_enabled == false then
                    local text_col = iff(is_active, iff(is_selected, color_white, color_black), iff(is_selected, color_grey_dark, color_grey_dark))
                    local back_col = iff(is_active, iff(is_selected, color_white, color_button_bg_inactive), iff(is_selected, color_grey_mid, color_button_bg_inactive))

                    render_button_bg_outline(bx, y, bw, bh, back_col)
                    update_ui_text(bx, by + 2, labels[i], math.floor(bw / 2) * 2, 1, text_col, 0)
                else
                    local text_col = iff(is_active, iff(is_selected, iff(self.input_action_held or self.input_pointer_1_held, color_white, color_white), color_black), color_black)
                    local back_col = iff(is_active, iff(is_selected, iff(self.input_action_held or self.input_pointer_1_held, color_highlight, color_highlight), color_button_bg), iff(is_selected, color_grey_dark, color_button_bg_inactive))

                    render_button_bg(bx, by, bw, bh, back_col)
                    update_ui_text(bx, by + 2, labels[i], math.floor(bw / 2) * 2, 1, text_col, 0)
                end

                if is_selected and is_active then
                    local is_clicked = is_hovered and self.input_pointer_1
        
                    if is_hovered or update_get_active_input_type() == e_active_input.gamepad then
                        update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
                    end

                    if self.input_action or is_clicked then
                        button_action = button_index
                        self.input_action = false
                        self.input_pointer_1 = false
                    end
                end

                button_index = button_index + 1
            end

            bx = bx + bw + spacing
        end

        self:end_nav_row(15)

        return button_action
    end,

    divider = function(self, space_top, space_bottom)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()

        space_top = space_top or 3
        space_bottom = space_bottom or 4

        update_ui_line(x + 5, y + space_top, w - 3, y + space_top, color_grey_dark)
        window.cy = window.cy + space_top + space_bottom
    end,

    spacer = function(self, size)
        local window = self:get_window()
        window.cy = window.cy + size
    end,

    text_basic = function(self, label, active_col, inactive_col, align)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = window.is_active

        active_col = active_col or color_grey_dark
        inactive_col = inactive_col or color_grey_dark
        align = align or 0

        local text_h = update_ui_text(x + 5, y + 2, label, w - 10, align, iff(is_active, active_col, inactive_col), 0)
        window.cy = window.cy + text_h + 2
    end,

    text = function(self, label)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_selected = window.selected_index_y == window.index_y
        local is_active = window.is_active

        local text_h = update_ui_text(x + 5, y + 2, label, w - 10, 0, iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark), 0)
        window.cy = window.cy + text_h + 2
        
        local is_hovered = self:hoverable(x, y, w, window.cy - y, true)

        local is_action = false

        if is_selected and is_active then
            if self.input_action then
                is_action = true
                self.input_action = false
            end
        end

        return is_action
    end,

    image = function(self, icon_region, padding, bg_col, bg_pad, is_outline)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = window.is_active
        bg_pad = bg_pad or 0
        padding = padding or 0

        local region_w, region_h = update_ui_get_image_size(icon_region)

        if bg_col ~= nil then
            bg_col = iff(is_active, bg_col, color_grey_dark)

            if is_outline then
                update_ui_rectangle_outline(x + (w - region_w) / 2 - bg_pad, y + padding, region_w + 2 * bg_pad, region_h + 2 * bg_pad, bg_col)
            else
                update_ui_rectangle(x + (w - region_w) / 2 - bg_pad, y + padding, region_w + 2 * bg_pad, region_h + 2 * bg_pad, bg_col)
            end
        end

        update_ui_image(x + (w - region_w) / 2, y + padding + bg_pad, icon_region, iff(is_active, color_white, color_grey_dark), 0)

        window.cy = window.cy + region_h + padding * 2 + bg_pad * 2
    end,

    stat = function(self, label_icon, stat_label, stat_col, stat_col_selected)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_selected = window.selected_index_y == window.index_y and window.is_selection_enabled
        local is_active = window.is_active
        stat_col_selected = stat_col_selected or stat_col

        local label_w = math.floor(w * window.label_bias)
        local stat_w = w - label_w - 2
        local text_col = iff(is_active, iff(is_selected, color_grey_mid, color_grey_dark), color_grey_dark)
        local text_h = 10

        if type(label_icon) == "string" then
            text_h = update_ui_text(x + 5, y + 2, label_icon, label_w - 10, 0, text_col, 0)
        else
            update_ui_image(x + 5, y + 2, label_icon, text_col, 0)
        end

        local stat_h = update_ui_text(x + 5 + label_w, y + 2, stat_label, stat_w - 10, 0, iff(is_active, iff(is_selected, stat_col_selected, stat_col), color_grey_dark), 0)
        window.cy = window.cy + math.max(text_h, stat_h) + 2

        self:hoverable(x, y, w, window.cy - y, true)
    end,

    stat_button = function(self, label_icon, stat_label, stat_col, stat_col_selected)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_selected = window.selected_index_y == window.index_y and window.is_selection_enabled
        local is_active = window.is_active
        stat_col_selected = stat_col_selected or stat_col

        local label_w = math.floor(w * window.label_bias)
        local stat_w = w - label_w - 2
        local text_col = iff(is_active, iff(is_selected, color_grey_mid, color_grey_dark), color_grey_dark)
        local text_h = 10

        if type(label_icon) == "string" then
            text_h = update_ui_text(x + 5, y + 2, label_icon, label_w - 10, 0, text_col, 0)
        else
            update_ui_image(x + 5, y + 2, label_icon, text_col, 0)
        end

        local stat_h = update_ui_text(x + 5 + label_w, y + 2, stat_label, stat_w - 10, 0, iff(is_active, iff(is_selected, stat_col_selected, stat_col), color_grey_dark), 0)
        window.cy = window.cy + math.max(text_h, stat_h) + 2
        
        local is_hovered = self:hoverable(x, y, w, window.cy - y, true)
        local is_action = false

        if is_selected and is_active then
            local is_clicked = is_hovered and self.input_pointer_1

            if is_hovered or update_get_active_input_type() == e_active_input.gamepad then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
            end

            if self.input_action or is_clicked then
                is_action = true
                self.input_action = false
                self.input_pointer_1 = false
            end
        end

        return is_action
    end,

    textbox = function(self, label_or_text, text, is_enabled)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_selected = window.selected_index_y == window.index_y and window.is_selection_enabled
        local is_active = window.is_active
        is_enabled = iff(is_enabled == nil, true, is_enabled)

        local label_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)
        local text_col = iff(is_active, iff(is_selected, iff(is_enabled, color_highlight, color_grey_dark), color_grey_dark), color_grey_dark)
        local box_col = iff(is_active, iff(is_selected, iff(is_enabled, color_white, color_grey_mid), color_grey_dark), color_grey_dark)
        local text_h = 10
        
        if text ~= nil then
            local label_w = math.floor(w * window.label_bias)
            local textbox_w = w - label_w - 2

            text_h = math.max(text_h, update_ui_text(x + 5, y + 2, label_or_text, label_w - 5, 0, label_col, 0))
            
            local box_h = math.max(update_ui_text(x + label_w + 5, y + 2, text, textbox_w - 10, 0, text_col, 0), 10)
            update_ui_rectangle_outline(x + label_w, y, textbox_w, box_h + 3, box_col)
            text_h = math.max(text_h, box_h)
        else
            text_h = math.max(text_h, update_ui_text(x + 5, y + 2, label_or_text, w - 12, 0, text_col, 0))
            update_ui_rectangle_outline(x + 2, y, w - 4, text_h + 3, box_col)
        end

        window.cy = window.cy + text_h + 4
        local is_hovered = self:hoverable(x, y, w, window.cy - y, true)

        local is_action = false

        if is_selected and is_active then
            local is_clicked = is_hovered and self.input_pointer_1

            if is_hovered or update_get_active_input_type() == e_active_input.gamepad then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
            end

            if self.input_action or is_clicked then
                is_action = true
                self.input_action = false
                self.input_pointer_1 = false
            end
        end

        return is_action
    end,

    selector = function(self, label, value, min, max, step, format)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = window.is_active

        local label_w = math.floor(w * window.label_bias)
        local combo_w = w - label_w - 2
        local _, text_label_height = update_ui_get_text_size(label, label_w, 0)
        local selector_h = math.max(text_label_height, 12)
        local is_hovered, is_selected = self:hoverable(x, y, w, selector_h, true)

        local text_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)
        local combo_col = iff(is_active, iff(is_selected, color_highlight, color_grey_mid), color_grey_dark)
        local arrow_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)

        update_ui_text(x + 5, y + 1, label, label_w - 5, 0, text_col, 0)

        local value_label = tostring(value)

        if format ~= nil then
            value_label = string.format(format, value)
        end

        update_ui_text(x + label_w, y + 1, value_label, math.floor(combo_w / 2) * 2, 1, combo_col, 0)
        
        update_ui_text(x + label_w, y + 1, "-", 10, 0, iff(value > min, arrow_col, color_grey_dark), 0)
        update_ui_text(x + label_w + combo_w - 5, y + 1, "+", 10, 0, iff(value < max, arrow_col, color_grey_dark), 0)

        -- update_ui_image(x + label_w, y + 1, atlas_icons.text_back, iff(value > min, arrow_col, color_grey_dark), 0)
        -- update_ui_image(x + label_w + combo_w - 5, y + 2, atlas_icons.text_back, iff(value < max, arrow_col, color_grey_dark), 2)

        window.cy = window.cy + selector_h

        local is_modified = false

        if is_selected and is_active then
            local is_left_hovered = self:is_hovered(x + label_w, y, 5, selector_h)
            local is_right_hovered = self:is_hovered(x + label_w + combo_w - 5, y, 5, selector_h)
            local is_left_clicked = is_hovered and (self.input_pointer_1 or self.input_pointer_1_repeat) and is_left_hovered
            local is_right_clicked = is_hovered and (self.input_pointer_1 or self.input_pointer_1_repeat) and is_right_hovered

            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_select), e_ui_interaction_special.gamepad_dpad_lr)

            if (is_left_hovered or is_right_hovered) and update_get_active_input_type() == e_active_input.keyboard then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
            end

            if self.input_left or self.input_left_repeat or is_left_clicked then
                is_modified = true
                value = clamp(value - step, min, max)
            elseif self.input_right or self.input_right_repeat or is_right_clicked then
                is_modified = true
                value = clamp(value + step, min, max)
            end
        end

        return value, is_modified
    end,

    combo = function(self, label, value, items, is_enabled, callback_render_item)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = window.is_active
        local is_hovered, is_selected = self:hoverable(x, y, w, 12, true)
        local is_modified = false
        is_enabled = iff(is_enabled == nil, true, false)

        local label_w = math.floor(w * window.label_bias)
        local combo_w = w - label_w - 2

        local text_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)
        local combo_col = iff(is_active, iff(is_selected, iff(is_enabled, color_highlight, color_grey_dark), iff(is_enabled, color_grey_mid, color_grey_dark)), color_grey_dark)
        local arrow_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)

        local text_h = update_ui_text(x + 5, y + 1, label, label_w - 5, 0, text_col, 0)

        update_ui_push_offset(x + label_w + 5, y + 1)

        if callback_render_item ~= nil then
            callback_render_item(items[value + 1], math.floor(combo_w / 2) * 2 - 10, 10)
        else
            text_h = math.max(text_h, update_ui_text(0, 0, items[value + 1], math.floor(combo_w / 2) * 2 - 10, 1, combo_col, 0))
        end

        update_ui_pop_offset()
        
        update_ui_image(x + label_w, y + 1, atlas_icons.text_back, iff(value > 0, arrow_col, color_grey_dark), 0)
        update_ui_image(x + label_w + combo_w - 5, y + 2, atlas_icons.text_back, iff(value + 1 < #items, arrow_col, color_grey_dark), 2)

        window.cy = window.cy + text_h + 2

        if is_selected and is_active then
            local is_left_hovered = self:is_hovered(x + label_w, y, 5, 12)
            local is_right_hovered = self:is_hovered(x + label_w + combo_w - 5, y, 5, 12)
            local is_left_clicked = is_hovered and self.input_pointer_1 and is_left_hovered
            local is_right_clicked = is_hovered and self.input_pointer_1 and is_right_hovered

            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_select), e_ui_interaction_special.gamepad_dpad_lr)
            
            if (is_left_hovered or is_right_hovered) and update_get_active_input_type() == e_active_input.keyboard then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
            end

            if self.input_left or is_left_clicked then
                if value > 0 then
                    value = value - 1
                    is_modified = true
                end
            elseif self.input_right or is_right_clicked then
                if value + 1 < #items then
                    value = value + 1
                    is_modified = true
                end
            end
        end

        return value, is_modified
    end,

    combo_color8 = function(self, label, value, items, is_gamma_correct)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = window.is_active
        local is_hovered, is_selected = self:hoverable(x, y, w, 12, true)

        local label_w = math.floor(w * window.label_bias)
        local combo_w = w - label_w - 2

        local text_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)
        local combo_col = iff(is_active, iff(is_selected, color_highlight, color_grey_mid), color_grey_dark)
        local arrow_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)

        update_ui_text(x + 5, y + 1, label, label_w - 5, 0, text_col, 0)

        local selected_index = 0

        for i = 1, #items do
            if color8_eq(value, items[i]) then
                selected_index = i
                break
            end
        end

        local function render_color_icon(x, y, size, col_front, col_back)
            update_ui_rectangle(x - size / 2, y - size / 2, size, size, col_back)
            update_ui_rectangle(x - size / 2 + 1, y - size / 2 + 1, size - 2, size - 2, col_front)
        end

        local function gamma(col)
            return iff(is_gamma_correct, gamma_correct(col), col)
        end

        render_color_icon(x + label_w + combo_w * 0.5, y + 5, 10, gamma(value), combo_col)
        
        -- render prev
        local icon_index = selected_index - 1
        local icon_x = x + label_w + combo_w * 0.5 - 12

        while icon_index > 0 and icon_x > x + label_w + 10 do
            render_color_icon(icon_x, y + 5, 10, gamma(items[icon_index]), color_grey_dark)
            icon_x = icon_x - 12
            icon_index = icon_index - 1
        end

        -- render next
        icon_index = selected_index + 1
        icon_x = x + label_w + combo_w * 0.5 + 12

        while icon_index <= #items and icon_x < x + label_w + combo_w - 10 do
            render_color_icon(icon_x, y + 5, 10, gamma(items[icon_index]), color_grey_dark)
            icon_x = icon_x + 12
            icon_index = icon_index + 1
        end

        update_ui_image(x + label_w, y + 1, atlas_icons.text_back, iff(selected_index > 1, arrow_col, color_grey_dark), 0)
        update_ui_image(x + label_w + combo_w - 5, y + 2, atlas_icons.text_back, iff(selected_index < #items, arrow_col, color_grey_dark), 2)

        window.cy = window.cy + 12

        if is_selected and is_active then
            local is_left_hovered = self:is_hovered(x + label_w, y, 5, 12)
            local is_right_hovered = self:is_hovered(x + label_w + combo_w - 5, y, 5, 12)
            local is_left_clicked = is_hovered and self.input_pointer_1 and is_left_hovered
            local is_right_clicked = is_hovered and self.input_pointer_1 and is_right_hovered

            update_add_ui_interaction_special(update_get_loc(e_loc.interaction_select), e_ui_interaction_special.gamepad_dpad_lr)
            
            if (is_left_hovered or is_right_hovered) and update_get_active_input_type() == e_active_input.keyboard then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
            end    

            if self.input_left or is_left_clicked then
                if selected_index > 1 then
                    value = items[selected_index - 1]
                end
            elseif self.input_right or is_right_clicked then
                if selected_index < #items then
                    value = items[selected_index + 1]
                end
            end
        end

        return value
    end,

    keybinding = function(self, label, key, pointer, button, axis, joy_button, joy_axis, joy_name, is_connected)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_selected = window.selected_index_y == window.index_y and window.is_selection_enabled
        local is_active = window.is_active

        local label_w = math.floor(w * window.label_bias)
        local icon_w = w - label_w
        local text_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)

        local text_h = update_ui_text(x + 5, y + 2, label, label_w - 5, 0, text_col, 0)
        local icon_x = x + label_w + icon_w / 2
        local icon_y = y + 2 + text_h / 2

        if key > 0 then
            local name = update_get_key_name(key)
            local key_w = imgui_key_icon_width(name)
            imgui_render_key_icon(icon_x - math.floor(key_w / 2), icon_y - 5, name, is_active)
        elseif pointer >= 0 and pointer < 3 then
            local icon, icon_col = get_pointer_icon(pointer)
            update_ui_image(icon_x - 5, icon_y - 5, icon, iff(is_active, icon_col, color_grey_dark), 0)
        elseif button >= 0 and button < 15 then
            local icon, icon_col = get_gamepad_button_icon(button)
            update_ui_image(icon_x - 5, icon_y - 5, icon, iff(is_active, icon_col, color_grey_dark), 0)
        elseif axis >= 0 and axis < 6 then
            local icon, icon_col = get_gamepad_axis_icon(axis)
            update_ui_image(icon_x - 5, icon_y - 5, icon, iff(is_active, icon_col, color_grey_dark), 0)
        elseif joy_button >= 0 then
            local icon, icon_col = get_joystick_button_icon(joy_button)
            update_ui_image(icon_x - 5, icon_y - 5, icon, iff(is_active, icon_col, color_grey_dark), 0)
            update_ui_image(icon_x - 5 + 20, icon_y - 5, atlas_icons.column_joystick, iff(is_connected, color_status_ok, color_status_dark_red), 0)
        elseif joy_axis >= 0 then
            local icon, icon_col = get_joystick_axis_icon(joy_axis)
            update_ui_image(icon_x - 5, icon_y - 5, icon, iff(is_active, icon_col, color_grey_dark), 0)
            update_ui_image(icon_x - 5 + 20, icon_y - 5, atlas_icons.column_joystick, iff(is_connected, color_status_ok, color_status_dark_red), 0)
        else
            update_ui_text(x + label_w, y + 2, "---", math.floor(icon_w / 2) * 2, 1, color_grey_dark, 0)
        end

        window.cy = window.cy + text_h + 2
        
        if joy_button >= 0 or joy_axis >= 0 then
            if #joy_name > 0 then
                window.cy = window.cy + 2
                text_h = update_ui_text(x + 5, window.cy, joy_name, w - 5, 0, iff(is_active and is_selected, color_grey_mid, color_grey_dark), 0)
                window.cy = window.cy + text_h
            end
        end
        
        local is_hovered = self:hoverable(x, y, w, window.cy - y, true)
        local is_action = false

        if is_selected and is_active then
            local is_clicked = is_hovered and self.input_pointer_1

            if is_hovered or update_get_active_input_type() == e_active_input.gamepad then
                update_add_ui_interaction(update_get_loc(e_loc.rebind), e_game_input.interact_a)
            end
            
            if self.input_action or is_clicked then
                is_action = true
                self.input_action = false
                self.input_pointer_1 = false
            end
        end

        return is_action
    end,

    keyboard = function(self, selected_key, edit_text, max_length)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = window.is_active
        max_length = max_length or 128

        local rows_lower = { 
            { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" },
            { "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]" },
            { "a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'", "#" },
            { "shift", "\\", "z", "x", "c", "v", "b", "n", "m", ",", ".", "/" },
            { "done", "space", "del", "paste" }
        }

        local rows_upper = {
            { "!", "\"", "£", "$", "%", "^", "&", "*", "(", ")", "_", "+" },
            { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "{", "}" },
            { "A", "S", "D", "F", "G", "H", "J", "K", "L", ":", "@", "~" },
            { "shift", "|", "Z", "X", "C", "V", "B", "N", "M", "<", ">", "?" },
            { "done", "space", "del", "paste" }
        }

        local selected_key_index = selected_key & 255
        local is_upper = (selected_key & 256) > 0
        local rows = iff(is_upper, rows_upper, rows_lower)

        local key_w = 10
        local key_h = 10
        local output_text = ""
        local key_value = ""
        local is_selected = false
        local keyboard_w = #rows_lower[1] * key_w
        x = x + w / 2 - keyboard_w / 2
        local sx = x
        local sy = y
        local keyboard_h = (#rows + 1) * 10 + 2

        update_ui_rectangle(sx - 1, sy, keyboard_w + 3, keyboard_h, color_black)

        y = y + 3

        for i = 1, #rows do
            local is_hovered, is_row_selected = self:hoverable(x, y, w, key_h + 2, true)

            if is_row_selected then
                if selected_key_index < 0 then selected_key_index = 0 end
                if selected_key_index >= #rows[i] then selected_key_index = #rows[i] - 1 end

                if is_active then
                    if self.input_left or self.input_left_repeat then
                        selected_key_index = selected_key_index - 1
                        self.input_left = false
                        self.input_left_repeat = false
                    elseif self.input_right or self.input_right_repeat then
                        selected_key_index = selected_key_index + 1
                        self.input_left = false
                        self.input_right_repeat = false
                    end
                end

                if is_hovered then
                    local offset_x, offset_y = update_ui_get_offset()
                    selected_key_index = math.floor(remap_clamp(self.mouse_x - offset_x, sx, sx + keyboard_w, 0, #rows[1])) 
                    selected_key_index = clamp(selected_key_index, 0, #rows[i] - 1)
                end

                if selected_key_index < 0 then selected_key_index = #rows[i] - 1 end
                if selected_key_index >= #rows[i] then selected_key_index = 0 end
            end

            for j = 1, #rows[i] do
                local is_key_selected = is_row_selected and j == (selected_key_index + 1)
                local is_render_selected = is_key_selected
                local is_render_pressed = self.input_action_held or self.input_pointer_1_held
                local key = rows[i][j]
                
                if key == "space" and self.input_text_space_held then
                    is_render_selected = true
                    is_render_pressed = true
                elseif key == "del" and self.input_text_backspace_held then
                    is_render_selected = true
                    is_render_pressed = true
                end

                local text_col = iff(is_active, iff(is_render_selected, iff(is_render_pressed, color_highlight, color_white), color_grey_dark), color_grey_dark)

                if is_key_selected then
                    key_value = key
                    is_selected = true
                end

                update_ui_push_offset(x + 3 + (j - 1) * key_w, iff(is_render_selected and is_render_pressed, y + 1, y))
                local col_bg = iff(is_render_selected, color_button_bg, color_empty)

                if key == "shift" then
                    render_button_bg(-2, 0, key_w - 1, key_h - 1, col_bg, 1)
                    update_ui_image(0, 0, atlas_icons.text_shift, text_col, 0)
                elseif key == "done" then
                    local confirm_col = iff(is_active, iff(is_render_selected, iff(is_render_pressed, color_highlight, color_white), color_status_ok), color_grey_dark)
                    render_button_bg(-2, 0, key_w - 1, key_h - 1, col_bg, 1)
                    update_ui_image(0, 0, atlas_icons.text_confirm, confirm_col, 0)
                elseif key == "space" then
                    render_button_bg(-2, 0, key_w - 1, key_h - 1, col_bg, 1)
                    update_ui_image(0, 0, atlas_icons.text_space, text_col, 0)
                elseif key == "del" then
                    render_button_bg(-2, 0, key_w - 1, key_h - 1, col_bg, 1)
                    update_ui_image(0, 0, atlas_icons.text_del, text_col, 0)
                elseif key == "paste" then
                    local paste_text = update_get_loc(e_loc.upp_paste)
                    local paste_key_w = update_ui_get_text_size(paste_text, 200, 0)
                    render_button_bg(-2, 0, paste_key_w + 4, key_h - 1, col_bg, 1)
                    update_ui_text(0, 0, paste_text, 200, 0, text_col, 0)
                else
                    render_button_bg(-2, 0, key_w - 1, key_h - 1, col_bg, 1)
                    update_ui_text(0, 0, rows[i][j], 10, 0, text_col, 0)
                end

                update_ui_pop_offset()
            end

            y = y + key_h + 2
        end

        update_ui_rectangle_outline(sx - 1, sy, keyboard_w + 3, y - sy, iff(is_active, iff(is_selected, color_button_bg_inactive, color_button_bg_inactive), color_grey_dark))

        local is_done = false
        selected_key = (selected_key & 0xffffff00) | selected_key_index

        if is_active and key_value ~= "" then
            local is_clicked = self:is_hovered(sx - 1, sy, keyboard_w + 3, y - sy) and (self.input_pointer_1 or self.input_pointer_1_repeat)

            if self.input_text_shift then
                selected_key = selected_key ~ 256
                self.input_text_shift = false
            end

            if self.input_action or self.input_action_repeat or is_clicked then
                if key_value == "shift" then
                    selected_key = selected_key ~ 256
                elseif key_value == "space" then
                    edit_text = edit_text .. " "
                    g_text_blink_time = 0
                elseif key_value == "del" then
                    if #edit_text > 0 then
                        edit_text = edit_text:sub(1, utf8.offset(edit_text, -1) - 1)
                        g_text_blink_time = 0
                    end
                elseif key_value == "done" then
                    is_done = true
                elseif key_value == "paste" then
                    update_ui_event("paste_clipboard")
                else
                    edit_text = edit_text .. key_value
                    g_text_blink_time = 0
                end

                self.input_action = false
                self.input_action_repeat = false
                self.input_pointer_1 = false
                self.input_pointer_1_repeat = false
            end
        end

        if is_active then
            if self.input_text_space or self.input_text_space_repeat then
                edit_text = edit_text .. " "
                g_text_blink_time = 0
                self.input_text_space = false
                self.input_text_space_repeat = false
            end
            
            if self.input_text_backspace or self.input_text_backspace_repeat then
                if #edit_text > 0 then
                    edit_text = edit_text:sub(1, utf8.offset(edit_text, -1) - 1)
                    g_text_blink_time = 0
                end

                self.input_text_backspace = false
                self.input_text_backspace_repeat = false
            elseif self.input_text_enter then
                is_done = true
                self.input_text_enter = false
            end
        end

        window.cy = y + 2
        
        edit_text = clamp_str(edit_text, max_length)
        return selected_key, edit_text, is_done
    end,

    save_slot = function(self, index, display_name, save_name, time)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = window.is_active
        local is_selected = window.selected_index_y == window.index_y and window.is_selection_enabled

        local is_set = #save_name > 0
        local text_name = iff(is_set, display_name, update_get_loc(e_loc.upp_empty))
        local text_time = iff(is_set, update_string_from_epoch(time, "%H:%M:%S %d/%m/%Y"), "---")

        local text_col = iff(is_active, iff(is_selected, iff(is_set, color_white, color_grey_mid), color_grey_dark), color_grey_dark)
        local num_col = iff(is_active, iff(is_selected, color_grey_dark, color_grey_dark), color_grey_dark)
        local time_col = iff(is_active, iff(is_selected, color_grey_mid, color_grey_dark), color_grey_dark)
        local back_col = iff(is_active, iff(is_selected, color_highlight, color_button_bg), color_button_bg_inactive)
        
        update_ui_image(x + 5, y + 3, atlas_icons.column_save, num_col, 0)

        local _, text_name_height = update_ui_get_text_size(text_name, w - 25, 0)
        local _, text_time_height = update_ui_get_text_size(text_time, w - 25, 0)
        render_button_bg_outline(x + 2, y, w - 4, text_name_height + text_time_height + 5, back_col)

        update_ui_text(x + 15, y + 3, text_name, w - 25, 0, text_col, 0)
        y = y + text_name_height + 3
        
        update_ui_image(x + 5, y, atlas_icons.column_time, num_col, 0)
        update_ui_text(x + 15, y, text_time, w - 25, 0, time_col, 0)
        y = y + text_time_height + 2

        local is_hovered = self:hoverable(x, window.cy, w, y - window.cy, true)

        window.cy = y + 2

        local is_action = false

        if is_selected and is_active then
            local is_clicked = is_hovered and self.input_pointer_1

            if is_hovered or update_get_active_input_type() == e_active_input.gamepad then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
            end

            if self.input_action or is_clicked then
                is_action = true
                self.input_action = false
                self.input_pointer_1 = false
            end
        end

        return is_action
    end,
    
    mod_details = function(self, name, author, is_enabled)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = window.is_active
        local is_selected = window.selected_index_y == window.index_y and window.is_selection_enabled

        local text_name = name
        local text_desc = author

        local text_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)
        local icon_col = iff(is_active, iff(is_selected, color_grey_dark, color_grey_dark), color_grey_dark)
        local desc_col = iff(is_active, iff(is_selected, color_grey_mid, color_grey_dark), color_grey_dark)
        local back_col = iff(is_active, iff(is_selected, color_highlight, color_button_bg), color_button_bg_inactive)
        local check_col = iff(is_active, iff(is_enabled, color_status_ok, color_status_bad), iff(is_enabled, color_status_dark_green, color_status_dark_red))

        local check_w = 16
        local check_h = 10
        local left_w = w - check_w - 4
        local right_w = w - left_w - 2
        update_ui_image(x + 5, y + 3, atlas_icons.column_repair, icon_col, 0)

        local _, text_name_height = update_ui_get_text_size(text_name, left_w - 25, 0)
        local _, text_desc_height = update_ui_get_text_size(text_desc, left_w - 25, 0)
        render_button_bg_outline(x + 2, y, w - 4, text_name_height + text_desc_height + 5, back_col)

        update_ui_text(x + 15, y + 3, text_name, left_w - 25, 0, text_col, 0)

        if is_enabled then
            render_button_bg(x + left_w + 2 + check_w - check_h, y + 5, check_h - 4, check_h - 4, check_col, 1)
        else
            render_button_bg(x + left_w + 2, y + 5, check_h - 4, check_h - 4, check_col, 1)
        end

        render_button_bg_outline(x + left_w, y + 3, check_w, check_h, color_grey_dark, 2)

        y = y + text_name_height + 3

        update_ui_image(x + 5, y, atlas_icons.column_profile, icon_col, 0)
        update_ui_text(x + 15, y, text_desc, left_w - 25, 0, desc_col, 0)
        y = y + text_desc_height + 2

        local is_hovered = self:hoverable(x, window.cy, w, y - window.cy, true)

        window.cy = y + 2

        local is_action = false

        if is_selected and is_active then
            local is_clicked = is_hovered and self.input_pointer_1

            if is_hovered or update_get_active_input_type() == e_active_input.gamepad then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
            end

            if self.input_action or is_clicked then
                is_action = true
                self.input_action = false
                self.input_pointer_1 = false
            end
        end

        return is_action
    end,
    
    server_details = function(self, name, player_count, max_players, is_password, status, version, latency, is_modded)
        local window = self:get_window()
        local x = window.cx
        local y = window.cy
        local w, h = self:get_region()
        local is_active = window.is_active
        local is_selected = window.selected_index_y == window.index_y and window.is_selection_enabled

        local text_name = name
        local text_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)
        local icon_col = iff(status == 0, color_status_ok, color_status_bad)
        local back_col = iff(is_active, iff(is_selected, color_highlight, color_button_bg), color_button_bg_inactive)
        local detail_col = iff(is_active, iff(is_selected, color_grey_mid, color_grey_dark), color_grey_dark)
        local version_col = iff(version == update_get_version(), detail_col, color_status_bad)

        if version ~= update_get_version() then
            back_col = iff(is_selected, color_grey_dark, color_button_bg_inactive)
        end

        local left_w = w - 2
        update_ui_image(x + 5, y + 3, atlas_icons.column_controlling_peer, icon_col, 0)

        local _, text_name_height = update_ui_get_text_size(text_name, left_w - 25, 0)
        render_button_bg_outline(x + 2, y, w - 4, text_name_height + 15, back_col)

        update_ui_text(x + 15, y + 3, text_name, left_w - 25, 0, text_col, 0)
        y = y + text_name_height + 3

        local cx = x + 5
        local column_w = 70
        update_ui_image(cx, y, atlas_icons.column_pending, color_grey_dark, 0)
        update_ui_text(cx + 10, y, version, left_w - 25, 0, version_col, 0)
        cx = cx + column_w

        update_ui_image(cx, y, atlas_icons.column_profile, color_grey_dark, 0)
        update_ui_text(cx + 10, y, player_count .. "/" .. max_players, left_w - 25, 0, iff(player_count > 0, color_status_ok, color_grey_dark), 0)
        cx = cx + column_w

        update_ui_image(cx, y, atlas_icons.column_propulsion, color_grey_dark, 0)
        update_ui_text(cx + 10, y, math.min(latency, 9999) .. update_get_loc(e_loc.acronym_milliseconds), left_w - 25, 0, iff(latency < 100, color_status_ok, color_status_bad), 0)

        cx = w - 12
        if is_password then
            update_ui_image(cx, y, atlas_icons.column_locked, color_status_bad, 0)
            cx = cx - 10
        end

        if is_modded then
            update_ui_image(cx, y, atlas_icons.column_repair, color_status_warning, 0)
            cx = cx - 10
        end

        y = y + 10 + 2

        local is_hovered = self:hoverable(x, window.cy, w, y - window.cy, true)

        window.cy = y + 2

        local is_action = false

        if is_selected and is_active and version == update_get_version() then
            local is_clicked = is_hovered and self.input_pointer_1

            if is_hovered or update_get_active_input_type() == e_active_input.gamepad then
                update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
            end

            if self.input_action or is_clicked then
                is_action = true
                self.input_action = false
                self.input_pointer_1 = false
            end
        end

        return is_action
    end,
}

function update_ui_rectangle_outline(x, y, w, h, color)
    update_ui_rectangle(x, y, w, 1, color)
    update_ui_rectangle(x, y + 1, 1, h - 2, color)
    update_ui_rectangle(x + w - 1, y + 1, 1, h - 2, color)
    update_ui_rectangle(x, y + h - 1, w, 1, color)
end

function update_ui_circle(x, y, rad, steps, col)
    local step = math.pi * 2 / steps
    
    update_ui_push_offset(x, y)
    update_ui_begin_triangles()

    for i = 0, steps - 1 do
        local angle = i * step
        local angle_next = angle + step

        update_ui_add_triangle(
            vec2(0, 0),
            vec2(math.cos(angle) * rad, math.sin(angle) * rad),
            vec2(math.cos(angle_next) * rad, math.sin(angle_next) * rad),
            col
        )
    end

    update_ui_end_triangles()
    update_ui_pop_offset()
end

function gamma_correct(col)
    local pow = 2.2
    return color8(math.min(math.floor((col:r() / 255) ^ pow * 255), 255), math.min(math.floor((col:g() / 255) ^ pow * 255), 255), math.min(math.floor((col:b() / 255) ^ pow * 255), 255), col:a())
end

function get_gamepad_button_icon(index)
    local icons = {
        [-1] = { icon = atlas_icons.hud_warning, color = color_white },
        [0] = { icon = atlas_icons.gamepad_icon_a, color = color8(8, 255, 8, 255) },
        [1] = { icon = atlas_icons.gamepad_icon_b, color = color8(255, 8, 8, 255) },
        [2] = { icon = atlas_icons.gamepad_icon_x, color = color8(8, 64, 255, 255) },
        [3] = { icon = atlas_icons.gamepad_icon_y, color = color8(255, 255, 8, 255) },
        [4] = { icon = atlas_icons.gamepad_icon_lb },
        [5] = { icon = atlas_icons.gamepad_icon_rb },
        [6] = { icon = atlas_icons.gamepad_icon_back },
        [7] = { icon = atlas_icons.gamepad_icon_start },
        [8] = nil,
        [9] = { icon = atlas_icons.gamepad_icon_ls },
        [10] = { icon = atlas_icons.gamepad_icon_rs },
        [11] = { icon = atlas_icons.gamepad_icon_dpad_up },
        [12] = { icon = atlas_icons.gamepad_icon_dpad_right },
        [13] = { icon = atlas_icons.gamepad_icon_dpad_down },
        [14] = { icon = atlas_icons.gamepad_icon_dpad_left },
    }

    local icon = icons[index] or icons[-1]

    return icon.icon, (icon.color or color_white)
end

function get_gamepad_axis_icon(index)
    local icons = {
        [-1] = { icon = atlas_icons.hud_warning, color = color_white },
        [0] = { icon = atlas_icons.gamepad_icon_special_ls_lr },
        [1] = { icon = atlas_icons.gamepad_icon_special_ls_ud },
        [2] = { icon = atlas_icons.gamepad_icon_special_rs_lr },
        [3] = { icon = atlas_icons.gamepad_icon_special_rs_ud },
        [4] = { icon = atlas_icons.gamepad_icon_lt },
        [5] = { icon = atlas_icons.gamepad_icon_rt },
    }

    local icon = icons[index] or icons[-1]

    return icon.icon, (icon.color or color_white)
end

function get_joystick_button_icon(index)
    local icons = {
        [-1] = { icon = atlas_icons.hud_warning, color = color_white },
        [0] = { icon = atlas_icons.joystick_icon_b1 },
        [1] = { icon = atlas_icons.joystick_icon_b2 },
        [2] = { icon = atlas_icons.joystick_icon_b3 },
        [3] = { icon = atlas_icons.joystick_icon_b4 },
        [4] = { icon = atlas_icons.joystick_icon_b5 },
        [5] = { icon = atlas_icons.joystick_icon_b6 },
        [6] = { icon = atlas_icons.joystick_icon_b7 },
        [7] = { icon = atlas_icons.joystick_icon_b8 },
        [8] = { icon = atlas_icons.joystick_icon_b9 },
        [9] = { icon = atlas_icons.joystick_icon_b10 },
        [10] = { icon = atlas_icons.joystick_icon_b11 },
        [11] = { icon = atlas_icons.joystick_icon_b12 },
        [12] = { icon = atlas_icons.joystick_icon_b13 },
        [13] = { icon = atlas_icons.joystick_icon_b14 },
        [14] = { icon = atlas_icons.joystick_icon_b15 },
        [15] = { icon = atlas_icons.joystick_icon_b16 },
        [16] = { icon = atlas_icons.joystick_icon_b17 },
        [17] = { icon = atlas_icons.joystick_icon_b18 },
        [18] = { icon = atlas_icons.joystick_icon_b19 },
        [19] = { icon = atlas_icons.joystick_icon_b20 },
        [20] = { icon = atlas_icons.joystick_icon_b21 },
        [21] = { icon = atlas_icons.joystick_icon_b22 },
        [22] = { icon = atlas_icons.joystick_icon_b23 },
        [23] = { icon = atlas_icons.joystick_icon_b24 },
        [24] = { icon = atlas_icons.joystick_icon_b25 },
        [25] = { icon = atlas_icons.joystick_icon_b26 },
        [26] = { icon = atlas_icons.joystick_icon_b27 },
        [27] = { icon = atlas_icons.joystick_icon_b28 },
        [28] = { icon = atlas_icons.joystick_icon_b29 },
        [29] = { icon = atlas_icons.joystick_icon_b30 },
        [30] = { icon = atlas_icons.joystick_icon_b31 },
        [31] = { icon = atlas_icons.joystick_icon_b32 },
        [32] = { icon = atlas_icons.joystick_icon_b33 },
        [33] = { icon = atlas_icons.joystick_icon_b34 },
        [34] = { icon = atlas_icons.joystick_icon_b35 },
        [35] = { icon = atlas_icons.joystick_icon_b36 },
        [36] = { icon = atlas_icons.joystick_icon_b37 },
        [37] = { icon = atlas_icons.joystick_icon_b38 },
        [38] = { icon = atlas_icons.joystick_icon_b39 },
        [39] = { icon = atlas_icons.joystick_icon_b40 },
        [40] = { icon = atlas_icons.joystick_icon_b41 },
        [41] = { icon = atlas_icons.joystick_icon_b42 },
        [42] = { icon = atlas_icons.joystick_icon_b43 },
        [43] = { icon = atlas_icons.joystick_icon_b44 },
        [44] = { icon = atlas_icons.joystick_icon_b45 },
        [45] = { icon = atlas_icons.joystick_icon_b46 },
        [46] = { icon = atlas_icons.joystick_icon_b47 },
        [47] = { icon = atlas_icons.joystick_icon_b48 },
    }

    local icon = icons[index] or icons[-1]
    return icon.icon, (icon.color or color_grey_mid)
end

function get_joystick_axis_icon(index)
    local icons = {
        [-1] = { icon = atlas_icons.hud_warning, color = color_white },
        [0] = { icon = atlas_icons.joystick_icon_a1 },
        [1] = { icon = atlas_icons.joystick_icon_a2 },
        [2] = { icon = atlas_icons.joystick_icon_a3 },
        [3] = { icon = atlas_icons.joystick_icon_a4 },
        [4] = { icon = atlas_icons.joystick_icon_a5 },
        [5] = { icon = atlas_icons.joystick_icon_a6 },
        [6] = { icon = atlas_icons.joystick_icon_a7 },
        [7] = { icon = atlas_icons.joystick_icon_a8 },
    }

    local icon = icons[index] or icons[-1]
    return icon.icon, (icon.color or color_white)
end

function get_pointer_icon(index)
    local icons = {
        [-1] = { icon = atlas_icons.hud_warning, color = color_white },
        [0] = { icon = atlas_icons.mouse_icon_lmb },
        [1] = { icon = atlas_icons.mouse_icon_rmb },
        [2] = { icon = atlas_icons.mouse_icon_mmb },
    }

    local icon = icons[index] or icons[-1]

    return icon.icon, (icon.color or color_white)
end

function update_ui_event(command, ...)
    local args = {}
    table.insert(args, command)

    for k, v in ipairs({...}) do
        if type(v) == "string" then
            table.insert(args, "\"" .. tostring(v) .. "\"")
        else
            table.insert(args, tostring(v))
        end
    end

    callback_script_event(table.concat(args, " "))
end

function imgui_options_menu(ui, x, y, w, h, is_active, selected_category_index, is_highlight)
    local settings = update_get_game_settings()
    local rebinding_keyboard = update_get_rebinding_keyboard()
    local rebinding_gamepad = update_get_rebinding_gamepad()
    local input_count = update_get_game_input_count()
    local window_label_bias = 0.55

    if rebinding_keyboard ~= -1 then
        local window = ui:begin_window(update_get_loc(e_loc.rebind), x, y, w, h, nil, is_active, 0, true, is_highlight)
            ui:text(update_get_loc(e_loc.rebind).." "..update_get_game_input_name(rebinding_keyboard))
            ui:divider()
            ui:text_basic(update_get_loc(e_loc.press_key_to_bind))
            ui:divider(5, 5)

            local cx = window.cx + 5

            if update_get_active_input_type() == e_active_input.keyboard then
                cx = cx + imgui_render_key_icon(cx, window.cy, update_get_key_name(259)) + 5
            elseif update_get_active_input_type() == e_active_input.gamepad then
                update_ui_image(cx, window.cy, atlas_icons.gamepad_icon_start, color_white, 0)
                cx = cx + 15
            end

            update_ui_text(cx, window.cy, update_get_loc(e_loc.esc_to_cancel), w - cx - 5, 0, color_grey_dark, 0)
        ui:end_window()
    elseif rebinding_gamepad ~= -1 then
        local window = ui:begin_window(update_get_loc(e_loc.rebind), x, y, w, h, nil, is_active, 0, true, is_highlight)
            ui:text(update_get_loc(e_loc.rebind).." "..update_get_game_input_name(rebinding_gamepad))
            ui:divider()
            ui:text_basic(update_get_loc(e_loc.press_key_to_bind))
            ui:divider(5, 5)

            local cx = window.cx + 5

            if update_get_active_input_type() == e_active_input.keyboard then
                cx = cx + imgui_render_key_icon(cx, window.cy, update_get_key_name(259)) + 5
            elseif update_get_active_input_type() == e_active_input.gamepad then
                update_ui_image(cx, window.cy, atlas_icons.gamepad_icon_start, color_white, 0)
                cx = cx + 15
            end

            update_ui_text(cx, window.cy, update_get_loc(e_loc.esc_to_cancel), w - cx - 5, 0, color_grey_dark, 0)
        ui:end_window()
    elseif selected_category_index == 0 then
        local window = ui:begin_window(update_get_loc(e_loc.upp_graphics), x, y, w, h, nil, is_active, 0, true, is_highlight)
            window.label_bias = window_label_bias

            ui:header(update_get_loc(e_loc.upp_quality))
            settings.gfx_lights                     = ui:combo(update_get_loc(e_loc.lights), settings.gfx_lights, { update_get_loc(e_loc.low), update_get_loc(e_loc.med), update_get_loc(e_loc.high) })
            settings.gfx_main_shadows               = ui:combo(update_get_loc(e_loc.main_shadow), settings.gfx_main_shadows, { update_get_loc(e_loc.off), update_get_loc(e_loc.low), update_get_loc(e_loc.med), update_get_loc(e_loc.high), update_get_loc(e_loc.ultra) })
            settings.gfx_spotlight_shadows          = ui:combo(update_get_loc(e_loc.spot_shadow), settings.gfx_spotlight_shadows, { update_get_loc(e_loc.off), update_get_loc(e_loc.low), update_get_loc(e_loc.med), update_get_loc(e_loc.high), update_get_loc(e_loc.ultra) })
            settings.gfx_trees                      = ui:combo(update_get_loc(e_loc.trees), settings.gfx_trees, { update_get_loc(e_loc.low), update_get_loc(e_loc.med), update_get_loc(e_loc.high), update_get_loc(e_loc.ultra) })
            settings.gfx_ocean_foam                 = ui:checkbox(update_get_loc(e_loc.ocean_foam), settings.gfx_ocean_foam )
            settings.gfx_screen_lights              = ui:checkbox(update_get_loc(e_loc.screen_glow), settings.gfx_screen_lights )
            settings.gfx_bloom                      = ui:slider(update_get_loc(e_loc.bloom), settings.gfx_bloom, 0, 2)
            settings.gfx_antialiasing               = ui:checkbox(update_get_loc(e_loc.antialiasing), settings.gfx_antialiasing )
            ui:header(update_get_loc(e_loc.upp_display))
            
            local resolution_options = update_get_gfx_resolution_modes()

            local resolution_combo_options = {}
            local resolution_selected_index = 0

            for i = 1, #resolution_options do
                table.insert(resolution_combo_options, resolution_options[i].x .. "x" .. resolution_options[i].y)

                if resolution_options[i].x == settings.gfx_resolution_pending_x and resolution_options[i].y == settings.gfx_resolution_pending_y then
                    resolution_selected_index = i - 1
                end
            end

            if update_get_is_vr() == false then
                resolution_selected_index           = ui:combo(update_get_loc(e_loc.resolution), resolution_selected_index, resolution_combo_options)
                
                settings.gfx_resolution_pending_x = resolution_options[resolution_selected_index + 1].x
                settings.gfx_resolution_pending_y = resolution_options[resolution_selected_index + 1].y

                if ui:button(update_get_loc(e_loc.upp_apply), settings.gfx_resolution_pending_x ~= settings.gfx_resolution_x or settings.gfx_resolution_pending_y ~= settings.gfx_resolution_y) then
                    update_ui_event("set_game_setting gfx_resolution apply")
                end
                
                ui:divider()
            end
            
            settings.gfx_vsync                      = ui:checkbox(update_get_loc(e_loc.vsync), settings.gfx_vsync)

            if update_get_is_vr() == false then
                settings.gfx_fullscreen                 = ui:checkbox(update_get_loc(e_loc.fullscreen), settings.gfx_fullscreen)
            end

            settings.gfx_gamma                      = ui:slider(update_get_loc(e_loc.gamma), settings.gfx_gamma, -1, 1)
            
            if update_get_is_vr() == false then
                settings.gfx_fov                        = ui:slider(update_get_loc(e_loc.fov), settings.gfx_fov, 0.75, 1.15, 0.05)
            end
            
            settings.gfx_screen_shake               = ui:slider(update_get_loc(e_loc.screen_shake), settings.gfx_screen_shake, 0.0, 1.0)
        ui:end_window()
    elseif selected_category_index == 1 then
        local window = ui:begin_window(update_get_loc(e_loc.upp_audio), x, y, w, h, nil, is_active, 0, true, is_highlight)
            window.label_bias = window_label_bias

            ui:header(update_get_loc(e_loc.upp_volume))
            settings.audio_mute                     = ui:checkbox(update_get_loc(e_loc.mute), settings.audio_mute)
            settings.audio_volume_master            = ui:slider(update_get_loc(e_loc.master), settings.audio_volume_master, 0, 1)
            ui:divider()
            settings.audio_volume_sfx               = ui:slider(update_get_loc(e_loc.sfx), settings.audio_volume_sfx, 0, 1)
            settings.audio_volume_voice             = ui:slider(update_get_loc(e_loc.voice), settings.audio_volume_voice, 0, 1)
            settings.audio_volume_music             = ui:slider(update_get_loc(e_loc.music), settings.audio_volume_music, 0, 1)
            settings.audio_volume_ui                = ui:slider(update_get_loc(e_loc.ui), settings.audio_volume_ui, 0, 1)
            settings.audio_volume_ambience          = ui:slider(update_get_loc(e_loc.ambience), settings.audio_volume_ambience, 0, 1)
        ui:end_window()
    elseif selected_category_index == 2 then
        local window = ui:begin_window(update_get_loc(e_loc.upp_ui), x, y, w, h, nil, is_active, 0, true, is_highlight)
            window.label_bias = window_label_bias

            ui:header(update_get_loc(e_loc.upp_accessibility))
            if update_get_is_vr() == false then
                settings.ui_scale                   = ui:combo(update_get_loc(e_loc.ui_scale), settings.ui_scale - 1, { "0.5x", "1x", "1.5x", "2x" }) + 1
            end
            settings.ui_show_highlights             = ui:checkbox(update_get_loc(e_loc.interaction_highlight), settings.ui_show_highlights)

            if update_get_is_vr() == false then
                ui:header(update_get_loc(e_loc.hud))
                settings.ui_show_control_hints          = ui:checkbox(update_get_loc(e_loc.controls), settings.ui_show_control_hints)
                settings.ui_show_subtitles              = ui:checkbox(update_get_loc(e_loc.subtitles), settings.ui_show_subtitles)
                settings.ui_show_tooltips               = ui:checkbox(update_get_loc(e_loc.tooltips), settings.ui_show_tooltips)
                settings.ui_show_voice_chat_self        = ui:checkbox(update_get_loc(e_loc.voice_indicator), settings.ui_show_voice_chat_self)
                settings.ui_show_voice_chat_others      = ui:checkbox(update_get_loc(e_loc.team_voice_indicators), settings.ui_show_voice_chat_others)
                
                ui:header(update_get_loc(e_loc.upp_vehicle_hud))
                settings.ui_show_mouse_joystick_on_hud  = ui:checkbox(update_get_loc(e_loc.ui_show_mouse_joystick_on_hud), settings.ui_show_mouse_joystick_on_hud)
            end
        ui:end_window()
    elseif selected_category_index == 3 then
        if update_get_is_vr() then
            local window = ui:begin_window(update_get_loc(e_loc.upp_vr), x, y, w, h, nil, is_active, 0, true, is_highlight)
                window.label_bias = window_label_bias

                settings.vr_world_scale                 = ui:slider(update_get_loc(e_loc.vr_world_scale), settings.vr_world_scale, 0.5, 2, 0.1)
                settings.vr_tablet_index                = ui:combo(update_get_loc(e_loc.vr_tablet_index), settings.vr_tablet_index, { "1", "2" })
                settings.vr_controller_tooltips         = ui:checkbox(update_get_loc(e_loc.vr_controller_tooltips), settings.vr_controller_tooltips)
                settings.vr_screen_tilt                 = ui:checkbox(update_get_loc(e_loc.vr_screen_tilt), settings.vr_screen_tilt)
                settings.vr_move_mode                   = ui:combo(update_get_loc(e_loc.vr_move_mode), settings.vr_move_mode, { update_get_loc(e_loc.vr_move_mode_teleport), update_get_loc(e_loc.vr_move_mode_smooth) })
                settings.vr_smooth_move_speed           = ui:slider(update_get_loc(e_loc.vr_smooth_move_speed), settings.vr_smooth_move_speed, 0.5, 2, 0.1)
                settings.vr_smooth_rotate_speed         = ui:slider(update_get_loc(e_loc.vr_smooth_rotate_speed), settings.vr_smooth_rotate_speed, 0.5, 2, 0.1)
            ui:end_window()
        else
            local window = ui:begin_window(update_get_loc(e_loc.upp_settings_gameplay), x, y, w, h, nil, is_active, 0, true, is_highlight)
                window.label_bias = window_label_bias

                settings.gameplay_lock_camera_to_horizon    = ui:checkbox(update_get_loc(e_loc.eyes_level_with_horizon), settings.gameplay_lock_camera_to_horizon)
            ui:end_window()
            end
    elseif selected_category_index == 4 then
        local window = ui:begin_window(update_get_loc(e_loc.upp_keyboard), x, y, w, h, nil, is_active, 0, true, is_highlight)
            window.label_bias = window_label_bias

            settings.keyboard_back_opens_pause      = ui:checkbox(update_get_loc(e_loc.BACK_opens_pause_menu), settings.keyboard_back_opens_pause)

            ui:header(update_get_loc(e_loc.upp_bindings_keys))

            if ui:button(update_get_loc(e_loc.upp_reset), true, 1) then
                update_ui_event("rebind_input keyboard reset")
            end
            
            local category_inputs = {}
            
            for i = 0, input_count - 1 do
                if update_get_is_input_rebindable_keyboard(i) then
                    local category = update_get_game_input_category(i)
                    if category_inputs[category] == nil then category_inputs[category] = {} end
                    table.insert(category_inputs[category], i)
                end
            end

            local categories = {}
            for k, _ in pairs(category_inputs) do table.insert(categories, k) end
            table.sort(categories)

            for _, v in ipairs(categories) do
                local inputs = category_inputs[v]
                ui:header(update_get_input_category_name(v))

                for i = 1, #inputs do
                    local input = inputs[i]

                    if ui:keybinding(update_get_game_input_name(input), update_get_input_binding_keyboard_key(input), update_get_input_binding_keyboard_pointer(input), -1, -1, -1, -1, "", false) then
                        update_ui_event("rebind_input keyboard " .. input)
                    end
                    ui:divider()
                end
            end
        ui:end_window()
    elseif selected_category_index == 5 then
        local window = ui:begin_window(update_get_loc(e_loc.upp_mouse), x, y, w, h, nil, is_active, 0, true, is_highlight)
            window.label_bias = window_label_bias

            ui:header(update_get_loc(e_loc.upp_sensitivity))
            settings.mouse_sensitivity_x            = ui:slider(update_get_loc(e_loc.horizontal), settings.mouse_sensitivity_x, 0.5, 4, 0.25)
            settings.mouse_sensitivity_y            = ui:slider(update_get_loc(e_loc.vertical), settings.mouse_sensitivity_y, 0.5, 4, 0.25)
            ui:header(update_get_loc(e_loc.upp_invert))
            settings.mouse_inv_x                    = ui:checkbox(update_get_loc(e_loc.horizontal), settings.mouse_inv_x)
            settings.mouse_inv_y                    = ui:checkbox(update_get_loc(e_loc.vertical), settings.mouse_inv_y)
            ui:header(update_get_loc(e_loc.upp_mouse_flight))
            settings.mouse_flight_mode              = ui:combo(update_get_loc(e_loc.mouse_flight_mode), settings.mouse_flight_mode, { update_get_loc(e_loc.mouse_flight_mode_disabled), update_get_loc(e_loc.mouse_flight_mode_roll_pitch), update_get_loc(e_loc.mouse_flight_mode_yaw_pitch) })

            if settings.mouse_flight_mode ~= e_mouse_flight_mode.disabled then
                settings.mouse_joystick_mode        = ui:combo(update_get_loc(e_loc.mouse_joystick_mode), settings.mouse_joystick_mode, { update_get_loc(e_loc.mouse_joystick_mode_motion), update_get_loc(e_loc.mouse_joystick_mode_offset) })

                local axis_names = { 
                    [0] = { x = "X", y = "Y" },
                    [1] = { 
                        x = update_get_loc(e_loc.mouse_flight_sensitivity_roll),
                        y = update_get_loc(e_loc.mouse_flight_sensitivity_pitch)
                    },
                    [2] = {
                        x = update_get_loc(e_loc.mouse_flight_sensitivity_yaw),
                        y = update_get_loc(e_loc.mouse_flight_sensitivity_pitch)
                    }
                }

                if settings.mouse_joystick_mode == e_mouse_joystick_mode.motion then
                    ui:header(update_get_loc(e_loc.upp_mouse_flight_sensitivity))
                    settings.mouse_flight_sensitivity_x = ui:slider(axis_names[settings.mouse_flight_mode].x, settings.mouse_flight_sensitivity_x, 0.5, 4, 0.25)
                    settings.mouse_flight_sensitivity_y = ui:slider(axis_names[settings.mouse_flight_mode].y, settings.mouse_flight_sensitivity_y, 0.5, 4, 0.25)
                end

                ui:header(update_get_loc(e_loc.upp_mouse_flight_invert))
                settings.mouse_flight_inv_x         = ui:checkbox(axis_names[settings.mouse_flight_mode].x, settings.mouse_flight_inv_x)
                settings.mouse_flight_inv_y         = ui:checkbox(axis_names[settings.mouse_flight_mode].y, settings.mouse_flight_inv_y)
            end
        ui:end_window()
    elseif selected_category_index == 6 then
        local window = ui:begin_window(update_get_loc(e_loc.upp_gamepad), x, y, w, h, nil, is_active, 0, true, is_highlight)
            window.label_bias = window_label_bias
            
            ui:header(update_get_loc(e_loc.upp_sensitivity))
            settings.gamepad_sensitivity_x          = ui:slider(update_get_loc(e_loc.horizontal), settings.gamepad_sensitivity_x, 0.2, 2, 0.1)
            settings.gamepad_sensitivity_y          = ui:slider(update_get_loc(e_loc.vertical), settings.gamepad_sensitivity_y, 0.2, 2, 0.1)
            ui:header(update_get_loc(e_loc.upp_flight_invert))
            settings.gamepad_flight_inv_x           = ui:checkbox(update_get_loc(e_loc.horizontal), settings.gamepad_flight_inv_x)
            settings.gamepad_flight_inv_y           = ui:checkbox(update_get_loc(e_loc.vertical), settings.gamepad_flight_inv_y)

            local throttle_modes = { update_get_loc(e_loc.vehicle_throttle_mode_relative), update_get_loc(e_loc.vehicle_throttle_mode_absolute), }

            ui:header(update_get_loc(e_loc.upp_vehicle_throttle_mode))
            settings.gamepad_vehicle_throttle_mode_air      = ui:combo(update_get_loc(e_loc.vehicle_throttle_mode_air), settings.gamepad_vehicle_throttle_mode_air, throttle_modes)
            settings.gamepad_vehicle_throttle_mode_ground   = ui:combo(update_get_loc(e_loc.vehicle_throttle_mode_ground), settings.gamepad_vehicle_throttle_mode_ground, throttle_modes)
            ui:header(update_get_loc(e_loc.upp_bindings_buttons))
            
            if ui:button(update_get_loc(e_loc.upp_reset), true, 1) then
                update_ui_event("rebind_input gamepad reset")
            end
            
            local category_inputs = {}
            
            for i = 0, input_count - 1 do
                if update_get_is_input_rebindable_gamepad(i) or update_get_is_input_rebindable_gamepad_as_axis(i) then
                    local category = update_get_game_input_category(i)
                    if category_inputs[category] == nil then category_inputs[category] = {} end
                    table.insert(category_inputs[category], i)
                end
            end

            local categories = {}
            for k, _ in pairs(category_inputs) do table.insert(categories, k) end
            table.sort(categories)

            for _, v in ipairs(categories) do
                local inputs = category_inputs[v]

                table.sort(inputs, function(a, b)
                    if update_get_is_input_rebindable_gamepad_as_axis(a) == update_get_is_input_rebindable_gamepad_as_axis(b) then
                        return a < b
                    end

                    return update_get_is_input_rebindable_gamepad_as_axis(b)
                end)

                ui:header(update_get_input_category_name(v))

                for i = 1, #inputs do
                    local input = inputs[i]

                    if update_get_is_input_rebindable_gamepad_as_axis(input) then
                        imgui_gamepad_axis_binding(ui, input)
                        ui:divider()
                    else
                        if ui:keybinding(update_get_game_input_name(input), -1, -1, update_get_input_binding_gamepad_button(input), update_get_input_binding_gamepad_axis(input), update_get_input_binding_joystick_button(input), update_get_input_binding_joystick_axis(input), update_get_input_binding_joystick_name(input), update_get_input_binding_joystick_connected(input)) then
                            update_ui_event("rebind_input gamepad " .. input)
                        end
                        ui:divider()
                    end
                end
            end
        ui:end_window()
    end

    local settings_prev = update_get_game_settings()

    for k, v in pairs(settings) do
        if v ~= settings_prev[k] and type(v) ~= "userdata" then
            update_ui_event("set_game_setting", k, v)
        end
    end

    if settings.gfx_resolution_pending_x ~= settings_prev.gfx_resolution_pending_x or settings.gfx_resolution_pending_y ~= settings_prev.gfx_resolution_pending_y then
        update_ui_event("set_game_setting gfx_resolution", settings.gfx_resolution_pending_x, settings.gfx_resolution_pending_y)
    end
end

function imgui_gamepad_axis_binding(ui, input)
    local gamepad_axis_icons = {
        [0] = atlas_icons.gamepad_icon_special_ls_lr,
        [1] = atlas_icons.gamepad_icon_special_ls_ud,
        [2] = atlas_icons.gamepad_icon_special_rs_lr,
        [3] = atlas_icons.gamepad_icon_special_rs_ud,
    }

    local joystick_axis_icons = {
        [0] = atlas_icons.joystick_icon_a1,
        [1] = atlas_icons.joystick_icon_a2,
        [2] = atlas_icons.joystick_icon_a3,
        [3] = atlas_icons.joystick_icon_a4,
        [4] = atlas_icons.joystick_icon_a5,
        [5] = atlas_icons.joystick_icon_a6,
        [6] = atlas_icons.joystick_icon_a7,
        [7] = atlas_icons.joystick_icon_a8,
    }

    local axis_options = {
        { axis=0, icon=gamepad_axis_icons[0] },
        { axis=1, icon=gamepad_axis_icons[1] },
        { axis=2, icon=gamepad_axis_icons[2] },
        { axis=3, icon=gamepad_axis_icons[3] },
    }

    for i = 0, 7 do
        if update_get_input_joystick_connected(i) then
            for j = 0, update_get_input_joystick_axis_count(i) - 1 do
                table.insert(axis_options, {
                    axis=j,
                    icon=joystick_axis_icons[j],
                    joystick=i,
                    guid=update_get_input_joystick_guid(i),
                    name=update_get_input_joystick_name(i)
                })
            end
        end
    end

    local axis = update_get_input_binding_gamepad_axis(input)
    local joy_axis = update_get_input_binding_joystick_axis(input)
    local joy_guid = update_get_input_binding_joystick_guid(input)
    local selected_index = -1

    for i = 1, #axis_options do
        if #joy_guid > 0 then
            if axis_options[i].guid == joy_guid and axis_options[i].axis == joy_axis then
                selected_index = i - 1
                break
            end
        elseif axis_options[i].axis == axis then
            selected_index = i - 1
            break
        end
    end

    if selected_index == -1 then
        -- joystick not connected

        if #joy_guid > 0 then
            table.insert(axis_options, {
                axis=joy_axis,
                icon=joystick_axis_icons[joy_axis],
                joystick=-1,
                guid=joy_guid,
                name=update_get_input_binding_joystick_name(input),
            })
            selected_index = #axis_options - 1
        elseif axis >= 0 then
            table.insert(axis_options, {
                axis=axis,
                icon=gamepad_axis_icons[axis],
            })
            selected_index = #axis_options - 1
        end
    end

    ui:spacer(2)

    selected_index, is_modified = ui:combo(update_get_game_input_name(input), selected_index, axis_options, true, function(item, w, h)
        if item == nil or item.icon == nil then
            update_ui_text(0, 0, "---", w, 1, color_grey_dark, 0)
            return
        end

        update_ui_image(2, 0, item.icon, color_white, 0)
        local axis_value = 0

        if item.joystick == nil then
            axis_value = clamp(update_get_input_gamepad_axis_value(item.axis), -1, 1)
        else
            axis_value = clamp(update_get_input_joystick_axis_value(item.joystick, item.axis), -1, 1)
        end

        local bar_x = 15
        local bar_w = w - 18

        if update_get_input_binding_is_axis_inverted(input) then
            update_ui_rectangle(bar_x, h / 2 - 1, bar_w, 2, color_grey_dark)
            update_ui_rectangle(bar_x + bar_w / 2, h / 2 - 1, math.floor(bar_w / 2 * axis_value + 0.5), 2, color8(255, 255, 255, 8))
            update_ui_rectangle(bar_x + bar_w / 2, h / 2 - 1, math.floor(bar_w / 2 * axis_value + 0.5) * -1, 2, color_highlight)
        else
            update_ui_rectangle(bar_x, h / 2 - 1, bar_w, 2, color_grey_dark)
            update_ui_rectangle(bar_x + bar_w / 2, h / 2 - 1, math.floor(bar_w / 2 * axis_value + 0.5), 2, color_highlight)
        end
    end)

    local is_ui_selected = ui:is_item_selected()
    local selected = axis_options[selected_index + 1]

    if selected ~= nil then
        if selected.joystick then
            local window = ui:get_window()
            local w, h = ui:get_region()
            update_ui_image(window.cx + w - 15, window.cy, atlas_icons.column_joystick, iff(update_get_input_binding_joystick_connected(input), color_status_ok, color_status_dark_red), 0)
            window.cy = window.cy + update_ui_text(window.cx + 5, window.cy, selected.name, w - 25, 0, iff(is_ui_selected, color_grey_mid, color_grey_dark), 0)
        end

        if is_modified then
            if selected.joystick == nil then
                update_ui_event("rebind_input_axis gamepad", input, selected.axis)
            else
                update_ui_event("rebind_input_axis joystick", input, selected.joystick, selected.axis)
            end
        end
    end

    local is_inverted = update_get_input_binding_is_axis_inverted(input)
    is_inverted, is_modified = ui:checkbox(update_get_loc(e_loc.input_invert), is_inverted)

    if is_modified then
        update_ui_event("rebind_input_axis invert", input, is_inverted)
    end
end

function imgui_character_options(ui, x, y, w, h, is_active)
    local settings = update_get_game_settings()
    local skin_color_options = update_get_skin_color_options()
    local hair_color_options = update_get_hair_color_options()

    ui:begin_window(update_get_loc(e_loc.upp_profile), x, y, w, h, atlas_icons.column_profile, is_active)
        ui:header(update_get_loc(e_loc.upp_body))
        settings.character_gender                   = ui:combo(update_get_loc(e_loc.gender), settings.character_gender, { update_get_loc(e_loc.male), update_get_loc(e_loc.female) })
        settings.character_skin_color               = ui:combo_color8(update_get_loc(e_loc.skin), settings.character_skin_color, skin_color_options, true)
        ui:header(update_get_loc(e_loc.upp_hair))
        settings.character_hair_type                = ui:combo(update_get_loc(e_loc.type), settings.character_hair_type, { "A", "B", "C", "D", "E", "F", "G", "H" })
        settings.character_hair_color               = ui:combo_color8(update_get_loc(e_loc.color), settings.character_hair_color, hair_color_options, true)

        if settings.character_gender == 0 then
            settings.character_facial_hair_type     = ui:combo(update_get_loc(e_loc.facial), settings.character_facial_hair_type + 1, { update_get_loc(e_loc.none), "A", "B", "C", "D", "E", "F", "G", "H" })
            settings.character_facial_hair_type = settings.character_facial_hair_type - 1
        end
    ui:end_window()

    local settings_prev = update_get_game_settings()

    for k, v in pairs(settings) do
        if v ~= settings_prev[k] and type(v) ~= "userdata" then
            update_ui_event("set_game_setting", k, v)
        end
    end

    if color8_eq(settings.character_skin_color, settings_prev.character_skin_color) == false then
        update_ui_event("set_game_setting character_skin_color", settings.character_skin_color:r(), settings.character_skin_color:g(), settings.character_skin_color:b(), settings.character_skin_color:a()) 
    end
    
    if color8_eq(settings.character_hair_color, settings_prev.character_hair_color) == false then
        update_ui_event("set_game_setting character_hair_color", settings.character_hair_color:r(), settings.character_hair_color:g(), settings.character_hair_color:b(), settings.character_hair_color:a()) 
    end
end

function imgui_carrier_docking_bays(ui, carrier_vehicle, item_spacing, column_spacing, animation_tick)
    local window = ui:get_window()
    local w, h = ui:get_region()
    local is_active = window.is_active
    local selected_bay_index = -1
    local hovered_bay_index = -1

    local item_w = 22
    local item_h = 26
    local total_w = item_w * 4 + item_spacing * 2 + column_spacing
    local item_x = window.cx + (w - total_w) / 2

    local bay_indices_rows = {
        { 6, 7, 14, 15 },
        { 4, 5, 12, 13 },
        { 2, 3, 10, 11 },
        { 0, 1, 8, 9 },
    }

    local function render_bar(x, y, factor, color)
        local bar_h = math.floor(16 * factor + 0.5)
        update_ui_rectangle(x, y, 1, 16, color_grey_dark)
        update_ui_rectangle(x, y + 16 - bar_h, 1, bar_h, color)
    end

    local color_repair = color8(47, 116, 255, 255)
    local color_fuel = color8(119, 85, 161, 255)
    local color_ammo = color8(201, 171, 68, 255)
    local color_selected = color8(255, 16, 16, 255)

    for i = 1, #bay_indices_rows do
        ui:begin_nav_row()

        local x = item_x
        local y = window.cy
        local is_row_selected = window.selected_index_y == window.index_y
        
        for j = 1, #bay_indices_rows[i] do
            local bay_index = bay_indices_rows[i][j]

            local is_hovered, is_selected = ui:hoverable(x, y, item_w, item_h, true)
            is_selected = is_selected and update_get_is_focus_local()
            local repair_factor = 0
            local fuel_factor = 0
            local ammo_factor = 0
            local is_fuel_blocked = false
            local is_ammo_blocked = false
            local vehicle_definition_name = ""
            local region_vehicle_icon = nil
            local vehicle_color = color_grey_dark
            local bay_color = color_grey_dark

            local attached_vehicle_id = carrier_vehicle:get_attached_vehicle_id(bay_index)

            if attached_vehicle_id ~= 0 then
                local attached_vehicle = update_get_map_vehicle_by_id(attached_vehicle_id)

                if attached_vehicle:get() then
                    vehicle_definition_name, region_vehicle_icon = get_chassis_data_by_definition_index(attached_vehicle:get_definition_index())
                    repair_factor = attached_vehicle:get_repair_factor()
                    fuel_factor = attached_vehicle:get_fuel_factor()
                    ammo_factor = attached_vehicle:get_ammo_factor()
                    is_fuel_blocked = attached_vehicle:get_is_fuel_blocked()
                    is_ammo_blocked = attached_vehicle:get_is_ammo_blocked()
                    vehicle_color = iff(is_fuel_blocked or is_ammo_blocked, color_grey_dark, iff(is_selected, color_selected, color_white))
                    bay_color = color_white

                    if attached_vehicle:get_dock_state() ~= 4 then
                        if animation_tick % 20 > 10 then
                            vehicle_color = color_highlight
                        end
                    end
                end
            end
            
            bay_color = iff(is_selected, color_selected, bay_color)

            local function render_bay_icon(x, y)
                update_ui_push_offset(x, y)
                update_ui_image(0, 0, atlas_icons.bay_marker, bay_color, 0)

                if region_vehicle_icon ~= nil then
                    update_ui_image(0, 0, region_vehicle_icon, vehicle_color, iff(j % 2 == 0, 3, 1))

                    if ui.animation_timer % 30 > 15 then
                        if is_fuel_blocked and is_ammo_blocked then
                            update_ui_image(3, 6, atlas_icons.map_icon_low_fuel, color_status_bad, 0)
                            update_ui_image(9, 6, atlas_icons.map_icon_low_ammo, color_status_bad, 0)
                        elseif is_fuel_blocked then
                            update_ui_image(6, 6, atlas_icons.map_icon_low_fuel, color_status_bad, 0)
                        elseif is_ammo_blocked then
                            update_ui_image(6, 6, atlas_icons.map_icon_low_ammo, color_status_bad, 0)
                        end
                    end
                end

                update_ui_pop_offset()
            end

            if j % 2 == 0 then
                update_ui_text(x, y, get_carrier_bay_name(bay_index), 200, 0, bay_color, 0)
                render_bay_icon(x, y + 9)
                render_bar(x + 17, y + 9, repair_factor, color_repair)
                render_bar(x + 19, y + 9, fuel_factor, color_fuel)
                render_bar(x + 21, y + 9, ammo_factor, color_ammo)
            else
                update_ui_text(x + item_w - 16, y, get_carrier_bay_name(bay_index), 200, 0, bay_color, 0)
                render_bay_icon(x + item_w - 16, y + 9)
                render_bar(x + item_w - 22, y + 9, repair_factor, color_repair)
                render_bar(x + item_w - 20, y + 9, fuel_factor, color_fuel)
                render_bar(x + item_w - 18, y + 9, ammo_factor, color_ammo)
            end

            if is_selected then
                selected_bay_index = bay_index
            end

            if is_hovered then
                hovered_bay_index = bay_index
            end

            x = x + item_w + iff(j == 2, column_spacing, item_spacing)
        end

        ui:end_nav_row(item_h)
    end

    local is_action = false

    if selected_bay_index ~= -1 and is_active then
        local is_clicked = hovered_bay_index ~= -1 and ui.input_pointer_1

        if ui.input_action or is_clicked then
            is_action = true
            ui.input_action = false
            ui.input_pointer_1 = false
        end
    end

    return selected_bay_index, is_action
end

function get_ui_vehicle_chassis_attachments(vehicle)
    local vehicle_definition_index = vehicle:get_definition_index()
    local vehicle_attachment_count = vehicle:get_attachment_count()

    local vehicle_attachment_rows = {}

    if vehicle_definition_index == e_game_object_type.chassis_land_wheel_light then
        vehicle_attachment_rows = {
            {
                { i=2, x=0, y=-16 }
            },
            {
                { i=1, x=0, y=0 }
            },
            {
                { i=3, x=0, y=16 }
            }
        }
    elseif vehicle_definition_index == e_game_object_type.chassis_land_wheel_medium then
        vehicle_attachment_rows = {
            {
                { i=2, x=0, y=-16 }
            },
            {
                { i=1, x=0, y=0 }
            },
            {
                { i=3, x=0, y=16 }
            }
        }
    elseif vehicle_definition_index == e_game_object_type.chassis_land_wheel_heavy then
        vehicle_attachment_rows = {
            {
                { i=3, x=-16, y=0 },
                { i=2, x=0, y=-0 },
                { i=1, x=16, y=0 }
            }
        }
    elseif vehicle_definition_index == e_game_object_type.chassis_air_wing_light then
        vehicle_attachment_rows = {
            {
                { i=1, x=0, y=-22 }
            },
            {
                { i=2, x=-26, y=0 },
                { i=4, x=-14, y=0 },
                { i=5, x=14, y=0 },
                { i=3, x=26, y=0 }
            }
        }

    elseif vehicle_definition_index == e_game_object_type.chassis_air_wing_heavy then
        vehicle_attachment_rows = {
            {
                { i=1, x=0, y=-22 }
            },
            {
                { i=2, x=-26, y=0 },
                { i=4, x=-14, y=0 },
                { i=6, x=0, y=4 },
                { i=5, x=14, y=0 },
                { i=3, x=26, y=0 }
            },
            {
                { i=7, x=-14, y=20 },
                { i=8, x=14, y=20 }
            }
        }
    elseif vehicle_definition_index == e_game_object_type.chassis_air_rotor_light then
        vehicle_attachment_rows = {
            {
                { i=1, x=-26, y=0 },
                { i=3, x=-14, y=0 },
                { i=4, x=14, y=0 },
                { i=2, x=26, y=0 }
            }
        }
    elseif vehicle_definition_index == e_game_object_type.chassis_air_rotor_heavy then
        vehicle_attachment_rows = {
            {
                { i=1, x=0, y=-22 }
            },
            {
                { i=2, x=-20, y=0 },
                { i=4, x=-10, y=0 },
                { i=5, x=10, y=0 },
                { i=3, x=20, y=0 }
            }
        }
    elseif vehicle_definition_index == e_game_object_type.chassis_land_turret then
        vehicle_attachment_rows = {
            {
                { i=0, x=0, y=0 }
            }
        }
    elseif vehicle_definition_index == e_game_object_type.chassis_sea_ship_light then
        vehicle_attachment_rows = {
            {
                { i=1, x=0, y=-5 },
                { i=2, x=0, y=15 },
            }
        }
    elseif vehicle_definition_index == e_game_object_type.chassis_land_wheel_mule then
        vehicle_attachment_rows = {
            {
                { i=1, x=-20, y=-18 },
                { i=2, x=20, y=-18 }
            },
            {
                { i=3, x=-20, y=0 },
                { i=4, x=20, y=0 }
            },
            {
                { i=5, x=-20, y=18 },
                { i=6, x=20, y=18 }
            }
        }
    elseif vehicle_definition_index == e_game_object_type.chassis_deployable_droid then
        vehicle_attachment_rows = {
            {
                { i=0, x=0, y=-13 }
            },
            {
                { i=1, x=0, y=0 }
            }
        }
    end

    return vehicle_attachment_rows
end

function imgui_vehicle_chassis_loadout(ui, vehicle, selected_bay_index)
    local window = ui:get_window()
    local w, h = ui:get_region()
    local cx = window.cx
    local cy = window.cy
    local is_active = window.is_active
    local selected_attachment_index = -1
    local hovered_attachment_index = -1

    cx = cx + (w - 64) / 2

    if vehicle == nil or vehicle:get() == false then
        update_ui_image(cx, cy, atlas_icons.icon_chassis_unknown, color_grey_dark, 0)
        return
    end

    local vehicle_definition_index = vehicle:get_definition_index()
    local vehicle_attachment_count = vehicle:get_attachment_count()

    if selected_bay_index ~= nil then
        local bay_name = get_carrier_bay_name(selected_bay_index)
        update_ui_text(cx, cy, bay_name, 200, 0, color_grey_dark, 0)
    end

    -- chassis background image
            
    local chassis_image = get_chassis_image_by_definition_index(vehicle_definition_index)
    local chassis_color = iff(chassis_image == atlas_icons.icon_chassis_unknown, color_grey_dark, color_white)
    update_ui_image(cx, cy, chassis_image, chassis_color, 0)
            
    -- hardpoint buttons

    local attachment_rows = get_ui_vehicle_chassis_attachments(vehicle)

    for i = 1, #attachment_rows do
        ui:begin_nav_row()

        local is_row_selected = window.selected_index_y == window.index_y
        
        for j = 1, #attachment_rows[i] do
            local render_data = attachment_rows[i][j]
            local attachment_type = vehicle:get_attachment_type(render_data.i)

            local attachment_w = 8
            local attachment_h = 8
    
            if attachment_type == e_game_object_attachment_type.plate_small then
                attachment_w = 8
                attachment_h = 8
            elseif attachment_type == e_game_object_attachment_type.plate_large then
                attachment_w = 16
                attachment_h = 16
            elseif attachment_type == e_game_object_attachment_type.camera then
                attachment_w = 12
                attachment_h = 12
            elseif attachment_type == e_game_object_attachment_type.hardpoint_small then
                attachment_w = 8
                attachment_h = 24
            elseif attachment_type == e_game_object_attachment_type.hardpoint_large then
                attachment_w = 12
                attachment_h = 32
            elseif attachment_type == e_game_object_attachment_type.plate_huge then
                attachment_w = 20
                attachment_h = 20
            elseif attachment_type == e_game_object_attachment_type.plate_small_inverted then
                attachment_w = 8
                attachment_h = 8
            elseif attachment_type == e_game_object_attachment_type.plate_logistics_container then
                attachment_w = 16
                attachment_h = 16
            end

            local x = cx + 32 - (attachment_w / 2) + render_data.x
            local y = cy + 32 - (attachment_h / 2) + render_data.y
            local is_hovered, is_selected = ui:hoverable(x, y, attachment_w, attachment_h, true)

            render_button_bg(x, y, attachment_w, attachment_h, iff(is_active, iff(is_selected, color_highlight, color8(4, 12, 12, 210)), color8(16, 16, 16, 192)), 1)

            local attachment = vehicle:get_attachment(render_data.i)

            if attachment:get() then
                local attachment_definition_index = attachment:get_definition_index()

                if attachment_definition_index > 0 then
                    local total_capacity = 0
                    local resupply_factor = 0

                    if attachment:get_ammo_capacity() > 0 then
                        total_capacity = total_capacity + 1
                        resupply_factor = resupply_factor + attachment:get_ammo_factor()
                    end

                    if attachment:get_fuel_capacity() > 0 then
                        total_capacity = total_capacity + 1
                        resupply_factor = resupply_factor + attachment:get_fuel_factor()
                    end

                    resupply_factor = iff(total_capacity == 0, 1, resupply_factor / total_capacity)
                    
                    local attachment_icon_region, attachment_16_icon_region = get_attachment_icons(attachment_definition_index)
                    local icon_w, icon_h = update_ui_get_image_size(attachment_icon_region)

                    if resupply_factor < 1.0 then
                        update_ui_image(x + (attachment_w - icon_w) / 2, y + (attachment_h - icon_h) / 2, attachment_icon_region, color_status_bad, 0)

                        update_ui_rectangle(x + 1, y + (attachment_h / 2) - 2, attachment_w - 2, 4, color_black)
                        update_ui_rectangle(x + 1, y + (attachment_h / 2) - 2, (attachment_w - 2) * resupply_factor, 4, color_white)
                    else
                        update_ui_image(x + (attachment_w - icon_w) / 2, y + (attachment_h - icon_h) / 2, attachment_icon_region, color_status_ok, 0)
                    end
                end
            end

            if is_selected then
                selected_attachment_index = render_data.i
            end

            if is_hovered then
                hovered_attachment_index = render_data.i
            end
        end

        ui:end_nav_row(0)
    end

    local is_action = false

    if selected_attachment_index ~= -1 and is_active then
        local is_clicked = hovered_attachment_index ~= -1 and ui.input_pointer_1

        if hovered_attachment_index ~= -1 or update_get_active_input_type() == e_active_input.gamepad then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
        end

        if ui.input_action or is_clicked then
            is_action = true
            ui.input_action = false
            ui.input_pointer_1 = false
        end
    end

    return selected_attachment_index, is_action
end

function imgui_combo_custom(ui, selected_index, items, item_w, item_h, scroll_offset, callback_render_item)
    local window = ui:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = ui:get_region()
    local is_active = window.is_active
    local is_hovered, is_selected = ui:hoverable(x, y, w, item_h, true)

    local border_w = 5
    local arrow_w = 5
    local arrow_h = 8
    local combo_w = w - 2 * (arrow_w + border_w)
    local scroll_min = 0
    local scroll_max = #items * item_w - combo_w
    local scroll_w = #items * item_w
    local is_mouse_mode = update_get_active_input_type() == e_active_input.keyboard

    local function calc_scroll_pos(index)
        local item_pos = index * item_w + item_w / 2
        return item_pos - combo_w / 2
    end

    local function clamp_scroll()
        scroll_offset = clamp(scroll_offset, scroll_min, scroll_max)
    end

    if #items > 0 then
        selected_index = clamp(selected_index, 0, #items - 1)
    else
        selected_index = 0
    end

    if scroll_offset == -1 then
        scroll_offset = calc_scroll_pos(selected_index)
        clamp_scroll()
    end

    local arrow_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)

    if scroll_w > combo_w then
        update_ui_image(x + border_w, y + (item_h - arrow_h) / 2, atlas_icons.text_back, iff(scroll_offset > scroll_min, arrow_col, color_grey_dark), 0)
        update_ui_image(x + w - arrow_w - border_w, y + (item_h - arrow_h) / 2, atlas_icons.text_back, iff(scroll_offset < scroll_max, arrow_col, color_grey_dark), 2)
    end
    
    update_ui_push_clip(x + border_w + arrow_w, y, combo_w, item_h)

    local is_hovered_item_region = ui:is_hovered(x + border_w + arrow_w, y, combo_w, item_h) and update_get_active_input_type() == e_active_input.keyboard
    local cx = x + w / 2 - scroll_w / 2
    local cy = y

    if scroll_w > combo_w then
        cx = x + border_w + arrow_w - scroll_offset
    end

    for i = 1, #items do
        if is_hovered_item_region and ui:is_hovered(cx, cy, item_w, item_h) then
            selected_index = i - 1
        end

        local is_item_selected = is_selected and (selected_index + 1) == i

        update_ui_push_offset(cx, cy)
        callback_render_item(items[i], is_active, is_item_selected)
        update_ui_pop_offset()

        cx = cx + item_w
    end

    update_ui_pop_clip()

    local is_action = false

    if is_selected and is_active then
        local is_left_hovered = ui:is_hovered(x + border_w, y, 5, item_h)
        local is_right_hovered = ui:is_hovered(x + w - arrow_w - border_w, y, 5, item_h)
        local is_content_hovered = ui:is_hovered(x + border_w + arrow_w, y, w - 2 * (border_w + arrow_w), item_h)

        local is_left_clicked = ui.input_pointer_1 and is_left_hovered
        local is_right_clicked = ui.input_pointer_1 and is_right_hovered
        local is_clicked = ui.input_pointer_1 and is_content_hovered

        update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_lr)
        
        if update_get_active_input_type() == e_active_input.gamepad then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
        elseif is_left_hovered or is_right_hovered then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_scroll), e_game_input.interact_a)
        elseif is_content_hovered then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
        end

        if is_left_clicked then
            scroll_offset = scroll_offset - item_w
        elseif is_right_clicked then
            scroll_offset = scroll_offset + item_w
        elseif ui.input_left then
            if is_mouse_mode then
                if selected_index > 0 then
                    selected_index = selected_index - 1

                    local item_x = calc_scroll_pos(selected_index)
                    scroll_offset = clamp(scroll_offset, item_x - combo_w / 2 + item_w / 2, item_x + combo_w / 2 - item_w / 2)
                else
                    scroll_offset = scroll_offset - item_w
                end
            else
                if selected_index > 0 then
                    selected_index = selected_index - 1
                    scroll_offset = calc_scroll_pos(selected_index)
                end
            end
        elseif ui.input_right then
            if is_mouse_mode then
                if selected_index + 1 < #items then
                    selected_index = selected_index + 1

                    local item_x = calc_scroll_pos(selected_index)
                    scroll_offset = clamp(scroll_offset, item_x - combo_w / 2 + item_w / 2, item_x + combo_w / 2 - item_w / 2)
                else
                    scroll_offset = scroll_offset + item_w
                end
            else
                if selected_index + 1 < #items then
                    selected_index = selected_index + 1
                    scroll_offset = calc_scroll_pos(selected_index)
                end
            end
        elseif ui.input_action or is_clicked then
            is_action = true
            ui.input_action = false
            ui.input_pointer_1 = false
        end
    end

    clamp_scroll()

    return selected_index, scroll_offset, is_action
end

function imgui_table_header(ui, columns)
    local window = ui:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = ui:get_region()
    
    local cx = x
    update_ui_rectangle(x, y, w, 12, color_grey_dark)

    for i = 1, #columns do
        if type(columns[i].value) == "string" then
            update_ui_text(cx + columns[i].margin, y + 2, columns[i].value, columns[i].w - columns[i].margin, 0, color_black, 0)
        else
            update_ui_image(cx + columns[i].margin, y + 2, columns[i].value, color_black, 0)
        end

        cx = cx + columns[i].w
    end

    window.cy = window.cy + 12
end

function imgui_table_entry(ui, columns, is_selectable, min_row_h)
    local window = ui:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = ui:get_region()
    local is_selected = window.selected_index_y == window.index_y and window.is_selection_enabled
    local is_active = window.is_active

    local cx = 0
    local row_h = min_row_h or 10
    local is_bg_enabled = false

    for i = 1, #columns do
        if columns[i].bg_col ~= nil then
            is_bg_enabled = true
        end
    end

    for i = 1, #columns do
        if columns[i].row_h ~= nil then
            row_h = math.max(columns[i].row_h, row_h)
        end
        if type(columns[i].value) == "string" then
            local text_render_w, text_render_h = update_ui_get_text_size(columns[i].value, columns[i].w - columns[i].margin, 0)
            row_h = math.max(text_render_h, row_h)
        end
    end

    if is_selected and is_active then
        update_ui_rectangle(cx, y, w, row_h + 3, iff(is_selectable, color_button_bg, color_button_bg_inactive))
    end

    for i = 1, #columns do
        local is_highlight = columns[i].is_highlight == nil or columns[i].is_highlight
        local col = iff(is_active, iff(is_selected and is_highlight, columns[i].col or iff(is_selectable, color_highlight, color_grey_mid), columns[i].col or color_grey_dark), color_grey_dark)

        if columns[i].bg_col ~= nil then
            update_ui_rectangle(cx, y, columns[i].w, row_h + 3, columns[i].bg_col)
        end

        if type(columns[i].value) == "string" then
            update_ui_text(cx + columns[i].margin, y + 3, columns[i].value, columns[i].w - columns[i].margin, 0, col, 0)
        elseif type(columns[i].value) == "function" then
            update_ui_push_offset(cx + columns[i].margin, y)
            columns[i].value(columns[i].w - columns[i].margin, row_h, is_selected)
            update_ui_pop_offset()
        else
            update_ui_image(cx + columns[i].margin, y + 3, columns[i].value, col, 0)
        end

        cx = cx + columns[i].w
    end

    cx = columns[1].w

    update_ui_rectangle(x, y + row_h + 3, w, 1, color8(255, 255, 255, 2))

    for i = 2, #columns do
        local is_border = columns[i - 1].is_border == nil or columns[i].is_border

        if is_border then
            update_ui_rectangle(cx, y, 1, row_h + 3, color_grey_dark)
        end

        cx = cx + columns[i].w
    end
    
    window.cy = window.cy + row_h + 3

    local is_hovered = ui:hoverable(x, y, w, window.cy - y, true)
    local is_action = false

    if is_selected and is_active and is_selectable then
        local is_clicked = is_hovered and ui.input_pointer_1

        if is_hovered or update_get_active_input_type() == e_active_input.gamepad then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
        end

        if ui.input_action or is_clicked then
            is_action = true
            ui.input_action = false
            ui.input_pointer_1 = false
        end
    end

    return is_action
end

function imgui_table_entry_grid(ui, columns)
    local window = ui:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = ui:get_region()
    local is_row_selected = window.selected_index_y == window.index_y and window.is_selection_enabled
    local is_active = window.is_active
    local selected_col = -1
    local selected_col_x = 0
    local selected_col_y = 0
    local selected_col_w = 0
    local selected_col_h = 0

    local cx = 0
    local row_h = 10

    for i = 1, #columns do
        if type(columns[i].value) == "string" then
            local _, text_h = update_ui_get_text_size(columns[i].value, columns[i].w - columns[i].margin, 0)
            row_h = math.max(row_h, text_h)
        end
    end

    ui:begin_nav_row()

    for i = 1, #columns do
        local _, is_selected = ui:hoverable(cx, y, columns[i].w, row_h + 3, true)
        local is_highlight = columns[i].is_highlight == nil or columns[i].is_highlight
        local col = iff(is_active, iff(is_selected and is_highlight, columns[i].col or color_highlight, columns[i].col or color_grey_dark), color_grey_dark)

        if is_row_selected and is_active then
            if is_selected then
                update_ui_rectangle(cx, y, columns[i].w, row_h + 3, color_button_bg)
            else
                update_ui_rectangle(cx, y, columns[i].w, row_h + 3, color8(255, 255, 255, 3))
            end
        end

        if is_selected then
            selected_col = i
            selected_col_x = cx
            selected_col_y = y
            selected_col_w = columns[i].w
            selected_col_h = row_h + 3
        end

        if type(columns[i].value) == "string" then
            update_ui_text(cx + columns[i].margin, y + 3, columns[i].value, columns[i].w - columns[i].margin, 0, col, 0)
        elseif type(columns[i].value) == "function" then
            update_ui_push_offset(cx + columns[i].margin, y)
            columns[i].value(columns[i].w - columns[i].margin, row_h, is_selected)
            update_ui_pop_offset()
        else
            update_ui_image(cx + columns[i].margin, y + 3, columns[i].value, col, 0)
        end

        cx = cx + columns[i].w
    end

    ui:end_nav_row(row_h + 3)

    cx = columns[1].w

    update_ui_rectangle(x, y + row_h + 3, w, 1, color8(255, 255, 255, 2))

    for i = 2, #columns do
        local is_border = columns[i - 1].is_border == nil or columns[i].is_border

        if is_border then
            update_ui_rectangle(cx, y, 1, row_h + 3, color_grey_dark)
        end

        cx = cx + columns[i].w
    end

    local is_action = false

    if is_row_selected and is_active then
        local is_clicked = ui:is_hovered(x, y, w, row_h + 3) and ui.input_pointer_1

        if ui.input_action or is_clicked then
            is_action = true
            ui.input_action = false
            ui.input_pointer_1 = false
        end
    end

    return is_action, selected_col, selected_col_x, selected_col_y, selected_col_w, selected_col_h
end

function imgui_vehicle_inventory_table(ui, vehicle)
    local window = ui:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = ui:get_region()
    local selected_item = -1
    local selected_row = -1
    local selected_col = -1
    local selected_x = 0
    local selected_y = 0
    local selected_w = 0
    local selected_h = 0
    local row_index = 1

    local island_stock = {}
    local barge_stock = {}
    local team = update_get_team(vehicle:get_team())

    if team:get() then
        island_stock = team:get_island_stock()
        barge_stock = team:get_barge_stock()
    end

    local column_widths = { w - 109, 27, 27, 27, 27 }
    local column_margins = { 5, 2, 2, 2, 2 }
    
    for _, category in pairs(g_item_categories) do
        if #category.items > 0 then
            local is_added_header = false

            local header_columns = {
                { w=column_widths[1], margin=column_margins[1], value=category.name },
                { w=column_widths[2], margin=column_margins[2], value=atlas_icons.column_warehouse },
                { w=column_widths[3], margin=column_margins[3], value=atlas_icons.column_pending },
                { w=column_widths[4], margin=column_margins[4], value=atlas_icons.column_distance },
                { w=column_widths[5], margin=column_margins[5], value=atlas_icons.column_stock }
            }

            for _, item in pairs(category.items) do
                if update_get_resource_item_hidden(item.index) == false then
                    if is_added_header == false then
                        imgui_table_header(ui, header_columns)
                        is_added_header = true
                    end

                    local island_count = clamp(island_stock[item.index] or 0, -99999, 99999)
                    local barge_count = clamp(barge_stock[item.index] or 0, -99999, 99999)
                    local order_count = clamp(vehicle:get_inventory_order(item.index), -99999, 99999)
                    local stock_count = clamp(vehicle:get_inventory_count_by_item_index(item.index), -99999, 99999)

                    local columns = { 
                        { w=column_widths[1], margin=column_margins[1], value=item.name },
                        { w=column_widths[2], margin=column_margins[2], value=format_quantity(island_count) },
                        { w=column_widths[3], margin=column_margins[3], value=format_quantity(order_count), col=iff(order_count > 0, color_status_ok, iff(order_count < 0, color_status_bad, color_grey_dark)) },
                        { w=column_widths[4], margin=column_margins[4], value=format_quantity(barge_count) },
                        { w=column_widths[5], margin=column_margins[5], value=format_quantity(stock_count), col=iff(stock_count > 0, color_status_ok, color_status_bad) }
                    }

                    local is_action, row_selected_col, col_x, col_y, col_w, col_h = imgui_table_entry_grid(ui, columns)

                    if ui:get_is_item_selected() then
                        selected_row = row_index
                        selected_col = row_selected_col
                        selected_x = col_x
                        selected_y = col_y
                        selected_w = col_w
                        selected_h = col_h
                    end

                    if is_action then
                        selected_item = item.index
                    end

                    row_index = row_index + 1
                end
            end
        end
    end

    return selected_item, selected_row, selected_col, selected_x, selected_y, selected_w, selected_h
end

function imgui_barge_inventory_table(ui, vehicle, is_category_headers)
    local window = ui:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = ui:get_region()
    local selected_item = -1
    
    local column_widths = { w - 50, 50 }
    local column_margins = { 5, 2 }
    local item_count = 0

    for _, category in pairs(g_item_categories) do
        if #category.items > 0 then
            local is_added_header = false

            local header_columns = {
                { w=column_widths[1], margin=column_margins[1], value=category.name },
                { w=column_widths[2], margin=column_margins[2], value=atlas_icons.column_stock }
            }

            for _, item in pairs(category.items) do
                if update_get_resource_item_hidden(item.index) == false then
                    local stock_count = clamp(vehicle:get_inventory_count_by_item_index(item.index), -99999, 99999)
                    
                    if stock_count > 0 then
                        item_count = item_count + 1

                        if is_added_header == false and is_category_headers then
                            imgui_table_header(ui, header_columns)
                            is_added_header = true
                        end

                        local columns = { 
                            { w=column_widths[1], margin=column_margins[1], value=item.name },
                            { w=column_widths[2], margin=column_margins[2], value=tostring(stock_count), col=iff(stock_count > 0, color_status_ok, color_status_bad) }
                        }

                        local is_action = imgui_table_entry(ui, columns)

                        if is_action then
                            selected_item = item.index
                        end
                    end
                end
            end
        end
    end

    if item_count == 0 then
        ui:text_basic(update_get_loc(e_loc.upp_empty), color_grey_dark)
        ui:spacer(1)
    end

    return selected_item
end

function imgui_facility_inventory_table(ui, tile)
    local window = ui:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = ui:get_region()
    local selected_item = -1

    local column_widths = { w - 50, 50 }
    local column_margins = { 5, 2 }
    
    for _, category in pairs(g_item_categories) do
        if #category.items > 0 then
            local is_added_header = false

            local header_columns = {
                { w=column_widths[1], margin=column_margins[1], value=category.name },
                { w=column_widths[2], margin=column_margins[2], value=atlas_icons.column_stock },
            }
            
            for _, item in pairs(category.items) do
                if update_get_resource_item_hidden(item.index) == false then
                    if not is_added_header then
                        imgui_table_header(ui, header_columns)
                        is_added_header = true
                    end

                    local stock_count = tile:get_facility_inventory_count(item.index)

                    local columns = { 
                        { w=column_widths[1], margin=column_margins[1], value=item.name },
                        { w=column_widths[2], margin=column_margins[2], value=tostring(stock_count), col=iff(stock_count > 0, color_status_ok, color_status_bad) }
                    }

                    local is_action = imgui_table_entry(ui, columns)

                    if is_action then
                        selected_item = item.index
                    end
                end
            end
        end
    end

    return selected_item
end

function imgui_item_button(self, item_data, label, is_enabled)
    local window = self:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = self:get_region()
    local is_selected = window.selected_index_y == window.index_y
    local is_active = is_enabled and window.is_active
    local is_action = false
    
    local bx = x + 5
    local by = y
    
    local icon_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)
    local text_col = iff(is_active, iff(is_selected, color_black, color_grey_dark), color_grey_dark)
    
     local _, text_h = update_ui_get_text_size(label, w - bx - 23, 0)

    if is_active and is_selected then
        render_button_bg(x + 1, y, w - 2, text_h + 6, color_highlight)
    end

    update_ui_image(bx, by, item_data.icon, icon_col, 0)
    update_ui_text(bx + 16 + 2, by + 3, label, w - bx - 23, 0, text_col, 0)
    window.cy = window.cy + text_h + 7

    local is_hovered = self:hoverable(x, y, w, window.cy - y, true)

    if is_selected and is_active then
        local is_clicked = is_hovered and self.input_pointer_1

        if is_hovered or update_get_active_input_type() == e_active_input.gamepad then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
        end

        if self.input_action or is_clicked then
            is_action = true
            self.input_action = false
            self.input_pointer_1 = false
        end
    end

    return is_action
end

function render_tab(x, y, w, text, col_back, col_front)
    update_ui_push_offset(x, y)
    w = math.max(w, 8)

    update_ui_image(0, 0, atlas_icons.tab_border, col_back, 0)
    update_ui_image(w - 8, 0, atlas_icons.tab_border, col_back, 0)
    update_ui_rectangle(3, 0, w - 6, 10, col_back)

    update_ui_text(0, 1, text, w, 1, col_front, 0)

    update_ui_pop_offset()
end

function get_tab_colors(is_active, is_selected, is_hovered, is_inactive)
    local col_back = color_grey_dark
    local col_front = color_black

    if is_inactive then
        return col_back, col_front
    elseif is_active then
        col_back = color_white
        col_front = color_black
    elseif is_selected then
        col_back = color_highlight
        col_front = color_white
    elseif is_hovered then
        col_back = color_grey_mid
        col_front = color_white
    end

    return col_back, col_front
end

function render_tooltip(region_x, region_y, region_w, region_h, x, y, w, h, rad, callback_render_content, col)
    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)
    
    local pos_y = y
    y = pos_y - h - math.floor(rad)

    col = col or color_black

    if y < region_y then
        y = pos_y + math.floor(rad)
        update_ui_image(clamp(x - 3, region_x, region_x + region_w - 6), y - 3, atlas_icons.text_back, col, 1)
    else
        update_ui_image(clamp(x - 4, region_x - 2, region_x + region_w - 8), y + h - 2, atlas_icons.text_back, col, 3)
    end

    x = clamp(x - w / 2, region_x, region_x + region_w - w)
    update_ui_push_offset(x, y)
    update_ui_push_clip(0, 0, w, h)

    update_ui_rectangle(0, 0, w, h, col)

    callback_render_content(w, h)

    update_ui_pop_clip()
    update_ui_pop_offset()
end

function render_button_bg(x, y, w, h, col, rad)
    local rounding = math.min(math.min(rad or 2, h / 2), w / 2)
    update_ui_push_offset(x, y)
    
    for i = 0, rounding - 1 do
        update_ui_rectangle(rounding - i, i, w - (rounding - i) * 2, 1, col)
        update_ui_rectangle(rounding - i, h - i - 1, w - (rounding - i) * 2, 1, col)
    end

    update_ui_rectangle(0, rounding, w, h - 2 * rounding, col)
    update_ui_pop_offset()
end

function render_button_bg_outline(x, y, w, h, col, rad)
    local rounding = math.min(math.min(rad or 2, h / 2), w / 2)
    update_ui_push_offset(x, y)
    
    update_ui_rectangle(rounding, 0, w - rounding * 2, 1, col)
    update_ui_rectangle(rounding, h - 1, w - rounding * 2, 1, col)
    update_ui_rectangle(0, rounding, 1, h - rounding * 2, col)
    update_ui_rectangle(w - 1, rounding, 1, h - rounding * 2, col)

    for i = 1, rounding - 1 do
        update_ui_rectangle(rounding - i, i, 1, 1, col)
        update_ui_rectangle(w - rounding - 1 + i, i, 1, 1, col)
        update_ui_rectangle(rounding - i, h - 1 - i, 1, 1, col)
        update_ui_rectangle(w - rounding - 1 + i, h - 1 - i, 1, 1, col)
    end
    
    update_ui_pop_offset()
end

function imgui_checkbox_toggle(self, label, value, is_enabled)
    local window = self:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = self:get_region()
    local is_active = window.is_active
    local is_hovered, is_selected = self:hoverable(x, y, w, 12, true)

    local label_w = math.floor(w * window.label_bias)
    local check_w = math.min(w - label_w - 5, 18)

    local text_col = iff(is_active, iff(is_selected, iff(is_enabled, color_white, color_grey_mid), color_grey_dark), color_grey_dark)
    local check_col = iff(is_active and is_enabled, iff(value, color_status_ok, color_status_bad), color_grey_dark)
    local border_col = iff(is_active, iff(is_selected, iff(is_enabled, color_white, color_grey_mid), color_grey_dark), color_grey_dark)

    update_ui_text(x + 5, y + 1, label, label_w - 5, 0, text_col, 0)

    if value then
        update_ui_rectangle(x + label_w + check_w / 2, y + 3, check_w / 2 - 2, 5, check_col)    
    else
        update_ui_rectangle(x + label_w + 2, y + 3, check_w / 2 - 2, 5, check_col)
    end
    
    update_ui_rectangle_outline(x + label_w, y + 1, check_w, 9, border_col)

    window.cy = window.cy + 12

    local is_modified = false

    if is_selected and is_active and is_enabled then
        local is_check_hovered = self:is_hovered(x + label_w, y, check_w, 12)
        local is_clicked = is_hovered and self.input_pointer_1 and is_check_hovered

        if is_check_hovered or update_get_active_input_type() == e_active_input.gamepad then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
        end

        if self.input_action or is_clicked then
            is_modified = true
            value = not value
        end
    end

    return value, is_modified
end

g_menu_overlay_factor = 1

function imgui_menu_focus_overlay(ui, screen_w, screen_h, text, ticks)
    text = text .. "  "
    local text_h = 25
    local text_w = math.min(screen_w - 80, update_ui_get_text_size(text, 10000, 0) * 3)
    

    local col = color_white
    local button_col = color_highlight
    local bg_col = color_white

    local w = text_w + 20
    local h = text_h + 35
    local x = (screen_w - w) / 2
    local y = (screen_h - h) / 2

    local target_factor = iff(update_get_is_focus_local(), 0, 1)
    g_menu_overlay_factor = g_menu_overlay_factor + clamp(target_factor - g_menu_overlay_factor, -ticks / 15, ticks / 15)

    if g_menu_overlay_factor < 1 and update_get_is_focus_local() then
        if g_menu_overlay_factor > 0.7 then
            col = color_black
            button_col = color_white
        else
            col = color_black
            button_col = color_grey_dark
        end
    end

    if update_get_is_focus_local() then
        local factor = 1 - (clamp((1 - g_menu_overlay_factor - 0.5) / 0.5, 0, 1))
        update_ui_rectangle(0, 0, screen_w, screen_h, color8(0, 0, 0, math.floor(lerp(0, 230, factor))))
        update_ui_push_clip(0, y, screen_w, h * factor)
    else
        local factor = g_menu_overlay_factor
        update_ui_rectangle(0, 0, screen_w, screen_h, color8(0, 0, 0, math.floor(lerp(0, 230, factor))))
        update_ui_push_clip(0, y, screen_w, h * factor)
    end

    local inactive_col = ui.window_col_inactive
    ui.window_col_inactive = bg_col
    ui:begin_window("##overlay", x, y, w, h, atlas_icons.column_pending, false, 2)
        local region_w, region_h = ui:get_region()

        update_ui_rectangle(5, (region_h - text_h) / 2 - 5, region_w - 10, text_h + 10, button_col)
        update_ui_text_scale((region_w - text_w) / 2, (region_h - text_h) / 2, text, text_w, 1, col, 0, 3)

        update_ui_push_offset(region_w - 20, region_h / 2 - 10)
        update_ui_begin_triangles()
        update_ui_add_triangle(vec2(0, 0), vec2(10, 10), vec2(0, 20), col)
        update_ui_end_triangles()
        update_ui_pop_offset()
    ui:end_window()
    ui.window_col_inactive = inactive_col

    update_ui_pop_clip()
end

function imgui_menu_overlay(ui, x, y, w, h, text, text_w, text_h, col, bg_col)
    update_ui_rectangle(0, 0, 256, 256, color8(0, 0, 0, 230))

    local inactive_col = ui.window_col_inactive
    ui.window_col_inactive = bg_col
    ui:begin_window("##overlay", x, y, w, h, atlas_icons.column_pending, false, 2)
        local region_w, region_h = ui:get_region()
        update_ui_text_scale((region_w - text_w) / 2, (region_h - text_h) / 2, text, text_w, 1, col, 0, 3)
    ui:end_window()
    ui.window_col_inactive = inactive_col
end

function imgui_key_icon_width(label)
    return math.max(10, #label * 6 + 5)
end

function imgui_render_key_icon(x, y, label, is_active, override_col)
    update_ui_push_offset(x, y)
    
    is_active = iff(is_active == nil, true, is_active)

    local w = imgui_key_icon_width(label)
    local h = 10
    local col_back = color_grey_dark
    local col_edge = iff(is_active, color8(32, 32, 32, 255), color_grey_dark)
    local col_text = iff(is_active, color_white, color_black)

    if override_col ~= nil then
        col_back = override_col
        col_edge = override_col
        col_text = override_col
    end

    update_ui_rectangle(0, 1, w, h - 2, col_back)
    update_ui_rectangle(1, 0, w - 2, h, col_back)
    update_ui_rectangle(1, h - 1, w - 2, 1, col_edge)
    update_ui_rectangle(0, h - 3, 1, 2, col_edge)
    update_ui_rectangle(w - 1, h - 3, 1, 2, col_edge)

    update_ui_text(1, 0, label, math.floor(w / 2) * 2, 1, col_text, 0)

    update_ui_pop_offset()

    return w
end

function imgui_list_item_blink(ui, label, is_select_on_hover, is_enabled)
    is_enabled = iff(is_enabled == nil, true, is_enabled)

    local window = ui:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = ui:get_region()
    local is_active = is_enabled and window.is_active
    local is_action = false
    is_select_on_hover = is_select_on_hover or false
    local is_hovered, is_selected = ui:hoverable(x, y, w, 13, is_select_on_hover)

    local function blink(rate, col0, col1)
        return iff(update_get_logic_tick() % rate < rate / 2, col0, col1)
    end

    local text_col = iff(is_active, iff(is_selected, blink(16, color_white, color_black), iff(is_hovered and is_select_on_hover == false, color_white, blink(16, color_white, color_black))), iff(is_selected, color_black, color_grey_dark))
    local back_col = iff(is_active, iff(is_selected, color_highlight, color_button_bg), iff(is_selected, color_grey_dark, color_button_bg_inactive))

    render_button_bg(x + 1, y, w - 2, 12, back_col)
    update_ui_push_clip(x + 1, y, w - 10, 12)
    update_ui_text(x + 5, y + 2, label, 999999, 0, text_col, 0)
    update_ui_pop_clip()

    if is_active then
        if is_hovered or (update_get_active_input_type() == e_active_input.gamepad and is_selected) then
            update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
        end
    end

    if is_selected then
        update_ui_image(x + w - 7, y + 3, atlas_icons.text_back, text_col, 2)

        if is_active then
            local is_clicked = is_hovered and ui.input_pointer_1

            if ui.input_action or is_clicked then
                is_action = true
                ui.input_action = false
                ui.input_pointer_1 = false
            end
        end
    end

    window.cy = window.cy + 13

    return is_action
end

function format_quantity(amount)
    if amount < 10000 then
        return string.format("%.0f", amount)
    else
        return string.format("%.0f", amount / 1000) .. update_get_loc(e_loc.acronym_thousand)
    end
end

function imgui_item_description(ui, vehicle, item_data, is_inventory, is_active)
    local window = ui:get_window()
    local region_w, region_h = ui:get_region()
    ui:spacer(2)

    update_ui_rectangle_outline(window.cx + 4, window.cy - 1, 18, 18, color_grey_dark)
    update_ui_image(window.cx + 5, window.cy, item_data.icon, iff(is_active, color_white, color_grey_dark), 0)

    local text_h = update_ui_text(window.cx + 25, window.cy, item_data.desc, region_w - 30, 0, color_grey_dark, 0)
    window.cy = window.cy + math.max(text_h, 17)

    ui:spacer(2)

    local icon_w = region_w / 4
    local cx = window.cx
    local cy = window.cy

    if update_get_resource_item_hidden(item_data.index) == false then
        update_ui_image(math.floor(cx + 5), cy, atlas_icons.column_weight, color_grey_dark, 0)
        update_ui_text(math.floor(cx + 15), cy, item_data.mass, math.floor(icon_w) - 15, 0, color_grey_dark, 0)
    end

    cx = cx + icon_w

    if is_inventory then
        local island_stock = {}
        local barge_stock = {}
        local team = update_get_team(vehicle:get_team())

        if team:get() then
            island_stock = team:get_island_stock()
            barge_stock = team:get_barge_stock()
        end

        local island_count = clamp(island_stock[item_data.index] or 0, -99999, 99999)
        local col = iff(is_active, iff(island_count > 0, color_status_ok, color_status_bad), color_grey_dark)

        update_ui_image(math.floor(cx + 5), cy, atlas_icons.column_warehouse, col, 0)
        update_ui_text(math.floor(cx + 16), cy, island_count, math.floor(icon_w) - 15, 0, col, 0)
        cx = cx + icon_w

        local barge_count = clamp(barge_stock[item_data.index] or 0, -99999, 99999)
        col = iff(is_active, iff(barge_count > 0, color_status_ok, color_grey_dark), color_grey_dark)

        update_ui_image(math.floor(cx + 5), cy, atlas_icons.column_distance, col, 0)
        update_ui_text(math.floor(cx + 16), cy, barge_count, math.floor(icon_w) - 15, 0, col, 0)
        cx = cx + icon_w

        local stock_count = vehicle:get_inventory_count_by_item_index(item_data.index)
        col = iff(is_active, iff(stock_count > 0, color_status_ok, color_status_bad), color_grey_dark)

        update_ui_image(math.floor(cx + 5), cy, atlas_icons.column_stock, col, 0)
        update_ui_text(math.floor(cx + 16), cy, stock_count, math.floor(icon_w) - 15, 0, col, 0)
        cx = cx + icon_w
    else
        update_ui_image(math.floor(cx + 5), cy, atlas_icons.column_time, color_grey_dark, 0)
        update_ui_text(math.floor(cx + 16), cy, item_data.time .. "s", math.floor(icon_w) - 15, 0, color_grey_dark, 0)
        cx = cx + icon_w

        local team = update_get_team(update_get_screen_team_id())
        local col = color_status_bad

        if team:get() and team:get_currency() >= item_data.cost then
            col = color_status_ok
        end

        update_ui_image(math.floor(cx + 5), cy, atlas_icons.column_currency, col, 0)
        update_ui_text(math.floor(cx + 16), cy, item_data.cost, math.floor(icon_w) - 15, 0, col, 0)
    end

    ui:spacer(10)
end