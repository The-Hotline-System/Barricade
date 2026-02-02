#define MAX_COOKIE_LENGTH 5

/*********************************
For the main html chat area
*********************************/

//Precaching a bunch of shit
GLOBAL_DATUM_INIT(iconCache, /savefile, new("tmp/iconCache.sav")) //Cache of icons for the browser output

//On client, created on login
/datum/chatOutput
	var/client/owner	 //client ref
	var/loaded       = FALSE // Has the client loaded the browser output area?
	var/list/messageQueue = list()//If they haven't loaded chat, this is where messages will go until they do
	var/cookieSent   = FALSE // Has the client sent a cookie for analysis
	var/broken       = FALSE
	var/list/connectionHistory //Contains the connection history passed from chat cookie
	var/adminMusicVolume = 50 //This is for the Play Global Sound verb
	var/total_checks = 0
	var/load_attempts = 0


/datum/chatOutput/New(client/C)
	owner = C
	messageQueue = list()
	connectionHistory = list()

/datum/chatOutput/proc/start()
	//Check for existing chat
	if(!owner)
		return FALSE

	if(!winexists(owner, "browseroutput")) // Oh goddamnit.
		set waitfor = FALSE
		broken = TRUE
		message_admins("Couldn't start chat for [key_name_admin(owner)]!")
		. = FALSE
		alert(owner.mob, "Updated chat window does not exist. If you are using a custom skin file please allow the game to update.")
		return

	if(!owner) // In case the client vanishes before winexists returns
		return 0

	if(winget(owner, "browseroutput", "is-visible") == "true") //Already setup
		doneLoading()

	else //Not setup
		load()

	return TRUE

/client/proc/force_white_theme() //There's no way round it. We're essentially changing the skin by hand. It's painful but it works, and is the way Lummox suggested.
	return

/client/proc/force_dark_theme() //Inversely, if theyre using white theme and want to swap to the superior dark theme, let's get WINSET() ing
	return

/datum/chatOutput/proc/load()
	set waitfor = FALSE
	if(!owner)
		return
	if(loaded)
		return
	var/datum/asset/stuff = get_asset_datum(/datum/asset/group/goonchat)
	stuff.send(owner)

	var/datum/asset/stat_stuff = get_asset_datum(/datum/asset/group/statpanel)
	stat_stuff.send(owner)

	// var/datum/asset/command_bar_stuff = get_asset_datum(/datum/asset/simple/command_bar)
	// command_bar_stuff.send(owner)

	owner << browse(file('code/modules/goonchat/browserassets/html/browserOutput.html'), "window=output_browser.browseroutput")
	owner << browse(file('code/modules/sovlpanel/html/html/statpanel.html'), "window=statwindow.browser;")
	owner << browse(file('code/modules/goonchat/browserassets/html/command_bar.html'), "window=inputwindow.command_bar_browser;size=805x20")
	owner << browse(file('code/modules/goonchat/browserassets/html/send_button.html'), "window=inputbuttons.send_button_browser;size=120x20")

	if (load_attempts < 5) //To a max of 5 load attempts
		spawn(20 SECONDS)
			if (owner && !loaded)
				load_attempts++
				load()
	else
		return

/client/verb/focus_chat_input()
	set name = "focus-chat-input"
	set hidden = TRUE
	set instant = TRUE

	// Focus the browser window
	winset(src, "inputwindow.command_bar_browser", "focus=true")
	// Focus the input element inside it
	src << output(null, "inputwindow.command_bar_browser:focusInput")

/datum/keybinding/client/chat/cycle_chat_mode
	hotkey_keys = list("`")
	name = "cycle_chat_mode"
	full_name = "Cycle Chat Mode"
	description = "Cycle through chat modes (SAY/WHSPR/ME/OOC/CMD)"
	keybind_signal = COMSIG_KB_CLIENT_CYCLECHATMODE_DOWN

/datum/keybinding/client/chat/cycle_chat_mode/down(client/user)
	. = ..()
	if(.)
		return
	user << output(null, "inputwindow.command_bar_browser:cycleMode")
	return TRUE


/datum/chatOutput/Topic(href, list/href_list)
	if(usr.client != owner)
		return TRUE

	var/data // Data to be sent back to the chat.
	switch(href_list["proc"])
		if("doneLoading")
			data = doneLoading()

		if("debug")
			data = debug(href_list["error"])

		if("ping")
			data = ping()

		if("analyzeClientData")
			data = analyzeClientData(href_list["cookie"])

		if("setMusicVolume")
			data = setMusicVolume(href_list["volume"])
		if("swaptodarkmode")
			swaptodarkmode()
		if("swaptolightmode")
			swaptolightmode()

	if(data)
		ehjax_send(data = data)

/datum/chatOutput/proc/executeCommand(command)
	if(!owner || !owner.mob || !command)
		return

	// Parse the command to determine the type and extract the message
	// Commands come in formats: say "text", whisper "text", me "text", ooc "text", or raw commands

	if(findtext(command, "say \"") == 1)
		// Extract the message from say "message"
		var/message = copytext(command, 6, -1) // Remove 'say "' and trailing '"'
		owner.mob.say_verb(message)

	else if(findtext(command, "whisper \"") == 1)
		// Extract the message from whisper "message"
		var/message = copytext(command, 10, -1) // Remove 'whisper "' and trailing '"'
		owner.mob.whisper_verb(message)

	else if(findtext(command, "me \"") == 1)
		// Extract the message from me "message"
		var/message = copytext(command, 5, -1) // Remove 'me "' and trailing '"'
		owner.mob.me_verb(message)

	else if(findtext(command, "ooc \"") == 1)
		// Extract the message from ooc "message"
		var/message = copytext(command, 6, -1) // Remove 'ooc "' and trailing '"'
		owner.ooc(message)

	else
		// Raw command - try to execute it as a verb or command
		// Use winset to execute the command as if typed in the command bar
		winset(owner, null, "command=[command]")

/datum/chatOutput/proc/handleModeChange(mode)
	if(!owner || !mode)
		return
	// Update the send button's mode
	owner << output(list2params(list(mode)), "inputbuttons.send_button_browser:updateButtonMode")

/datum/chatOutput/proc/handleSendButtonClick()
	if(!owner)
		return
	// Trigger the send command in the command bar
	owner << output("triggerSend()", "inputwindow.command_bar_browser:triggerSend")


//Called on chat output done-loading by JS.
/datum/chatOutput/proc/doneLoading()
	if(loaded || !owner)
		return

	testing("Chat loaded for [owner.ckey]")
	loaded = TRUE


	for(var/message in messageQueue)
		// whitespace has already been handled by the original to_chat
		to_chat(owner, message, handle_whitespace=FALSE)

	messageQueue = null
	sendClientData()

	syncRegex()

	// Send available commands to command bar
	sendAvailableCommands()

	// Debug message removed - chat is loading correctly now that tgui_panel is disabled

/datum/chatOutput/proc/sendAvailableCommands()
	if(!owner || !owner.mob)
		return

	var/list/commands = list()

	// Gather all verbs from the mob that are actually accessible
	for(var/verb_path in owner.mob.verbs)
		var/procpath/P = verb_path
		if(!P || P.hidden)
			continue

		// Skip admin-only verbs if user is not an admin
		if(P.category && (findtext(P.category, "Admin") || findtext(P.category, "Debug")) && !owner.holder)
			continue

		// Use the verb's actual name, not the path
		var/verb_name = P.name
		if(!verb_name)
			continue

		// Check if the mob can actually call this verb
		if(!hascall(owner.mob, verb_name))
			continue

		// Replace spaces with hyphens for command-line compatibility
		verb_name = replacetext(verb_name, " ", "-")
		verb_name = lowertext(verb_name)
		if(verb_name && !(verb_name in commands))
			commands += verb_name

	// Gather client verbs that are accessible
	for(var/verb_path in owner.verbs)
		var/procpath/P = verb_path
		if(!P || P.hidden)
			continue

		// Skip admin-only verbs if user is not an admin
		if(P.category && (findtext(P.category, "Admin") || findtext(P.category, "Debug")) && !owner.holder)
			continue

		// Use the verb's actual name, not the path
		var/verb_name = P.name
		if(!verb_name)
			continue

		// Check if the client can actually call this verb
		if(!hascall(owner, verb_name))
			continue

		// Replace spaces with hyphens for command-line compatibility
		verb_name = replacetext(verb_name, " ", "-")
		verb_name = lowertext(verb_name)
		if(verb_name && !(verb_name in commands))
			commands += verb_name

	// Send the commands list to the command bar
	var/commands_json = json_encode(commands)
	owner << output(list2params(list("commands" = commands_json)), "inputwindow.command_bar_browser:setCommands")


/proc/syncChatRegexes()
	for (var/user in GLOB.clients)
		var/client/C = user
		var/datum/chatOutput/Cchat = C.chatOutput
		if (Cchat && !Cchat.broken && Cchat.loaded)
			Cchat.syncRegex()

/datum/chatOutput/proc/syncRegex()
	var/list/regexes = list()

	if (config.ic_filter_regex)
		regexes["show_filtered_ic_chat"] = list(
			config.ic_filter_regex.name,
			"ig",
			span_boldwarning("$1")
		)

	if (regexes.len)
		ehjax_send(data = list("syncRegex" = regexes))

/datum/chatOutput/proc/ehjax_send(client/C = owner, window = "output_browser.browseroutput", data)
	if(islist(data))
		data = json_encode(data)
	C << output("[data]", "[window]:ehjaxCallback")

/datum/chatOutput/proc/sendMusic(music, list/extra_data)
	if(!findtext(music, GLOB.is_http_protocol))
		return
	var/list/music_data = list("adminMusic" = url_encode(url_encode(music)))

	if(extra_data?.len)
		music_data["musicRate"] = extra_data["pitch"]
		music_data["musicSeek"] = extra_data["start"]
		music_data["musicHalt"] = extra_data["end"]

	ehjax_send(data = music_data)

/datum/chatOutput/proc/stopMusic()
	ehjax_send(data = "stopMusic")

/datum/chatOutput/proc/setMusicVolume(volume = "")
	return

//Sends client connection details to the chat to handle and save
/datum/chatOutput/proc/sendClientData()
	//Get dem deets
	var/list/deets = list("clientData" = list())
	deets["clientData"]["ckey"] = owner.ckey
	deets["clientData"]["ip"] = owner.address
	deets["clientData"]["compid"] = owner.computer_id
	var/data = json_encode(deets)
	ehjax_send(data = data)


//Called by client, sent data to investigate (cookie history so far)
/datum/chatOutput/proc/analyzeClientData(cookie = "")
	if(!cookie)
		return

	if(cookie != "none")
		var/regex/simple_crash_regex = new /regex("(\\\[ *){5}")
		if(simple_crash_regex.Find(cookie))
			message_admins("[key_name(src.owner)] tried to crash the server using malformed JSON")
			log_admin("[key_name(owner)] tried to crash the server using malformed JSON")
			return
		var/list/connData = json_decode(cookie)
		if (connData && islist(connData) && connData.len > 0 && connData["connData"])
			connectionHistory = connData["connData"] //lol fuck
			var/list/found = new()
			if(connectionHistory.len > MAX_COOKIE_LENGTH)
				message_admins("[key_name(src.owner)] was kicked for an invalid ban cookie)")
				qdel(owner)
				return
			for(var/i in connectionHistory.len to 1 step -1)
				var/list/row = src.connectionHistory[i]
				if (!row || row.len < 3 || (!row["ckey"] || !row["compid"] || !row["ip"])) //Passed malformed history object
					return
				if (world.IsBanned(row["ckey"], row["ip"], row["compid"], real_bans_only=TRUE))
					found = row
					break

			//Uh oh this fucker has a history of playing on a banned account!!
			if (found.len > 0)
				//TODO: add a new evasion ban for the CURRENT client details, using the matched row details
				message_admins("[key_name(src.owner)] has a cookie from a banned account! (Matched: [found["ckey"]], [found["ip"]], [found["compid"]])")
				log_admin_private("[key_name(owner)] has a cookie from a banned account! (Matched: [found["ckey"]], [found["ip"]], [found["compid"]])")

	cookieSent = TRUE

//Called by js client every 60 seconds
/datum/chatOutput/proc/ping()
	return "pong"

//Called by js client on js error
/datum/chatOutput/proc/debug(error)
	log_world("\[[time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")]\] Client: [(src.owner.key ? src.owner.key : src.owner)] triggered JS error: [error]")

//Global chat procs
/proc/to_chat_immediate(target, message, handle_whitespace = TRUE)
	if(!target || !message)
		return

	if(target == world)
		target = GLOB.clients

	var/original_message = message
	if(handle_whitespace)
		message = replacetext(message, "\n", "<br>")
		message = replacetext(message, "\t", "[FOURSPACES][FOURSPACES]") //EIGHT SPACES IN TOTAL!!

	if(islist(target))
		// Do the double-encoding outside the loop to save nanoseconds
		var/twiceEncoded = url_encode(url_encode(message))
		for(var/I in target)
			var/client/C = CLIENT_FROM_VAR(I) //Grab us a client if possible

			if (!C)
				continue

			//Send it to the old style output window.
			SEND_TEXT(C, original_message)

			if(!C.chatOutput || C.chatOutput.broken) // A player who hasn't updated his skin file.
				continue

			if(!C.chatOutput.loaded)
				//Client still loading, put their messages in a queue
				C.chatOutput.messageQueue += message
				continue

			C << output(twiceEncoded, "output_browser.browseroutput:output")
	else
		var/client/C = CLIENT_FROM_VAR(target) //Grab us a client if possible

		if (!C)
			return

		//Send it to the old style output window.
		SEND_TEXT(C, original_message)

		if(!C.chatOutput || C.chatOutput.broken) // A player who hasn't updated his skin file.
			return

		if(!C.chatOutput.loaded)
			//Client still loading, put their messages in a queue
			C.chatOutput.messageQueue += message
			return

		// url_encode it TWICE, this way any UTF-8 characters are able to be decoded by the Javascript.
		C << output(url_encode(url_encode(message)), "output_browser.browseroutput:output")

/proc/to_chat(
	target,
	text = null,
	type = null,
	html,
	avoid_highlighting = FALSE,
	// FIXME: These flags are now pointless and have no effect
	handle_whitespace = TRUE,
	trailing_newline = TRUE,
	confidential = FALSE
	)
	// Use html if text is null - many admin functions pass messages via the html parameter
	var/message = text || html
	if(Master.current_runlevel == RUNLEVEL_LOBBY || !SSchat?.initialized)
		to_chat_immediate(target, message, handle_whitespace)
		return
	SSchat.queue(target, message, handle_whitespace)

/proc/to_world(text, type, html, avoid_highlighting)
	to_chat(world, text, type, html, avoid_highlighting)

/datum/chatOutput/proc/swaptolightmode() //Dark mode light mode stuff. Yell at KMC if this breaks! (See darkmode.dm for documentation)
	owner.force_white_theme()

/datum/chatOutput/proc/swaptodarkmode()
	owner.force_dark_theme()

