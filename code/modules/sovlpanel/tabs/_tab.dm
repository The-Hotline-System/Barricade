// ============================================================================
// STATPANEL TAB DATUM SYSTEM
// ============================================================================
// Base datum for statpanel tabs. Tabs are registered globally and dynamically
// displayed based on client state via can_view().
// ============================================================================

GLOBAL_LIST_EMPTY(statpanel_tabs)

/proc/init_statpanel_tabs()
	if(length(GLOB.statpanel_tabs))
		return // Already initialized
	for(var/tab_type in subtypesof(/datum/statpanel_tab))
		var/datum/statpanel_tab/tab = new tab_type
		if(tab.id)
			GLOB.statpanel_tabs += tab
	// Sort by priority
	sortTim(GLOB.statpanel_tabs, GLOBAL_PROC_REF(cmp_statpanel_tab_priority))

/proc/cmp_statpanel_tab_priority(datum/statpanel_tab/a, datum/statpanel_tab/b)
	return a.priority - b.priority

/datum/statpanel_tab
	/// Unique identifier for this tab
	var/id
	/// Display name shown to user
	var/name
	/// Icon filename (without path, e.g. "button_note.png")
	var/icon
	/// Sort priority - lower values appear first (left)
	var/priority = 50

/// Returns HTML content for this tab
/datum/statpanel_tab/proc/get_content(client/C)
	return ""

/// Returns TRUE if this tab should be visible to the client
/datum/statpanel_tab/proc/can_view(client/C)
	return TRUE

/// Returns the button HTML for the buttonpanel
/datum/statpanel_tab/proc/get_button_html()
	if(!id || !icon)
		return ""
	return {"<a href='byond://?_src_=stat;tab=[id]' class='button' id='[id]' style='background-image:url("[icon]");'></a>"}
