/client/Topic(href, href_list, hsrc)
	. = ..()
	if(href_list["_src_"] == "stat")
		if(href_list["spload"] == "1")
			statpanel_loaded = TRUE
			init_panel()
		if(href_list["modernbrowser"] == "1")
			statpanel_loaded = TRUE
		// Unified tab handler for datumized tabs
		if(href_list["tab"])
			src << 'sound/uibutton.ogg'
			var/tab_id = href_list["tab"]
			if(current_button == tab_id)
				return
			for(var/datum/statpanel_tab/tab in GLOB.statpanel_tabs)
				if(tab.id == tab_id)
					current_button = tab_id
					newtext(tab.get_content(src))
					return
		if(href_list["proc"])
			//src << 'sound/uibutton.ogg'
			call(src, href_list["proc"])()

