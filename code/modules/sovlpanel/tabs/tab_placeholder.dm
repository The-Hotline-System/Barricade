// ============================================================================
// PLACEHOLDER TAB - Auto-generated for unknown verb categories
// ============================================================================
// Inherits from dynamic tab - automatically created at runtime when verbs
// with unknown categories are detected. Uses category-derived icon with
// blank.png as fallback.
//
// To set custom priorities for specific categories, add them to
// GLOB.verb_category_priorities. Example:
//   GLOB.verb_category_priorities["scissors"] = 61
// ============================================================================

/// Associative list: category name -> priority value
/// Set priorities here for categories that should have non-default ordering
GLOBAL_LIST_INIT(verb_category_priorities, list(
	"Admin" = 70
))

/datum/statpanel_tab/dynamic/placeholder
	priority = 80 // Default priority for unknown categories

/datum/statpanel_tab/dynamic/placeholder/New(category_name)
	if(category_name)
		verb_category = category_name
		id = ckey(category_name) // Sanitize to valid id
		name = capitalize(category_name)
		// Check for custom priority - This will also try to set icon from verb_category.
		if(GLOB.verb_category_priorities[category_name])
			icon = "button_[verb_category].png"
			priority = GLOB.verb_category_priorities[category_name]
		else
			icon = "blank.png" // Default to blank if it isn't pre-prioritized.
	. = ..()
