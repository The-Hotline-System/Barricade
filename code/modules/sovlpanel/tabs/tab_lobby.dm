// ============================================================================
// LOBBY TAB - Pre-Spawn Lobby Info
// ============================================================================
// Displays lobby information for new players before they spawn
// ============================================================================

/datum/statpanel_tab/lobby
	id = "lobby"
	name = "Lobby"
	icon = "button_lobby.png"
	priority = 5 // Show first

/datum/statpanel_tab/lobby/can_view(client/C)
	if(!C?.mob)
		return FALSE
	return istype(C.mob, /mob/dead/new_player)

/datum/statpanel_tab/lobby/get_content(client/C)
	var/newHTML = ""
	// Lobby timer and player count can be added here
	/*
	if(SSticker.current_state < GAME_STATE_PLAYING)
		var/time_remaining = SSticker.GetTimeLeft()
		if(time_remaining > 0)
			newHTML += "Time To Start: [round(time_remaining/10)]s<br>"
		else if(time_remaining == -10)
			newHTML += "Time To Start: DELAYED<br>"
		else
			newHTML += "Time To Start: SOON<br>"
		newHTML += "Total players ready: [SSticker.totalPlayersReady]<br>"
	*/
	return {"<span style='color:#600; font-weight:bold;'>[newHTML]</span>"}
