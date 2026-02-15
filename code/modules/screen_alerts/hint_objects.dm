/**
 * # Hint Screwdriver
 *
 * A screwdriver that triggers a proximity hint to teach players how to use it.
 */
/obj/item/screwdriver/hint

/obj/item/screwdriver/hint/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/proximity_hint, "This is a screwdriver.\nUse it to screw and unscrew things!", /atom/movable/screen/text/screen_text/atom_picture, 7, 8, TRUE)

/obj/item/screwdriver/hint_pickup
	name = "screwdriver"

/obj/item/screwdriver/hint_pickup/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/proximity_hint, \
		stages = list(
			HINT_STAGE("This screwdriver is vital for repairs.\nPick it up to proceed!", "pickup_small", 'sound/effects/beepclear.ogg'),
			HINT_STAGE("Great! Now you can use it to maintain equipment or open panels.", "hint_small", 'sound/effects/beepclear.ogg')
		), \
		delete_on_pickup = FALSE)
	RegisterSignal(src, COMSIG_ITEM_PICKUP, PROC_REF(on_pickup))

/obj/item/screwdriver/hint_pickup/proc/on_pickup(datum/source, mob/living/user)
	SIGNAL_HANDLER
	var/datum/component/proximity_hint/hint_comp = GetComponent(/datum/component/proximity_hint)
	if(hint_comp)
		hint_comp.advance_stage()

/**
 * # Tutorial Job Closet
 *
 * A specialized closet that shows a hint when players are nearby.
 */
/obj/structure/closet/tutorial
	name = "job equipment locker"

/obj/structure/closet/tutorial/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/proximity_hint, \
		"Your job equipment is inside this locker.", \
		"info_small", \
		preset = HINT_PRESET_TUTORIAL)

/**
 * # Tutorial Fabricator
 *
 * A fabricator that guides the player to print a screwdriver and adds a dynamic hint to it.
 */
/obj/machinery/rnd/production/fabricator/tutorial
	name = "tutorial fabricator"

/obj/machinery/rnd/production/fabricator/tutorial/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/proximity_hint, \
		"Use this to print tools and equipment.\nTry printing a screwdriver.", \
		preset = HINT_PRESET_TUTORIAL)

/obj/machinery/rnd/production/fabricator/tutorial/do_print(datum/design/D, amount)
	. = ..()
	
	// Remove our tutorial hint since objective is met
	
	// Add hints to any screwdrivers that were just printed and don't have one yet
	var/turf/T = get_turf(src)
	for(var/obj/item/screwdriver/S in T)
		if(S.GetComponent(/datum/component/proximity_hint))
			continue
		S.AddComponent(/datum/component/proximity_hint, \
			"Screwdrivers are your first step to hacking shit.\nThey're also good eye-stabbers.", \
			preset = HINT_PRESET_PICKUP)
		var/datum/component/proximity_hint/H = GetComponent(/datum/component/proximity_hint)
		if(H)
			qdel(H)
		break