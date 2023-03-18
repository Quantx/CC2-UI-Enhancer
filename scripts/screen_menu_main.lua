g_screens = {
	main = 0,
	new_game = 1,
	new_custom = 2,
	join = 3,
	load = 4,
	host = 5,
	host_new = 6,
	host_load = 7,
	join_meta = 8,
	network_error = 9,
	join_steam = 10,
	join_code = 11,
	host_new_game_type = 12,
	load_game_error = 13,
	vr_multiplayer_warning = 14,
	mods = 15,
	mod_upload = 16,
	mod_upload_selection = 17,
	mod_upload_loading = 18,
	mod_upload_error = 19,
	mod_upload_complete = 20,
	mod_upload_select_existing = 21,
	join_public = 22,
}

g_region_icon = 0
g_is_menu_active = true
g_is_menu_active_prev = true
g_screen_index = g_screens.main
g_screen_nav_stack = {}
g_selected_team_index = 0
g_selected_mod_id = 0
g_selected_mod_overwrite = nil
g_selected_mod_confirm = false
g_disable_mods_confirm = false
g_mod_upload_visibility = e_mod_visibility.public

g_ui = nil
g_keyboard_state = 0
g_text = {
	["host_password"] = "",
	["join_password"] = "",
	["invite_code"] = "",
}
g_edit_text = nil
g_text_blink_time = 0
g_animation_time = 0

g_server_name = ""
g_connect_address = ""
g_connect_type = e_network_connect_type.steam_id
g_network_error = ""
g_load_game_error = ""
g_mod_upload_error = ""

function get_words_from_string(str)
	local words = {}

	for match in string.gmatch(str, "([^%s]+)") do
		table.insert(words, match)
	end

	return words
end

function begin()
    begin_load()
	g_region_icon = begin_get_ui_region_index("microprose")
	g_ui = lib_imgui:create_ui()
	g_text["host_password"] = update_get_host_password()

	g_server_name = update_get_server_name()
	g_connect_address, g_connect_type = update_get_connect_address()
	g_text["join_password"] = update_get_join_password()
end

function update(screen_w, screen_h, ticks)
	if g_is_menu_active ~= g_is_menu_active_prev then
		g_is_menu_active_prev = g_is_menu_active

		if g_is_menu_active then
			g_boot_counter = 30
		end
	end
	
	if update_screen_overrides(screen_w, screen_h, ticks)  then return end

	update_interaction_ui()

	g_animation_time = g_animation_time + ticks
	g_text_blink_time = g_text_blink_time + ticks

	local ui = g_ui
	local is_active = g_edit_text == nil

	ui:begin_ui()

	local win_x = 15
	local win_y = 15
	local win_w = screen_w - 30
	local win_h = screen_h - 30
	
	if g_is_menu_active then
		if g_screen_index == g_screens.main then
			ui:begin_window(update_get_loc(e_loc.upp_game), win_x, win_y, win_w, win_h, atlas_icons.column_pending, is_active)
			ui:header(update_get_loc(e_loc.upp_singleplayer))

			if ui:list_item(update_get_loc(e_loc.upp_new_game), true) then
				nav_set_screen(g_screens.new_game)
			end

			if ui:list_item(update_get_loc(e_loc.upp_load_game), true) then
				nav_set_screen(g_screens.load)
			end

			ui:header(update_get_loc(e_loc.upp_multiplayer))
			
			if ui:list_item(update_get_loc(e_loc.upp_join), true) then
				if update_get_is_show_vr_multiplayer_warning() then
					nav_set_screen(g_screens.vr_multiplayer_warning)
				else
					nav_set_screen(g_screens.join)
				end
			end
			
			if ui:list_item(update_get_loc(e_loc.upp_host), true) then
				if update_get_is_show_vr_multiplayer_warning() then
					nav_set_screen(g_screens.vr_multiplayer_warning)
				else
					nav_set_screen(g_screens.host)
				end
			end

			ui:divider()

			if ui:list_item(update_get_loc(e_loc.upp_mods), true) then
				update_refresh_workshop_published_mods()
				nav_set_screen(g_screens.mods)
			end

			ui:divider()
    
			if ui:list_item(update_get_loc(e_loc.upp_report_issue), true) then
				update_ui_event("open_feedback_website")
			end
	
			ui:end_window()
		elseif g_screen_index == g_screens.new_game then
			ui:begin_window(update_get_loc(e_loc.upp_new_game), win_x, win_y, win_w, win_h, atlas_icons.column_pending, is_active)

			ui:header(update_get_loc(e_loc.upp_game_type))

			if ui:list_item(update_get_loc(e_loc.upp_campaign), true) then
				update_ui_event("new_game_campaign")
			end

			if ui:list_item(update_get_loc(e_loc.upp_custom), true) then
				nav_set_screen(g_screens.new_custom)
			end

			ui:end_window()
		elseif g_screen_index == g_screens.new_custom then
			ui:begin_window(update_get_loc(e_loc.upp_new_game), win_x, win_y, win_w, win_h, atlas_icons.column_pending, is_active)
			
			imgui_game_customisation(ui, false)

			ui:divider()

			if ui:button(update_get_loc(e_loc.upp_start), true, 1) then
				update_ui_event("new_game_custom")
			end
			
			ui:end_window()
		elseif g_screen_index == g_screens.vr_multiplayer_warning then
			local window = ui:begin_window(update_get_loc(e_loc.upp_multiplayer), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active)
			local region_w, region_h = ui:get_region()

			local error_text = "$[0]To play multiplayer, please launch the VR $[1]carrier_command.exe$[0] directly from the folder rather than through Steam. The exe can usually be found at:\n\n$[2]C:\\Program Files (x86)\\Steam\\steamapps\\common\\Carrier Command 2 VR\\carrier_command.exe$[0]\n\nThe reason for this is that Steam networking doesn't currently support cross-app multiplayer. Launching the exe directly causes Steam to think you are playing the non-VR version and therefore you can communicate with non-VR players."

			update_ui_set_text_color(0, color_grey_dark)
			update_ui_set_text_color(1, color_grey_mid)
			update_ui_set_text_color(2, color_grey_mid)
			update_ui_text(5, 5, error_text, region_w - 10, 0, color_white, 0)

			ui:end_window()
		elseif g_screen_index == g_screens.join then
			local window = ui:begin_window(update_get_loc(e_loc.upp_join), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active)
			ui:header(update_get_loc(e_loc.upp_connect_to).."...")

			if ui:list_item(update_get_loc(e_loc.upp_public_servers), true) then
				update_ui_event("refresh_server_list")
				nav_set_screen(g_screens.join_public)
			end
			
			if ui:list_item(update_get_loc(e_loc.upp_steam_friends), true) then
				nav_set_screen(g_screens.join_steam)
			end

			if ui:list_item(update_get_loc(e_loc.upp_invite_code), true) then
				nav_set_screen(g_screens.join_code)
			end

			ui:end_window()
		elseif g_screen_index == g_screens.join_steam then
			local window = ui:begin_window(update_get_loc(e_loc.upp_join_steam_friends), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active)
			local friend_games = update_get_friend_games()

			ui:spacer(5)
			ui:header(update_get_loc(e_loc.upp_steam_friends))

			if table_count(friend_games) > 0 then
				for _, v in ipairs(friend_games) do
					if ui:list_item(v.name, true) then
						request_join_game(v.address, e_network_connect_type.steam_id, v.name)
					end
				end
			else
				ui:text_basic(update_get_loc(e_loc.upp_no_friend_games_found), color_grey_dark)
			end

			ui:end_window()
		elseif g_screen_index == g_screens.join_code then
			local window = ui:begin_window(update_get_loc(e_loc.upp_join_invite_code), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active)
			ui:header(update_get_loc(e_loc.upp_invite_code))
			window.label_bias = 0.2

			if ui:textbox(update_get_loc(e_loc.upp_code), g_text["invite_code"]) then
				g_edit_text = "invite_code"
			end

			window.label_bias = 0.5

			ui:divider()

			if ui:list_item(update_get_loc(e_loc.upp_connect), true) then
				request_join_game(g_text["invite_code"], e_network_connect_type.token, g_text["invite_code"])
			end

			ui:end_window()
		elseif g_screen_index == g_screens.join_public then
			local window_title = update_get_loc(e_loc.upp_join_public_server)
			local server_list = update_get_server_list()
			
			if server_list.is_loading then
				local char_index = math.floor(g_animation_time / 4) % 4
				window_title = window_title .. " " .. string.sub("/-\\|", char_index + 1, char_index + 1)
			end
			
			local window = ui:begin_window(window_title .. "##join_public", win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active)

			ui:spacer(5)
			ui:header(update_get_loc(e_loc.upp_public_servers))

			if #server_list.servers > 0 then
				for _, v in ipairs(server_list.servers) do
					if ui:server_details(v.name, v.player_count, v.max_players, v.is_password, v.status, v.version, v.latency, v.is_modded) then
						request_join_game(v.connect_address, e_network_connect_type.steam_id, v.name)
					end
				end
			else
				ui:text_basic(update_get_loc(e_loc.upp_no_public_servers_found), color_grey_dark)
			end

			ui:end_window()
		elseif g_screen_index == g_screens.join_meta then
			ui:begin_window(update_get_loc(e_loc.upp_join), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active)
			local region_w, region_h = ui:get_region()
			local is_meta_set, meta = update_get_server_meta() 

			ui:stat(update_get_loc(e_loc.server), iff(is_meta_set, meta.server_name, g_server_name), color_grey_dark)

			if is_meta_set then
				ui:header(update_get_loc(e_loc.upp_details))
				ui:stat(update_get_loc(e_loc.players), meta.player_count .. "/" .. meta.max_players, iff(meta.max_players == 0 or meta.player_count < meta.max_players, color_status_ok, color_status_bad))
				ui:stat(update_get_loc(e_loc.teams), #meta.teams, color_grey_mid)
				
				ui:divider()

				local available_team_ids = {}
				local available_teams = {}

				for _, v in ipairs(meta.teams) do
					if v.is_ai == false and v.is_destroyed == false then
						table.insert(available_team_ids, v.team_id)
						table.insert(available_teams, v.team_id .. " [" .. update_get_loc(e_loc.upp_human).."]")
					end
				end

				if #available_teams == 0 then
					ui:stat(update_get_loc(e_loc.join_team), update_get_loc(e_loc.upp_unavailable), color_status_bad)
				else
					g_selected_team_index = ui:combo(update_get_loc(e_loc.join_team), g_selected_team_index, available_teams)
				end
				
				if g_connect_type == e_network_connect_type.token then
					ui:textbox(update_get_loc(e_loc.password), "*****", false)
				else
					if ui:textbox(update_get_loc(e_loc.password), g_text["join_password"]) then
						g_edit_text = "join_password"
					end
				end

				if ui:button(update_get_loc(e_loc.upp_join), #available_teams > 0, 0) then
					local join_team_id = available_team_ids[g_selected_team_index + 1]

					if join_team_id ~= nil then
						if g_connect_type == e_network_connect_type.steam_id then
							MM_LOG("joining game (steam id: " .. g_connect_address .. "), team id: " .. join_team_id)
							update_ui_event("join_game_steam_id", g_connect_address, join_team_id, g_text["join_password"])
						elseif g_connect_type == e_network_connect_type.token then
							MM_LOG("joining game (token: " .. g_connect_address .. "), team id: " .. join_team_id)
							update_ui_event("join_game_token", g_connect_address, join_team_id)
						end
					end
				end

				ui:spacer(5)

				ui:header(update_get_loc(e_loc.upp_teams))

				local column_widths = { 10, 20, 20, 115, 40, -1 }
				local column_margins = { 5, 5, 5, 5, 5, 5 }
			
				local header_columns = {
					{ w=column_widths[1], margin=column_margins[1], value="" },
					{ w=column_widths[2], margin=column_margins[2], value=atlas_icons.column_team_control },
					{ w=column_widths[3], margin=column_margins[3], value=atlas_icons.column_profile },
					{ w=column_widths[4], margin=column_margins[4], value=atlas_icons.column_pending },
					{ w=column_widths[5], margin=column_margins[5], value=atlas_icons.column_difficulty },
					{ w=column_widths[6], margin=column_margins[6], value=atlas_icons.column_laser },
				}

				imgui_table_header(ui, header_columns)

				for _, v in ipairs(meta.teams) do
					local id = tostring(v.team_id)
					local players = tostring(v.players)
					local is_ai = iff(v.is_ai, update_get_loc(e_loc.ai), update_get_loc(e_loc.upp_human))
					local is_destroyed = iff(v.is_destroyed, "X", "-")
					local team_col = update_get_team_color(v.team_id)

					local players_on_team = {}

					for _, p in ipairs(meta.players) do
						if p.team_id == v.team_id then
							table.insert(players_on_team, p)
						end
					end

					local player_name = "-"
					local player_peer_id = 0
					local players_col = color_grey_dark

					if #players_on_team > 0 then
						player_name = players_on_team[1].name
						player_peer_id = players_on_team[1].peer_id
						players_col = color_grey_mid
					end

					local columns = { 
						{ w=column_widths[1], margin=column_margins[1], value=atlas_icons.column_team_control, col=team_col, is_highlight = false, is_border = false },
						{ w=column_widths[2], margin=column_margins[2], value=id, col=team_col, is_highlight = false },
						{ w=column_widths[3], margin=column_margins[3], value=players, col=iff(v.players > 0, color_grey_mid, color_grey_dark) },
						{ w=column_widths[4], margin=column_margins[4], value=update_ui_format_peer_display_name(player_name, player_peer_id), col=players_col },
						{ w=column_widths[5], margin=column_margins[5], value=is_ai },
						{ w=column_widths[6], margin=column_margins[6], value=is_destroyed, col=iff(v.is_destroyed, color_status_bad, color_grey_dark) },
					}
			
					imgui_table_entry(ui, columns)

					for i = 2, #players_on_team do
						columns = { 
							{ w=column_widths[1], margin=column_margins[1], value="", is_border = false },
							{ w=column_widths[2], margin=column_margins[2], value="" },
							{ w=column_widths[3], margin=column_margins[3], value="" },
							{ w=column_widths[4], margin=column_margins[4], value=update_ui_format_peer_display_name(players_on_team[i].name, players_on_team[i].peer_id), col=players_col },
							{ w=column_widths[5], margin=column_margins[5], value="" },
							{ w=column_widths[6], margin=column_margins[6], value="" },
						}
	
						imgui_table_entry(ui, columns)
					end
				end

				ui:divider(0, 3)
				ui:divider(0, 5)
			else
				local char_index = math.floor(g_animation_time / 4) % 4
				local load_text = update_get_loc(e_loc.waiting_for_details) .. " " .. string.sub("/-\\|", char_index + 1, char_index + 1)
				update_ui_text(0, region_h / 2 - 10, load_text, region_w, 1, color_status_ok, 0)
			end

			ui:end_window()
		elseif g_screen_index == g_screens.load then
			ui:begin_window(update_get_loc(e_loc.upp_load_game), win_x, win_y, win_w, win_h, atlas_icons.column_load, is_active)
			
			ui:header(update_get_loc(e_loc.upp_save_slots))

			local save_slots = update_get_save_slots()
			table.sort(save_slots, function(a, b) return a.time > b.time end)

			for i, v in ipairs(save_slots) do
				if ui:save_slot(i, v.display_name, v.save_name, v.time) then
					update_ui_event("load_game", v.slot_index)
				end
			end

			ui:end_window()
		elseif g_screen_index == g_screens.host then
			local window = ui:begin_window(update_get_loc(e_loc.upp_host), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active)
			
			ui:header(update_get_loc(e_loc.upp_server_settings))

			local max_players = update_get_host_max_players()
			max_players, is_modified = ui:selector(update_get_loc(e_loc.max_players), max_players, 1, 16, 1)
			if is_modified then update_set_host_max_players(max_players) end

			if ui:textbox(update_get_loc(e_loc.password), g_text["host_password"]) then
				g_edit_text = "host_password"
			end

			ui:header(update_get_loc(e_loc.upp_multiplayer_game_type))

			if ui:list_item(update_get_loc(e_loc.upp_new_game), true) then
				nav_set_screen(g_screens.host_new_game_type)
			end
			
			if ui:list_item(update_get_loc(e_loc.upp_load_game), true) then
				nav_set_screen(g_screens.host_load)
			end

			ui:end_window()
		elseif g_screen_index == g_screens.host_new_game_type then
			ui:begin_window(update_get_loc(e_loc.upp_host), win_x, win_y, win_w, win_h, atlas_icons.column_pending, is_active)

			ui:header(update_get_loc(e_loc.upp_game_type))

			if ui:list_item(update_get_loc(e_loc.upp_campaign), true) then
				update_ui_event("host_game_campaign")
			end

			if ui:list_item(update_get_loc(e_loc.upp_custom), true) then
				nav_set_screen(g_screens.host_new)
			end

			ui:end_window()
		elseif g_screen_index == g_screens.host_new then
			ui:begin_window(update_get_loc(e_loc.upp_host), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active)
			
			imgui_game_customisation(ui, true)
			ui:divider()

			if ui:button(update_get_loc(e_loc.upp_start), true, 1) then
				update_ui_event("host_game")
			end

			ui:end_window()
		elseif g_screen_index == g_screens.host_load then
			ui:begin_window(update_get_loc(e_loc.upp_host_saved_game), win_x, win_y, win_w, win_h, atlas_icons.column_load, is_active)
			
			ui:header(update_get_loc(e_loc.upp_save_slots))

			local save_slots = update_get_save_slots()
			table.sort(save_slots, function(a, b) return a.time > b.time end)

			for i, v in ipairs(save_slots) do
				if ui:save_slot(i, v.display_name, v.save_name, v.time) then
					update_ui_event("host_load_game", v.slot_index)
				end
			end

			ui:end_window()
		elseif g_screen_index == g_screens.network_error then
			ui:begin_window(update_get_loc(e_loc.upp_network_error), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active)
			local region_w, region_h = ui:get_region()

			local error_text = iff(#g_network_error > 0, g_network_error, update_get_loc(e_loc.network_error) .. ": " .. update_get_loc(e_loc.network_error_unknown_error))
			update_ui_text(0, region_h / 2 - 10, error_text, region_w, 1, color_status_bad, 0)

			ui:end_window()
		elseif g_screen_index == g_screens.load_game_error then
			ui:begin_window(update_get_loc(e_loc.upp_load_game), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active)
			local region_w, region_h = ui:get_region()
			
			update_ui_text(0, region_h / 2 - 10, g_load_game_error, region_w, 1, color_status_bad, 0)

			ui:end_window()
		elseif g_screen_index == g_screens.mods then
			local mods = update_get_mod_details()
			local selected_mod = findif(mods, function(m) return m.id == g_selected_mod_id end)

			if selected_mod == nil then
				g_selected_mod_id = 0
				g_selected_mod_confirm = false
			end

			ui:begin_window(update_get_loc(e_loc.upp_mods), win_x, win_y, win_w, win_h, atlas_icons.column_repair, is_active and selected_mod == nil and g_disable_mods_confirm == false)
			local region_w, region_h = ui:get_region()

			if ui:list_item(update_get_loc(e_loc.upp_upload_to_workshop), true) then
				nav_set_screen(g_screens.mod_upload)
			end

			local active_mod_count = countif(mods, function(m) return m.is_enabled end)
			local active_mod_text = active_mod_count .. "/" .. #mods
			local active_mod_text_w = update_ui_get_text_size(active_mod_text, region_w, 2)

			imgui_table_header(ui, { 
				{ w=region_w - active_mod_text_w - 5, margin=5, value=update_get_loc(e_loc.upp_installed_mods) }, 
				{ w=active_mod_text_w, margin=0, value=active_mod_text }
			})

			ui:spacer(1)

			if #mods == 0 then
				ui:text_basic(update_get_loc(e_loc.no_mods_installed))
			else
				if ui:button(update_get_loc(e_loc.upp_disable_all), active_mod_count > 0, 1) then
					g_disable_mods_confirm = true
				end

				local mods_steam = {}
				local mods_local = {}

				for _, mod in ipairs(mods) do
					table.insert(iff(mod.type == e_mod_type.steam, mods_steam, mods_local), mod)
				end

				if #mods_steam > 0 then
					ui:header(update_get_loc(e_loc.upp_steam_mods))
				end

				for _, mod in ipairs(mods_steam) do
					if ui:mod_details(mod.manifest.name, mod.manifest.author, mod.is_enabled) then
						g_selected_mod_id = mod.id
						g_selected_mod_confirm = false
					end
				end

				if #mods_local > 0 then
					ui:header(update_get_loc(e_loc.upp_local_mods))
				end

				for _, mod in ipairs(mods_local) do
					if ui:mod_details(mod.manifest.name, mod.manifest.author, mod.is_enabled) then
						g_selected_mod_id = mod.id
						g_selected_mod_confirm = false
					end
				end
			end

			ui:end_window()

			if g_disable_mods_confirm then
				ui.window_col_active = color_status_bad
				ui:begin_window_dialog(update_get_loc(e_loc.upp_sure), screen_w / 2, screen_h / 2, win_w - 20, winh, atlas_icons.hud_warning, is_active)
				
				ui:text_basic(update_get_loc(e_loc.confirm_disable_all_mods), color_grey_dark)
				
				local action_index = ui:end_window_dialog(update_get_loc(e_loc.upp_no), update_get_loc(e_loc.upp_yes))

				if action_index == 0 then
					g_disable_mods_confirm = false
				elseif action_index == 1 then
					for _, mod in ipairs(mods) do
						update_set_is_mod_enabled(mod.id, false)
					end

					g_disable_mods_confirm = false
				end
			elseif selected_mod then
				local incompatible_mods = update_get_mod_incompatible_active_mods(selected_mod.id)
				local is_show_mod_confirm = false

				ui:begin_window(update_get_loc(e_loc.upp_details), win_x + 20, win_y + 20, win_w - 40, win_h - 40, atlas_icons.column_pending, is_active and g_selected_mod_confirm == false, 2)
				ui:spacer(2)

				local is_enabled = iff(selected_mod.is_enabled, 1, 0)
				is_enabled, is_modified = ui:combo(update_get_loc(e_loc.mod), is_enabled, { update_get_loc(e_loc.combo_disabled), update_get_loc(e_loc.combo_enabled) })
				
				if is_modified then 
					if is_enabled and #incompatible_mods > 0 then
						is_show_mod_confirm = true
					else
						update_set_is_mod_enabled(selected_mod.id, is_enabled == 1)
					end
				end

				if #incompatible_mods > 0 then
					ui:text_basic(#incompatible_mods .. " " .. update_get_loc(e_loc.incompatible), color_status_bad)
				end

				ui:divider()

				ui:text_basic(selected_mod.manifest.name, color_grey_mid)
				ui:text_basic(selected_mod.manifest.author, color_grey_dark)
				ui:spacer(8)
				ui:text_basic(selected_mod.manifest.description, color_grey_dark)
				ui:spacer(3)
				ui:end_window()

				if g_selected_mod_confirm then
					ui.window_col_active = color_status_bad
					ui:begin_window_dialog(update_get_loc(e_loc.upp_sure), screen_w / 2, screen_h / 2, win_w - 20, winh, atlas_icons.hud_warning, is_active)
					ui:text_basic(update_get_loc(e_loc.incompatible_mods_warning), color_grey_dark)
					
					for _, v in ipairs(incompatible_mods) do
						local data = findif(mods, function(m) return m.id == v end)

						if data then
							ui:text_basic("  " .. data.manifest.name, color_status_dark_red)
						end
					end

					ui:spacer(2)

					local action_index = ui:end_window_dialog(update_get_loc(e_loc.upp_cancel), update_get_loc(e_loc.upp_confirm))

					if action_index == 0 then
						g_selected_mod_confirm = false
					elseif action_index == 1 then
						update_set_is_mod_enabled(selected_mod.id, true)
						g_selected_mod_confirm = false
					end
				end

				if is_show_mod_confirm then
					g_selected_mod_confirm = true
					local window_confirm = ui:get_create_window(update_get_loc(e_loc.upp_sure))
					window_confirm.selected_index_x = 0
				end
			end
		elseif g_screen_index == g_screens.mod_upload then
			local mods = update_get_mod_details()
			local hovered_mod = nil

			local details_h = 34

			ui:begin_window(update_get_loc(e_loc.upp_upload_to_workshop), win_x, win_y, win_w, win_h - details_h - 2, atlas_icons.column_controlling_peer, is_active)
			ui:header(update_get_loc(e_loc.upp_local_mods))

			local user_mod_count = 0

			for _, mod in ipairs(mods) do
				if mod.type == e_mod_type.user then
					user_mod_count = user_mod_count + 1

					if ui:list_item(mod.manifest.name, true) then
						g_selected_mod_id = mod.id
						nav_set_screen(g_screens.mod_upload_selection)
					end

					if ui:is_item_selected() then
						hovered_mod = mod
					end
				end
			end

			if user_mod_count == 0 then
				ui:text_basic(update_get_loc(e_loc.no_local_mods_found), color_grey_dark)
			end

			ui:end_window()

			update_ui_push_offset(win_x, win_y + win_h - details_h)
			update_ui_rectangle_outline(0, 0, win_w, details_h, color_grey_dark)
			
			local path = "---"
			if hovered_mod then
				path = hovered_mod.system_folder:gsub("\\", "/")
			end

			update_ui_text(4, 2, path, win_w - 8, 0, color_grey_dark, 0)

			update_ui_pop_offset()
		elseif g_screen_index == g_screens.mod_upload_selection then
			local mods = update_get_mod_details()
			local selected_mod = findif(mods, function(m) return m.id == g_selected_mod_id end)
			local is_show_mod_confirm = false

			if selected_mod == nil then
				g_selected_mod_id = 0
				g_selected_mod_confirm = false
				nav_back()
			end

			local window = ui:begin_window(update_get_loc(e_loc.upp_upload_to_workshop), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active and g_selected_mod_confirm == false)
			window.label_bias = 0.6

			if selected_mod then
				ui:header(update_get_loc(e_loc.upp_upload))
				
				g_mod_upload_visibility = ui:combo(update_get_loc(e_loc.mod_visibility), g_mod_upload_visibility, { update_get_loc(e_loc.mod_visibility_public), update_get_loc(e_loc.mod_visibility_friends), update_get_loc(e_loc.mod_visibility_private) })

				if ui:list_item(update_get_loc(e_loc.upp_new_workshop_item), true) then
					is_show_mod_confirm = true
				end

				if ui:list_item(update_get_loc(e_loc.upp_update_existing_item), true) then
					nav_set_screen(g_screens.mod_upload_select_existing)
				end

				ui:header(update_get_loc(e_loc.upp_details))
				window.label_bias = 0.05
				ui:stat(atlas_icons.column_repair, selected_mod.manifest.name, color_white)
				ui:stat(atlas_icons.column_profile, selected_mod.manifest.author, color_grey_mid)
				ui:stat(atlas_icons.column_load, selected_mod.system_folder:gsub("\\", "/"), color_grey_dark)
				ui:spacer(8)
				ui:stat(atlas_icons.text_ellipsis, selected_mod.manifest.description, color_grey_dark)
			end

			ui:end_window()

			if g_selected_mod_confirm then
				ui:begin_window_dialog(update_get_loc(e_loc.upp_sure), screen_w / 2, screen_h / 2, win_w - 20, winh, atlas_icons.hud_warning, is_active)
				
				ui:text_basic(update_get_loc(e_loc.workshop_agreement), color_grey_dark)
				ui:text_basic(update_get_loc(e_loc.confirm_upload_mod), color_grey_dark)
				
				local action_index = ui:end_window_dialog(update_get_loc(e_loc.upp_no), update_get_loc(e_loc.upp_yes))

				if action_index == 0 then
					g_selected_mod_confirm = false
				elseif action_index == 1 then
					update_create_workshop_mod(selected_mod.id, g_mod_upload_visibility)
					nav_set_screen(g_screens.mod_upload_loading)

					g_selected_mod_confirm = false
				end
			end

			if is_show_mod_confirm then
				g_selected_mod_confirm = true
				local window_confirm = ui:get_create_window(update_get_loc(e_loc.upp_sure))
				window_confirm.selected_index_x = 0
			end
		elseif g_screen_index == g_screens.mod_upload_loading then
			local workshop_upload_status = update_get_mod_workshop_upload_status()

			ui:begin_window(update_get_loc(e_loc.upp_upload_to_workshop), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active)
			local region_w, region_h = ui:get_region()

			local loading_text = update_get_loc(e_loc.uploading)
            local dot_count = math.floor(g_animation_time / (30 / 4)) % 4

            for i = 1, dot_count, 1 do
                loading_text = loading_text .. "."
            end

            local cx = region_w / 2 - 40
            local cy = region_h / 2 - 5
            update_ui_text(cx, cy, loading_text, 100, 0, color_white, 0)

            local anim = g_animation_time / 30.0
            local bound_left = cx
            local bound_right = bound_left + 75
            local left = bound_left + (bound_right - bound_left) * math.abs(math.sin((anim - math.pi / 2) % (math.pi / 2))) ^ 4
            local right = left + (bound_right - left) * math.abs(math.sin(anim % (math.pi / 2)))

            update_ui_rectangle(left, cy + 12, right - left, 1, color_status_ok)
            update_ui_rectangle(bound_right + bound_left - right, cy - 3, right - left, 1, color_status_ok)

			ui:end_window()

			if workshop_upload_status.is_uploading == false then
				if workshop_upload_status.is_error then
					g_mod_upload_error = workshop_upload_status.error_message
					nav_back()
					nav_set_screen(g_screens.mod_upload_error)
				else
					nav_back()
					nav_set_screen(g_screens.mod_upload_complete)
				end
			end
		elseif g_screen_index == g_screens.mod_upload_error then
			ui:begin_window(update_get_loc(e_loc.upp_upload_to_workshop), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active)
			local region_w, region_h = ui:get_region()

			local error_text = iff(#g_mod_upload_error > 0, g_mod_upload_error, update_get_loc(e_loc.upload_error) .. ": " .. update_get_loc(e_loc.upload_error_unknown_error))
			update_ui_text(0, region_h / 2 - 10, error_text, region_w, 1, color_status_bad, 0)

			ui:end_window()
		elseif g_screen_index == g_screens.mod_upload_complete then
			ui:begin_window(update_get_loc(e_loc.upp_upload_to_workshop), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active)
			local region_w, region_h = ui:get_region()

			update_ui_text(0, region_h / 2 - 10, update_get_loc(e_loc.upload_complete), region_w, 1, color_status_ok, 0)

			ui:end_window()
		elseif g_screen_index == g_screens.mod_upload_select_existing then
			local is_show_mod_confirm = false

			ui:begin_window(update_get_loc(e_loc.upp_update_existing_item), win_x, win_y, win_w, win_h, atlas_icons.column_controlling_peer, is_active and g_selected_mod_confirm == false)
			local published_mods = update_get_workshop_published_mods()

			ui:header(update_get_loc(e_loc.upp_steam_mods))

			if published_mods.is_loading then
				local char_index = math.floor(g_animation_time / 4) % 4
				local load_text = update_get_loc(e_loc.waiting_for_details) .. " " .. string.sub("/-\\|", char_index + 1, char_index + 1)
				ui:text_basic(load_text, color_grey_dark)
			end

			if (published_mods.items == nil or #published_mods.items == 0) and published_mods.is_loading == false then
				ui:text_basic(update_get_loc(e_loc.no_mods_published), color_grey_dark)
			elseif published_mods.items ~= nil then
				for _, mod in ipairs(published_mods.items) do
					if ui:list_item(mod.name, true) then
						is_show_mod_confirm = true
						g_selected_mod_overwrite = mod
					end
				end
			end

			ui:end_window()

			if g_selected_mod_confirm then
				if g_selected_mod_overwrite == nil then
					g_selected_mod_confirm = false
				else
					ui.window_col_active = color_status_bad
					ui:begin_window_dialog(update_get_loc(e_loc.upp_sure), screen_w / 2, screen_h / 2, win_w - 20, winh, atlas_icons.hud_warning, is_active)
					
					ui:text_basic(update_get_loc(e_loc.workshop_agreement), color_grey_dark)
					ui:text_basic(update_get_loc(e_loc.following_mod_will_be_overwritten) .. ":", color_status_bad)
					ui:text_basic("  " .. g_selected_mod_overwrite.name, color_status_dark_red)
					ui:text_basic(update_get_loc(e_loc.confirm_upload_mod), color_grey_dark)

					local action_index = ui:end_window_dialog(update_get_loc(e_loc.upp_no), update_get_loc(e_loc.upp_yes))
	
					if action_index == 0 then
						g_selected_mod_confirm = false
					elseif action_index == 1 then
						update_update_workshop_mod(g_selected_mod_id, g_selected_mod_overwrite.published_id, g_mod_upload_visibility)
						nav_back()
						nav_set_screen(g_screens.mod_upload_loading)
	
						g_selected_mod_confirm = false
					end
				end
			end

			if is_show_mod_confirm then
				g_selected_mod_confirm = true
				local window_confirm = ui:get_create_window(update_get_loc(e_loc.upp_sure))
				window_confirm.selected_index_x = 0
			end
		end

		imgui_menu_focus_overlay(ui, screen_w, screen_h, update_get_loc(e_loc.upp_game), ticks)
	else
		local color = color8_lerp(color_black, color_status_ok, math.sin(g_animation_time * 0.2) * 0.5 + 0.5)
		local text = ""
		local text_w = 0
		local text_h = 10 * 3
		local max_line_length = 0

		local words = get_words_from_string(update_get_loc(e_loc.upp_press_any_key_newline))

		for i = 1, #words do
			text = text .. words[i] .. "\n"
			max_line_length = math.max(update_ui_get_text_size(words[i], 10000, 1), max_line_length) 
		end
		
		text_w = math.min(max_line_length * 3, screen_w - 30)
		text_h = #words * 10 * 3

		local x = ((screen_w - text_w) / 2) - 15
		local y = ((screen_h - text_h) / 2) - 15

		imgui_menu_overlay(ui, x, y, text_w + 30, text_h + 30, text, text_w, text_h, color, color_white)
	end
	
	if g_edit_text then
		update_ui_rectangle(0, 0, screen_w, screen_h, color8(0, 0, 0, 200))

		local display_text = g_text[g_edit_text] .. iff(g_text_blink_time % 20 > 10, "$[1]|", "$[2]|")
		local border = 32
		local text_w, text_h = update_ui_get_text_size(display_text, screen_w - border * 2, 1)

		update_ui_set_text_color(1, color_empty)
		update_ui_set_text_color(2, color_highlight)
		update_ui_rectangle_outline(border - 6, screen_h / 2 - 5 - text_h - 2, screen_w - border * 2 + 12, text_h + 4, color_button_bg_inactive)
		update_ui_text(border, screen_h / 2 - 5 - text_h, display_text, screen_w - border * 2, 1, color_white, 0)

		ui:begin_window("##keyboard", 0, screen_h / 2, screen_w, screen_h, nil, true, 1)
		
		local is_done = false
		g_keyboard_state, g_text[g_edit_text], is_done = ui:keyboard(g_keyboard_state, g_text[g_edit_text])
		
		if is_done then
			if g_edit_text == "host_password" then
				update_set_host_password(g_text[g_edit_text])
			elseif g_edit_text == "join_password" then
				update_set_join_password(g_text[g_edit_text])
			end

			g_edit_text = nil
		end

		ui:end_window()
	end

	ui:end_ui()
end

function update_interaction_ui()
	local is_meta_set = update_get_server_meta() 

	if g_edit_text ~= nil then
		update_add_ui_interaction(update_get_loc(e_loc.interaction_confirm), e_game_input.text_enter)
		
		if update_get_active_input_type() == e_active_input.keyboard then
			update_add_ui_interaction("", e_game_input.back)
		else
			update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)
			update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_all)
			update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
		end
	elseif g_screen_index == g_screens.join_meta and is_meta_set == false then
		update_add_ui_interaction(update_get_loc(e_loc.interaction_cancel), e_game_input.back)
	elseif g_screen_index == g_screens.mods and g_disable_mods_confirm then
		update_add_ui_interaction(update_get_loc(e_loc.interaction_cancel), e_game_input.back)
	elseif g_screen_index == g_screens.mods and g_selected_mod_id ~= 0 then
		if g_selected_mod_confirm then
			update_add_ui_interaction(update_get_loc(e_loc.interaction_cancel), e_game_input.back)
		else
			update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)
		end
	elseif g_screen_index == g_screens.mod_upload_loading then
		update_add_ui_interaction("", e_game_input.back)
	elseif #g_screen_nav_stack > 0 then
		update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)

		if g_screen_index ~= g_screens.network_error then
			update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)
		end
	else
		update_add_ui_interaction_special(update_get_loc(e_loc.interaction_navigate), e_ui_interaction_special.gamepad_dpad_ud)
	end

	if is_gamepad_scroll() then
		update_add_ui_interaction_special(update_get_loc(e_loc.interaction_scroll), e_ui_interaction_special.gamepad_scroll)
	end
end

function nav_set_screen(index)
	if g_screen_index ~= index then
		table.insert(g_screen_nav_stack, g_screen_index)
		g_screen_index = index
	end
end

function nav_back()
	if #g_screen_nav_stack > 0 then
		g_screen_index = g_screen_nav_stack[#g_screen_nav_stack]
		g_screen_nav_stack[#g_screen_nav_stack] = nil
	else
		update_set_screen_state_exit()
	end
end

function input_event(event, action)
	if g_edit_text ~= nil and update_get_active_input_type() == e_active_input.keyboard and event ~= e_input.pointer_1 and event ~= e_input.text_backspace and event ~= e_input.text_enter then
		return
	end

	if action == e_input_action.release then
		if event == e_input.back then
			if g_screen_index == g_screens.mod_upload_loading then
				-- player should wait for upload to complete
			elseif g_edit_text ~= nil then
				g_edit_text = nil
			elseif g_selected_mod_confirm then
				g_selected_mod_confirm = false
			elseif g_disable_mods_confirm then
				g_disable_mods_confirm = false
			elseif g_screen_index == g_screens.mod_upload_selection then
				g_selected_mod_id = 0
				nav_back()
			elseif g_screen_index == g_screens.mods and g_selected_mod_id ~= 0 then
				g_selected_mod_id = 0
			else
				nav_back()
			end
        end
	end

	g_ui:input_event(event, action)
end

function input_pointer(is_hovered, x, y)
    g_ui:input_pointer(is_hovered, x, y)
end

function input_scroll(dy)
	g_ui:input_scroll(dy)
end

function input_axis(x, y, z, w)
	if is_gamepad_scroll() then
		g_ui:input_scroll_gamepad(w)
	end
end

function input_text(text)
	if g_edit_text ~= nil then
		g_text[g_edit_text] = g_text[g_edit_text] .. text
		g_text[g_edit_text] = clamp_str(g_text[g_edit_text], 128)
		g_text_blink_time = 0
	end
end

function on_steam_connect_request(server_name, server_address, password)
	unwind_nav_stack()

	set_persistent_connect_data(server_address, e_network_connect_type.steam_id, server_name)
	g_text["join_password"] = password

	g_selected_team_index = 0
	g_boot_counter = 0
	g_menu_overlay_factor = 0
	nav_set_screen(g_screens.join_meta)
end

function on_network_error(error)
	unwind_nav_stack()

	g_network_error = error
	g_boot_counter = 0
	g_menu_overlay_factor = 0

	local is_meta_set, meta = update_get_server_meta() 
	nav_set_screen(g_screens.join)

	if is_meta_set then
		nav_set_screen(g_screens.join_meta)
	end

	nav_set_screen(g_screens.network_error)
end

function on_load_game_error(error)
	if #error > 0 then
		unwind_nav_stack()
		
		g_load_game_error = error
		g_boot_counter = 0
		g_menu_overlay_factor = 0
		
		nav_set_screen(g_screens.load_game_error)
	end
end

function unwind_nav_stack()
	while #g_screen_nav_stack > 0 do
		nav_back()
	end
end

function imgui_game_customisation(ui, is_multiplayer)
	local window = ui:get_window()
	local label_bias = window.label_bias

	window.label_bias = 0.6

	local island_count = update_get_new_game_island_count()
	local team_count_ai = update_get_new_game_team_count_ai()
	local team_count_human = update_get_new_game_team_count_human()
	local island_count_per_team = update_get_new_game_island_count_per_team()
	local carrier_count_per_team = update_get_new_game_carrier_count_per_team()
	local base_difficulty = update_get_new_game_base_difficulty()
	local loadout_type = update_get_new_game_loadout_type()
	local blueprints_type = update_get_new_game_blueprints()
	local is_tutorial = update_get_new_game_is_tutorial()

	local loadout_type_names = { 
		update_get_loc(e_loc.loadout_default), 
		update_get_loc(e_loc.loadout_minimal), 
		update_get_loc(e_loc.loadout_complete) 
	}

	local blueprints_type_names = { 
		update_get_loc(e_loc.unlocked_blueprints_default), 
		update_get_loc(e_loc.unlocked_blueprints_none), 
		update_get_loc(e_loc.unlocked_blueprints_all) 
	}

	local is_modified = false

	ui:header(update_get_loc(e_loc.upp_game_settings))

	if is_multiplayer == false then
		if base_difficulty ~= 1 or loadout_type ~= 0 or blueprints_type ~= 0 then
			ui:combo(update_get_loc(e_loc.tutorial), 0, { update_get_loc(e_loc.tutorial_unavailable) }, false)
		else
			local tutorial = iff(is_tutorial, 0, 1)
			tutorial, is_modified = ui:combo(update_get_loc(e_loc.tutorial), tutorial, { update_get_loc(e_loc.combo_enabled), update_get_loc(e_loc.combo_disabled) })
			if is_modified then 
				update_set_new_game_is_tutorial(tutorial == 0)
			end
		end
	end

	island_count, is_modified = ui:selector(update_get_loc(e_loc.islands), island_count, 4, 64, 1)
	if is_modified then update_set_new_game_island_count(island_count) end

	if is_multiplayer then
		team_count_human, is_modified = ui:selector(update_get_loc(e_loc.human_teams), team_count_human, 1, 4, 1)
		if is_modified then update_set_new_game_team_count_human(team_count_human) end

		team_count_ai, is_modified = ui:selector(update_get_loc(e_loc.ai_teams), team_count_ai, 0, 4, 1)
		if is_modified then update_set_new_game_team_count_ai(team_count_ai) end
	else
		if team_count_ai == 0 then
			team_count_ai = 1
			update_set_new_game_team_count_ai(team_count_ai)
		end

		team_count_ai, is_modified = ui:selector(update_get_loc(e_loc.ai_teams), team_count_ai, 1, 4, 1)
		
		if is_modified then update_set_new_game_team_count_ai(team_count_ai) end
	end

	island_count_per_team, is_modified = ui:selector(update_get_loc(e_loc.starting_islands), island_count_per_team, 1, 64, 1)
	if is_modified then update_set_new_game_island_count_per_team(island_count_per_team) end

	if is_multiplayer then
		carrier_count_per_team, is_modified = ui:selector(update_get_loc(e_loc.carriers_per_human_team), carrier_count_per_team, 1, 4, 1)
		if is_modified then update_set_new_game_carrier_count_per_team(carrier_count_per_team) end
	end

	base_difficulty, is_modified = imgui_selector_icon(ui, update_get_loc(e_loc.base_difficulty), base_difficulty, 1, 4, 1, atlas_icons.column_difficulty, 8, iff(base_difficulty > 1, iff(base_difficulty > 3, color_status_bad, color_status_warning), color_status_ok))
	if is_modified then update_set_new_game_base_difficulty(base_difficulty) end

	loadout_type, is_modified = ui:combo(update_get_loc(e_loc.loadout), loadout_type, loadout_type_names)
	if is_modified then update_set_new_game_loadout_type(loadout_type) end

	blueprints_type, is_modified = ui:combo(update_get_loc(e_loc.unlocked_blueprints), blueprints_type, blueprints_type_names)
	if is_modified then update_set_new_game_blueprints(blueprints_type) end

	window.label_bias = label_bias
end

function imgui_selector_icon(self, label, value, min, max, step, icon, icon_w, icon_col)
    local window = self:get_window()
    local x = window.cx
    local y = window.cy
    local w, h = self:get_region()
    local is_active = window.is_active
    local is_hovered, is_selected = self:hoverable(x, y, w, 12, true)

    local label_w = math.floor(w * window.label_bias)
    local combo_w = w - label_w - 2

    local text_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)
    local combo_col = iff(is_active, iff(is_selected, icon_col, color_grey_mid), color_grey_dark)
    local arrow_col = iff(is_active, iff(is_selected, color_white, color_grey_dark), color_grey_dark)

    update_ui_text(x + 5, y + 1, label, label_w - 5, 0, text_col, 0)

    local value_label = tostring(value)

    if format ~= nil then
        value_label = string.format(format, value)
    end

    local icon_spacing = 2
    local total_icon_w = icon_w * value + icon_spacing * math.max(value - 1, 0)

    for i = 0, value - 1 do
        update_ui_image(x + label_w + (combo_w - total_icon_w) / 2 + i * (icon_w + icon_spacing), y + 1, icon, combo_col, 0)
    end
    
    update_ui_text(x + label_w, y + 1, "-", 10, 0, iff(value > min, arrow_col, color_grey_dark), 0)
    update_ui_text(x + label_w + combo_w - 5, y + 1, "+", 10, 0, iff(value < max, arrow_col, color_grey_dark), 0)

    window.cy = window.cy + 12

    local is_modified = false

	if is_selected and is_active then
		local is_left_hovered = self:is_hovered(x + label_w, y, 5, 12)
		local is_right_hovered = self:is_hovered(x + label_w + combo_w - 5, y, 5, 12)
        local is_left_clicked = is_hovered and self.input_pointer_1 and is_left_hovered
        local is_right_clicked = is_hovered and self.input_pointer_1 and is_right_hovered

		update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_ui_interaction_special.gamepad_dpad_lr)

		if (is_left_hovered or is_right_hovered) and update_get_active_input_type() == e_active_input.keyboard then
			update_add_ui_interaction(update_get_loc(e_loc.interaction_select), e_game_input.interact_a)
		end

        if self.input_left or is_left_clicked then
            is_modified = true
            value = clamp(value - step, min, max)
        elseif self.input_right or is_right_clicked then
            is_modified = true
            value = clamp(value + step, min, max)
        end
    end

    return value, is_modified
end

function set_persistent_connect_data(address, connect_type, server_name)
	g_connect_address = address
	g_connect_type = connect_type
	g_server_name = server_name

	update_set_connect_address(g_connect_address, g_connect_type)
	update_set_server_name(g_server_name)
end

function request_join_game(address, connect_type, server_name)
	set_persistent_connect_data(address, connect_type, server_name)

	g_selected_team_index = 0
	nav_set_screen(g_screens.join_meta)
	
	if connect_type == e_network_connect_type.steam_id then
		update_ui_event("request_server_meta_steam_id", address)
	elseif connect_type == e_network_connect_type.token then
		update_ui_event("request_server_meta_token", address)
	end
end

function is_gamepad_scroll()
	return (g_screen_index == g_screens.mods and g_selected_mod_id ~= 0) or g_selected_mod_confirm
end