/mob/dead/observer/DblClickOn(atom/A, params)
	if(check_click_intercept(params, A))
		return

	if(can_reenter_corpse && mind?.current)
		if(A == mind.current || (mind.current in A)) // double click your corpse or whatever holds it
			reenter_corpse() // (body bag, closet, mech, etc)
			return // seems legit.

	// Things you might plausibly want to follow
	if(ismovable(A))
		ManualFollow(A)

	// Otherwise jump
	else if(A.loc)
		var/turf/target_turf = get_turf(A)
		if(target_turf)
			// Check for ghostclip before jumping (both destination and line of sight)
			if(!client?.holder)
				// O(1) check if destination has ghostclip
				if(target_turf.flags_2 & FLAG_GHOSTCLIP)
					to_chat(src, span_warning("You cannot jump to that location!"))
					return
				// Check if line of sight is blocked by ghostclip
				var/turf/source_turf = get_turf(src)
				if(ghostclip_blocks_los(source_turf, target_turf))
					to_chat(src, span_warning("You cannot jump through the barrier!"))
					return
			abstract_move(target_turf)

/mob/dead/observer/ClickOn(atom/A, params)
	if(check_click_intercept(params,A))
		return

	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, SHIFT_CLICK))
		if(LAZYACCESS(modifiers, MIDDLE_CLICK))
			ShiftMiddleClickOn(A)
			return
		if(LAZYACCESS(modifiers, CTRL_CLICK))
			CtrlShiftClickOn(A)
			return
		ShiftClickOn(A)
		return
	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		if(LAZYACCESS(modifiers, CTRL_CLICK))
			CtrlMiddleClickOn(A)
		else
			MiddleClickOn(A, params)
		return
	if(LAZYACCESS(modifiers, ALT_CLICK))
		AltClickNoInteract(src, A)
		return
	if(LAZYACCESS(modifiers, CTRL_CLICK))
		CtrlClickOn(A)
		return

	if(world.time <= next_move)
		return
	// You are responsible for checking config.ghost_interaction when you override this function
	// Not all of them require checking, see below
	A.attack_ghost(src)

// Oh by the way this didn't work with old click code which is why clicking shit didn't spam you
/atom/proc/attack_ghost(mob/dead/observer/user)
	if(SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_GHOST, user) & COMPONENT_CANCEL_ATTACK_CHAIN)
		return TRUE
	if(user.client)
		// Check if ghost can reach this atom (ghostclip blocking)
		if(!user.client.holder && !ghost_can_reach(user, src))
			to_chat(user, span_warning("You cannot reach that through the barrier!"))
			return TRUE

		if(user.gas_scan && atmos_scan(user=user, target=src, tool=null, silent=TRUE))
			return TRUE
		else if(isAdminGhostAI(user))
			attack_ai(user)
		else if(user.client.prefs.read_preference(/datum/preference/toggle/inquisitive_ghost) && !user.observetarget)
			user.examinate(src)
	return FALSE

/mob/living/attack_ghost(mob/dead/observer/user)
	if(user.client && user.health_scan)
		healthscan(user, src, TRUE)
	if(user.client && user.chem_scan)
		chemscan(user, src)
	return ..()

// ---------------------------------------
// And here are some good things for free:
// Now you can click through portals, wormholes, gateways, and teleporters while observing. -Sayu

/obj/effect/gateway_portal_bumper/attack_ghost(mob/user)
	if(gateway)
		gateway.Transfer(user)
	return ..()

/obj/machinery/teleport/hub/attack_ghost(mob/user)
	if(!power_station?.engaged || !power_station.teleporter_console || !power_station.teleporter_console.target_ref)
		return ..()

	var/atom/target = power_station.teleporter_console.target_ref.resolve()
	if(!target)
		power_station.teleporter_console.target_ref = null
		return ..()

	var/turf/target_turf = get_turf(target)
	if(target_turf)
		// Check for ghostclip before teleporting (both destination and line of sight)
		if(!user.client?.holder)
			// O(1) check if destination has ghostclip
			if(target_turf.flags_2 & FLAG_GHOSTCLIP)
				to_chat(user, span_warning("You cannot teleport to that location!"))
				return ..()
			// Check if line of sight is blocked by ghostclip
			var/turf/source_turf = get_turf(user)
			if(ghostclip_blocks_los(source_turf, target_turf))
				to_chat(user, span_warning("You cannot teleport through the barrier!"))
				return ..()
		user.abstract_move(target_turf)
