/obj/effect/map_entity/clip
	name = "clip"
	icon_state = "playerclip"
	is_brush = TRUE
	density = FALSE
	alpha = 0

/*
Inputs:
Toggle - Toggles the enabled state
Allow - Enables the entity (allows passage if logic inversed, but usually enables the clip)
Disallow - Disables the entity
*/
/obj/effect/map_entity/clip/receive_input(input_name, atom/activator, atom/caller, list/params)
	. = ..()
	if(.)
		return TRUE
	switch(lowertext(input_name))
		if("toggle")
			enabled = !enabled
			return TRUE
		if("allow")
			enabled = TRUE
			return TRUE
		if("disallow")
			enabled = FALSE
			return TRUE
	return FALSE

/obj/effect/map_entity/clip/ghost
	name = "ghost_clip"
	icon_state = "ghostclip"
	flags_2 = FLAG_GHOSTCLIP

/obj/effect/map_entity/clip/bullet
	name = "bullet_clip"
	icon_state = "block_bullets"
	density = FALSE

/obj/effect/map_entity/clip/bullet/CanAllowThrough(atom/movable/mover, border_dir)
	if(!enabled)
		return ..()
	if(istype(mover, /obj/projectile))
		return FALSE
	else
		return ..()

/obj/effect/map_entity/clip/bullet/bullet_act(obj/projectile/P, def_zone)
	if(!enabled)
		return
	P.on_hit(src, 100)
	return 0

/obj/effect/map_entity/clip/player
	name = "player_clip"
	icon_state = "playerclip"
	density = FALSE

/obj/effect/map_entity/clip/player/CanAllowThrough(atom/movable/mover, border_dir)
	if(!enabled)
		return ..()
	if(istype(mover, /obj/projectile) || istype(mover, /obj/item))
		return ..()
	if(ismob(mover))
		return FALSE

/obj/effect/map_entity/clip/npc
	name = "npc_clip"
	icon_state = "playerclip"
	density = FALSE

/obj/effect/map_entity/clip/npc/CanAllowThrough(atom/movable/mover, border_dir)
	if(!enabled)
		return ..()
	if(istype(mover, /obj/projectile))
		return ..()
	if(ishuman(mover))
		var/mob/living/carbon/human/H = mover
		if(H.client)
			return ..()
	if(istype(mover, /mob/living/simple_animal))
		return FALSE

/*
/obj/effect/map_entity/clip/faction
	name = "faction_clip"
	icon_state = "noteam"
	density = TRUE
	var/blocked_faction = null

/obj/effect/map_entity/clip/faction/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group || !height || !enabled)
		return TRUE
	if(istype(mover, /obj/projectile))
		return TRUE
	if(ismob(mover))
		var/mob/M = mover
		if(blocked_faction && M.warfare_faction == blocked_faction)
			return FALSE
	return TRUE
*/
/*
/obj/effect/map_entity/clip/faction/red
	name = "red_clip"
	icon_state = "red"
	blocked_faction = RED_TEAM

/obj/effect/map_entity/clip/faction/blue
	name = "blue_clip"
	icon_state = "blue"
	blocked_faction = BLUE_TEAM

/obj/effect/map_entity/clip/faction/toggle
	name = "red"
	blocked_faction = RED_TEAM
*/
/*
Inputs:
Toggle - Toggles blocked faction between RED and BLUE
*/
/*
/obj/effect/map_entity/clip/faction/toggle/receive_input(input_name, atom/activator, atom/caller, list/params)
	. = ..()
	if(.)
		return TRUE

	switch(lowertext(input_name))
		if("toggle")
			if(blocked_faction == RED_TEAM)
				blocked_faction = BLUE_TEAM
			else
				blocked_faction = RED_TEAM
			return TRUE
	return FALSE

/obj/effect/map_entity/clip/faction/toggle/blue
	name = "blue"
	blocked_faction = BLUE_TEAM
*/
/obj/effect/map_entity/clip/oneway
	name = "noteam"
	icon_state = "oneway"
	density = FALSE
	var/inverse = FALSE
	var/cull_backside = FALSE

/obj/effect/map_entity/clip/oneway/CanAllowThrough(atom/movable/mover, border_dir)
	if(!enabled)
		return TRUE
	if(istype(mover, /obj/projectile))
		return TRUE
	var/move_dir = get_dir(mover, src)
	if(inverse)
		if(move_dir & turn(dir, 180))
			return FALSE
	else
		if(!(move_dir & dir))
			return FALSE
	return ..()

/obj/effect/map_entity/clip/oneway/CheckExit(atom/movable/mover, turf/target)
	if(!enabled || !cull_backside)
		return TRUE

	if(target)
		var/move_dir = get_dir(src, target)
		if(move_dir & dir)
			if(ismob(mover) && !istype(mover, /mob/living/simple_animal))
				return FALSE

	return ..()

/obj/effect/map_entity/clip/oneway/inverse
	icon_state = "oneway_thin"
	inverse = TRUE
	cull_backside = TRUE
