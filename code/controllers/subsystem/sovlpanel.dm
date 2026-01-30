// ============================================================================
// SOVLPANEL SUBSYSTEM - Realtime Tab Updates
// ============================================================================
// Manages periodic updates to sovlpanel tab content for connected clients.
// Only updates tabs with realtime = TRUE and only for the active tab.
// ============================================================================

SUBSYSTEM_DEF(sovlpanel)
	name = "Sovlpanel"
	priority = FIRE_PRIORITY_STATPANEL
	wait = 5
	flags = SS_NO_INIT
	runlevels = RUNLEVEL_LOBBY | RUNLEVEL_SETUP | RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	/// Current batch of clients being processed
	var/list/currentrun = list()

/datum/controller/subsystem/sovlpanel/stat_entry(msg)
	return ..(msg + "C:[length(currentrun)]")

/datum/controller/subsystem/sovlpanel/fire(resumed = FALSE)
	// Prepare the new batch of clients
	if(!resumed)
		currentrun = GLOB.clients.Copy()

	// De-reference the list for performance
	var/list/current = currentrun

	while(length(current))
		var/client/C = current[length(current)]
		current.len--

		// Skip clients without loaded statpanels
		if(!C?.statpanel_loaded || !C.current_button)
			if(MC_TICK_CHECK)
				return
			continue

		// Find and update the active realtime tab
		C.update_active_tab_content()

		if(MC_TICK_CHECK)
			return
