// ============================================================================
// ROUND STATUS TAB - Default tab showing round information
// ============================================================================
// Displays round status information including ping, map, round ID, time
// dilation, and other server statistics. This is a default tab visible to
// all players.
// ============================================================================

/datum/statpanel_tab/round_status
	id = "round_status"
	name = "Round"
	icon = "blank.png"
	priority = 30 // Show first (leftmost)
	realtime = TRUE // Update in realtime
	var/is_pregame = FALSE

/datum/statpanel_tab/round_status/can_view(client/C)
	return TRUE // Always visible to everyone

/datum/statpanel_tab/round_status/get_content(client/C)
	if(!C)
		return ""

	. = "<table><tr><td valign='top'><table><tr><td>"

	// ==================== ROUND INFO ====================
	. += "<u>|- <b>ROUND INFO</b> -|</u><br>"

	// Round ID
	if(GLOB.round_id)
		. += "<span class='verb'>Round ID:</span> <span class='verb dim'>#[GLOB.round_id]</span><br>"
	else
		. += "<span class='verb'>Round ID:</span> <span class='verb dim'>N/A</span><br>"

	// Time to Start (pregame only)
	if(is_pregame && SSticker?.start_at)
		var/time_left = max(0, SSticker.start_at - world.time)
		var/minutes = round(time_left / 600)
		var/seconds = round((time_left % 600) / 10)
		. += "<span class='verb'>Time to Start:</span> <span class='verb dim'>[minutes]m [seconds]s</span><br>"

	// Ready Players (pregame only)
	if(is_pregame && SSticker)
		. += "<span class='verb'>Ready Players:</span> <span class='verb dim'>[SSticker.totalPlayersReady]/[SSticker.totalPlayers]</span><br>"

	// Round Duration (playing only)
	if(!is_pregame && SSticker?.round_start_time)
		var/round_duration = world.time - SSticker.round_start_time
		var/hours = round(round_duration / 36000)
		var/minutes = round((round_duration % 36000) / 600)
		var/seconds = round((round_duration % 600) / 10)
		. += "<span class='verb'>Duration:</span> <span class='verb dim'>[hours]H:[minutes]M:[seconds]S</span><br>"

	. += "<br>"

	// ==================== GAME INFO ====================
	// Only show server info to admins
	if(C.holder)
		. += "<u>|- <b>GAME INFO</b> -|</u><br>"

		// Round State
		var/round_state = "Unknown"
		is_pregame = FALSE
		if(SSticker)
			switch(SSticker.current_state)
				if(GAME_STATE_STARTUP)
					round_state = "Starting Up"
					is_pregame = FALSE
				if(GAME_STATE_PREGAME)
					round_state = "Pre-Game"
					is_pregame = TRUE
				if(GAME_STATE_SETTING_UP)
					round_state = "Setting Up"
				if(GAME_STATE_PLAYING)
					round_state = "Playing"
				if(GAME_STATE_FINISHED)
					round_state = "Finished"
		. += "<span class='verb'>State:</span> <span class='verb dim'>[round_state]</span><br>"

		// Time Dilation
		if(SStime_track)
			var/td_current = round(SStime_track.time_dilation_current, 0.01)
			var/td_avg = round(SStime_track.time_dilation_avg, 0.01)
			. += "<span class='verb'>Time Dilation:</span> <span class='verb dim'>[td_current]% (avg: [td_avg]%)</span><br>"
		else
			. += "<span class='verb'>Time Dilation:</span> <span class='verb dim'>N/A</span><br>"

		// Players Online
		var/player_count = length(GLOB.clients)
		//mincounting
		var/list/adm = get_admin_counts()
		var/admin_count = length(adm["present"])
		. += "<span class='verb'>Players:</span> <span class='verb dim'>[player_count] (A:[admin_count])</span><br>"

		// Map Name
		if(SSmapping?.config?.map_name)
			. += "<span class='verb'>Map:</span> <span class='verb dim'>[SSmapping.config.map_name]</span><br>"
		else
			. += "<span class='verb'>Map:</span> <span class='verb dim'>Loading...</span><br>"

		. += "<br>"
