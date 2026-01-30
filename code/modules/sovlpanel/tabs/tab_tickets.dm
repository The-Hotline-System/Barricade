// ============================================================================
// TICKETS TAB - Admin-only adminhelp ticket display
// ============================================================================
// Displays adminhelp tickets and interview manager status for admins.
// Shows active, closed, and resolved ticket counts with clickable links.
// ============================================================================

/datum/statpanel_tab/tickets
	id = "tickets"
	name = "Tickets"
	icon = "blank.png"
	priority = 15
	realtime = TRUE

/datum/statpanel_tab/tickets/can_view(client/C)
	return !!C?.holder

/datum/statpanel_tab/tickets/get_content(client/C)
	if(!C?.holder || !GLOB.ahelp_tickets)
		return ""

	var/href_token = C.holder.href_token

	. = "<table><tr><td valign='top'><table><tr><td>"
	. += "<u>|- <b>ADMINHELP TICKETS</b> -|</u><br>"

	// Get ticket data from the global ticket manager
	var/datum/admin_help_tickets/tickets = GLOB.ahelp_tickets
	var/num_disconnected = 0

	// Active Tickets header with count
	var/active_count = length(tickets.active_tickets)
	. += "<a href='?_src_=holder;admin_token=[href_token];ahelp_tickets=[AHELP_ACTIVE]' class='verb'>Active Tickets: [active_count]</a><br>"

	// List active tickets
	for(var/datum/admin_help/AH in tickets.active_tickets)
		if(AH.initiator)
			var/ticket_ref = REF(AH)
			var/handler_text = AH.handler ? "H-[AH.handler] " : ""
			. += "<a href='?_src_=holder;admin_token=[href_token];ahelp=[ticket_ref];ahelp_action=ticket' class='verb dim'>"
			. += "[handler_text]#[AH.id]. [AH.initiator_key_name]: [AH.name]</a><br>"
		else
			num_disconnected++

	// Show disconnected count if any
	if(num_disconnected)
		. += "<span class='verb dim'>Disconnected: [num_disconnected]</span><br>"

	. += "<br>"

	// Closed Tickets
	var/closed_count = length(tickets.closed_tickets)
	. += "<a href='?_src_=holder;admin_token=[href_token];ahelp_tickets=[AHELP_CLOSED]' class='verb'>Closed Tickets: [closed_count]</a><br>"

	// Resolved Tickets
	var/resolved_count = length(tickets.resolved_tickets)
	. += "<a href='?_src_=holder;admin_token=[href_token];ahelp_tickets=[AHELP_RESOLVED]' class='verb'>Resolved Tickets: [resolved_count]</a><br>"

	// ==================== INTERVIEWS SECTION ====================
	. += "<br><u>|- <b>INTERVIEWS</b> -|</u><br>"

	// Interview Manager link
	. += "<a href='?_src_=holder;admin_token=[href_token];interview_man=1' class='verb'>Open Interview Manager</a><br><br>"

	// Get interview data
	if(GLOB.interviews)
		var/datum/interview_manager/IM = GLOB.interviews

		// Interview stats
		var/open_count = length(IM.open_interviews)
		var/queued_count = length(IM.interview_queue)
		var/closed_count_interviews = length(IM.closed_interviews)

		. += "<span class='verb dim'>Open: [open_count] | Queued: [queued_count] | Closed: [closed_count_interviews]</span><br><br>"

		// List queued interviews (sorted by queue position)
		if(queued_count)
			. += "<span class='verb'>Pending Review:</span><br>"
			for(var/datum/interview/I in IM.interview_queue)
				var/interview_ref = REF(I)
				var/dc_text = I.owner ? "" : " (DC)"
				. += "<a href='?_src_=holder;admin_token=[href_token];interview=[interview_ref]' class='verb dim'>"
				. += "#[I.pos_in_queue]. [I.owner_ckey][dc_text]</a><br>"

		// List other open interviews (not queued, still being filled out)
		var/list/non_queued = list()
		for(var/ckey in IM.open_interviews)
			var/datum/interview/I = IM.open_interviews[ckey]
			if(I && !(I in IM.interview_queue))
				non_queued += I

		if(length(non_queued))
			. += "<span class='verb'>In Progress:</span><br>"
			for(var/datum/interview/I in non_queued)
				var/interview_ref = REF(I)
				var/dc_text = I.owner ? "" : " (DC)"
				. += "<a href='?_src_=holder;admin_token=[href_token];interview=[interview_ref]' class='verb dim'>"
				. += "[I.owner_ckey][dc_text] - Filling out</a><br>"

	. += "</td></tr></table></td></tr></table>"
