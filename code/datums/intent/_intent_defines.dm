/**
 * # Intent System Defines
 *
 * Global intent instances and related defines
 */

// Intent type paths for easy reference
#define INTENT_HELP /datum/intent/help
#define INTENT_DISARM /datum/intent/disarm
#define INTENT_GRAB /datum/intent/grab
#define INTENT_HARM /datum/intent/harm

// Global intent instances - initialized in _INIT_ORDER_INTENTS
GLOBAL_DATUM(intent_help, /datum/intent/help)
GLOBAL_DATUM(intent_disarm, /datum/intent/disarm)
GLOBAL_DATUM(intent_grab, /datum/intent/grab)
GLOBAL_DATUM(intent_harm, /datum/intent/harm)

// List of all available intents
GLOBAL_LIST_INIT(all_intents, list(
	GLOB.intent_help,
	GLOB.intent_disarm,
	GLOB.intent_grab,
	GLOB.intent_harm
))

/**
 * Initialize global intent datums
 * Called during world initialization
 */
/proc/initialize_intents()
	GLOB.intent_help = new /datum/intent/help()
	GLOB.intent_disarm = new /datum/intent/disarm()
	GLOB.intent_grab = new /datum/intent/grab()
	GLOB.intent_harm = new /datum/intent/harm()

	GLOB.all_intents = list(
		GLOB.intent_help,
		GLOB.intent_disarm,
		GLOB.intent_grab,
		GLOB.intent_harm
	)
