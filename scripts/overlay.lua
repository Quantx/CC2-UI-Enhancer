g_animation_time = 0
g_is_loading = false
g_loading_text = e_loc.screen_loading
g_loading_alpha = 0

function update(screen_w, screen_h, tick_fraction, delta_time)
    g_animation_time = g_animation_time + delta_time
    update_ui_set_back_color(color8(0, 0, 0, math.floor(g_loading_alpha * 255)))

    if g_is_loading then
        g_loading_alpha = g_loading_alpha + delta_time / 1000.0
        g_loading_alpha = clamp(g_loading_alpha, 0, 1)

        update_ui_push_alpha(math.floor(g_loading_alpha * 255))
        render_loading_text(screen_w, screen_h)
        update_ui_pop_alpha()
    else
        g_loading_alpha = 0
    end

    update_set_is_visible(g_loading_alpha > 0)
end

function render_loading_text(screen_w, screen_h)
    local connecting_text = g_loading_text
    update_ui_text(screen_w / 2 - 100, screen_h / 2 - 10, connecting_text, 200, 1, color_white, 0)

    local anim = g_animation_time * 0.001
    local bound_left = screen_w / 2 - 32
    local bound_right = bound_left + 64
    local left = bound_left + (bound_right - bound_left) * math.abs(math.sin((anim - math.pi / 2) % (math.pi / 2))) ^ 4
    local right = left + (bound_right - left) * math.abs(math.sin(anim % (math.pi / 2)))

    update_ui_rectangle(left, screen_h / 2 + 5, right - left, 5, color_status_ok)
    update_ui_rectangle_outline(screen_w / 2 - 32, screen_h / 2 + 5, 64, 5, color_grey_mid)
end