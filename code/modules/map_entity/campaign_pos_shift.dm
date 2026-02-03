/// Campaign Position Shift Map Entity
/// Allows seamless map transitions by defining coordinate offsets between maps
/// Place one entity per source map to define how positions should be shifted

GLOBAL_LIST_EMPTY(campaign_pos_shifts)

/obj/effect/map_entity/campaign_pos_shift
	name = "campaign_pos_shift"
	desc = "Defines position offset for campaign map transitions."
	icon_state = "landmark2"
	
	/// X coordinate offset to apply when loading from source map
	var/shift_x = 0
	/// Y coordinate offset to apply when loading from source map
	var/shift_y = 0
	/// Z coordinate offset to apply when loading from source map
	var/shift_z = 0
	/// The map name this shift applies FROM (source map)
	/// Leave empty to apply to all maps
	var/source_map = ""

/obj/effect/map_entity/campaign_pos_shift/Initialize()
	. = ..()
	// Register globally so campaign subsystem can find us
	var/key = lowertext(source_map)
	GLOB.campaign_pos_shifts[key] = src

/obj/effect/map_entity/campaign_pos_shift/Destroy()
	var/key = lowertext(source_map)
	if(GLOB.campaign_pos_shifts[key] == src)
		GLOB.campaign_pos_shifts -= key
	return ..()

/// Apply position shift to coordinates
/obj/effect/map_entity/campaign_pos_shift/proc/apply_shift(px, py, pz)
	return list(
		"x" = px + shift_x,
		"y" = py + shift_y,
		"z" = pz + shift_z
	)

/// Get the pos_shift entity for a given source map, or the wildcard one
/proc/get_campaign_pos_shift(source_map_name)
	if(!source_map_name)
		return null
	var/key = lowertext(source_map_name)
	// First try exact match
	if(GLOB.campaign_pos_shifts[key])
		return GLOB.campaign_pos_shifts[key]
	// Then try wildcard (empty source_map)
	if(GLOB.campaign_pos_shifts[""])
		return GLOB.campaign_pos_shifts[""]
	return null

/// Campaign Transition Map Entity
/// Triggers a map change within the campaign
/obj/effect/map_entity/campaign_transition
	name = "campaign_transition"
	desc = "Triggers a map change for the current campaign."
	icon_state = "landmark2"
	
	/// The name of the map to transition to
	var/destination_map = ""
	/// Whether to automatically reboot the world on transition
	var/auto_reboot = TRUE

/obj/effect/map_entity/campaign_transition/receive_input(input_name, atom/activator, atom/caller, list/params)
	if(..())
		return TRUE
	
	switch(lowertext(input_name))
		if("transition")
			trigger_transition()
			return TRUE
	return FALSE

/obj/effect/map_entity/campaign_transition/proc/trigger_transition()
	if(!destination_map)
		return
	
	// Set the next map
	if(SSmapping.changemap(destination_map))
		to_chat(world, span_boldannounce("Campaign transitioning to [destination_map]..."))
		if(auto_reboot)
			SSticker.standard_reboot()
	else
		debug_log("Failed to change map to [destination_map]")

