/**
 * # Harm Intent
 *
 * Aggressive intent for attacking and causing damage
 */
/datum/intent/harm
	name = "Harm"
	desc = "Attack to cause damage"
	icon_state = "harm"

/datum/intent/harm/on_close_range_interact(mob/living/user, atom/target, list/modifiers)
	if(!isliving(target))
		return FALSE

	var/mob/living/living_target = target

	// Perform unarmed attack based on mob type
	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		// Check for martial arts
		if(human_user.dna?.species)
			var/datum/martial_art/martial = human_user.mind?.martial_art
			if(martial?.harm_act(human_user, living_target) == MARTIAL_ATTACK_SUCCESS)
				return TRUE

		// Default punch behavior
		return living_target.attack_hand(human_user, modifiers)
	else if(iscarbon(user))
		// Paw attack for non-humans
		return living_target.attack_paw(user, modifiers)
	else
		// Generic animal attack
		living_target.attack_animal(user, modifiers)
		return TRUE

/datum/intent/harm/on_object_interact(mob/living/user, atom/target, list/modifiers)
	// Aggressive interaction with objects (smashing, etc)
	return FALSE

/datum/intent/harm/get_screentip_text(mob/living/user, atom/target)
	if(isliving(target))
		return "Attack"
	return "Smash"
