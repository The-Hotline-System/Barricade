// ============================================================================
// DYNAMIC TABS - Verb Category Tabs
// ============================================================================
// Dynamically generated tabs based on verb categories
// ============================================================================

/datum/statpanel_tab/dynamic
	id = "dynamic" // Base - not used directly
	priority = 60

	/// Category to match for verbs
	var/verb_category

/datum/statpanel_tab/dynamic/can_view(client/C)
	if(!C?.mob || !verb_category)
		return FALSE
	// Check if client/mob has any verbs in this category
	var/list/verb_list = C.verbs + C.mob.verbs
	for(var/v in verb_list)
		var/procpath/P = v
		if(P.category == verb_category)
			return TRUE
	return FALSE

/datum/statpanel_tab/dynamic/get_content(client/C)
	if(!C?.mob || !verb_category)
		return ""

	var/list/stat_verbs = list()
	var/list/verb_list = C.verbs + C.mob.verbs

	for(var/v in verb_list)
		var/procpath/P = v
		if(!P || P.category != verb_category)
			continue
		if(P.hidden)
			continue
		stat_verbs += list(list(P.name, P.desc))

	if(!length(stat_verbs))
		return ""

	return "<table><tr><td>" + generateVerbList(stat_verbs) + "</td></tr></table>"

// ============================================================================
// DYNAMIC TAB SUBTYPES
// ============================================================================

/datum/statpanel_tab/dynamic/craft
	id = "craft"
	name = "Craft"
	icon = "craft.png"
	verb_category = "craft"
	priority = 61

/datum/statpanel_tab/dynamic/verbs
	id = "verbs"
	name = "Verbs"
	icon = "verb.png"
	verb_category = "verb"
	priority = 62

/datum/statpanel_tab/dynamic/emotes
	id = "emotes"
	name = "Emotes"
	icon = "emotes.png"
	verb_category = "emotes"
	priority = 63

/datum/statpanel_tab/dynamic/fangs
	id = "fangs"
	name = "Fangs"
	icon = "fangs.png"
	verb_category = "fangs"
	priority = 64

/datum/statpanel_tab/dynamic/dead
	id = "dead"
	name = "Dead"
	icon = "dead.png"
	verb_category = "dead"
	priority = 65

/datum/statpanel_tab/dynamic/gpc
	id = "gpc"
	name = "GPC"
	icon = "gpc.png"
	verb_category = "gpc"
	priority = 66

/datum/statpanel_tab/dynamic/cross
	id = "cross"
	name = "Cross"
	icon = "cross.png"
	verb_category = "cross"
	priority = 67

/datum/statpanel_tab/dynamic/crown
	id = "crown"
	name = "Crown"
	icon = "crown.png"
	verb_category = "crown"
	priority = 68

/datum/statpanel_tab/dynamic/villain
	id = "villain"
	name = "Villain"
	icon = "villain.png"
	verb_category = "villain"
	priority = 69

/datum/statpanel_tab/dynamic/thanati
	id = "thanati"
	name = "Thanati"
	icon = "thanati.png"
	verb_category = "thanati"
	priority = 70
