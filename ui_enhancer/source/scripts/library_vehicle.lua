function get_carrier_bay_name(index)
    bay_name = update_get_loc(e_loc.upp_acronym_surface).."1";

    if(index >= 8)
    then
        bay_name = update_get_loc(e_loc.upp_acronym_air)..(index - 7)
    else
        bay_name = update_get_loc(e_loc.upp_acronym_surface)..(index + 1)
    end

    return bay_name
end

function get_icon_data_by_definition_index(index)
    region_vehicle_icon = atlas_icons.map_icon_air
    icon_offset = 4

    if index == e_game_object_type.chassis_land_wheel_light or index == e_game_object_type.chassis_land_wheel_medium or index == e_game_object_type.chassis_land_wheel_heavy or index == e_game_object_type.chassis_land_wheel_mule then
        region_vehicle_icon = atlas_icons.map_icon_surface
        icon_offset = 4
    elseif index == e_game_object_type.chassis_carrier then
        region_vehicle_icon = atlas_icons.map_icon_carrier
        icon_offset = 8
    elseif index == e_game_object_type.chassis_sea_barge then
        region_vehicle_icon = atlas_icons.map_icon_barge
        icon_offset = 4
    elseif index == e_game_object_type.chassis_land_turret then
        region_vehicle_icon = atlas_icons.map_icon_turret
        icon_offset = 4
    elseif index == e_game_object_type.chassis_land_robot_dog then
        region_vehicle_icon = atlas_icons.map_icon_robot_dog
        icon_offset = 4
    elseif index == e_game_object_type.chassis_sea_ship_light or index == e_game_object_type.chassis_sea_ship_heavy then
        region_vehicle_icon = atlas_icons.map_icon_ship
        icon_offset = 5
    elseif index == e_game_object_type.chassis_deployable_droid then
        region_vehicle_icon = atlas_icons.map_icon_droid
        icon_offset = 4
    end

    return region_vehicle_icon, icon_offset
end

function get_chassis_data_by_definition_index(index)
    if index == e_game_object_type.chassis_carrier then
        return update_get_loc(e_loc.upp_carrier), atlas_icons.icon_chassis_16_carrier, update_get_loc(e_loc.upp_crr), update_get_loc(e_loc.upp_logistics_carrier)
    elseif index == e_game_object_type.chassis_land_wheel_light then
        return update_get_loc(e_loc.upp_seal), atlas_icons.icon_chassis_16_wheel_small, update_get_loc(e_loc.upp_sel), update_get_loc(e_loc.upp_light_scout_vehicle)
    elseif index == e_game_object_type.chassis_land_wheel_medium then
        return update_get_loc(e_loc.upp_walrus), atlas_icons.icon_chassis_16_wheel_medium, update_get_loc(e_loc.upp_wlr), update_get_loc(e_loc.upp_all_purpose_vehicle)
    elseif index == e_game_object_type.chassis_land_wheel_heavy then
        return update_get_loc(e_loc.upp_bear), atlas_icons.icon_chassis_16_wheel_large, update_get_loc(e_loc.upp_ber), update_get_loc(e_loc.upp_heavy_platform)
    elseif index == e_game_object_type.chassis_air_wing_light then
        return update_get_loc(e_loc.upp_albatross), atlas_icons.icon_chassis_16_wing_small, update_get_loc(e_loc.upp_alb), update_get_loc(e_loc.upp_scout_wing_aircraft)
    elseif index == e_game_object_type.chassis_air_wing_heavy then
        return update_get_loc(e_loc.upp_manta), atlas_icons.icon_chassis_16_wing_large, update_get_loc(e_loc.upp_mnt), update_get_loc(e_loc.upp_fast_jet_aircraft)
    elseif index == e_game_object_type.chassis_air_rotor_light then
        return update_get_loc(e_loc.upp_razorbill), atlas_icons.icon_chassis_16_rotor_small, update_get_loc(e_loc.upp_rzr), update_get_loc(e_loc.upp_light_rotor)
    elseif index == e_game_object_type.chassis_air_rotor_heavy then
        return update_get_loc(e_loc.upp_petrel), atlas_icons.icon_chassis_16_rotor_large, update_get_loc(e_loc.upp_ptr), update_get_loc(e_loc.upp_heavy_lift_rotor)
    elseif index == e_game_object_type.chassis_sea_barge then
        return update_get_loc(e_loc.upp_barge), atlas_icons.icon_chassis_16_barge, update_get_loc(e_loc.upp_brg), update_get_loc(e_loc.upp_support_barge)
    elseif index == e_game_object_type.chassis_land_turret then
        return update_get_loc(e_loc.upp_turret), atlas_icons.icon_chassis_16_land_turret, update_get_loc(e_loc.upp_trt), update_get_loc(e_loc.upp_stationary_turret)
    elseif index == e_game_object_type.chassis_land_robot_dog then
        return update_get_loc(e_loc.upp_control_bot), atlas_icons.icon_chassis_16_robot_dog, update_get_loc(e_loc.upp_bot), update_get_loc(e_loc.upp_control_bot)
    elseif index == e_game_object_type.chassis_sea_ship_light then
        return update_get_loc(e_loc.upp_needlefish), atlas_icons.icon_chassis_16_ship_light, update_get_loc(e_loc.upp_ndl), update_get_loc(e_loc.upp_light_patrol_ship)
    elseif index == e_game_object_type.chassis_sea_ship_heavy then
        return update_get_loc(e_loc.upp_swordfish), atlas_icons.icon_chassis_16_ship_heavy, update_get_loc(e_loc.upp_swd), update_get_loc(e_loc.upp_heavy_patrol_ship)
    elseif index == e_game_object_type.chassis_land_wheel_mule then
        return update_get_loc(e_loc.upp_mule), atlas_icons.icon_chassis_16_wheel_mule, update_get_loc(e_loc.upp_mul), update_get_loc(e_loc.upp_logistics_support_vehicle)
    elseif index == e_game_object_type.chassis_deployable_droid then
        return update_get_loc(e_loc.upp_droid), atlas_icons.icon_chassis_16_droid, update_get_loc(e_loc.upp_drd), update_get_loc(e_loc.upp_droid)
    end

    return update_get_loc(e_loc.upp_unknown), atlas_icons.icon_chassis_16_wheel_small, "---", ""
end

function get_attachment_data_by_definition_index(index)
    local attachment_data = {
        [-1] = { 
            unknown = true,
            name = update_get_loc(e_loc.upp_unknown),
            icon16 = atlas_icons.icon_attachment_16_none,
            name_short = update_get_loc(e_loc.upp_unknown),
        },
        [e_game_object_type.attachment_turret_15mm] = {
            name = update_get_loc(e_loc.upp_15mm_cannon),
            icon16 = atlas_icons.icon_attachment_16_turret_main_gun_light,
            name_short = update_get_loc(e_loc.upp_gun) .. " 15MM",
        },
        [e_game_object_type.attachment_turret_30mm] = {
            name = update_get_loc(e_loc.upp_30mm_cannon),
            icon16 = atlas_icons.icon_attachment_16_turret_main_gun,
            name_short = update_get_loc(e_loc.upp_gun) .. " 30MM",
        },
        [e_game_object_type.attachment_turret_40mm] = {
            name = update_get_loc(e_loc.upp_40mm_cannon),
            icon16 = atlas_icons.icon_attachment_16_turret_main_gun_2,
            name_short = update_get_loc(e_loc.upp_gun) .. " 40MM",
        },
        [e_game_object_type.attachment_turret_heavy_cannon] = {
            name = update_get_loc(e_loc.upp_heavy_cannon),
            icon16 = atlas_icons.icon_attachment_16_turret_main_heavy_cannon,
            name_short = update_get_loc(e_loc.upp_gun) .. " HEAVY",
        },
        [e_game_object_type.attachment_turret_battle_cannon] = {
            name = update_get_loc(e_loc.upp_100mm_cannon),
            icon16 = atlas_icons.icon_attachment_16_turret_main_battle_cannon,
            name_short = update_get_loc(e_loc.upp_gun) .. " BATTLE",
        },
        [e_game_object_type.attachment_turret_artillery] = {
            name = update_get_loc(e_loc.upp_artillery_gun),
            icon16 = atlas_icons.icon_attachment_16_turret_artillery,
            name_short = update_get_loc(e_loc.upp_gun) .. " 120MM",
        },
        [e_game_object_type.attachment_turret_carrier_main_gun] = {
            name = update_get_loc(e_loc.upp_naval_gun),
            icon16 = atlas_icons.icon_attachment_16_turret_main_battle_cannon,
            name_short = update_get_loc(e_loc.upp_gun) .. " 160MM",
        },
        [e_game_object_type.attachment_turret_plane_chaingun] = {
            name = update_get_loc(e_loc.upp_20mm_auto_cannon),
            icon16 = atlas_icons.icon_attachment_16_air_chaingun,
            name_short = "CHAINGUN",
        },
        [e_game_object_type.attachment_turret_rocket_pod] = {
            name = update_get_loc(e_loc.upp_rocket_pod),
            icon16 = atlas_icons.icon_attachment_16_rocket_pod,
            name_short = "ROCKET POD",
        },
        [e_game_object_type.attachment_turret_robot_dog_capsule] = {
            name = update_get_loc(e_loc.upp_control_bots),
            icon16 = atlas_icons.icon_attachment_16_turret_robots,
            name_short = update_get_loc(e_loc.upp_control_bot),
        },
        [e_game_object_type.attachment_turret_ciws] = {
            name = update_get_loc(e_loc.upp_anti_air_cannon),
            icon16 = atlas_icons.icon_attachment_16_turret_ciws,
            name_short = update_get_loc(e_loc.upp_a_msl),
        },
        [e_game_object_type.attachment_turret_missile] = {
            name = update_get_loc(e_loc.upp_missile_array),
            icon16 = atlas_icons.icon_attachment_16_turret_missile,
            name_short = update_get_loc(e_loc.upp_msl) .. " IR",
        },
        [e_game_object_type.attachment_turret_carrier_ciws] = {
            name = update_get_loc(e_loc.upp_naval_anti_air_cannon),
            icon16 = atlas_icons.icon_attachment_16_turret_ciws,
            name_short = update_get_loc(e_loc.upp_a_msl),
        },
        [e_game_object_type.attachment_turret_carrier_missile] = {
            name = update_get_loc(e_loc.upp_naval_missile_array),
            icon16 = atlas_icons.icon_attachment_16_turret_missile,
            name_short = update_get_loc(e_loc.upp_msl) .. " AA",
        },
        [e_game_object_type.attachment_turret_carrier_missile_silo] = {
            name = update_get_loc(e_loc.upp_naval_cruise_missile),
            icon16 = atlas_icons.icon_attachment_16_turret_missile,
            name_short = "CRUISE MSL",
        },
        [e_game_object_type.attachment_turret_carrier_flare_launcher] = {
            name = update_get_loc(e_loc.upp_naval_flare_launcher),
            icon16 = atlas_icons.icon_attachment_16_small_flare,
            name_short = "FLARE",
        },
        [e_game_object_type.attachment_turret_carrier_camera] = {
            name = update_get_loc(e_loc.upp_naval_camera),
            icon16 = atlas_icons.icon_attachment_16_camera_large,
            name_short = "OBS CAM",
        },
        [e_game_object_type.attachment_turret_carrier_torpedo] = {
            name = update_get_loc(e_loc.upp_torpedo),
            icon16 = atlas_icons.icon_attachment_16_air_torpedo,
            name_short = "TORP EXPL",
        },
        [e_game_object_type.attachment_turret_carrier_torpedo_decoy] = {
            name = update_get_loc(e_loc.upp_torpedo_decoy),
            icon16 = atlas_icons.icon_attachment_16_air_torpedo_decoy,
            name_short = "TORP DECOY",
        },
        [e_game_object_type.attachment_hardpoint_bomb_1] = {
            name = update_get_loc(e_loc.upp_bomb_1),
            icon16 = atlas_icons.icon_attachment_16_air_bomb_1,
            name_short = "BOMB LIGHT",
        },
        [e_game_object_type.attachment_hardpoint_bomb_2] = {
            name = update_get_loc(e_loc.upp_bomb_2),
            icon16 = atlas_icons.icon_attachment_16_air_bomb_2,
            name_short = "BOMB MEDIUM",
        },
        [e_game_object_type.attachment_hardpoint_bomb_3] = {
            name = update_get_loc(e_loc.upp_bomb_3),
            icon16 = atlas_icons.icon_attachment_16_air_bomb_3,
            name_short = "BOMB HEAVY",
        },
        [e_game_object_type.attachment_hardpoint_torpedo] = {
            name = update_get_loc(e_loc.upp_torpedo),
            icon16 = atlas_icons.icon_attachment_16_air_torpedo,
            name_short = "TORP EXPL",
        },
        [e_game_object_type.attachment_hardpoint_torpedo_noisemaker] = {
            name = update_get_loc(e_loc.upp_torpedo_noisemaker),
            icon16 = atlas_icons.icon_attachment_16_air_torpedo_noisemaker,
            name_short = "TORP NOISE",
        },
        [e_game_object_type.attachment_hardpoint_torpedo_decoy] = {
            name = update_get_loc(e_loc.upp_torpedo_decoy),
            icon16 = atlas_icons.icon_attachment_16_air_torpedo_decoy,
            name_short = "TORP DECOY",
        },
        [e_game_object_type.attachment_hardpoint_missile_ir] = {
            name = update_get_loc(e_loc.upp_missile_1),
            icon16 = atlas_icons.icon_attachment_16_air_missile_1,
            name_short = update_get_loc(e_loc.upp_msl) .. " IR",
        },
        [e_game_object_type.attachment_hardpoint_missile_laser] = {
            name = update_get_loc(e_loc.upp_missile_2),
            icon16 = atlas_icons.icon_attachment_16_air_missile_2,
            name_short = update_get_loc(e_loc.upp_msl) .. " LSR",
        },
        [e_game_object_type.attachment_hardpoint_missile_aa] = {
            name = update_get_loc(e_loc.upp_missile_4),
            icon16 = atlas_icons.icon_attachment_16_air_missile_4,
            name_short = update_get_loc(e_loc.upp_msl) .. " AA",
        },
        [e_game_object_type.attachment_hardpoint_missile_tv] = {
            name = update_get_loc(e_loc.upp_missile_tv),
            icon16 = atlas_icons.icon_attachment_16_air_missile_tv,
            name_short = update_get_loc(e_loc.upp_msl) .. " TV",
        },
        [e_game_object_type.attachment_camera] = {
            name = update_get_loc(e_loc.upp_actuated_camera),
            icon16 = atlas_icons.icon_attachment_16_small_camera_obs,
            name_short = "VIEW CAM",
        },
        [e_game_object_type.attachment_camera_vehicle_control] = {
            name = update_get_loc(e_loc.upp_fixed_camera),
            icon16 = atlas_icons.icon_attachment_16_small_camera,
            name_short = "CONTROL",
        },
        [e_game_object_type.attachment_camera_plane] = {
            name = update_get_loc(e_loc.upp_gimbal_camera),
            icon16 = atlas_icons.icon_attachment_16_camera_aircraft,
            name_short = "OBS CAM",
        },
        [e_game_object_type.attachment_camera_observation] = {
            name = update_get_loc(e_loc.upp_observation_camera),
            icon16 = atlas_icons.icon_attachment_16_camera_large,
            name_short = "OBS CAM",
        },
        [e_game_object_type.attachment_radar_awacs] = {
            name = update_get_loc(e_loc.upp_awacs_radar_system),
            icon16 = atlas_icons.icon_attachment_16_air_radar,
            name_short = "AWACS",
        },
        [e_game_object_type.attachment_fuel_tank_plane] = {
            name = update_get_loc(e_loc.upp_external_fuel_tank),
            icon16 = atlas_icons.icon_attachment_16_air_fuel,
            name_short = "FUEL TANK",
        },
        [e_game_object_type.attachment_flare_launcher] = {
            name = update_get_loc(e_loc.upp_ir_countermeasures),
            icon16 = atlas_icons.icon_attachment_16_small_flare,
            name_short = "FLARE",
        },
        [e_game_object_type.attachment_radar_golfball] = {
            name = update_get_loc(e_loc.upp_radar_golfball),
            icon16 = atlas_icons.icon_attachment_16_radar_golfball,
            name_short = "RADAR",
        },
        [e_game_object_type.attachment_sonic_pulse_generator] = {
            name = update_get_loc(e_loc.upp_sonic_pulse_generator),
            icon16 = atlas_icons.icon_attachment_16_sonic_pulse_generator,
            name_short = "PULSE GEN",
        },
        [e_game_object_type.attachment_smoke_launcher_explosive] = {
            name = update_get_loc(e_loc.upp_smoke_launcher_explosive),
            icon16 = atlas_icons.icon_attachment_16_smoke_launcher_explosive,
            name_short = "SMK EXPL",
        },
        [e_game_object_type.attachment_smoke_launcher_stream] = {
            name = update_get_loc(e_loc.upp_smoke_launcher_stream),
            icon16 = atlas_icons.icon_attachment_16_smoke_launcher_stream,
            name_short = "SMK STRM",
        },
        [e_game_object_type.attachment_turret_carrier_torpedo] = {
            name = update_get_loc(e_loc.upp_torpedo),
            icon16 = atlas_icons.icon_attachment_16_air_torpedo,
            name_short = "TORP EXPL",
        },
        [e_game_object_type.attachment_logistics_container_20mm] = {
            name = update_get_loc(e_loc.upp_logistics_container_20mm),
            icon16 = atlas_icons.icon_attachment_16_logistics_container_20mm,
            name_short = "BOX 20MM",
        },
        [e_game_object_type.attachment_logistics_container_30mm] = {
            name = update_get_loc(e_loc.upp_logistics_container_30mm),
            icon16 = atlas_icons.icon_attachment_16_logistics_container_30mm,
            name_short = "BOX 30MM",
        },
        [e_game_object_type.attachment_logistics_container_40mm] = {
            name = update_get_loc(e_loc.upp_logistics_container_40mm),
            icon16 = atlas_icons.icon_attachment_16_logistics_container_40mm,
            name_short = "BOX 40MM",
        },
        [e_game_object_type.attachment_logistics_container_100mm] = {
            name = update_get_loc(e_loc.upp_logistics_container_100mm),
            icon16 = atlas_icons.icon_attachment_16_logistics_container_100mm,
            name_short = "BOX 100MM",
        },
        [e_game_object_type.attachment_logistics_container_120mm] = {
            name = update_get_loc(e_loc.upp_logistics_container_120mm),
            icon16 = atlas_icons.icon_attachment_16_logistics_container_120mm,
            name_short = "BOX 120MM",
        },
        [e_game_object_type.attachment_logistics_container_fuel] = {
            name = update_get_loc(e_loc.upp_logistics_container_fuel),
            icon16 = atlas_icons.icon_attachment_16_logistics_container_fuel,
            name_short = "BOX FUEL",
        },
        [e_game_object_type.attachment_logistics_container_ir_missile] = {
            name = update_get_loc(e_loc.upp_logistics_container_ir_missile),
            icon16 = atlas_icons.icon_attachment_16_logistics_container_ir_missile,
            name_short = "BOX IR " .. update_get_loc(e_loc.upp_msl),
        },
        [e_game_object_type.attachment_turret_droid] = {
            name = update_get_loc(e_loc.upp_turret_droid),
            icon16 = atlas_icons.icon_attachment_16_turret_droid,
            name_short = "DUAL 30MM",
        },
        [e_game_object_type.attachment_deployable_droid] = {
            name = update_get_loc(e_loc.upp_deployable_droid),
            icon16 = atlas_icons.icon_attachment_16_deployable_droid,
            name_short = "DROID",
        },
        [e_game_object_type.attachment_turret_gimbal_30mm] = {
            name = update_get_loc(e_loc.upp_30mm_gimbal),
            icon16 = atlas_icons.icon_attachment_16_turret_gimbal,
            name_short = update_get_loc(e_loc.upp_gun) .. " 30MM",
        },
    }

    return attachment_data[index] or attachment_data[-1]
end

function get_chassis_image_by_definition_index(index)
    if index == e_game_object_type.chassis_land_wheel_light then
        return atlas_icons.icon_chassis_wheel_small
    elseif index == e_game_object_type.chassis_land_wheel_medium then
        return atlas_icons.icon_chassis_wheel_medium
    elseif index == e_game_object_type.chassis_land_wheel_heavy then
        return atlas_icons.icon_chassis_wheel_large
    elseif index == e_game_object_type.chassis_air_wing_light then
        return atlas_icons.icon_chassis_wing_small
    elseif index == e_game_object_type.chassis_air_wing_heavy then
        return atlas_icons.icon_chassis_wing_large
    elseif index == e_game_object_type.chassis_air_rotor_light then
        return atlas_icons.icon_chassis_rotor_small
    elseif index == e_game_object_type.chassis_air_rotor_heavy then
        return atlas_icons.icon_chassis_rotor_large
    elseif index == e_game_object_type.chassis_land_turret then
        return atlas_icons.icon_chassis_turret
    elseif index == e_game_object_type.chassis_sea_ship_light then
        return atlas_icons.icon_chassis_sea_ship_light
    elseif index == e_game_object_type.chassis_land_wheel_mule then
        return atlas_icons.icon_chassis_wheel_mule
    elseif index == e_game_object_type.chassis_deployable_droid then
        return atlas_icons.icon_chassis_deployable_droid
    end

    return atlas_icons.icon_chassis_unknown
end

function get_is_vehicle_air(definition_index)
    return definition_index == e_game_object_type.chassis_air_wing_light
        or definition_index == e_game_object_type.chassis_air_wing_heavy
        or definition_index == e_game_object_type.chassis_air_rotor_light
        or definition_index == e_game_object_type.chassis_air_rotor_heavy
end

function get_is_vehicle_sea(definition_index)
    return definition_index == e_game_object_type.chassis_carrier
        or definition_index == e_game_object_type.chassis_sea_barge
        or definition_index == e_game_object_type.chassis_sea_ship_light
        or definition_index == e_game_object_type.chassis_sea_ship_heavy
end

function get_is_vehicle_land(definition_index)
    return definition_index == e_game_object_type.chassis_land_wheel_heavy
        or definition_index == e_game_object_type.chassis_land_wheel_medium
        or definition_index == e_game_object_type.chassis_land_wheel_light
        or definition_index == e_game_object_type.chassis_land_robot_dog
        or definition_index == e_game_object_type.chassis_land_turret
        or definition_index == e_game_object_type.chassis_land_wheel_mule
        or definition_index == e_game_object_type.chassis_deployable_droid
end

function get_is_vehicle_airliftable(definition_index)
    return definition_index == e_game_object_type.chassis_land_wheel_heavy
        or definition_index == e_game_object_type.chassis_land_wheel_medium
        or definition_index == e_game_object_type.chassis_land_wheel_light
        or definition_index == e_game_object_type.chassis_land_robot_dog
        or definition_index == e_game_object_type.chassis_land_wheel_mule
end

function get_attack_type_icon(attack_type)
    if attack_type == e_attack_type.none then
        return atlas_icons.icon_attack_type_any
    elseif attack_type == e_attack_type.any then
        return atlas_icons.icon_attack_type_any
    elseif attack_type == e_attack_type.bomb_single then
        return atlas_icons.icon_attack_type_bomb_single
    elseif attack_type == e_attack_type.bomb_double then
        return atlas_icons.icon_attack_type_bomb_double
    elseif attack_type == e_attack_type.missile_single then
        return atlas_icons.icon_attack_type_missile_single
    elseif attack_type == e_attack_type.missile_double then
        return atlas_icons.icon_attack_type_missile_double
    elseif attack_type == e_attack_type.torpedo_single then
        return atlas_icons.icon_attack_type_torpedo_single
    elseif attack_type == e_attack_type.gun then
        return atlas_icons.icon_attack_type_gun
    elseif attack_type == e_attack_type.rockets then
        return atlas_icons.icon_attack_type_rockets
    elseif attack_type == e_attack_type.airlift then
        return atlas_icons.icon_attack_type_airlift
    end

    return atlas_icons.icon_attack_type_any
end

function render_ui_chassis_definition_description(x, y, vehicle, index)
    update_ui_push_offset(x, y)
    local cy = 0

    vehicle_definition_name, region_vehicle_icon, vehicle_definition_abreviation, vehicle_definition_description = get_chassis_data_by_definition_index(index)
    update_ui_text(0, cy, vehicle_definition_name, 120, 0, color_white, 0)

    local inventory_count = vehicle:get_inventory_count_by_definition_index(index)
    update_ui_text(0, cy, "x" .. inventory_count, 120, 2, iff(inventory_count > 0, color_status_ok, color_status_bad), 0)
    cy = cy + 10

    local text_h = update_ui_text(0, cy, vehicle_definition_description, 120, 0, color_grey_dark, 0)
    cy = cy + text_h + 2
    
    local hitpoints, armour, mass = update_get_definition_vehicle_stats(index)
    local icon_col = color_white
    local text_col = color_status_ok

    update_ui_image(0, cy, atlas_icons.icon_health, icon_col, 0)
    update_ui_text(10, cy, hitpoints, 64, 0, text_col, 0)
    cy = cy + 10

    update_ui_image(0, cy, atlas_icons.column_difficulty, icon_col, 0)
    update_ui_text(10, cy, armour, 64, 0, text_col, 0)
    cy = cy + 10

    update_ui_image(0, cy, atlas_icons.column_weight, icon_col, 0)
    update_ui_text(10, cy, mass .. update_get_loc(e_loc.upp_kg), 64, 0, text_col, 0)
    cy = cy + 10

    update_ui_pop_offset()
end

function get_is_vehicle_type_waypoint_capable(vehicle_definition_index)
    if vehicle_definition_index == e_game_object_type.chassis_carrier then
        return false
    elseif vehicle_definition_index == e_game_object_type.chassis_land_wheel_light then
        return true
    elseif vehicle_definition_index == e_game_object_type.chassis_land_wheel_medium then
        return true
    elseif vehicle_definition_index == e_game_object_type.chassis_land_wheel_heavy then
        return true
    elseif vehicle_definition_index == e_game_object_type.chassis_air_wing_light then
        return true
    elseif vehicle_definition_index == e_game_object_type.chassis_air_wing_heavy then
        return true
    elseif vehicle_definition_index == e_game_object_type.chassis_air_rotor_light then
        return true
    elseif vehicle_definition_index == e_game_object_type.chassis_air_rotor_heavy then
        return true
    elseif vehicle_definition_index == e_game_object_type.chassis_sea_barge then
        return false
    elseif vehicle_definition_index == e_game_object_type.chassis_land_turret then
        return false
    elseif vehicle_definition_index == e_game_object_type.chassis_sea_ship_light then
        return true
    elseif vehicle_definition_index == e_game_object_type.chassis_sea_ship_heavy then
        return true
    elseif vehicle_definition_index == e_game_object_type.chassis_land_wheel_mule then
        return true
    elseif vehicle_definition_index == e_game_object_type.chassis_deployable_droid then
        return true
    end

    return false
end

function get_vehicle_controlling_peers(vehicle)
    local peers = {}

    if not update_get_is_multiplayer() or vehicle:get_definition_index() == e_game_object_type.chassis_carrier then return peers end

    local attachment_count = vehicle:get_attachment_count()
    for i = 0, attachment_count - 1 do
        local attachment = vehicle:get_attachment(i)
        if attachment:get() then
            local peer_id = attachment:get_controlling_peer_id()

            if peer_id ~= 0 then
                local peer_ctrl = attachment:get_control_mode() == "manual"

                local peer_index = update_get_peer_index_by_id(peer_id)
                table.insert( peers, {
                    id = peer_id,
                    name = update_get_peer_name(peer_index),
                    ctrl = peer_ctrl,
                    attachment_index = i
                })
            end
        end
    end

    return peers
end


g_item_categories = {}
g_item_data = {}
g_item_count = 0

function begin_load_inventory_data()
    for i = 0, update_get_resource_inventory_category_count() - 1 do
        local category_index, category_name, icon_name = update_get_resource_inventory_category_data(i)
        local category_object = 
        {
            index = category_index, 
            name = category_name, 
            icon = atlas_icons[icon_name], 
            items = {},
            item_count = 0,
        }
        g_item_categories[category_index] = category_object

        if category_object.icon == nil then
            MM_LOG("icon not found: "..icon_name)
        end
    end
    
    for i = 0, update_get_resource_inventory_item_count() - 1 do
        local item_type, item_category, item_mass, item_production_cost, item_production_time, item_name, item_desc, icon_name, transfer_duration = update_get_resource_inventory_item_data(i)

        local item_object = 
        {
            index = item_type, 
            category = item_category, 
            mass = item_mass, 
            cost = item_production_cost, 
            time = item_production_time, 
            name = item_name,
            desc = item_desc, 
            icon = atlas_icons[icon_name],
            transfer_duration = transfer_duration,
        }
        g_item_data[item_type] = item_object
        g_item_count = g_item_count + 1
        
        if item_object.icon == nil then
            MM_LOG("icon not found: "..icon_name)
        end
    end

    for k, v in pairs(g_item_data) do
        local item_data = v
        local category_data = g_item_categories[item_data.category]
        
        if category_data ~= nil then
            table.insert(category_data.items, item_data)
            category_data.item_count = category_data.item_count + 1
        end
    end
end

function get_vehicle_capability(vehicle)
    local attachment_count = vehicle:get_attachment_count()

    local capabilities = {}

    for i = 0, attachment_count - 1 do
        local attachment = vehicle:get_attachment(i)

        if attachment:get() then
            local attachment_def = attachment:get_definition_index()

            if attachment_def ~= e_game_object_type.attachment_camera_vehicle_control then
               capabilities[attachment_def] = get_attachment_data_by_definition_index(attachment_def)
               capabilities[attachment_def].definition = attachment_def
            end
        end
    end

    local out = {}
    
    -- Big enough to iterate over all possible attachments
    for i = 0, 2000 do
        if capabilities[i] ~= nil and not capabilities[i].unknown then
            table.insert( out, capabilities[i] )
        end
    end

    return out
end

function join_strings(strings, delim)
    local str = ""

    for i = 1, #strings do
        if i > 1 then
            str = str .. (delim or ", ")
        end

        str = str .. strings[i]
    end

    return str
end