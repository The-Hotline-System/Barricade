// ============================================================================
// OPTIONS TAB - OOC Options
// ============================================================================
// Displays OOC options like adminhelp, OOC chat, LOOC, preferences, fixes
// ============================================================================

/datum/statpanel_tab/options
	id = "options"
	name = "Options"
	icon = "button_options.png"
	priority = 30

/datum/statpanel_tab/options/can_view(client/C)
	return TRUE // Always visible

/datum/statpanel_tab/options/get_content(client/C)
	. = "<table><tr>"

	// Main section in left column
	. += "<td valign='top'><table><tr><td>"
	var/list/main_options = list(
		list("<u>|- <b>OOC</b> -|</u>", "", ISHTML),
		list("adminhelp", "Admin Help", ISVERB),
		list("ooc", "OOC", ISVERB),
		list("looc", "LOOC", ISVERB),
		list("<br><u>|- <b>PREFS</b> -|</u>", "", ISHTML),
		list("fullscreen", "Toggle Fullscreen", ISPROC),
		list("ToggleOldUI", "Toggle Old UI", ISPROC),
		list("<u>|- <b>FIXES</b> -|</u>", "", ISHTML),
		list("StopSounds", "Stop Sounds", ISVERB),
		list("fix_chat", "Fix Chat", ISPROC)
	)
	. += generateVerbList(main_options)
	. += "</td></tr></table></td>"

	. += "</tr></table>"
