color_white = color8(255, 255, 255, 255)
color_black = color8(0, 0, 0, 255)
color_grey_dark = color8(16, 16, 16, 255)
color_grey_mid = color8(63, 63, 63, 255)
color_status_dark_red = color8(63, 16, 16, 255)
color_status_dark_yellow = color8(202, 174, 11, 255)
color_status_dark_green = color8(16, 64, 40, 255)
color_status_ok = color8(16, 255, 127, 255)
color_status_bad = color8(255, 16, 16, 255)
color_status_warning = color8(255, 255, 16, 255)
color_highlight = color8(16, 64, 64, 255)
color_empty = color8(0, 0, 0, 0)
color_friendly = color8(16, 255, 255, 255)
color_enemy = color8(255, 16, 16, 255)
color_button_bg = color8(4, 12, 12, 255)
color_button_bg_inactive = color8(7, 7, 7, 255)

vessel_names = {
    "Mu",

    "Epsilon",
    "Omega",

    "Upsilon",
    "Omicron",
    "Sigma",
    "Lambda",

    "Alpha",
    "Beta",
    "Gamma",
    "Delta",
    "Zeta",
    "Eta",
    "Theta",
    "Iota",
    "Kappa"
}

atlas_icons = {
    bay_marker = 0,
    icon_chassis_16_wheel_small = 0,
    icon_chassis_16_wheel_medium = 0,
    icon_chassis_16_wheel_large = 0,
    icon_chassis_16_wing_small = 0,
    icon_chassis_16_wing_large = 0,
    icon_chassis_16_rotor_large = 0,
    icon_chassis_16_rotor_small = 0,
    icon_chassis_wheel_small = 0,
    icon_chassis_wheel_medium = 0,
    icon_chassis_wheel_large = 0,
    icon_chassis_wing_small = 0,
    icon_chassis_wing_large = 0,
    icon_chassis_rotor_small = 0,
    icon_chassis_rotor_large = 0,
    map_icon_air = 0,
    map_icon_surface = 0,
    map_icon_carrier = 0,
    map_icon_waypoint = 0,
    map_icon_attack = 0,
    map_icon_island = 0,
    map_icon_circle_9 = 0,
    icon_health = 0,
    icon_fuel = 0,
    icon_ammo = 0,
    microprose = 0,
    holomap_missile = 0,
    icon_attachment_camera_aircraft = 0,
    icon_attachment_camera_large = 0,
    icon_attachment_turret_missile = 0,
    icon_attachment_turret_main_gun = 0,
    icon_attachment_turret_ciws = 0,
    icon_attachment_turret_robots = 0,
    icon_attachment_air_chaingun = 0,
    icon_attachment_air_fuel = 0,
    icon_attachment_air_bomb_1 = 0,
    icon_attachment_air_bomb_2 = 0,
    icon_attachment_air_bomb_3 = 0,
    icon_attachment_air_bomb_4 = 0,
    icon_attachment_air_torpedo = 0,
    icon_attachment_air_torpedo_noisemaker = 0,
    icon_attachment_air_torpedo_decoy = 0,
    icon_attachment_air_missile_1 = 0,
    icon_attachment_air_missile_2 = 0,
    icon_attachment_air_missile_3 = 0,
    icon_attachment_air_missile_4 = 0,
    icon_attachment_air_radar = 0,
    icon_attachment_small_camera = 0,
    icon_attachment_small_camera_obs = 0,
    icon_attachment_small_flare = 0,
    icon_attachment_rocket_pod = 0,
    icon_attachment_turret_main_battle_cannon = 0,
    icon_attachment_turret_artillery = 0,
    icon_attachment_16_none = 0,
    icon_attachment_16_camera_aircraft = 0,
    icon_attachment_16_camera_large = 0,
    icon_attachment_16_turret_missile = 0,
    icon_attachment_16_turret_main_gun = 0,
    icon_attachment_16_turret_ciws = 0,
    icon_attachment_16_turret_robots = 0,
    icon_attachment_16_air_chaingun = 0,
    icon_attachment_16_turret_main_gun_2 = 0,
    icon_attachment_16_turret_main_heavy_cannon = 0,
    icon_attachment_16_air_fuel = 0,
    icon_attachment_16_air_bomb_1 = 0,
    icon_attachment_16_air_bomb_2 = 0,
    icon_attachment_16_air_bomb_3 = 0,
    icon_attachment_16_air_bomb_4 = 0,
    icon_attachment_16_air_torpedo = 0,
    icon_attachment_16_air_torpedo_noisemaker = 0,
    icon_attachment_16_air_torpedo_decoy = 0,
    icon_attachment_16_air_missile_1 = 0,
    icon_attachment_16_air_missile_2 = 0,
    icon_attachment_16_air_missile_3 = 0,
    icon_attachment_16_air_missile_4 = 0,
    icon_attachment_16_air_radar = 0,
    icon_attachment_16_small_camera = 0,
    icon_attachment_16_small_camera_obs = 0,
    icon_attachment_16_small_flare = 0,
    icon_attachment_16_rocket_pod = 0,
    icon_attachment_16_turret_main_battle_cannon = 0,
    icon_attachment_16_turret_artillery = 0,
    icon_attachment_16_unknown = 0,
    icon_tree_next = 0,
    gauge = 0,
    hud_target = 0,
    hud_target_locked = 0,
    hud_ticker_large = 0,
    hud_ticker_small = 0,
    hud_bracket = 0,
    hud_target_offscreen = 0,
    hud_horizon_mid = 0,
    hud_horizon_low = 0,
    hud_horizon_high = 0,
    hud_horizon_cursor = 0,
    hud_compass_indicator = 0,
    hud_zoom_indicator = 0,
    hud_zoom_indicator_2 = 0,
    icon_control_mode = 0,
    icon_stabilisation_mode = 0,
    hud_impact_marker = 0,
    hud_gun_crosshair = 0,
    map_icon_command_center = 0,
    map_icon_vehicle_control = 0,
    icon_controlling_peer = 0,
    map_icon_loop = 0,
    icon_attack_type_any = 0,
    icon_attack_type_bomb_single = 0,
    icon_attack_type_bomb_double = 0,
    icon_attack_type_missile_single = 0,
    icon_attack_type_missile_double = 0,
    icon_attack_type_torpedo_single = 0,
    icon_attack_type_gun = 0,
    icon_attack_type_rockets = 0,
    screen_compass_background = 0,
    screen_compass_dial_pivot = 0,
    screen_compass_dial_overlay = 0,
    screen_compass_tilt_side_pivot = 0,
    screen_compass_tilt_front_pivot = 0,
    hud_warning = 0,
    text_ellipsis = 0,
    text_back = 0,
    column_stock = 0,
    column_pending = 0,
    column_transit = 0,
    column_warehouse = 0,
    map_icon_crosshair = 0,
    map_icon_logistic_node = 0,
    map_icon_warehouse = 0,
    map_icon_factory = 0,
    map_icon_factory_small_munitions = 0,
    map_icon_factory_large_munitions = 0,
    map_icon_factory_turrets = 0,
    map_icon_factory_utility = 0,
    map_icon_factory_chassis_land = 0,
    map_icon_factory_chassis_air = 0,
    map_icon_factory_fuel = 0,
    map_icon_factory_barge = 0,
    map_icon_barge = 0,
    tab_border = 0,
    screen_propulsion_gauge = 0,
    screen_propulsion_carrier = 0,
    column_distance = 0,
    column_weight = 0,
    column_stabilisation_mode = 0,
    column_weapon = 0,
    column_laser = 0,
    column_control_mode = 0,
    column_ammo = 0,
    column_controlling_peer = 0,
    column_fuel = 0,
    hud_target_friendly = 0,
    hud_target_locked_friendly = 0,
    hud_target_missile = 0,
    icon_chassis_16_land_turret = 0,
    map_icon_turret = 0,
    hud_capsule_armed = 0,
    hud_capsule_deployed = 0,
    column_team_control = 0,
    column_team_capture = 0,
    column_capture_progress = 0,
    icon_chassis_16_robot_dog = 0,
    map_icon_robot_dog = 0,
    screen_weapon_aa = 0,
    screen_weapon_missile = 0,
    screen_weapon_missile_cruise = 0,
    screen_weapon_shell = 0,
    screen_radar_land = 0,
    screen_radar_air = 0,
    screen_radar_missile = 0,
    icon_chassis_16_carrier = 0,
    icon_chassis_16_barge = 0,
    column_time = 0,
    icon_attack_type_airlift = 0,
    icon_deploy_vehicle = 0,
    self_destruct = 0,
    countdown_0 = 0,
    countdown_1 = 0,
    countdown_2 = 0,
    countdown_3 = 0,
    countdown_4 = 0,
    countdown_5 = 0,
    countdown_6 = 0,
    countdown_7 = 0,
    countdown_8 = 0,
    countdown_9 = 0,
    map_icon_last_known_pos = 0,
    map_icon_missile = 0,
    map_icon_missile_outline = 0,
    map_icon_torpedo = 0,
    map_icon_torpedo_decoy = 0,
    icon_chassis_unknown = 0,
    map_icon_damage_indicator = 0,
    map_icon_low_fuel = 0,
    map_icon_low_ammo = 0,
    damage_hull = 0,
    damage_bg = 0,
    damage_fr = 0,
    damage_fl = 0,
    damage_bridge = 0,
    damage_br = 0,
    damage_bl = 0,
    damage_thruster = 0,
    icon_exclamation = 0,
    icon_play = 0,
    icon_pause = 0,
    icon_stop = 0,
    flag_en = 0,
    flag_de = 0,
    flag_fr = 0,
    flag_es = 0,
    flag_pt = 0,
    flag_ru = 0,
    flag_cn = 0,
    flag_jp = 0,
    column_profile = 0,
    gamepad_icon_a = 0,
    gamepad_icon_b = 0,
    gamepad_icon_x = 0,
    gamepad_icon_y = 0,
    gamepad_icon_start = 0,
    gamepad_icon_back = 0,
    gamepad_icon_dpad_up = 0,
    gamepad_icon_dpad_down = 0,
    gamepad_icon_dpad_left = 0,
    gamepad_icon_dpad_right = 0,
    gamepad_icon_dpad = 0,
    gamepad_icon_rt = 0,
    gamepad_icon_lt = 0,
    gamepad_icon_rb = 0,
    gamepad_icon_lb = 0,
    gamepad_icon_rs = 0,
    gamepad_icon_ls = 0,
    mouse_icon_lmb = 0,
    mouse_icon_rmb = 0,
    mouse_icon_mmb = 0,
    column_save = 0,
    column_load = 0,
    facialhair_a = 0,
    facialhair_a_side = 0,
    facialhair_b = 0,
    facialhair_b_side = 0,
    facialhair_c = 0,
    facialhair_c_side = 0,
    facialhair_d = 0,
    facialhair_d_side = 0,
    facialhair_e = 0,
    facialhair_e_side = 0,
    facialhair_f = 0,
    facialhair_f_side = 0,
    facialhair_g = 0,
    facialhair_g_side = 0,
    facialhair_h = 0,
    facialhair_h_side = 0,
    female_a = 0,
    female_a_side = 0,
    female_b = 0,
    female_b_side = 0,
    female_c = 0,
    female_c_side = 0,
    female_d = 0,
    female_d_side = 0,
    female_e = 0,
    female_e_side = 0,
    female_f = 0,
    female_f_side = 0,
    female_g = 0,
    female_g_side = 0,
    female_h = 0,
    female_h_side = 0,
    female_head = 0,
    female_head_side = 0,
    male_a = 0,
    male_a_side = 0,
    male_b = 0,
    male_b_side = 0,
    male_c = 0,
    male_c_side = 0,
    male_d = 0,
    male_d_side = 0,
    male_f = 0,
    male_f_side = 0,
    male_g = 0,
    male_g_side = 0,
    male_h = 0,
    male_h_side = 0,
    male_head = 0,
    male_head_side = 0,
    text_shift = 0,
    text_del = 0,
    text_space = 0,
    text_confirm = 0,
    column_power = 0,
    column_repair = 0,
    column_propulsion = 0,
    column_difficulty = 0,
    icon_attachment_air_missile_tv = 0,
    icon_attachment_16_air_missile_tv = 0,
    map_icon_camera = 0,
    map_icon_visible = 0,
    map_icon_ship = 0,
    icon_chassis_16_ship_light = 0,
    icon_chassis_16_ship_heavy = 0,
    column_locked = 0,
    column_angle = 0,
    hud_audio = 0,
    icon_attachment_radar_golfball = 0,
    icon_attachment_16_radar_golfball = 0,
    icon_attachment_sonic_pulse_generator = 0,
    icon_attachment_16_sonic_pulse_generator = 0,
    icon_attachment_smoke_launcher_explosive = 0,
    icon_attachment_16_smoke_launcher_explosive = 0,
    icon_attachment_smoke_launcher_stream = 0,
    icon_attachment_16_smoke_launcher_stream = 0,
    gamepad_icon_special_dpad_all = 0,
    gamepad_icon_special_dpad_lr = 0,
    gamepad_icon_special_dpad_ud = 0,
    mouse_icon_special_scroll = 0,
    mouse_icon_special_drag = 0,
    gamepad_icon_special_ls = 0,
    gamepad_icon_special_ls_lr = 0,
    gamepad_icon_special_ls_ud = 0,
    gamepad_icon_special_rs = 0,
    gamepad_icon_special_rs_lr = 0,
    gamepad_icon_special_rs_ud = 0,
    hud_audio_small = 0,
    holomap_icon_carrier = 0,
    icon_chassis_shuttle = 0,
    icon_chassis_16_spaceship = 0,
    column_parachute = 0,
    help_button_breaker = 0,
    help_button_covered = 0,
    help_button_green = 0,
    help_button_grey = 0,
    help_button_grey_small = 0,
    help_button_red = 0,
    help_button_switch = 0,
    help_screen = 0,
    help_icon_indicator = 0,
    help_button_blue = 0,
    crosshair = 0,
    hud_manual_control = 0,
    hud_target_offscreen_friendly = 0,
    map_icon_surface_capture = 0,
    icon_attachment_turret_main_gun_light = 0,
    icon_attachment_16_turret_main_gun_light = 0,
    icon_attachment_turret_main_gun_2 = 0,
    icon_attachment_turret_main_heavy_cannon = 0,
    column_currency = 0,
    column_message = 0,
    column_audio = 0,
    icon_item_16_ammo_30mm = 0,
    icon_item_16_ammo_40mm = 0,
    icon_item_16_ammo_missile = 0,
    icon_item_16_ammo_aa_missile = 0,
    icon_item_16_ammo_cruise_missile = 0,
    icon_item_16_ammo_rocket = 0,
    icon_item_16_ammo_flare = 0,
    icon_item_16_ammo_20mm = 0,
    icon_item_16_ammo_100mm = 0,
    icon_item_16_ammo_120mm = 0,
    icon_item_16_ammo_160mm = 0,
    icon_item_16_fuel_barrel = 0,
    icon_item_16_ammo_sonic_pulse = 0,
    icon_item_16_ammo_smoke = 0,
    icon_chassis_turret = 0,
    mouse_icon_special_ud = 0,
    mouse_icon_special_lr = 0,
    map_icon_load = 0,
    map_icon_unload = 0,
    column_trash = 0,
    icon_chassis_sea_ship_light = 0,
    icon_chassis_wheel_mule = 0,
    icon_chassis_16_wheel_mule = 0,
    icon_attachment_logistics_container_20mm = 0,
    icon_attachment_logistics_container_30mm = 0,
    icon_attachment_logistics_container_40mm = 0,
    icon_attachment_logistics_container_100mm = 0,
    icon_attachment_logistics_container_120mm = 0,
    icon_attachment_logistics_container_fuel = 0,
    icon_attachment_logistics_container_ir_missile = 0,
    icon_attachment_16_logistics_container_20mm = 0,
    icon_attachment_16_logistics_container_30mm = 0,
    icon_attachment_16_logistics_container_40mm = 0,
    icon_attachment_16_logistics_container_100mm = 0,
    icon_attachment_16_logistics_container_120mm = 0,
    icon_attachment_16_logistics_container_fuel = 0,
    icon_attachment_16_logistics_container_ir_missile = 0,
    map_icon_droid = 0,
    icon_chassis_16_droid = 0,
    icon_attachment_16_turret_droid = 0,
    icon_attachment_turret_droid = 0,
    icon_attachment_16_deployable_droid = 0,
    icon_attachment_deployable_droid = 0,
    icon_chassis_deployable_droid = 0,
    icon_attachment_turret_gimbal = 0,
    icon_attachment_16_turret_gimbal = 0,
    column_joystick = 0,
    joystick_icon_b1 = 0,
    joystick_icon_b2 = 0,
    joystick_icon_b3 = 0,
    joystick_icon_b4 = 0,
    joystick_icon_b5 = 0,
    joystick_icon_b6 = 0,
    joystick_icon_b7 = 0,
    joystick_icon_b8 = 0,
    joystick_icon_b9 = 0,
    joystick_icon_b10 = 0,
    joystick_icon_b11 = 0,
    joystick_icon_b12 = 0,
    joystick_icon_b13 = 0,
    joystick_icon_b14 = 0,
    joystick_icon_b15 = 0,
    joystick_icon_b16 = 0,
    joystick_icon_b17 = 0,
    joystick_icon_b18 = 0,
    joystick_icon_b19 = 0,
    joystick_icon_b20 = 0,
    joystick_icon_b21 = 0,
    joystick_icon_b22 = 0,
    joystick_icon_b23 = 0,
    joystick_icon_b24 = 0,
    joystick_icon_b25 = 0,
    joystick_icon_b26 = 0,
    joystick_icon_b27 = 0,
    joystick_icon_b28 = 0,
    joystick_icon_b29 = 0,
    joystick_icon_b30 = 0,
    joystick_icon_b31 = 0,
    joystick_icon_b32 = 0,
    joystick_icon_b33 = 0,
    joystick_icon_b34 = 0,
    joystick_icon_b35 = 0,
    joystick_icon_b36 = 0,
    joystick_icon_b37 = 0,
    joystick_icon_b38 = 0,
    joystick_icon_b39 = 0,
    joystick_icon_b40 = 0,
    joystick_icon_b41 = 0,
    joystick_icon_b42 = 0,
    joystick_icon_b43 = 0,
    joystick_icon_b44 = 0,
    joystick_icon_b45 = 0,
    joystick_icon_b46 = 0,
    joystick_icon_b47 = 0,
    joystick_icon_b48 = 0,
    column_gamepad = 0,
    joystick_icon_a1 = 0,
    joystick_icon_a2 = 0,
    joystick_icon_a3 = 0,
    joystick_icon_a4 = 0,
    joystick_icon_a5 = 0,
    joystick_icon_a6 = 0,
    joystick_icon_a7 = 0,
    joystick_icon_a8 = 0,
}

function begin_load()
    for k, v in pairs(atlas_icons) do
        atlas_icons[k] = begin_get_ui_region_index(k)
    end
end

function get_attachment_icons(definition_index)
    local def_map = {
        [-1] = { atlas_icons.icon_attachment_16_unknown, atlas_icons.icon_attachment_16_unknown },
        [e_game_object_type.attachment_turret_15mm] = { atlas_icons.icon_attachment_turret_main_gun_light, atlas_icons.icon_attachment_16_turret_main_gun_light },
        [e_game_object_type.attachment_turret_30mm] = { atlas_icons.icon_attachment_turret_main_gun, atlas_icons.icon_attachment_16_turret_main_gun },
        [e_game_object_type.attachment_turret_40mm] = { atlas_icons.icon_attachment_turret_main_gun_2, atlas_icons.icon_attachment_16_turret_main_gun_2 },
        [e_game_object_type.attachment_turret_heavy_cannon] = { atlas_icons.icon_attachment_turret_main_heavy_cannon, atlas_icons.icon_attachment_16_turret_main_heavy_cannon },
        [e_game_object_type.attachment_turret_plane_chaingun] = { atlas_icons.icon_attachment_air_chaingun, atlas_icons.icon_attachment_16_air_chaingun },
        [e_game_object_type.attachment_turret_rocket_pod] = { atlas_icons.icon_attachment_rocket_pod, atlas_icons.icon_attachment_16_rocket_pod },
        [e_game_object_type.attachment_turret_robot_dog_capsule] = { atlas_icons.icon_attachment_turret_robots, atlas_icons.icon_attachment_16_turret_robots },
        [e_game_object_type.attachment_turret_ciws] = { atlas_icons.icon_attachment_turret_ciws, atlas_icons.icon_attachment_16_turret_ciws },
        [e_game_object_type.attachment_turret_missile] = { atlas_icons.icon_attachment_turret_missile, atlas_icons.icon_attachment_16_turret_missile },
        [e_game_object_type.attachment_hardpoint_bomb_1] = { atlas_icons.icon_attachment_air_bomb_1, atlas_icons.icon_attachment_16_air_bomb_1 },
        [e_game_object_type.attachment_hardpoint_bomb_2] = { atlas_icons.icon_attachment_air_bomb_2, atlas_icons.icon_attachment_16_air_bomb_2 },
        [e_game_object_type.attachment_hardpoint_bomb_3] = { atlas_icons.icon_attachment_air_bomb_3, atlas_icons.icon_attachment_16_air_bomb_3 },
        [e_game_object_type.attachment_hardpoint_missile_ir] = { atlas_icons.icon_attachment_air_missile_1, atlas_icons.icon_attachment_16_air_missile_1 },
        [e_game_object_type.attachment_hardpoint_missile_laser] = { atlas_icons.icon_attachment_air_missile_2, atlas_icons.icon_attachment_16_air_missile_2 },
        [e_game_object_type.attachment_hardpoint_missile_aa] = { atlas_icons.icon_attachment_air_missile_4, atlas_icons.icon_attachment_16_air_missile_4 },
        [e_game_object_type.attachment_hardpoint_torpedo] = { atlas_icons.icon_attachment_air_torpedo, atlas_icons.icon_attachment_16_air_torpedo },
        [e_game_object_type.attachment_hardpoint_torpedo_noisemaker] = { atlas_icons.icon_attachment_air_torpedo_noisemaker, atlas_icons.icon_attachment_16_air_torpedo_noisemaker },
        [e_game_object_type.attachment_hardpoint_torpedo_decoy] = { atlas_icons.icon_attachment_air_torpedo_decoy, atlas_icons.icon_attachment_16_air_torpedo_decoy },
        [e_game_object_type.attachment_hardpoint_missile_tv] = { atlas_icons.icon_attachment_air_missile_tv, atlas_icons.icon_attachment_16_air_missile_tv },
        [e_game_object_type.attachment_camera_observation] = { atlas_icons.icon_attachment_camera_large, atlas_icons.icon_attachment_16_camera_large },
        [e_game_object_type.attachment_camera_vehicle_control] = { atlas_icons.icon_attachment_small_camera, atlas_icons.icon_attachment_16_small_camera },
        [e_game_object_type.attachment_camera_plane] = { atlas_icons.icon_attachment_camera_aircraft, atlas_icons.icon_attachment_16_camera_aircraft },
        [e_game_object_type.attachment_camera] = { atlas_icons.icon_attachment_small_camera_obs, atlas_icons.icon_attachment_16_small_camera_obs },
        [e_game_object_type.attachment_radar_awacs] = { atlas_icons.icon_attachment_air_radar, atlas_icons.icon_attachment_16_air_radar },
        [e_game_object_type.attachment_fuel_tank_plane] = { atlas_icons.icon_attachment_air_fuel, atlas_icons.icon_attachment_16_air_fuel },
        [e_game_object_type.attachment_flare_launcher] = { atlas_icons.icon_attachment_small_flare, atlas_icons.icon_attachment_16_small_flare },
        [e_game_object_type.attachment_turret_carrier_ciws] = { atlas_icons.icon_attachment_turret_ciws, atlas_icons.icon_attachment_16_turret_ciws },
        [e_game_object_type.attachment_turret_carrier_missile] = { atlas_icons.icon_attachment_turret_missile, atlas_icons.icon_attachment_16_turret_missile },
        [e_game_object_type.attachment_turret_carrier_missile_silo] = { atlas_icons.icon_attachment_turret_missile, atlas_icons.icon_attachment_16_turret_missile },
        [e_game_object_type.attachment_turret_carrier_main_gun] = { atlas_icons.icon_attachment_turret_artillery, atlas_icons.icon_attachment_16_turret_artillery },
        [e_game_object_type.attachment_turret_carrier_flare_launcher] = { atlas_icons.icon_attachment_small_flare, atlas_icons.icon_attachment_16_small_flare },
        [e_game_object_type.attachment_turret_carrier_torpedo] = { atlas_icons.icon_attachment_air_torpedo, atlas_icons.icon_attachment_16_air_torpedo },
        [e_game_object_type.attachment_turret_carrier_torpedo_decoy] = { atlas_icons.icon_attachment_air_torpedo_decoy, atlas_icons.icon_attachment_16_air_torpedo_decoy },
        [e_game_object_type.attachment_turret_carrier_camera] = { atlas_icons.icon_attachment_camera_large, atlas_icons.icon_attachment_16_camera_large },
        [e_game_object_type.attachment_turret_battle_cannon] = { atlas_icons.icon_attachment_turret_main_battle_cannon, atlas_icons.icon_attachment_16_turret_main_battle_cannon },
        [e_game_object_type.attachment_turret_artillery] = { atlas_icons.icon_attachment_turret_artillery, atlas_icons.icon_attachment_16_turret_artillery },
        [e_game_object_type.attachment_radar_golfball] = { atlas_icons.icon_attachment_radar_golfball, atlas_icons.icon_attachment_16_radar_golfball},
        [e_game_object_type.attachment_sonic_pulse_generator] = {  atlas_icons.icon_attachment_sonic_pulse_generator, atlas_icons.icon_attachment_16_sonic_pulse_generator},
        [e_game_object_type.attachment_smoke_launcher_explosive] = { atlas_icons.icon_attachment_smoke_launcher_explosive, atlas_icons.icon_attachment_16_smoke_launcher_explosive},
        [e_game_object_type.attachment_smoke_launcher_stream] = { atlas_icons.icon_attachment_smoke_launcher_stream, atlas_icons.icon_attachment_16_smoke_launcher_stream},
        [e_game_object_type.attachment_turret_carrier_torpedo] = { atlas_icons.icon_attachment_air_torpedo, atlas_icons.icon_attachment_16_air_torpedo },
        [e_game_object_type.attachment_logistics_container_20mm] = { atlas_icons.icon_attachment_logistics_container_20mm, atlas_icons.icon_attachment_16_logistics_container_20mm },
        [e_game_object_type.attachment_logistics_container_30mm] = { atlas_icons.icon_attachment_logistics_container_30mm, atlas_icons.icon_attachment_16_logistics_container_30mm },
        [e_game_object_type.attachment_logistics_container_40mm] = { atlas_icons.icon_attachment_logistics_container_40mm, atlas_icons.icon_attachment_16_logistics_container_40mm },
        [e_game_object_type.attachment_logistics_container_100mm] = { atlas_icons.icon_attachment_logistics_container_100mm, atlas_icons.icon_attachment_16_logistics_container_100mm },
        [e_game_object_type.attachment_logistics_container_120mm] = { atlas_icons.icon_attachment_logistics_container_120mm, atlas_icons.icon_attachment_16_logistics_container_120mm },
        [e_game_object_type.attachment_logistics_container_fuel] = { atlas_icons.icon_attachment_logistics_container_fuel, atlas_icons.icon_attachment_16_logistics_container_fuel },
        [e_game_object_type.attachment_logistics_container_ir_missile] = { atlas_icons.icon_attachment_logistics_container_ir_missile, atlas_icons.icon_attachment_16_logistics_container_ir_missile },
        [e_game_object_type.attachment_turret_droid] = { atlas_icons.icon_attachment_turret_droid, atlas_icons.icon_attachment_16_turret_droid },
        [e_game_object_type.attachment_deployable_droid] = { atlas_icons.icon_attachment_deployable_droid, atlas_icons.icon_attachment_16_deployable_droid },
        [e_game_object_type.attachment_turret_gimbal_30mm] = { atlas_icons.icon_attachment_turret_gimbal, atlas_icons.icon_attachment_16_turret_gimbal },
    }

    local def_data = def_map[definition_index] or def_map[-1]
    
    return def_data[1], def_data[2]
end

function get_screen_from_world(world_x, world_y, camera_x, camera_y, camera_size, screen_w, screen_h, aspect)
    local view_w = camera_size
    local view_h = camera_size
    
    if aspect == nil then
        aspect = screen_w / screen_h
    end

    if aspect > 1 then
        view_w = view_w * aspect
    else
        view_h = view_h / aspect
    end
    
    local view_x = (world_x - camera_x) / view_w
    local view_y = (camera_y - world_y) / view_h

    local screen_x = math.floor(((view_x + 0.5) * screen_w) + 0.5)
    local screen_y = math.floor(((view_y + 0.5) * screen_h) + 0.5)

    return screen_x, screen_y
end

function get_world_from_screen(screen_x, screen_y, camera_x, camera_y, camera_size, screen_w, screen_h, aspect)
    local view_x = (screen_x / screen_w) - 0.5
    local view_y = (screen_y / screen_h) - 0.5

    if aspect == nil then
        aspect = screen_w / screen_h
    end

    local world_x = camera_x + (view_x * camera_size * aspect)
    local world_y = camera_y - (view_y * camera_size)

    return world_x, world_y
end

function get_world_delta_from_screen(dx, dy, camera_size, screen_w, screen_h, aspect)
    return get_world_from_screen(screen_w / 2 + dx, screen_h / 2 + dy, 0, 0, camera_size, screen_w, screen_h, aspect)
end

function lerp(a, b, c)
    return a + (b - a) * c
end

function invlerp(a, min, max)
    return (a - min) / (max - min)
end

function invlerp_clamp(a, min, max)
    return clamp((a - min) / (max - min), 0, 1)
end

function remap(a, min0, max0, min1, max1)
    return lerp(min1, max1, invlerp(a, min0, max0))
end

function remap_clamp(a, min0, max0, min1, max1)
    return clamp(lerp(min1, max1, invlerp(a, min0, max0)), min1, max1)
end

function vec2_lerp(a, b, c)
    return vec2(lerp(a:x(), b:x(), c), lerp(a:y(), b:y(), c))
end

function vec2_dist_sq(a, b)
    local dx = a:x() - b:x()
    local dy = a:y() - b:y()
    return dx * dx + dy * dy
end

function vec2_dist(a, b)
    return math.sqrt(vec2_dist_sq(a, b))
end

function vec2_length_sq(a)
    return a:x() * a:x() + a:y() * a:y()
end

function vec2_length(a)
    return math.sqrt(vec2_length_sq(a))
end

function vec2_normal(a)
    local len = math.max(0.001, vec2_length(a))
    return vec2(a:x() / len, a:y() / len), len
end

function vec2_dot(a, b)
    return a:x() * b:x() + a:y() * b:y()
end

function vec2_clamp_to_rect(pos, min, max)
    local mid = vec2((max:x() + min:x()) / 2, (max:y() + min:y()) / 2)
    local dim = vec2((max:x() - min:x()) / 2, (max:y() - min:y()) / 2)
    local line = vec2(pos:x() - mid:x(), pos:y() - mid:y())
    local dist_x = line:x()
    local dist_y = line:y()
    local time_x = math.abs(dim:x() / dist_x)
    local time_y = math.abs(dim:y() / dist_y)
    local time = math.min(time_x, time_y)
    
    return vec2(mid:x() + line:x() * time, mid:y() + line:y() * time)
end

function vec2_in_rect(pos, min, max)
    return pos:x() > min:x() and pos:y() > min:y() and pos:x() < max:x() and pos:y() < max:y()
end

function vec2_angle(a, b)
    local angle = math.acos(clamp(vec2_dot(a, b), -1, 1))
    return iff(a:y() * b:x() - a:x() * b:y() > 0, angle, -angle)
end

function vec3_dist_sq(a, b)
    local dx = a:x() - b:x()
    local dy = a:y() - b:y()
    local dz = a:z() - b:z()
    return dx * dx + dy * dy + dz * dz
end

function vec3_dist(a, b)
    return math.sqrt(vec3_dist_sq(a, b))
end

function vec3_length(a)
    return math.sqrt(vec3_length_sq(a, b))
end

function vec3_length_sq(a)
    return  a:x() * a:x() + a:y() * a:y() + a:z() * a:z()
end

function vec3_dist(a, b)
    return math.sqrt(vec3_dist_sq(a, b))
end

function vec3_normal(a)
    local len = math.max(0.001, vec3_length(a))
    return vec3(a:x() / len, a:y() / len, a:z() / len), len
end

function vec3_dot(a, b)
    return a:x() * b:x() + a:y() * b:y() + a:z() * b:z()
end

function color8_lerp(a, b, c)
    return color8(
        math.floor(lerp(a:r(), b:r(), c) + 0.5),
        math.floor(lerp(a:g(), b:g(), c) + 0.5),
        math.floor(lerp(a:b(), b:b(), c) + 0.5),
        math.floor(lerp(a:a(), b:a(), c) + 0.5)
    )
end

function color8_eq(c0, c1)
    return c0:r() == c1:r() and c0:g() == c1:g() and c0:b() == c1:b() and c0:a() == c1:a()
end

function clamp(x, min, max)
    return math.max(min, math.min(max, x))
end

function clamp_str(str, max_chars)
    if str:len() > max_chars then
        --Return the byte offset for the start encoding UTF8 character at byte <max_chars>
        local offset = utf8.offset(str, 0, max_chars)

        if(offset == nil) then
            return str:sub(1, max_chars)
        else
            return str:sub(1, offset)
        end
    end

    return str
end

function round_down(val, precision)
    return math.floor(val / precision) * precision
end

function iff(condition, t, f)
    if condition then return t else return f end
end

function clip_line_to_rect(x0, y0, x1, y1, xmin, ymin, xmax, ymax)
    -- cohen-sutherland line clipping algorithm

    local regions = { 
        inside = 0,
        left = 1,
        right = 2,
        bottom = 4,
        top = 8
    }

    local function compute_region(x, y)
        local region = regions.inside

        if x < xmin then region = region | regions.left
        elseif x > xmax then region = region | regions.right
        end

        if y < ymin then region = region | regions.bottom 
        elseif y > ymax then region = region | regions.top
        end

        return region
    end

    local region_p0 = compute_region(x0, y0)
    local region_p1 = compute_region(x1, y1)

    while true do
        if (region_p0 | region_p1) == 0 then
            return x0, y0, x1, y1
        elseif (region_p0 & region_p1) ~= 0 then
            return nil
        else
            local region_out = iff(region_p1 > region_p0, region_p1, region_p0)
            local x = 0
            local y = 0

            if (region_out & regions.top) ~= 0 then
                x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
                y = ymax
            elseif (region_out & regions.bottom) ~= 0 then
                x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0)
                y = ymin
            elseif (region_out & regions.right) ~= 0 then
                x = xmax
                y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0)
            elseif (region_out & regions.left) ~= 0 then
                x = xmin
                y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0)
            end

            if region_out == region_p0 then
                x0 = x
                y0 = y
                region_p0 = compute_region(x0, y0)
            else
                x1 = x
                y1 = y
                region_p1 = compute_region(x1, y1)
            end
        end
    end
end

g_is_on = true
g_boot_counter = 30

g_self_destruct_modes = {
    locked = 0,
    input = 1,
    ready = 2,
    countdown = 3,
}

function update_screen_overrides(screen_w, screen_h, ticks)
    if update_boot_override(screen_w, screen_h, ticks) then
        return true
    elseif update_self_destruct_override(screen_w, screen_h) then
        return true
    elseif update_access_denied(screen_w, screen_h, ticks) then
        return true
    end

    return false
end

function update_boot_override(screen_w, screen_h, ticks)
    if g_is_on then
        if g_boot_counter > 0 then
        
            local cx = screen_w / 2
            local cy = screen_h / 2
            
            update_ui_rectangle(cx - 31, cy - 4, 62, 8, color_white)
            update_ui_rectangle(cx - 30, cy - 3, 60, 6, color_black)
            update_ui_rectangle(cx - 30, cy - 3, 60 - (g_boot_counter * 2), 6, color_status_ok)
            g_boot_counter = g_boot_counter - math.random(0, ticks)
            
            return true
        end
    else
        g_boot_counter = 30
    end
    
    return false
end

function update_self_destruct_override(screen_w, screen_h)
    local this_vehicle = update_get_screen_vehicle()
    if this_vehicle:get() == false then return false end
    local this_vehicle_object = update_get_vehicle_by_id(this_vehicle:get_id())
    if this_vehicle_object:get() == false then return false end

    if this_vehicle_object:get_self_destruct_mode() ~= g_self_destruct_modes.countdown then return false end

    update_set_screen_background_type(0)

    local countdown = this_vehicle_object:get_self_destruct_countdown()

    local cx = screen_w / 2
    local cy = screen_h / 2

    update_ui_image(cx - 16, cy - 42, atlas_icons.self_destruct, color_status_bad, 0)

    update_ui_text(cx - 64, cy - 12, update_get_loc(e_loc.upp_self_destruct_in), 128, 1, color_status_bad, 0)
    
    local digit_icons = {
        ['0'] = atlas_icons.countdown_0,
        ['1'] = atlas_icons.countdown_1,
        ['2'] = atlas_icons.countdown_2,
        ['3'] = atlas_icons.countdown_3,
        ['4'] = atlas_icons.countdown_4,
        ['5'] = atlas_icons.countdown_5,
        ['6'] = atlas_icons.countdown_6,
        ['7'] = atlas_icons.countdown_7,
        ['8'] = atlas_icons.countdown_8,
        ['9'] = atlas_icons.countdown_9,
    }

    local countdown_text = string.format("%05.2f", math.min(99, countdown / 30.0))
    local cursor = 0
    local text_w = 5 * 16

    for i = 1, #countdown_text do
        if digit_icons[countdown_text:sub(i, i)] ~= nil then
            update_ui_image(cx - text_w / 2 + cursor, cy + 2, digit_icons[countdown_text:sub(i, i)], color_status_bad, 0)
        else
            update_ui_rectangle(cx - text_w / 2 + cursor + 7, cy + 21, 3, 3, color_status_bad)
        end

        cursor = cursor + 16
    end

    return true
end

g_denied_anim = 0
function update_access_denied(screen_w, screen_h, ticks)
    if true or not update_get_is_multiplayer() then return false end

--[[ The following is not implemented yet so abort
    local peer_id = update_get_screen_peer_id()
    local peer_index = update_get_peer_index_by_id(peer_id)
    if update_get_peer_team(peer_index) ~= update_get_screen_team_id() then return false end
--]]

    g_denied_anim = g_denied_anim + ticks

    local msg = "ACCESS DENIED"

    local msg_w, msg_h = update_ui_get_text_size(msg, screen_w, 0)

    local cx = (screen_w / 2) - (msg_w / 2)
    local cy = (screen_h / 2) - (msg_h / 2)

    local rate = 10
    local blink_on = g_denied_anim % (2 * rate) > rate

    update_ui_rectangle( cx - 3, cy - 2, msg_w + 5, msg_h + 4, color_status_bad )

    update_ui_rectangle( cx - 2, cy - 1, msg_w + 3, msg_h + 2, iff(blink_on, color_status_bad, color_black) )

    update_ui_text(cx, cy, msg, msg_w, msg_h, iff(blink_on, color_black, color_status_bad), 0)

    return true
end

function point_in_rect(rx, ry, rw, rh, x, y)
    return x >= rx and y >= ry and x < rx + rw and y < ry + rh
end

function table_count(t)
    local i = 0

    for _, v in pairs(t) do
        i = i + 1
    end

    return i
end

function format_time(time)
    local seconds = math.floor(time) % 60
    local minutes = math.floor(time / 60) % 60
    local hours = math.min(math.floor(time / 60 / 60), 99)

    return string.format("%02.f:%02.f:%02.f", hours, minutes, seconds)
end

function mult_alpha(col, alpha)
    return color8(col:r(), col:g(), col:b(), math.floor(col:a() * alpha))  
end

function countif(table, pred)
    local count = 0

    for _, v in pairs(table) do
        if pred(v) then count = count + 1 end
    end

    return count
end

function findif(table, pred)
    for k, v in pairs(table) do
        if pred(v) then return v, k end
    end

    return nil
end