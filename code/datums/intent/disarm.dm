/**
 * # Disarm Intent
 *
 * Defensive intent for disarming and pushing others
 */
/datum/intent/disarm
	name = "Disarm"
	desc = "Push and disarm others"
	icon_state = "disarm"

/datum/intent/disarm/on_close_range_interact(mob/living/user, atom/target, list/modifiers)
	if(!iscarbon(user) || !iscarbon(target))
		return FALSE

	var/mob/living/carbon/carbon_user = user
	var/mob/living/carbon/carbon_target = target

	carbon_user.disarm(carbon_target)
	return TRUE

/datum/intent/disarm/get_screentip_text(mob/living/user, atom/target)
	if(isliving(target))
		return "Disarm"
	return "Push"
