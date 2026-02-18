// Color Correction Map Entity
// Modes:
// 0: Global (applied to everyone)
// 1: Specific (applied to target via Apply input)
// 2: Brush (applied to mobs entering the brush)
// 3: Area (applied to mobs in a specific area)
//
// Performance Notes:
// - Global: O(n) on enable/disable where n = number of clients
// - Input: O(1) per application
// - Brush: O(1) per turf crossing, fires on every turf in brush
// - Area: O(1) per area crossing, uses area/Entered and area/Exited signals (most efficient for large zones)
// - Manual_brush: O(1) per manual trigger, no automatic application
//
// Area Mode Implementation:
// - Registers COMSIG_AREA_ENTERED and COMSIG_AREA_EXITED on the target area(s)
// - Area itself handles detection, no per-mob signal overhead
// - Significantly more performant than brush mode for large zones

/// Global list of all global color correction entities for fast lookup
GLOBAL_LIST_EMPTY(global_color_corrections)

/datum/client_colour/map_entity_color_correction
	priority = 100 // PRIORITY_NORMAL equivalent
	override = FALSE
	var/obj/effect/map_entity/color_correction/source_entity

/datum/client_colour/map_entity_color_correction/New(mob/_owner, obj/effect/map_entity/color_correction/_source)
	source_entity = _source
	if(source_entity)
		colour = source_entity.color_val
		priority = source_entity.priority
	return ..(_owner)

/datum/client_colour/map_entity_color_correction/Destroy()
	if(!QDELETED(owner) && source_entity)
		owner.client_colours -= src
		if(owner.client_colours_by_source)
			owner.client_colours_by_source -= source_entity
		if(fade_out)
			owner.animate_client_colour(fade_out)
		else
			owner.update_client_colour()
	owner = null
	source_entity = null
	return ..()

/obj/effect/map_entity/color_correction
	name = "color_correction"
	icon_state = "colorcorrect" // Requires icon
	is_brush = FALSE // Set to TRUE for brush modes

	/// Mode: "global", "input", "brush", "manual_brush", "area"
	var/mode = "global"
	var/color_val = "#be3434" // Hex color or "r,g,b,a" matrix string
	var/list/entities_inside = null

	var/transition_time = 0 // 0 = instant, >0 = animate time
	var/priority = 100 // Priority for the color correction (lower = higher priority)
	var/replaceglobal = FALSE // If TRUE, removes any global color corrections from other entities when applied

	/// For area mode: the area type or instance to apply color correction to
	var/area/target_area = null

/obj/effect/map_entity/color_correction/samplebrush
	is_brush = TRUE
	mode = "brush"
	color_val = "#af89c0"

/obj/effect/map_entity/color_correction/samplearea
	mode = "area"
	color_val = "#4a90e2"
	// target_area will be set to the area this entity is placed in
	// or can be set via SetArea input to a specific area type

/// Helper proc to calculate mixed color from a list of client_colours
/// Returns the final mixed color value
/obj/effect/map_entity/color_correction/proc/calculate_mixed_color(list/colour_list)
	if(!colour_list || !colour_list.len)
		return ""

	var/_our_colour
	var/_number_colours = 0
	var/_pool_closed = INFINITY

	for(var/_c in colour_list)
		var/datum/client_colour/_colour = _c
		if(_pool_closed < _colour.priority)
			break
		_number_colours++
		if(_colour.override)
			_pool_closed = _colour.priority
		if(!_our_colour)
			_our_colour = _colour.colour
			continue
		if(_number_colours == 2)
			_our_colour = color_to_full_rgba_matrix(_our_colour)
		var/list/_colour_matrix = color_to_full_rgba_matrix(_colour.colour)
		var/list/_L = _our_colour
		for(var/_i in 1 to 20)
			_L[_i] += _colour_matrix[_i]

	if(_number_colours > 1)
		var/list/_L = _our_colour
		for(var/_i in 1 to 20)
			_L[_i] /= _number_colours

	return _our_colour

/obj/effect/map_entity/color_correction/Initialize()
	. = ..()

	// Legacy integer mode mapping
	if(isnum(mode))
		switch(mode)
			if(0) mode = "global"
			if(1) mode = "input"
			if(2) mode = "brush"

	// Register global CCs for fast lookup
	if(mode == "global")
		GLOB.global_color_corrections += src

	// Area mode setup
	if(mode == "area")
		if(!target_area)
			// Default to the area this entity is in
			var/turf/T = get_turf(src)
			if(T)
				target_area = T.loc

		// Register Entered/Exited on the target area
		if(target_area && enabled)
			if(istype(target_area))
				// Instance - register directly
				RegisterSignal(target_area, list(COMSIG_AREA_ENTERED, COMSIG_AREA_EXITED), PROC_REF(on_area_crossed))
			else if(ispath(target_area, /area))
				// Type path - register on all instances of this type
				for(var/area/A in world)
					if(istype(A, target_area))
						RegisterSignal(A, list(COMSIG_AREA_ENTERED, COMSIG_AREA_EXITED), PROC_REF(on_area_crossed))

	if(mode == "brush" || mode == "manual_brush")
		is_brush = TRUE
		var/static/list/loc_connections = list(
			COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
			COMSIG_ATOM_EXITED = PROC_REF(on_exited),
		)
		AddElement(/datum/element/connect_loc, loc_connections)
		if(mode == "brush")
			spawn(1)
				connect_brush_neighbors() // Ensure base handles this, but calling ensures linkage if we just set is_brush

	// Parse color_val if it's a matrix string
	if(istext(color_val))
		if(findtext(color_val, "#"))
			// Hex color, no parsing needed
		else
			var/clean_val = color_val
			// Basic cleanup for DM list formatting
			clean_val = replacetext(clean_val, "list(", "")
			clean_val = replacetext(clean_val, ")", "")
			clean_val = replacetext(clean_val, "\\", "")
			clean_val = replacetext(clean_val, "'", "")
			clean_val = replacetext(clean_val, "\n", "")
			clean_val = replacetext(clean_val, " ", "") // Remove spaces for cleaner splitting if needed

			// Allow for either ; or , as delimiters, or mixed
			clean_val = replacetext(clean_val, ",", ";")

			if(findtext(clean_val, ";"))
				var/list/split_colors = splittext(clean_val, ";")
				var/list/matrix_list = list()
				for(var/val in split_colors)
					var/num_val = text2num(val)
					if(!isnull(num_val))
						matrix_list += num_val

				if(matrix_list.len == 20 || matrix_list.len == 16)
					color_val = matrix_list

	if(mode == "global" && enabled)
		apply_global()

/obj/effect/map_entity/color_correction/Destroy()
	if(mode == "global")
		GLOB.global_color_corrections -= src
		if(enabled)
			remove_global()
	else if(mode == "area")
		// Unregister from areas
		if(istype(target_area))
			UnregisterSignal(target_area, list(COMSIG_AREA_ENTERED, COMSIG_AREA_EXITED))
		else if(ispath(target_area, /area))
			for(var/area/A in world)
				if(istype(A, target_area))
					UnregisterSignal(A, list(COMSIG_AREA_ENTERED, COMSIG_AREA_EXITED))
		// Remove from all mobs currently in the area
		for(var/mob/M in GLOB.mob_list)
			if(is_mob_in_target_area(M))
				remove_from(M)
	else if(enabled)
		if(LAZYLEN(entities_inside))
			for(var/mob/M in entities_inside)
				remove_from(M)
	return ..()

/*
Inputs:
Enable - Enables and applies (if global or area)
Disable - Disables and removes (if global or area)
Apply - Applies color. (Input mode: to activator. Manual_brush mode: into brush. Area mode: to all in area)
Remove - Removes color. (Input mode: from activator. Manual_brush mode: from brush. Area mode: from all in area)
SetTime - Sets transition time (param: value)
SetArea - Sets target area (param: area type path or area instance)
SetMode - Changes the mode at runtime (param: "global", "input", "brush", "manual_brush", or "area")
*/
/obj/effect/map_entity/color_correction/receive_input(input_name, atom/activator, atom/caller, list/params)
	. = ..()
	if(.)
		return TRUE

	switch(lowertext(input_name))
		if("enable")
			enabled = TRUE
			if(mode == "global")
				apply_global()
			else if(mode == "area")
				apply_area()
			fire_output("OnEnable", activator, caller)
			return TRUE
		if("disable")
			enabled = FALSE
			if(mode == "global")
				remove_global()
			else if(mode == "area")
				remove_area()
			fire_output("OnDisable", activator, caller)
			return TRUE
		if("apply")
			if(mode == "input" && ishuman(activator))
				apply_to(activator)
			else if(mode == "manual_brush")
				apply_brush_manual()
			else if(mode == "global")
				// Allow manual global application
				apply_global()
			else if(mode == "area")
				apply_area()
			return TRUE
		if("remove")
			if(mode == "input" && ishuman(activator))
				remove_from(activator)
			else if(mode == "manual_brush")
				remove_brush_manual()
			else if(mode == "global")
				// Allow manual global removal
				remove_global()
			else if(mode == "area")
				remove_area()
			return TRUE
		if("settime")
			transition_time = text2num(params["value"])
			return TRUE
		if("setarea")
			if(mode == "area")
				var/area_path = text2path(params["value"])
				if(ispath(area_path, /area))
					target_area = area_path
				else if(isarea(params["value"]))
					target_area = params["value"]
				// Re-register signals if enabled
				if(enabled)
					remove_area()
					apply_area()
			return TRUE
		if("setmode")
			var/new_mode = params["value"]
			if(new_mode in list("global", "input", "brush", "manual_brush", "area"))
				set_mode(new_mode)
			return TRUE
	return FALSE

/obj/effect/map_entity/color_correction/proc/on_entered(datum/source, atom/movable/AM, oldloc)
	SIGNAL_HANDLER
	if(!enabled)
		return
	if(mode != "brush" && mode != "manual_brush")
		return
	if(!isliving(AM))
		return

	var/mob/living/M = AM
	if(!M.client)
		return

	// Check if already tracked by this entity
	if(LAZYLEN(entities_inside) && (M in entities_inside))
		return

	// Check if moving from a connected brush neighbor
	if(brush_neighbors)
		for(var/obj/effect/map_entity/color_correction/E in brush_neighbors)
			if(LAZYLEN(E.entities_inside) && (M in E.entities_inside))
				// Transfer tracking from neighbor to this entity
				LAZYREMOVE(E.entities_inside, M)
				LAZYADD(entities_inside, M)

				// If the neighbor has different color/priority, smoothly transition
				if(mode == "brush" && E.mode == "brush")
					if(E.color_val != color_val || E.priority != priority)
						// Remove old, apply new with transition
						E.remove_from(M)
						apply_to(M)
				return

	LAZYADD(entities_inside, M)

	if(mode == "brush")
		apply_to(M)

/obj/effect/map_entity/color_correction/proc/on_exited(datum/source, atom/movable/AM, direction)
	SIGNAL_HANDLER
	if(mode != "brush" && mode != "manual_brush")
		return
	if(!isliving(AM))
		return

	var/mob/living/M = AM
	if(!LAZYLEN(entities_inside) || !(M in entities_inside))
		return

	// Check if moving to a connected brush neighbor
	var/turf/T = M.loc
	if(T && brush_neighbors)
		for(var/obj/effect/map_entity/color_correction/E in brush_neighbors)
			if(E.loc == T)
				// Moving to a connected brush, don't remove yet
				return

	LAZYREMOVE(entities_inside, M)

	// Only auto-remove in brush mode, not manual_brush mode
	if(mode == "brush")
		remove_from(M)

/obj/effect/map_entity/color_correction/proc/apply_brush_manual()
	if(!LAZYLEN(entities_inside))
		return
	for(var/mob/M in entities_inside)
		apply_to(M)

/obj/effect/map_entity/color_correction/proc/remove_brush_manual()
	if(!LAZYLEN(entities_inside))
		return
	for(var/mob/M in entities_inside)
		remove_from(M)


/obj/effect/map_entity/color_correction/proc/apply_global()
	for(var/client/C in GLOB.clients)
		if(C.mob)
			apply_to(C.mob, skip_global_check = TRUE)

/obj/effect/map_entity/color_correction/proc/remove_global()
	for(var/client/C in GLOB.clients)
		if(C.mob)
			remove_from(C.mob)

/obj/effect/map_entity/color_correction/proc/apply_to(mob/M, skip_global_check = FALSE)
	if(!M.client)
		return

	// If this is a replaceglobal brush, cancel any pending global restorations
	if(replaceglobal)
		if(M.pending_global_cc_restore_timer)
			deltimer(M.pending_global_cc_restore_timer)
			M.pending_global_cc_restore_timer = null

		// Clean up any stale suppressed globals that are no longer valid
		if(LAZYLEN(M.suppressed_global_ccs))
			for(var/datum/client_colour/map_entity_color_correction/suppressed in M.suppressed_global_ccs)
				if(QDELETED(suppressed) || !suppressed.source_entity || !suppressed.source_entity.enabled)
					M.suppressed_global_ccs -= suppressed
					if(!QDELETED(suppressed))
						qdel(suppressed)

	// Check if already applied to this mob using O(1) associative lookup
	if(!M.client_colours_by_source)
		M.client_colours_by_source = list()

	var/datum/client_colour/map_entity_color_correction/existing_cc = M.client_colours_by_source[src]

	if(existing_cc)
		// Already applied, update it instead
		if(existing_cc.colour != color_val || existing_cc.priority != priority)
			existing_cc.colour = color_val
			existing_cc.priority = priority
			// Re-sort the list since priority may have changed
			M.client_colours -= existing_cc
			BINARY_INSERT(existing_cc, M.client_colours, /datum/client_colour, existing_cc, priority, COMPARE_KEY)
			if(transition_time > 0)
				M.animate_client_colour(transition_time)
			else
				M.update_client_colour()
		return

	// Create a new client_colour datum for this color correction
	var/datum/client_colour/map_entity_color_correction/CC = new(M, src)

	// Calculate what the final color will be after this CC is added
	if(transition_time > 0)
		// Temporarily add to list to calculate target color
		if(!M.client_colours)
			M.client_colours = list()
		BINARY_INSERT(CC, M.client_colours, /datum/client_colour, CC, priority, COMPARE_KEY)
		M.client_colours_by_source[src] = CC

		// If replaceglobal, immediately suppress global colors (don't wait for transition)
		// This prevents both global and replaceglobal from being active simultaneously
		if(replaceglobal)
			// Immediately move globals to suppressed list
			remove_global_colors(M)

		// Calculate the target color (what it will be with this CC, without globals)
		var/target_color = calculate_mixed_color(M.client_colours)

		// Animate to the target color
		animate(M.client, color = target_color, time = transition_time)
	else
		// No transition, add to list first
		if(!M.client_colours)
			M.client_colours = list()
		BINARY_INSERT(CC, M.client_colours, /datum/client_colour, CC, priority, COMPARE_KEY)
		M.client_colours_by_source[src] = CC

		// Remove global colors immediately if replaceglobal
		if(replaceglobal)
			remove_global_colors(M)

		// Update client color immediately (no animation)
		M.update_client_colour()

	fire_output("OnApply", M, src)

/obj/effect/map_entity/color_correction/proc/remove_global_colors(mob/M)
	if(!M || !M.client)
		return

	// Instead of deleting global CCs, move them to a suppressed list
	// This allows them to be restored later even if quickly entering/exiting
	for(var/datum/client_colour/map_entity_color_correction/existing in M.client_colours)
		if(existing.source_entity != src && existing.source_entity.mode == "global")
			M.client_colours -= existing
			if(M.client_colours_by_source)
				M.client_colours_by_source -= existing.source_entity

			// Check if not already in suppressed list to prevent duplicates
			var/already_suppressed = FALSE
			if(LAZYLEN(M.suppressed_global_ccs))
				for(var/datum/client_colour/map_entity_color_correction/suppressed in M.suppressed_global_ccs)
					if(suppressed.source_entity == existing.source_entity)
						already_suppressed = TRUE
						// Delete the duplicate since we already have one suppressed
						qdel(existing)
						break
			if(!already_suppressed)
				LAZYADD(M.suppressed_global_ccs, existing)

/obj/effect/map_entity/color_correction/proc/remove_from(mob/M)
	if(!M.client)
		return

	// Use O(1) associative lookup
	var/datum/client_colour/map_entity_color_correction/CC = M.client_colours_by_source?[src]
	if(!CC)
		return

	// Calculate what the final color will be after this CC is removed
	// We need to do this BEFORE animating so the animation has the correct target
	if(transition_time > 0)
		// Temporarily remove from client_colours list to calculate target color
		// But keep it in client_colours_by_source until actual deletion
		M.client_colours -= CC

		// If this had replaceglobal enabled, restore suppressed globals for calculation
		var/list/restored_for_calc = list()
		if(replaceglobal && LAZYLEN(M.suppressed_global_ccs))
			for(var/datum/client_colour/map_entity_color_correction/suppressed in M.suppressed_global_ccs)
				if(!QDELETED(suppressed) && suppressed.source_entity && suppressed.source_entity.enabled)
					// Temporarily add back to list for calculation
					BINARY_INSERT(suppressed, M.client_colours, /datum/client_colour, suppressed, priority, COMPARE_KEY)
					restored_for_calc += suppressed

		// Calculate the target color (what it will be without this CC, but with globals)
		var/target_color = calculate_mixed_color(M.client_colours)

		// Remove the temporarily restored globals from the list (but keep them in suppressed list)
		for(var/datum/client_colour/map_entity_color_correction/restored in restored_for_calc)
			M.client_colours -= restored

		// Animate to the target color
		animate(M.client, color = target_color, time = transition_time)

		// Delete the datum after the transition completes
		// This will also remove from client_colours_by_source via delayed_removal
		addtimer(CALLBACK(src, PROC_REF(delayed_removal), M, CC), transition_time)

		// If we had replaceglobal, restore globals after animation
		if(replaceglobal)
			var/timer_id = addtimer(CALLBACK(src, PROC_REF(restore_global_colors), M, null, TRUE), transition_time)
			M.pending_global_cc_restore_timer = timer_id
	else
		// No transition - remove from list first
		M.client_colours -= CC
		if(M.client_colours_by_source)
			M.client_colours_by_source -= src

		// Restore global colors immediately if replaceglobal (before deleting CC)
		if(replaceglobal)
			restore_global_colors(M, null, FALSE)

		// Delete the CC datum
		qdel(CC)

		// Update client color immediately (no animation)
		M.update_client_colour()

	fire_output("OnRemove", M, src)

/obj/effect/map_entity/color_correction/proc/restore_global_colors(mob/M, list/unused_param, skip_update = TRUE)
	if(!M || !M.client)
		return

	// Clear the pending timer reference
	M.pending_global_cc_restore_timer = null

	// Check if the mob is currently in ANY replaceglobal brush
	// If so, don't restore globals - the brush is handling it
	for(var/datum/client_colour/map_entity_color_correction/check_cc in M.client_colours)
		if(check_cc.source_entity.replaceglobal && check_cc.source_entity != src)
			// Mob is in a replaceglobal brush, abort restoration
			return

	// Restore suppressed global CCs first (these were removed by replaceglobal)
	var/restored_any = FALSE
	if(LAZYLEN(M.suppressed_global_ccs))
		// Initialize lists if needed
		if(!M.client_colours)
			M.client_colours = list()
		if(!M.client_colours_by_source)
			M.client_colours_by_source = list()

		for(var/datum/client_colour/map_entity_color_correction/suppressed_cc in M.suppressed_global_ccs)
			// Check if it's still valid and should be applied
			if(!QDELETED(suppressed_cc) && suppressed_cc.source_entity && suppressed_cc.source_entity.mode == "global" && suppressed_cc.source_entity.enabled)
				// Check if not already in the list using O(1) lookup
				if(!M.client_colours_by_source[suppressed_cc.source_entity])
					// Restore to active list
					BINARY_INSERT(suppressed_cc, M.client_colours, /datum/client_colour, suppressed_cc, priority, COMPARE_KEY)
					M.client_colours_by_source[suppressed_cc.source_entity] = suppressed_cc
					restored_any = TRUE
					suppressed_cc.source_entity.fire_output("OnApply", M, suppressed_cc.source_entity)
				else
					// Already exists, delete the suppressed duplicate
					qdel(suppressed_cc)
			else
				// Invalid or disabled, clean it up
				if(!QDELETED(suppressed_cc))
					qdel(suppressed_cc)
		// Clear the suppressed list
		M.suppressed_global_ccs = null

	// Also check for any new global CCs that weren't suppressed (use cached list)
	if(LAZYLEN(GLOB.global_color_corrections))
		// Initialize lists if needed
		if(!M.client_colours)
			M.client_colours = list()
		if(!M.client_colours_by_source)
			M.client_colours_by_source = list()

		for(var/obj/effect/map_entity/color_correction/global_cc in GLOB.global_color_corrections)
			if(global_cc != src && global_cc.enabled)
				// Check if this mob should have this global CC using O(1) lookup
				if(!M.client_colours_by_source[global_cc])
					// Create and add the CC datum directly
					var/datum/client_colour/map_entity_color_correction/CC = new(M, global_cc)
					BINARY_INSERT(CC, M.client_colours, /datum/client_colour, CC, priority, COMPARE_KEY)
					M.client_colours_by_source[global_cc] = CC
					restored_any = TRUE
					global_cc.fire_output("OnApply", M, global_cc)

	// If we restored any globals and skip_update is FALSE, update the client color
	if(restored_any && !skip_update)
		M.update_client_colour()

/obj/effect/map_entity/color_correction/proc/delayed_removal(mob/M, datum/client_colour/map_entity_color_correction/CC)
	if(QDELETED(CC) || QDELETED(M))
		return
	if(M.client_colours_by_source && CC.source_entity)
		M.client_colours_by_source -= CC.source_entity
	qdel(CC)

// ============================================
// AREA MODE PROCS
// ============================================

/// Apply color correction to all mobs in the target area
/obj/effect/map_entity/color_correction/proc/apply_area()
	if(!target_area)
		return

	// Register Entered/Exited signals on the area(s)
	if(istype(target_area))
		// Instance - register directly
		RegisterSignal(target_area, list(COMSIG_AREA_ENTERED, COMSIG_AREA_EXITED), PROC_REF(on_area_crossed))
	else if(ispath(target_area, /area))
		// Type path - register on all instances of this type
		for(var/area/A in world)
			if(istype(A, target_area))
				RegisterSignal(A, list(COMSIG_AREA_ENTERED, COMSIG_AREA_EXITED), PROC_REF(on_area_crossed))

	// Apply to all existing mobs in the area
	for(var/mob/M in GLOB.mob_list)
		if(is_mob_in_target_area(M))
			apply_to(M)

/// Remove color correction from all mobs in the target area
/obj/effect/map_entity/color_correction/proc/remove_area()
	if(!target_area)
		return

	// Unregister signals from the area(s)
	if(istype(target_area))
		UnregisterSignal(target_area, list(COMSIG_AREA_ENTERED, COMSIG_AREA_EXITED))
	else if(ispath(target_area, /area))
		for(var/area/A in world)
			if(istype(A, target_area))
				UnregisterSignal(A, list(COMSIG_AREA_ENTERED, COMSIG_AREA_EXITED))

	// Remove from all mobs currently in the area
	for(var/mob/M in GLOB.mob_list)
		if(is_mob_in_target_area(M))
			remove_from(M)

/// Check if a mob is in the target area
/obj/effect/map_entity/color_correction/proc/is_mob_in_target_area(mob/M)
	if(!M || !target_area)
		return FALSE

	var/turf/T = get_turf(M)
	if(!T)
		return FALSE

	// Handle both area instances and area types
	if(istype(target_area))
		return T.loc == target_area
	else if(ispath(target_area))
		return istype(T.loc, target_area)

	return FALSE

/// Handle when a mob enters or exits the target area
/obj/effect/map_entity/color_correction/proc/on_area_crossed(area/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(!enabled || mode != "area")
		return

	if(!isliving(AM))
		return

	var/mob/living/M = AM
	if(!M.client)
		return

	// Check if the mob is now in the target area
	if(is_mob_in_target_area(M))
		// Entered the area
		apply_to(M)
	else
		// Exited the area
		remove_from(M)


// ============================================
// DEVELOPER PROCS
// ============================================

/// Change the mode of this color correction at runtime
/// Properly cleans up old mode and sets up new mode
/obj/effect/map_entity/color_correction/proc/set_mode(new_mode)
	if(mode == new_mode)
		return // Already in this mode

	var/was_enabled = enabled
	var/old_mode = mode

	// Disable and clean up old mode
	if(was_enabled)
		enabled = FALSE
		switch(old_mode)
			if("global")
				remove_global()
				GLOB.global_color_corrections -= src
			if("area")
				remove_area()
			if("brush", "manual_brush")
				// Remove from all entities inside
				if(LAZYLEN(entities_inside))
					for(var/mob/M in entities_inside)
						remove_from(M)
					entities_inside = null
				// Remove connect_loc element
				RemoveElement(/datum/element/connect_loc)

	// Always clear is_brush when changing modes, will be set again if needed
	is_brush = FALSE

	// Set new mode
	mode = new_mode

	// Set up new mode
	switch(new_mode)
		if("global")
			GLOB.global_color_corrections += src
		if("area")
			if(!target_area)
				var/turf/T = get_turf(src)
				if(T)
					target_area = T.loc
		if("brush", "manual_brush")
			is_brush = TRUE
			var/static/list/loc_connections = list(
				COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
				COMSIG_ATOM_EXITED = PROC_REF(on_exited),
			)
			AddElement(/datum/element/connect_loc, loc_connections)
			if(new_mode == "brush")
				spawn(1)
					connect_brush_neighbors()
		if("input")
			// Input mode doesn't need special setup, but ensure is_brush is false
			is_brush = FALSE

	// Re-enable if it was enabled before
	if(was_enabled)
		enabled = TRUE
		switch(new_mode)
			if("global")
				apply_global()
			if("area")
				apply_area()

	return TRUE

/// Developer verb to change mode at runtime
/obj/effect/map_entity/color_correction/verb/dev_change_mode()
	set name = "Change Color Correction Mode"
	set category = "Debug"
	set src in view(7)

	if(!check_rights(R_DEBUG))
		return

	var/list/mode_options = list("global", "input", "brush", "manual_brush", "area")
	var/new_mode = input(usr, "Select new mode for this color correction:", "Change Mode", mode) as null|anything in mode_options

	if(!new_mode)
		return

	if(new_mode == mode)
		to_chat(usr, span_notice("Already in [mode] mode."))
		return

	// Special handling for area mode
	if(new_mode == "area" && !target_area)
		var/area_choice = input(usr, "Select target area (or leave blank to use current area):", "Target Area") as null|anything in typesof(/area)
		if(area_choice)
			target_area = area_choice

	var/old_mode = mode
	if(set_mode(new_mode))
		to_chat(usr, span_notice("Changed color correction mode from [old_mode] to [new_mode]."))
		log_admin("[key_name(usr)] changed color correction [src] at [AREACOORD(src)] from [old_mode] to [new_mode] mode.")
		message_admins("[key_name_admin(usr)] changed color correction [src] at [AREACOORD(src)] from [old_mode] to [new_mode] mode.")
	else
		to_chat(usr, span_warning("Failed to change mode."))

/// Developer verb to view current settings
/obj/effect/map_entity/color_correction/verb/dev_view_settings()
	set name = "View Color Correction Settings"
	set category = "Debug"
	set src in view(7)

	if(!check_rights(R_DEBUG))
		return

	var/list/info = list()
	info += "=== Color Correction Settings ==="
	info += "Mode: [mode]"
	info += "Enabled: [enabled ? "Yes" : "No"]"
	info += "Color: [color_val]"
	info += "Transition Time: [transition_time]"
	info += "Priority: [priority]"
	info += "Replace Global: [replaceglobal ? "Yes" : "No"]"

	if(mode == "area")
		info += "Target Area: [target_area ? target_area : "None"]"

	if(mode == "brush" || mode == "manual_brush")
		info += "Entities Inside: [LAZYLEN(entities_inside)]"
		if(brush_neighbors)
			info += "Brush Neighbors: [brush_neighbors.len]"

	if(mode == "global")
		var/count = 0
		for(var/client/C in GLOB.clients)
			if(C.mob && C.mob.client_colours_by_source?[src])
				count++
		info += "Applied to: [count] clients"

	to_chat(usr, span_notice(jointext(info, "\n")))

/// Developer verb to test mode switching and verify is_brush state
/obj/effect/map_entity/color_correction/verb/dev_test_mode_switching()
	set name = "Test Mode Switching"
	set category = "Debug"
	set src in view(7)

	if(!check_rights(R_DEBUG))
		return

	to_chat(usr, span_notice("=== Testing Mode Switching ==="))
	to_chat(usr, span_notice("Initial state: mode=[mode], is_brush=[is_brush]"))

	var/list/test_modes = list("global", "input", "brush", "manual_brush", "area")
	var/list/expected_brush_states = list(
		"global" = FALSE,
		"input" = FALSE,
		"brush" = TRUE,
		"manual_brush" = TRUE,
		"area" = FALSE
	)

	for(var/test_mode in test_modes)
		set_mode(test_mode)
		var/expected = expected_brush_states[test_mode]
		var/actual = is_brush
		var/status = (expected == actual) ? "PASS" : "FAIL"
		var/color = (expected == actual) ? "green" : "red"
		to_chat(usr, "<span style='color:[color]'>[status]: mode=[test_mode], is_brush=[actual] (expected [expected])</span>")

	to_chat(usr, span_notice("=== Test Complete ==="))
