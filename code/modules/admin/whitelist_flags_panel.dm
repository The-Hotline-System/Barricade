// Whitelist Flags Management Panel
// Allows admins to view, add, and remove WL_ flags from players

/// Scans all player flag files to find unique WL_ flags in use
/proc/get_all_whitelist_flags()
	var/list/all_flags = list()

	// Scan all player save directories
	var/list/directories = flist("data/player_saves/")
	for(var/dir in directories)
		if(!findtext(dir, "/"))
			continue

		var/list/player_files = flist("data/player_saves/[dir]")
		for(var/player_dir in player_files)
			if(!findtext(player_dir, "/"))
				continue

			var/flag_file = "data/player_saves/[dir][player_dir]whitelists.json"
			if(!fexists(flag_file))
				continue

			var/list/flags = json_decode(file2text(flag_file))
			if(!islist(flags))
				continue

			for(var/entry in flags)
				if(!islist(entry))
					continue
				var/flag_value = entry["value"]
				if(!(flag_value in all_flags))
					all_flags += flag_value

	// Sort alphabetically
	all_flags = sort_list(all_flags)

	// Add option to create custom flag
	all_flags += "--- Custom Flag ---"

	return all_flags

/datum/admins/proc/manage_whitelist_flags_panel(client/target_client)
	if(!check_rights(R_ADMIN))
		return

	if(!target_client)
		to_chat(usr, span_warning("Target client not found."), confidential = TRUE)
		return

	var/dat = {"
		<html>
		<head>
			<title>Whitelist Flags - [target_client.ckey]</title>
			<style>
				body { font-family: Verdana, sans-serif; font-size: 13px; background-color: #1a1a1a; color: #e0e0e0; }
				h2 { color: #4a9eff; border-bottom: 2px solid #4a9eff; padding-bottom: 5px; }
				.container { margin: 10px; padding: 10px; background-color: #2a2a2a; border-radius: 5px; }
				.flag-item {
					background-color: #333;
					padding: 8px;
					margin: 5px 0;
					border-left: 3px solid #4a9eff;
					border-radius: 3px;
				}
				.flag-value { color: #4a9eff; font-weight: bold; }
				.flag-meta { color: #888; font-size: 11px; }
				.button {
					background-color: #4a9eff;
					color: white;
					border: none;
					padding: 5px 10px;
					cursor: pointer;
					border-radius: 3px;
					text-decoration: none;
					display: inline-block;
					margin: 2px;
				}
				.button:hover { background-color: #3a7fcf; }
				.button-remove { background-color: #ff4a4a; }
				.button-remove:hover { background-color: #cf3a3a; }
				.button-add { background-color: #4aff4a; }
				.button-add:hover { background-color: #3acf3a; }
				.no-flags { color: #888; font-style: italic; }
			</style>
		</head>
		<body>
			<h2>Whitelist Flags for [target_client.ckey]</h2>
	"}

	var/file_path = get_flag_path(target_client.ckey)
	if(!fexists(file_path))
		create_flag_file(target_client.ckey)

	var/list/flags = json_decode(file2text(file_path))
	if(!islist(flags))
		flags = list()

	dat += "<div class='container'>"
	dat += "<h3>Current Flags:</h3>"

	var/has_flags = FALSE
	for(var/entry in flags)
		if(!islist(entry))
			continue
		has_flags = TRUE
		dat += "<div class='flag-item'>"
		dat += "<span class='flag-value'>[entry["value"]]</span><br>"
		dat += "<span class='flag-meta'>Added by: [entry["added_by"] || "Unknown"] | Date: [entry["date"] || "Unknown"]</span><br>"
		dat += "<span class='flag-meta'>Reason: [entry["reason"] || "No reason provided"]</span><br>"
		dat += "<a href='?_src_=holder;[HrefToken()];wl_remove_flag=[target_client.ckey];flag_value=[entry["value"]]' class='button button-remove'>Remove</a>"
		dat += "</div>"

	if(!has_flags)
		dat += "<p class='no-flags'>No whitelist flags assigned.</p>"

	dat += "</div>"

	dat += "<div class='container'>"
	dat += "<h3>Add New Flag:</h3>"
	dat += "<a href='?_src_=holder;[HrefToken()];wl_add_flag=[target_client.ckey]' class='button button-add'>Add Flag</a>"
	dat += "</div>"

	dat += "<div class='container'>"
	dat += "<a href='?_src_=holder;[HrefToken()];wl_refresh_panel=[target_client.ckey]' class='button'>Refresh</a>"
	dat += "</div>"

	dat += "</body></html>"

	var/datum/browser/popup = new(usr, "wl_flags_[target_client.ckey]", "Whitelist Flags - [target_client.ckey]", 600, 500)
	popup.set_content(dat)
	popup.open()

// Topic handlers for whitelist flag management
/datum/admins/proc/handle_whitelist_flag_topics(href_list)
	if(href_list["wl_add_flag"])
		if(!check_rights(R_ADMIN))
			return

		var/target_ckey = href_list["wl_add_flag"]

		// Get all existing WL_ flags
		var/list/available_flags = get_all_whitelist_flags()

		if(!length(available_flags))
			to_chat(usr, span_warning("No whitelist flags found in the system. You can create a custom one."), confidential = TRUE)
			available_flags = list("--- Custom Flag ---")

		var/flag_value = input(usr, "Select a whitelist flag to add:", "Add Whitelist Flag") as null|anything in available_flags

		if(!flag_value)
			return

		// If custom flag selected, prompt for input
		if(flag_value == "--- Custom Flag ---")
			flag_value = input(usr, "Enter a custom whitelist flag (e.g., WL_NEWROLE):", "Custom Whitelist Flag") as text|null
			if(!flag_value)
				return

		flag_value = uppertext(trim(flag_value))

		if(!flag_value || flag_value == "--- CUSTOM FLAG ---")
			to_chat(usr, span_warning("Invalid flag value."), confidential = TRUE)
			return

		// Check if player already has this flag
		var/client/target_client = GLOB.directory[target_ckey]
		if(target_client && (flag_value in target_client.flags))
			to_chat(usr, span_warning("[target_ckey] already has the flag '[flag_value]'."), confidential = TRUE)
			return

		var/reason = input(usr, "Enter the reason for adding this flag:", "Flag Reason") as text|null
		if(!reason)
			reason = "No reason provided"

		if(target_client)
			add_to_whitelist(target_client, flag_value, usr.ckey, reason)
			to_chat(usr, span_notice("Added flag '[flag_value]' to [target_ckey]."), confidential = TRUE)
			message_admins("[key_name_admin(usr)] added whitelist flag '[flag_value]' to [target_ckey]. Reason: [reason]")
			log_admin("[key_name(usr)] added whitelist flag '[flag_value]' to [target_ckey]. Reason: [reason]")
		else
			add_to_whitelist_ckeyonly(target_ckey, flag_value, usr.ckey, reason)
			to_chat(usr, span_notice("Added flag '[flag_value]' to [target_ckey] (offline)."), confidential = TRUE)
			message_admins("[key_name_admin(usr)] added whitelist flag '[flag_value]' to [target_ckey] (offline). Reason: [reason]")
			log_admin("[key_name(usr)] added whitelist flag '[flag_value]' to [target_ckey] (offline). Reason: [reason]")

		// Refresh the panel
		if(target_client)
			manage_whitelist_flags_panel(target_client)
		return TRUE

	else if(href_list["wl_remove_flag"])
		if(!check_rights(R_ADMIN))
			return

		var/target_ckey = href_list["wl_remove_flag"]
		var/flag_value = href_list["flag_value"]

		if(!flag_value)
			return

		if(tgui_alert(usr, "Are you sure you want to remove flag '[flag_value]' from [target_ckey]?", "Confirm Removal", list("Yes", "No")) != "Yes")
			return

		var/client/target_client = GLOB.directory[target_ckey]
		if(target_client)
			remove_from_whitelist(target_client, flag_value)
			to_chat(usr, span_notice("Removed flag '[flag_value]' from [target_ckey]."), confidential = TRUE)
			message_admins("[key_name_admin(usr)] removed whitelist flag '[flag_value]' from [target_ckey].")
			log_admin("[key_name(usr)] removed whitelist flag '[flag_value]' from [target_ckey].")
		else
			remove_from_whitelist_ckeyonly(target_ckey, flag_value)
			to_chat(usr, span_notice("Removed flag '[flag_value]' from [target_ckey] (offline)."), confidential = TRUE)
			message_admins("[key_name_admin(usr)] removed whitelist flag '[flag_value]' from [target_ckey] (offline).")
			log_admin("[key_name(usr)] removed whitelist flag '[flag_value]' from [target_ckey] (offline).")

		// Refresh the panel
		if(target_client)
			manage_whitelist_flags_panel(target_client)
		return TRUE

	else if(href_list["wl_refresh_panel"])
		if(!check_rights(R_ADMIN))
			return

		var/target_ckey = href_list["wl_refresh_panel"]
		var/client/target_client = GLOB.directory[target_ckey]
		if(target_client)
			manage_whitelist_flags_panel(target_client)
		else
			to_chat(usr, span_warning("Target client not found."), confidential = TRUE)
		return TRUE

	return FALSE
