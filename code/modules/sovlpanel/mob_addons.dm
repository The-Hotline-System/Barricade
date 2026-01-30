/* HOW TO USE:
add/remove verbs with add_verb(verb_path) & remove_verb(verb_path).
both support lists which are better to use if you're adding/removing multiple verbs at once.
to make verbs appear in the panel. You'll need to set the verb's category to one of ("craft","verb","emotes","gpc","cross","crown","fangs","dead","villain")
and set its desc to what you want the verb to appear as in the statpanel.
*/

/// Duck check to see if text looks like a ckey
/proc/valid_ckey(text)
	var/static/regex/matcher = new (@"^[a-z0-9]{1,30}$")
	return matcher.Find_char(text)

/// Get the client associated with ckey text if it is currently connected
/proc/ckey2client(text)
	if (valid_ckey(text))
		for (var/client/C as anything in GLOB.clients)
			if (C.ckey == text)
				return C

/// Null, or a client if thing is a client, a mob with a client, a connected ckey, or null
/proc/resolve_client(client/thing)
	if (istype(thing))
		return thing
	if (!thing)
		thing = usr
	if (ismob(thing))
		var/mob/M = thing
		return M.client
	return ckey2client(thing)

/client
	var/scrollbarready = 0
	var/statpanel_loaded = FALSE
	var/list/stat_tabs = list()
	var/current_button
	var/list/html_verbs = list()

/typeverb
	var/name as text
	var/desc as text
	var/category as text
	var/hidden as num

/client/var/toggle_statpanel = FALSE

/client/verb/toggle_sovlpanel()
	set name = "statpanel"

	//if(!holder && !toggle_statpanel) return

	winset(src, "statwindow.stat", "is-visible=[toggle_statpanel]")
	winset(src, "statwindow.browser", "is-visible=[!toggle_statpanel]")

	toggle_statpanel = !toggle_statpanel

/client/proc/add_verbs(path)
	verbs |= path
	mob?.updateStatPanel()


/client/proc/remove_verbs(path)
	verbs -= path
	mob?.updateStatPanel()

/mob/add_verbs(path)
	verbs |= path
	updateStatPanel()

/mob/remove_verbs(path)
	verbs -= path
	updateStatPanel()

/atom/movable/proc/add_verbs(path)
	verbs |= path

/atom/movable/proc/remove_verbs(path)
	verbs -= path

/client/proc/init_panel()
	// Lazy initialization of tab datums
	init_statpanel_tabs()

	if(!statpanel_loaded)
		spawn(10)
			init_panel()
		return
	//else
	//	toggle_sovlpanel()
	mob.updateStatPanel()

/client/verb/debug_panel()
	init_panel()

/mob/dead/new_player/Login()
	..()
	sleep(35)
	if(client)
		client.init_panel()

/mob/Login()
	..()
	client.init_panel()

/mob/living/carbon/human/proc/updateSmalltext()
	if(!client)
		return

	var/list/text = list()
	var/fulltext = ""

	for(var/T in text)
		fulltext += "[T]<br>"

	return fulltext

/proc/generateVerbHtml(verbname = "", displayname = "", isverb, number = 1)
	if(isverb >= 2) // Free space, we get to do what we want
		if(number % 2)
			return {"<span class='verb dim'>[verbname][displayname]</span>"}
		return {"<span class='verb'>[verbname][displayname]</span>"}
	if(isverb) // very misleading, should be 'isproc'
		if(number % 2)
			return {"<a href='byond://?_src_=stat;proc=[verbname]' class='verb dim'>[displayname]</a>"}
		return {"<a href='byond://?_src_=stat;proc=[verbname]' class='verb'>[displayname]</a>"}
	if(number % 2)
		return {"<a href='#' class='verb dim' onclick='window.location = "byond://winset?command=[verbname]"'>[displayname]</a>"}
	return {"<a href='#' class='verb' onclick='window.location = "byond://winset?command=[verbname]"'>[displayname]</a>"}

/proc/generateVerbList(list/verbs = list(), count = 1)
	var/html = ""
	var/counter = count
	for(var/list/L in verbs)
		counter++
		html += generateVerbHtml(L[1], L[2], L[3], counter) + "<BR>"

	return html

/client/proc/newtext(newcontent = "", id)
	if(!newcontent || newcontent == "")
		return
	src << output(list2params(list("[newcontent]")), "statwindow.browser:InputMsg")
/*
/client/proc/changebuttoncontent(idcontent = "", newcontent = "")
	return
	if(!statpanel_loaded)
		return
	src << output(list2params(list("[newcontent]", "[idcontent]")), "statwindow.browser:changel")
*/
/client/proc/addbutton(newcontent = "", selector = "")
	src << output(list2params(list("[newcontent]", "")), "statwindow.browser:UpdateDynamicpanel")

/// Called by SSsovlpanel to update the active tab's content if it supports realtime updates
/client/proc/update_active_tab_content()
	if(!statpanel_loaded || !current_button)
		return
	// Find the active tab
	for(var/datum/statpanel_tab/tab in GLOB.statpanel_tabs)
		if(tab.id == current_button)
			// Only update if tab supports realtime and client can view it
			if(!tab.realtime || !tab.can_view(src))
				return
			var/new_content = tab.get_content(src)
			newtext(new_content)
			return


/mob/proc/updateStatPanel()
	set waitfor = 0
	if(!client)
		return
	if(!client.statpanel_loaded)
		return

	// Discover unknown verb categories and register placeholder tabs
	var/list/verb_list = verbs + client.verbs
	for(var/v in verb_list)
		var/procpath/P = v
		if(!P?.category || P.hidden)
			continue
		if(!istext(P.category))
			continue
		var/parent = get_parent_category(P.category)
		if(!(parent in GLOB.registered_verb_categories))
			register_dynamic_category(P.category)

	// Build button HTML from datumized tabs
	var/buttonHTML = ""
	var/current_content = FALSE

	for(var/datum/statpanel_tab/tab in GLOB.statpanel_tabs)
		if(!tab.can_view(client))
			continue

		// Cache tab content
		client.html_verbs[tab.id] = tab.get_content(client)

		// Check if this is current tab
		if(tab.id == client.current_button)
			client.newtext(client.html_verbs[tab.id])
			current_content = TRUE

		// Add button HTML
		buttonHTML += tab.get_button_html()

	// Default to first visible tab if current is not visible
	if(!current_content)
		for(var/datum/statpanel_tab/tab in GLOB.statpanel_tabs)
			if(tab.can_view(client) && tab.id)
				client.current_button = tab.id
				client.newtext(tab.get_content(client))
				break

	client.addbutton(buttonHTML, "#dynamicpanel")



#define ISHTML 2
#define ISPROC 1
#define ISVERB 0

/mob/living/carbon/human/Login()
	..()
	updateStatPanel()

