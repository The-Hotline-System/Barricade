/**
 * # Proximity Hint Component
 *
 * Automatically triggers a screen hint when a player comes into view/range of the parent atom.
 * Ends the hint when the player leaves view/range or picks up the item.
 */
/datum/component/proximity_hint
	dupe_mode = COMPONENT_DUPE_UNIQUE
	
	/// The text to display in the hint
	var/hint_text
	/// The image state to use (for atom_picture types)
	var/image_state
	/// Sound to play when hint appears
	var/hint_sound
	/// The alert type to use (must be a screen_text subtype)
	var/hint_type = /atom/movable/screen/text/screen_text/atom_picture
	/// Distance at which the hint triggers
	var/trigger_range = 5
	/// Distance at which the hint is removed
	var/removal_range = 8
	/// Whether the proximity hint is currently active and checking for distances
	var/enabled = TRUE
	/// Whether to require line-of-sight (view() check) for the hint to stay/trigger
	var/check_los = TRUE
	/// Whether to remove the component when the parent is picked up
	var/delete_on_pickup = TRUE
	/// Tracked hints: mob -> screen_text weakref
	var/list/active_hints
	/// Optional signal to listen for on parent to qdel this component
	var/cleanup_signal
	/// Optional IO input name to listen for on parent to qdel this component
	var/cleanup_input
	/// Multi-stage hint support - list of HINT_STAGE() definitions
	var/list/hint_stages
	/// Current stage index (1-based)
	var/current_stage = 1

/datum/component/proximity_hint/Initialize(text, type, trigger_range, removal_range, check_los, delete_on_pickup = TRUE, cleanup_signal, cleanup_input, image_state, hint_sound, stages, preset)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	
	// Apply preset defaults first
	if(preset)
		if(preset["trigger_range"])
			src.trigger_range = preset["trigger_range"]
		if(preset["removal_range"])
			src.removal_range = preset["removal_range"]
		if(!isnull(preset["check_los"]))
			src.check_los = preset["check_los"]
		if(!isnull(preset["delete_on_pickup"]))
			src.delete_on_pickup = preset["delete_on_pickup"]
	
	// Multi-stage support
	if(stages && length(stages))
		src.hint_stages = stages
		load_stage(1)
	else
		// Single-stage mode
		src.hint_text = text
		src.image_state = image_state
		src.hint_sound = hint_sound
	
	// Explicit parameters override preset
	if(!isnull(delete_on_pickup))
		src.delete_on_pickup = delete_on_pickup
	src.cleanup_signal = cleanup_signal
	src.cleanup_input = lowertext(cleanup_input)

	if(type)
		src.hint_type = type
	if(!isnull(trigger_range))
		src.trigger_range = trigger_range
	if(!isnull(removal_range))
		src.removal_range = removal_range
	if(!isnull(check_los))
		src.check_los = check_los

	if(cleanup_signal)
		RegisterSignal(parent, cleanup_signal, PROC_REF(on_cleanup_signal))
	if(cleanup_input)
		RegisterSignal(parent, COMSIG_MOVABLE_IO_RECEIVE, PROC_REF(on_io_receive))

	// Register existing mobs
	for(var/mob/M in GLOB.mob_list)
		RegisterSignal(M, COMSIG_MOVABLE_MOVED, PROC_REF(on_mob_moved))
		RegisterSignal(M.client, COMSIG_PARENT_QDELETING, PROC_REF(on_client_disconnect))
	
	// Register for new mobs
	RegisterSignal(SSatoms, COMSIG_GLOB_MOB_CREATED, PROC_REF(on_mob_created))

/// Load a specific stage's configuration
/datum/component/proximity_hint/proc/load_stage(stage_index)
	if(!hint_stages || stage_index < 1 || stage_index > length(hint_stages))
		return FALSE
		
	var/list/stage = hint_stages[stage_index]
	current_stage = stage_index
	hint_text = stage["text"]
	image_state = stage["image"]
	hint_sound = stage["sound"]
	return TRUE

/// Advance to the next stage
/datum/component/proximity_hint/proc/advance_stage()
	if(!hint_stages)
		return FALSE
		
	var/next_stage = current_stage + 1
	if(next_stage > length(hint_stages))
		return FALSE
		
	load_stage(next_stage)
	
	// Refresh all active hints with new stage
	if(active_hints)
		var/list/mobs_to_refresh = list()
		for(var/mob/M in active_hints)
			mobs_to_refresh += M
			
		for(var/mob/M in mobs_to_refresh)
			var/datum/weakref/W = active_hints[M]
			var/atom/movable/screen/text/screen_text/ST = W?.resolve()
			if(ST && !QDELETED(ST))
				ST.end_play()
			active_hints -= M
			check_mob_distance(M)
			
	return TRUE

/datum/component/proximity_hint/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ITEM_PICKUP, PROC_REF(on_pickup))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_parent_moved))

/datum/component/proximity_hint/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ITEM_PICKUP, COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_IO_RECEIVE))
	if(cleanup_signal)
		UnregisterSignal(parent, cleanup_signal)

/datum/component/proximity_hint/Destroy()
	cleanup_all_hints()
	return ..()

/// Clean up all active hints on all mobs
/datum/component/proximity_hint/proc/cleanup_all_hints()
	for(var/mob_key in active_hints)
		var/mob/M = mob_key
		var/datum/weakref/W = active_hints[M]
		var/atom/movable/screen/text/screen_text/ST = W?.resolve()
		if(ST && !QDELETED(ST))
			ST.end_play()
	active_hints = null

/datum/component/proximity_hint/proc/set_hint_text(new_text, new_image_state)
	if(!isnull(new_text))
		hint_text = new_text
	if(!isnull(new_image_state))
		image_state = new_image_state
	if(!active_hints)
		return
	
	// Create a copy of the keys since we'll be modifying the list (indirectly via ST.end_play or if we do it here)
	var/list/mobs_to_refresh = list()
	for(var/mob/M in active_hints)
		mobs_to_refresh += M
	
	for(var/mob/M in mobs_to_refresh)
		var/datum/weakref/W = active_hints[M]
		var/atom/movable/screen/text/screen_text/ST = W?.resolve()
		if(ST && !QDELETED(ST))
			ST.end_play()
		active_hints -= M
		
		// Re-trigger the hint creation
		check_mob_distance(M)

/datum/component/proximity_hint/proc/on_cleanup_signal()
	SIGNAL_HANDLER
	qdel(src)

/datum/component/proximity_hint/proc/on_io_receive(datum/source, input_name, activator, caller, list/params)
	SIGNAL_HANDLER
	var/lower_input = lowertext(input_name)
	if(lower_input == cleanup_input)
		qdel(src)
		return
	if(lower_input == "advancestage")
		advance_stage()
		return
	if(lower_input == "updatetext")
		if(params?["value"])
			set_hint_text(params["value"])
		return
	if(lower_input == "updateimage")
		var/new_image = params?["value"] || image_state
		set_hint_text(null, new_image)
		return

/datum/component/proximity_hint/proc/on_pickup(datum/source, mob/living/user)
	SIGNAL_HANDLER
	if(delete_on_pickup)
		qdel(src)

/datum/component/proximity_hint/proc/on_mob_created(datum/source, mob/M)
	SIGNAL_HANDLER
	RegisterSignal(M, COMSIG_MOVABLE_MOVED, PROC_REF(on_mob_moved))

/datum/component/proximity_hint/proc/on_mob_moved(mob/source)
	SIGNAL_HANDLER
	check_mob_distance(source)

/datum/component/proximity_hint/proc/on_client_disconnect(datum/source)
	SIGNAL_HANDLER
	if(!source)
		return
		
	var/client/C = source
	if(!C?.mob)
		return
		
	// Clean up hint for this mob
	var/mob/M = C.mob
	if(active_hints?[M])
		var/datum/weakref/W = active_hints[M]
		var/atom/movable/screen/text/screen_text/ST = W?.resolve()
		if(ST && !QDELETED(ST))
			ST.end_play()
		active_hints -= M
		if(!length(active_hints))
			active_hints = null

/datum/component/proximity_hint/proc/on_parent_moved()
	SIGNAL_HANDLER
	// Optimized: Only check mobs that already have this hint active
	if(active_hints)
		for(var/mob/M in active_hints)
			check_mob_distance(M)

/datum/component/proximity_hint/proc/check_mob_distance(mob/M)
	if(QDELETED(src) || !M || !M.client)
		return

	var/atom/A = parent
	var/turf/target_turf = get_turf(A)
	if(!target_turf)
		return

	var/datum/weakref/W = active_hints?[M]
	var/atom/movable/screen/text/screen_text/ST = W?.resolve()

	var/dist = get_dist(M, target_turf)
	var/is_held_by_owner = (A.loc == M)
	
	var/can_see = (target_turf.z == M.z) && (!check_los || (is_held_by_owner || (A in view(M))))
	
	// If it's a map entity, it's likely invisible (101). Check its turf instead.
	if(!can_see && check_los && istype(A, /obj/effect/map_entity))
		can_see = (target_turf.z == M.z) && (target_turf in view(M))

	if(ST && !QDELETED(ST))
		// Handle removal if they walk away, lose LOS, or component is disabled
		// (Don't remove if they are holding it even if "outside range" or "no LOS" in the traditional sense, 
		// though the check above handles is_held_by_owner)
		if(!enabled || (!is_held_by_owner && (dist > removal_range || !can_see)))
			SEND_SIGNAL(src, COMSIG_PROXIMITY_HINT_ENDED, M)
			ST.end_play()
			active_hints -= M
			if(!length(active_hints))
				active_hints = null
	else
		// Handle creation if they walk close, have LOS, and component is enabled
		if(enabled && (is_held_by_owner || (dist <= trigger_range && can_see)))
			var/atom/movable/screen/text/screen_text/new_hint = M.play_screen_text(hint_text, hint_type, A, image_state, hint_sound)
			if(new_hint)
				if(!active_hints)
					active_hints = list()
				active_hints[M] = WEAKREF(new_hint)
				SEND_SIGNAL(src, COMSIG_PROXIMITY_HINT_TRIGGERED, M)

/// Forcefully enable the hint system
/datum/component/proximity_hint/proc/enable()
	if(enabled)
		return
	enabled = TRUE
	// Re-check for everyone nearby immediately
	for(var/mob/M in GLOB.mob_list)
		check_mob_distance(M)

/// Forcefully disable the hint system and clear all active hints
/datum/component/proximity_hint/proc/disable()
	if(!enabled)
		return
	enabled = FALSE
	cleanup_all_hints()
