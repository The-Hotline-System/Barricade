// ============================================================================
// NOTE TAB - Character Actions
// ============================================================================
// Displays character-specific actions like Respawn, View Memory, Share Name, Pray
// ============================================================================

/datum/statpanel_tab/note
	id = "note"
	name = "Note"
	icon = "button_note.png"
	priority = 10

/datum/statpanel_tab/note/can_view(client/C)
	return TRUE // Always visible as default tab

/datum/statpanel_tab/note/get_content(client/C)
	if(!C?.mob)
		return ""
	return C.mob.get_note_content()

/// Mob proc to generate note tab content - overridden by subtypes
/mob/proc/get_note_content()
	return ""

/mob/living/carbon/human/get_note_content()
	. = "<td valign='top'><table><tr><td>"
	var/list/main_options = list(
		list("<u>|- <b>ACTIONS</b> -|</u>", "", ISHTML),
		list("descend", "Respawn", ISPROC),
		list("memory", "View Memory", ISVERB),
		list("ShareName", "Share Name", ISVERB),
		list("emote_pray", "Pray", ISVERB)
	)
	. += generateVerbList(main_options)
	. += "</td></tr></table></td>"

/mob/dead/new_player/get_note_content()
	var/newHTML = ""
	var/lobby = ""
	// Lobby timer info can be added here if needed
	newHTML += {"<span style='color:#600; font-weight:bold;'>[lobby]</span>"}
	return newHTML

/mob/dead/observer/get_note_content()
	var/newHTML = ""
	var/note = ""
	newHTML += {"<span style='color:#600; font-weight:bold;'>[note]</span>"}
	return newHTML
