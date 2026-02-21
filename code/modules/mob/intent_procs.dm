/**
 * # Mob Intent Procs
 *
 * Procedures for managing mob intents in the datumized system
 */

/**
 * Set the mob's active intent
 *
 * Arguments:
 * * new_intent - The intent datum or path to set
 * * silent - Whether to suppress feedback messages
 */
/mob/proc/set_intent(datum/intent/new_intent, silent = FALSE)
	if(ispath(new_intent))
		// Find the global instance
		for(var/datum/intent/intent as anything in GLOB.all_intents)
			if(intent.type == new_intent)
				new_intent = intent
				break

	if(!istype(new_intent))
		return FALSE

	if(a_intent == new_intent)
		return FALSE

	var/datum/intent/old_intent = a_intent
	a_intent = new_intent

	if(!silent && client)
		to_chat(src, span_notice("You are now using [new_intent.name] intent."))

	SEND_SIGNAL(src, COMSIG_MOB_INTENT_CHANGED, old_intent, new_intent)
	return TRUE

/**
 * Cycle to the next intent in the list
 */
/mob/proc/cycle_intent()
	if(!length(possible_a_intents))
		return FALSE

	var/current_index = possible_a_intents.Find(a_intent)
	if(!current_index)
		current_index = 0

	var/next_index = (current_index % length(possible_a_intents)) + 1
	var/datum/intent/next_intent = possible_a_intents[next_index]

	return set_intent(next_intent)

/**
 * Get the current intent datum
 */
/mob/proc/get_intent()
	return a_intent

/**
 * Initialize default intents for this mob
 */
/mob/proc/initialize_intents()
	if(!length(possible_a_intents))
		possible_a_intents = list(
			GLOB.intent_help,
			GLOB.intent_disarm,
			GLOB.intent_grab,
			GLOB.intent_harm
		)

	if(!a_intent)
		a_intent = GLOB.intent_help

/mob/Initialize(mapload)
	. = ..()
	initialize_intents()
