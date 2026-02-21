/**
 * # Grab Intent
 *
 * Intent for grabbing and restraining others
 */
/datum/intent/grab
	name = "Grab"
	desc = "Grab and restrain others"
	icon_state = "grab"
	grab_strength_modifier = 1

/datum/intent/grab/on_close_range_interact(mob/living/user, atom/target, list/modifiers)
	if(!isliving(target))
		return FALSE

	var/mob/living/living_target = target

	// Try to initiate a grab
	if(user.try_make_grab(living_target))
		return TRUE

	return FALSE

/datum/intent/grab/get_screentip_text(mob/living/user, atom/target)
	if(isliving(target))
		return "Grab"
	return null
