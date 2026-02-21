/// Checks for RIGHT_CLICK in modifiers and runs attack_hand_secondary if so. Returns TRUE if normal chain blocked
/mob/living/proc/right_click_attack_chain(atom/target, list/modifiers)
	if (!LAZYACCESS(modifiers, RIGHT_CLICK))
		return
	var/secondary_result = target.attack_hand_secondary(src, modifiers)

	if (secondary_result == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN || secondary_result == SECONDARY_ATTACK_CONTINUE_CHAIN)
		return TRUE
	else if (secondary_result != SECONDARY_ATTACK_CALL_NORMAL)
		CRASH("attack_hand_secondary did not return a SECONDARY_ATTACK_* define.")

/**
 * Checks if this mob is in a valid state to punch someone.
 */
/mob/living/proc/can_unarmed_attack()
	return !HAS_TRAIT(src, TRAIT_HANDS_BLOCKED)

/mob/living/carbon/can_unarmed_attack()
	. = ..()
	if(!.)
		return

	if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
		return FALSE

	if(!has_active_hand()) //can't attack without a hand.
		var/obj/item/bodypart/check_arm = get_active_hand()
		if(check_arm?.bodypart_disabled)
			to_chat(src, span_warning("Your [check_arm.name] is in no condition to be used."))
			return FALSE

		to_chat(src, span_notice("You look at your arm and sigh."))
		return FALSE


	return TRUE

/mob/living/UnarmedAttack(atom/attack_target, proximity_flag, list/modifiers)
	//This signal is needed to prevent gloves of the north star + hulk.
	var/sig_return = SEND_SIGNAL(src, COMSIG_LIVING_EARLY_UNARMED_ATTACK, attack_target, proximity_flag, modifiers)
	if(sig_return & COMPONENT_CANCEL_ATTACK_CHAIN)
		return ATTACK_CHAIN_SUCCESS

	if(sig_return & COMPONENT_SKIP_ATTACK_STEP)
		return ATTACK_CHAIN_CONTINUE

	if(!can_unarmed_attack())
		return ATTACK_CHAIN_CONTINUE

	sig_return = SEND_SIGNAL(src, COMSIG_LIVING_UNARMED_ATTACK, attack_target, proximity_flag, modifiers)
	if(sig_return & COMPONENT_CANCEL_ATTACK_CHAIN)
		return ATTACK_CHAIN_SUCCESS

	if(sig_return & COMPONENT_SKIP_ATTACK_STEP)
		return ATTACK_CHAIN_CONTINUE

	// If uses_intents is enabled and target is a living mob, try to use the intent system
	if(uses_intents && a_intent && isliving(attack_target))
		var/is_right_click = LAZYACCESS(modifiers, RIGHT_CLICK)
		var/intent_handled = FALSE

		if(proximity_flag)
			// Close range interaction
			if(is_right_click)
				intent_handled = try_intent_interaction(attack_target, modifiers, proximity_flag, is_right_click)
			else
				intent_handled = try_intent_interaction(attack_target, modifiers, proximity_flag, is_right_click)
		else
			// Ranged interaction
			intent_handled = try_intent_interaction(attack_target, modifiers, proximity_flag, is_right_click)

		// If intent handled the interaction, we're done
		if(intent_handled)
			return ATTACK_CHAIN_SUCCESS

	if(!right_click_attack_chain(attack_target, modifiers))
		resolve_unarmed_attack(attack_target, modifiers)

	return ATTACK_CHAIN_SUCCESS

/mob/living/carbon/human/UnarmedAttack(atom/attack_target, proximity_flag, list/modifiers)
	if(src == attack_target && !combat_mode && !HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
		// If uses_intents is enabled, skip self-injury check
		if(!uses_intents)
			check_self_for_injuries()
		return ATTACK_CHAIN_SUCCESS

	return ..()

/mob/living/carbon/resolve_unarmed_attack(atom/attack_target, list/modifiers)
	return attack_target.attack_paw(src, modifiers)

/mob/living/carbon/human/resolve_unarmed_attack(atom/attack_target, list/modifiers)
	if(!ISADVANCEDTOOLUSER(src))
		return ..()

	. = attack_target.attack_hand(src, modifiers)

	if(. == ATTACK_CHAIN_SUCCESS)
		animate_interact(attack_target, INTERACT_GENERIC)

/// Return TRUE to cancel other attack hand effects that respect it. Modifiers is the assoc list for click info such as if it was a right click.
/atom/proc/attack_hand(mob/user, list/modifiers)
	. = FALSE
	if(!(interaction_flags_atom & (INTERACT_ATOM_NO_FINGERPRINT_ATTACK_HAND | INTERACT_ATOM_ATTACK_HAND)))
		add_fingerprint(user)
	else
		log_touch(user)

	if(SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_HAND, user, modifiers) & COMPONENT_CANCEL_ATTACK_CHAIN)
		. = TRUE

	if(interaction_flags_atom & INTERACT_ATOM_ATTACK_HAND)
		. = _try_interact(user)

/// When the user uses their hand on an item while holding right-click
/// Returns a SECONDARY_ATTACK_* value.
/atom/proc/attack_hand_secondary(mob/user, list/modifiers)
	if(SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_HAND_SECONDARY, user, modifiers) & COMPONENT_CANCEL_ATTACK_CHAIN)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return SECONDARY_ATTACK_CALL_NORMAL

//Return a non FALSE value to cancel whatever called this from propagating, if it respects it.
/atom/proc/_try_interact(mob/user)
	if(isAdminGhostAI(user)) //admin abuse
		return interact(user)

	if(can_interact(user))
		return interact(user)

	return FALSE

/atom/proc/can_interact(mob/user)
	if(!user.can_interact_with(src))
		return FALSE

	if((interaction_flags_atom & INTERACT_ATOM_REQUIRES_DEXTERITY) && !ISADVANCEDTOOLUSER(user))
		to_chat(user, span_warning("You don't have the dexterity to do this!"))
		return FALSE

	if(!(interaction_flags_atom & INTERACT_ATOM_IGNORE_INCAPACITATED))
		var/ignore_flags = NONE
		if(interaction_flags_atom & INTERACT_ATOM_IGNORE_RESTRAINED)
			ignore_flags |= IGNORE_RESTRAINTS
		if(!(interaction_flags_atom & INTERACT_ATOM_CHECK_GRAB))
			ignore_flags |= IGNORE_GRAB

		if(user.incapacitated(ignore_flags))
			return FALSE

	return TRUE

/atom/ui_status(mob/user)
	. = ..()
	if(!can_interact(user))
		. = min(., UI_UPDATE)

/atom/movable/can_interact(mob/user)
	. = ..()
	if(!.)
		return
	if(!anchored && (interaction_flags_atom & INTERACT_ATOM_REQUIRES_ANCHORED))
		return FALSE

/atom/proc/interact(mob/user)
	if(interaction_flags_atom & INTERACT_ATOM_NO_FINGERPRINT_INTERACT)
		log_touch(user)
	else
		add_fingerprint(user)

	if(interaction_flags_atom & INTERACT_ATOM_UI_INTERACT)
		SEND_SIGNAL(src, COMSIG_ATOM_UI_INTERACT, user)
		return ui_interact(user)

	return FALSE


/mob/living/carbon/human/RangedAttack(atom/A, modifiers)
	. = ..()
	if(.)
		return

	if(isturf(A) && get_dist(src,A) <= 1)
		move_grabbed_atoms_towards(A)
		return TRUE


/// Called by UnarmedAttack(), directs the proc to a type-specified child proc.
/mob/living/proc/resolve_unarmed_attack(atom/attack_target, list/modifiers)
	attack_target.attack_animal(src, modifiers)

/*
	Animals & All Unspecified
*/

/**
 * Called when a simple animal is unarmed attacking / clicking on this atom.
 */
/atom/proc/attack_animal(mob/user, list/modifiers)
	SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_ANIMAL, user)

/atom/proc/attack_basic_mob(mob/user, list/modifiers)
	SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_BASIC_MOB, user)

///Attacked by monkey
/atom/proc/attack_paw(mob/user, list/modifiers)
	if(SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_PAW, user, modifiers) & COMPONENT_CANCEL_ATTACK_CHAIN)
		return TRUE
	return FALSE


/*
	Aliens
	Defaults to same as monkey in most places
*/
/mob/living/carbon/alien/resolve_unarmed_attack(atom/attack_target, list/modifiers)
	attack_target.attack_alien(src, modifiers)

/atom/proc/attack_alien(mob/living/carbon/alien/user, list/modifiers)
	attack_paw(user, modifiers)
	return


// Babby aliens
/mob/living/carbon/alien/larva/resolve_unarmed_attack(atom/attack_target, list/modifiers)
	attack_target.attack_larva(src)

/atom/proc/attack_larva(mob/user)
	return


/*
	Slimes
	Nothing happening here
*/
/mob/living/simple_animal/slime/resolve_unarmed_attack(atom/attack_target, list/modifiers)
	if(isturf(attack_target))
		return ..()

	return attack_target.attack_slime(src)

/atom/proc/attack_slime(mob/user)
	return


/*
	Drones
*/
/mob/living/simple_animal/drone/resolve_unarmed_attack(atom/attack_target, list/modifiers)
	return attack_target.attack_drone(src, modifiers)

/// Defaults to attack_hand or attack_hand_secondary. Override it when you don't want drones to do same stuff as humans.
/atom/proc/attack_drone(mob/living/simple_animal/drone/user, list/modifiers)
	if(!user.right_click_attack_chain(src, modifiers))
		attack_hand(user, modifiers)


/*
	Brain
*/

/mob/living/brain/UnarmedAttack(atom/attack_target, proximity_flag, list/modifiers)//Stops runtimes due to attack_animal being the default
	return


/*
	pAI
*/

/mob/living/silicon/pai/UnarmedAttack(atom/attack_target, proximity_flag, list/modifiers)//Stops runtimes due to attack_animal being the default
	return


/*
	Simple animals
*/

/mob/living/simple_animal/resolve_unarmed_attack(atom/attack_target, list/modifiers)
	if(dextrous && (isitem(attack_target) || !combat_mode))
		attack_target.attack_hand(src, modifiers)
		update_held_items()
	else
		return ..()

/*
	Hostile animals
*/

/mob/living/simple_animal/hostile/resolve_unarmed_attack(atom/attack_target, list/modifiers)
	GiveTarget(attack_target)
	if(dextrous && (isitem(attack_target) || !combat_mode))
		..()
	else
		AttackingTarget(attack_target)

/*
	New Players:
	Have no reason to click on anything at all.
*/
/mob/dead/new_player/ClickOn()
	return

/**
 * Try to use the current intent to interact with a target
 *
 * Arguments:
 * * target - The atom being targeted
 * * modifiers - Click modifiers list
 * * proximity - Whether this is a close range or ranged interaction
 * * is_right_click - Whether this is a right click
 *
 * Returns: TRUE if the intent handled the interaction, FALSE otherwise
 */
/mob/living/proc/try_intent_interaction(atom/target, list/modifiers, proximity, is_right_click)
	if(!a_intent)
		return FALSE

	// Route to the appropriate intent method based on the intent type
	switch(a_intent.type)
		if(/datum/intent/help)
			return try_help_intent(target, modifiers, proximity, is_right_click)
		if(/datum/intent/disarm)
			return try_disarm_intent(target, modifiers, proximity, is_right_click)
		if(/datum/intent/grab)
			return try_grab_intent(target, modifiers, proximity, is_right_click)
		if(/datum/intent/harm)
			return try_harm_intent(target, modifiers, proximity, is_right_click)

	return FALSE

/**
 * Handle help intent interaction
 */
/mob/living/proc/try_help_intent(atom/target, list/modifiers, proximity, is_right_click)
	if(!proximity || is_right_click)
		return FALSE

	if(!iscarbon(src) || !iscarbon(target))
		return FALSE

	var/mob/living/carbon/carbon_target = target
	carbon_target.help_shake_act(src)
	return TRUE

/**
 * Handle disarm intent interaction
 */
/mob/living/proc/try_disarm_intent(atom/target, list/modifiers, proximity, is_right_click)
	if(!proximity || is_right_click)
		return FALSE

	if(!iscarbon(src) || !iscarbon(target))
		return FALSE

	var/mob/living/carbon/carbon_user = src
	var/mob/living/carbon/carbon_target = target
	carbon_user.disarm(carbon_target)
	return TRUE

/**
 * Handle grab intent interaction
 */
/mob/living/proc/try_grab_intent(atom/target, list/modifiers, proximity, is_right_click)
	if(!proximity || is_right_click)
		return FALSE

	if(!isliving(target))
		return FALSE

	var/mob/living/living_target = target
	if(try_make_grab(living_target))
		return TRUE

	return FALSE

/**
 * Handle harm intent interaction
 */
/mob/living/proc/try_harm_intent(atom/target, list/modifiers, proximity, is_right_click)
	if(!proximity || is_right_click)
		return FALSE

	if(!isliving(target))
		return FALSE

	var/mob/living/living_target = target

	// Perform unarmed attack based on mob type
	if(ishuman(src))
		var/mob/living/carbon/human/human_user = src
		// Check for martial arts
		if(human_user.dna?.species)
			var/datum/martial_art/martial = human_user.mind?.martial_art
			if(martial?.harm_act(human_user, living_target) == MARTIAL_ATTACK_SUCCESS)
				return TRUE

		// Default punch behavior - call species attack
		if(human_user.dna?.species)
			human_user.dna.species.spec_attack_hand(human_user, living_target, null, modifiers)
			return TRUE
	else if(iscarbon(src))
		// Paw attack for non-humans
		return living_target.attack_paw(src, modifiers)
	else
		// Generic animal attack
		living_target.attack_animal(src, modifiers)
		return TRUE

	return FALSE
