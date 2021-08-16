g_ui = {}
g_power_systems = {}

function begin()
    begin_load()
    g_ui = lib_imgui:create_ui()

    local function create_power_system(label, icon)
        table.insert(g_power_systems, 
            { 
                label = label,
                icon = icon,
                allocated = 0, 
                desired = 0, 
            }
        )
    end

    create_power_system(update_get_loc(e_loc.upp_repair), atlas_icons.column_repair)
    create_power_system(update_get_loc(e_loc.upp_propulsion), atlas_icons.column_propulsion)
    create_power_system(update_get_loc(e_loc.upp_weapons), atlas_icons.column_weapon)
    create_power_system(update_get_loc(e_loc.upp_lift_crane), atlas_icons.map_icon_factory_chassis_land)
    create_power_system(update_get_loc(e_loc.upp_radar), atlas_icons.screen_radar_air)
end

function update(screen_w, screen_h, ticks) 
    if update_screen_overrides(screen_w, screen_h, ticks)  then return end

    local map_vehicle = update_get_screen_vehicle()
    if map_vehicle:get() == false then return end

    local vehicle = update_get_vehicle_by_id(map_vehicle:get_id())
    if vehicle:get() == false then return end

    local function step(a, b, c)
        return a + clamp(b - a, -c, c)
    end

    for i = 1, #g_power_systems do
        local system = g_power_systems[i]
        local target_desired, target_allocated = vehicle:get_power_system_state(i - 1)
        system.desired = step(system.desired, target_desired, 0.025)
        system.allocated = step(system.allocated, target_allocated, 0.025)
    end

    local ui = g_ui
    ui:begin_ui()

    ui:begin_window(update_get_loc(e_loc.upp_power), 5, 5, screen_w - 10, screen_h - 10, atlas_icons.column_power, true, 0)
        local region_w, region_h = ui:get_region()
    
        local bar_w = 8
        local bar_h = 80
        local spacing = 11
        local cx = (region_w - bar_w * #g_power_systems - spacing * (#g_power_systems - 2)) / 2 - 1
        local cy = 8

        for i = 1, #g_power_systems do
            local system = g_power_systems[i]

            render_power_bar(system.label, cx, cy, bar_w, bar_h, system.icon, system.desired, system.allocated)
            cx = cx + bar_w + spacing
        end
    ui:end_window()

    ui:end_ui()
end

function input_event(event, action)
    if action == e_input_action.release then
        if event == e_input.back then
            update_set_screen_state_exit()
        end
    end
end

function render_power_bar(label, x, y, w, h, icon, desired, allocated)
    update_ui_push_offset(x, y)

    update_ui_text(-10, h, label, 200, 0, color_grey_dark, 3)
    update_ui_rectangle_outline(0, 0, w, h, color_white)

    local bar_h = math.max(math.floor((h - 4) * desired + 0.5), 1)
    update_ui_rectangle(-1, h - 2 - bar_h, 3, 1, color_white)
    update_ui_rectangle(w - 2, h - 2 - bar_h, 3, 1, color_white)

    bar_h = math.floor((h - 4) * desired + 0.5)
    update_ui_rectangle(2, h - 2 - bar_h, w - 4, bar_h, color_grey_dark)

    bar_h = math.floor((h - 4) * allocated + 0.5)
    update_ui_rectangle(2, h - 2 - bar_h, w - 4, bar_h, get_bar_color(desired, allocated))

    update_ui_image(w / 2 - 3, h + 2, icon, get_bar_color(desired, allocated), 0)

    update_ui_pop_offset()
end

function get_bar_color(desired, allocated)
    if desired < 0.01 then
        return color_grey_dark
    elseif allocated < desired * 0.25 then
        return color_status_bad
    elseif allocated < desired then
        return color_status_warning
    end

    return color_status_ok
end