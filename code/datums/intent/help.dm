/**
 * # Help Intent
 *
 * Friendly, non-aggressive intent for helping others and gentle interactions
 */
/datum/intent/help
	name = "Help"
	desc = "Help others and interact gently"
	icon_state = "help"

/datum/intent/help/on_close_range_interact(mob/living/user, atom/target, list/modifiers)
	to_world("Help intent on_close_range_interact called")
	to_world("User: [user] ([user.type])")
	to_world("Target: [target] ([target.type])")
	to_world("iscarbon(user): [iscarbon(user)]")
	to_world("iscarbon(target): [iscarbon(target)]")

	if(!iscarbon(user) || !iscarbon(target))
		to_world("Failed iscarbon check, returning FALSE")
		return FALSE

	var/mob/living/carbon/carbon_user = user
	var/mob/living/carbon/carbon_target = target

	to_world("About to call help_shake_act")
	carbon_target.help_shake_act(carbon_user)
	to_world("help_shake_act completed, returning TRUE")
	return TRUE

/datum/intent/help/on_object_interact(mob/living/user, atom/target, list/modifiers)
	// Default gentle interaction
	return FALSE

/datum/intent/help/get_screentip_text(mob/living/user, atom/target)
	if(isliving(target))
		var/mob/living/living_target = target
		if(living_target.stat != CONSCIOUS && living_target.health < 0)
			return "Perform CPR"
		return "Help"
	return null
