/**
 * # Intent Datum
 *
 * Datumized intent system that separates combat mode from intent selection.
 * Each intent defines specific interaction behaviors for different contexts.
 */
/datum/intent
	var/name = "Intent" /// Display name of the intent
	var/desc = "An intent" 	/// Description shown in examine
	var/icon = null /// Icon file for the given intent button
	var/icon_state = "intent" /// Icon state for the intent button
	var/grab_strength_modifier = 0 /// Modifier applied to grab strength when initiating grabs
	var/canparry = TRUE // Can be parried?
	var/candodge = TRUE // Can be dodged?
	var/anim = "punch" 	/// Attack animation for the respective intent
	var/stamdrain = 0 // Base stamina drain applied to every action within this intent
	var/swingdelay = 0
	var/clickcd = CLICK_CD_MELEE //the cd invoked clicking on stuff with this intent
	/// HITTING
	var/list/attack_verbs = list("hits", "strikes") /// Attack verbage for chat display
	var/list/hitsounds /// Hitsounds
	var/hitcost = 5	//	Extra stamina drain on hit
	/// CHARGED ATTACKS
	var/list/chargedhitsounds /// Default to hitsounds if unset.
	var/chargetime = 0 // How long it takes to charge attack with this intent
	var/chargedrain = 0 // How much extra stamina is drained from a charge attack
	/// MISSING
	var/misstext = null /// Chat text for missing
	var/list/miss_sounds /// Miss sounds
	var/misscost = 1 //	Stamina drain from missing only, ALSO APPLIED IF ENEMY DODGES

/**
 * Called when this intent is used for a bare-handed attack on a mob
 *
 * Arguments:
 * * user - The mob performing the action
 * * target - The mob being targeted
 * * modifiers - Click modifiers list
 *
 * Returns: TRUE if the interaction was handled, FALSE otherwise
 */
/datum/intent/proc/on_unarmed_attack(mob/living/user, mob/living/target, list/modifiers)
	return FALSE

/**
 * Called when this intent is used for close range (adjacent) left click on a mob
 *
 * Arguments:
 * * user - The mob performing the action
 * * target - The mob being targeted
 * * modifiers - Click modifiers list
 *
 * Returns: TRUE if the interaction was handled, FALSE to continue default behavior
 */
/datum/intent/proc/on_close_range_interact(mob/living/user, atom/target, list/modifiers)
	return FALSE

/**
 * Called when this intent is used for ranged left click on a mob
 *
 * Arguments:
 * * user - The mob performing the action
 * * target - The atom being targeted
 * * modifiers - Click modifiers list
 *
 * Returns: TRUE if the interaction was handled, FALSE to continue default behavior
 */
/datum/intent/proc/on_ranged_interact(mob/living/user, atom/target, list/modifiers)
	return FALSE

/**
 * Called when this intent is used for close range (adjacent) right click
 *
 * Arguments:
 * * user - The mob performing the action
 * * target - The atom being targeted
 * * modifiers - Click modifiers list
 *
 * Returns: TRUE if the interaction was handled, FALSE to continue default behavior
 */
/datum/intent/proc/on_close_range_secondary(mob/living/user, atom/target, list/modifiers)
	return FALSE

/**
 * Called when this intent is used for ranged right click
 *
 * Arguments:
 * * user - The mob performing the action
 * * target - The atom being targeted
 * * modifiers - Click modifiers list
 *
 * Returns: TRUE if the interaction was handled, FALSE to continue default behavior
 */
/datum/intent/proc/on_ranged_secondary(mob/living/user, atom/target, list/modifiers)
	return FALSE

/**
 * Called when this intent is used to interact with an object
 *
 * Arguments:
 * * user - The mob performing the action
 * * target - The object being interacted with
 * * modifiers - Click modifiers list
 *
 * Returns: TRUE if the interaction was handled, FALSE otherwise
 */
/datum/intent/proc/on_object_interact(mob/living/user, atom/target, list/modifiers)
	return FALSE

/**
 * Called to get contextual screentip text for this intent
 *
 * Arguments:
 * * user - The mob viewing the screentip
 * * target - The atom being examined
 *
 * Returns: String to display, or null for default
 */
/datum/intent/proc/get_screentip_text(mob/living/user, atom/target)
	return null
