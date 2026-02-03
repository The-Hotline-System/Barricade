/proc/ghostclip_blocks_los(turf/source, turf/target)
	if(!source || !target)
		return FALSE

	var/list/line_turfs = get_line(source, target)
	for(var/turf/T in line_turfs)
		// Skip the source turf since the ghost is already there
		if(T == source)
			continue
		// O(1) check using turf flag instead of iterating objects
		if(T.flags_2 & FLAG_GHOSTCLIP)
			return TRUE
	return FALSE

/proc/ghost_can_reach(mob/dead/observer/G, atom/target)
	if(!G || !target)
		return FALSE

	if(G.client?.holder)
		return TRUE

	var/turf/ghost_turf = get_turf(G)
	var/turf/target_turf = get_turf(target)

	if(!ghost_turf || !target_turf)
		return FALSE

	// O(1) check using turf flag
	if(target_turf.flags_2 & FLAG_GHOSTCLIP)
		return FALSE

	if(ghostclip_blocks_los(ghost_turf, target_turf))
		return FALSE

	return TRUE
