// ============================================================================
// ADMIN TAB - Admin-Only Options
// ============================================================================
// Displays admin options - only visible to clients with admin holder
// ============================================================================

/datum/statpanel_tab/admin
	id = "admin"
	name = "Admin"
	icon = "button_admin.png"
	priority = 90 // Show last

/datum/statpanel_tab/admin/can_view(client/C)
	return C?.holder ? TRUE : FALSE // Only visible to admins

/datum/statpanel_tab/admin/get_content(client/C)
	if(!C?.holder)
		return ""

	. = "<table><tr>"
	. += "<td valign='top'><table><tr><td>"
	var/list/admin_options = list(
		list("<u>|- <b><i>ADMIN</i></b> -|</u>", "", ISHTML),
		list("deadmin", "De-admin self", ISPROC),
		list("readmin", "Re-Admin self", ISPROC),
		list("list_tickets", "List tickets", ISPROC),
		list("toggle_sovlpanel", "Toggle Statpanel", ISPROC),
		list("show_game_over", "Debug Credits (Self)", ISPROC)
	)
	. += generateVerbList(admin_options)
	. += "</td></tr></table></td>"
	. += "</tr></table>"
