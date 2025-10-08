/client/var/list/flags = list()

/proc/get_flag_path(key)
    return file("data/player_saves/[copytext(key,1,2)]/[key]/whitelists.json")


/proc/has_flag(client/C, str)
	if(!C) return FALSE
	if(C.holder) return TRUE // Oh fuck its a staffie
	if(!length(C.flags)) return FALSE
	if(islist(str))
		if(!length(str))
			return TRUE
		for(var/s in str)
			if(s in C.flags)
				return TRUE
		return FALSE
	if(!str) return TRUE
	return (str in C.flags)

/proc/create_flag_file(key)
	var/file_path = get_flag_path(key)
	if(!fexists(file_path))
		var/list/entry = list(
			"value" = "WL_EXAMPLE",
			"added_by" = "TEMPLATE",
			"reason" = "REASON HERE",
			"date" = "DATE HERE"
		)
		var/list/flags = list(entry)
		WRITE_FILE(file_path, json_encode(flags))

/proc/load_client_flags(client/C)
	if(!C) return
	var/key = C.ckey
	var/file_path = get_flag_path(key)
	if(!fexists(file_path))
		create_flag_file(key) // Create the file if it doesn't exist
		return FALSE // KINO

	var/list/raw_data = json_decode(file2text(file_path))
	if(!islist(raw_data))
		raw_data = list()
	var/list/entries = list()
	for(var/entry in raw_data)
		if(islist(entry) && entry["value"])
			entries += uppertext(entry["value"]) // case doesn't matter
	C.flags = entries
	return TRUE // KINO


/proc/add_to_whitelist_ckeyonly(key, str, added_by = null, reason = null) // Doesnt update the online player's stuff, meant for offline players
	var/file_path = get_flag_path(key)

	if(!fexists(file_path))
		create_flag_file(key)

	str = uppertext(str)

	var/list/flags = json_decode(file2text(file_path))

	if(!islist(flags))
		flags = list()

	// Prevent duplicates
	for(var/entry in flags)
		if(islist(entry) && entry["value"] == str)
			return // Already flaged

	var/list/entry = list(
		"value" = str,
		"added_by" = added_by,
		"reason" = reason,
		"date" = time2text(world.realtime, "YYYY-MM-DD")
	)

	flags += entry
	fdel(file_path)
	WRITE_FILE(file_path, json_encode(flags))

/proc/remove_from_whitelist_ckeyonly(key, str) // Doesnt update the online player's stuff, meant for offline players
	var/file_path = get_flag_path(key)

	if(!fexists(file_path))
		create_flag_file(key)

	str = uppertext(str)

	var/list/flags = json_decode(file2text(file_path))
	if(!islist(flags))
		flags = list()

	var/list/new_flags = list()
	for(var/entry in flags)
		if(!islist(entry)) continue
		if(entry["value"] != str) // keep only entries that don't match
			new_flags += list(entry)

	fdel(file_path)
	WRITE_FILE(file_path, json_encode(new_flags))

/proc/add_to_whitelist(client/C, str, added_by = null, reason = null)
	if(!C || !C.ckey) return
	var/key = C.ckey
	var/file_path = get_flag_path(key)

	if(!fexists(file_path))
		create_flag_file(key)

	str = uppertext(str)

	var/list/flags = json_decode(file2text(file_path))

	if(!islist(flags))
		flags = list()

	for(var/entry in flags)
		if(islist(entry) && entry["value"] == str)
			return // Already exists

	var/list/entry = list(
		"value" = str,
		"added_by" = added_by,
		"reason" = reason,
		"date" = time2text(world.realtime, "YYYY-MM-DD")
	)

	flags += list(entry)
	fdel(file_path)
	WRITE_FILE(file_path, json_encode(flags))

	load_client_flags(C) // refresh cache

/proc/remove_from_whitelist(client/C, str)
	if(!C) return
	var/key = C.ckey
	var/file_path = get_flag_path(key)
	if(!fexists(file_path))
		create_flag_file(key)

	str = uppertext(str)

	var/list/flags = json_decode(file2text(file_path))

	if(!islist(flags))
		flags = list()

	var/list/new_flags = list()
	for(var/entry in flags)
		if(!islist(entry)) continue
		if(entry["value"] != str) // keep only entries that don't match
			new_flags += list(entry)

	fdel(file_path)
	WRITE_FILE(file_path, json_encode(new_flags))
	load_client_flags(C)

/proc/check_flag_menu(ckey)

	if(!usr || !usr.client || !usr.client.holder)
		return

	var/file_path = get_flag_path(ckey)
	if(!fexists(file_path))
		to_chat(usr, "<span class='boldwarning'>User does not have a flag file.</span>")
		create_flag_file(ckey)
	var/popup_window_data = "<font size=4><center><b>[ckey]</b></center></font>"
	var/list/flags = json_decode(file2text(file_path))

	if(!islist(flags))
		to_chat(usr, "<span class='boldwarning'>Failed to parse JSON into list.</span>")
		return

	if(!length(flags))
		to_chat(usr, "<span class='boldwarning'>flag is empty.</span>")
		return

	popup_window_data += "<center><font size=3>The user has the following flags:</font></center><hr>"
	for(var/i = 1 to flags.len)
		var/entry = flags[i]
		if(islist(entry))
			if(!entry["value"])
				popup_window_data += "-- <font size=3><b>#[i]</b></font> --<br><span>Has been skipped. <br>Missing value.</span><br><br>"
				continue // Skip the template and fucked up
			else
				if(entry["value"] == "WL_EXAMPLE" || entry["added_by"] == "TEMPLATE")
					continue
				popup_window_data += "-- <font size=3><b>#[i]</b></font> --<br>- <b>String:</b> [entry["value"]],<br>- <b>Added by:</b> [entry["added_by"]]<br>- <b>Reason:</b> [entry["reason"]]<br>- <b>Date:</b> [entry["date"]]</span><br><br>"
		else
			popup_window_data += "-- Ough.. [i] has an issue in the json file.. --"

	var/datum/browser/popup = new(usr, "flags", "FLAG LIST", 390, 320)
	popup.set_content(popup_window_data)
	popup.open()

/client/New(TopicData)
	. = ..()
	load_client_flags(src)
