// ============================================================================
// DYNAMIC TABS - Verb Category Tabs
// ============================================================================
// Dynamically generated tabs based on verb categories.
// All dynamic tabs support subcategory grouping (e.g., Admin.Fun under Admin)
// ============================================================================

/datum/statpanel_tab/dynamic
	id = "dynamic" // Base - not used directly
	priority = 60

	/// Category to match for verbs (parent category for subcategory grouping)
	var/verb_category

/datum/statpanel_tab/dynamic/New()
	. = ..()

/datum/statpanel_tab/dynamic/can_view(client/C)
	if(!C?.mob || !verb_category)
		return FALSE
	// Check if client/mob has any verbs in this category or subcategories
	var/list/verb_list = C.verbs + C.mob.verbs
	for(var/v in verb_list)
		var/procpath/P = v
		if(!P?.category)
			continue
		if(matches_category(P.category))
			return TRUE
	return FALSE

/// Check if a verb category matches this tab (exact match or subcategory)
/datum/statpanel_tab/dynamic/proc/matches_category(check_category)
	if(!check_category || !verb_category)
		return FALSE
	// Exact match
	if(check_category == verb_category)
		return TRUE
	// Subcategory match (e.g., "Admin.Fun" matches "Admin")
	if(findtext(check_category, "[verb_category]."))
		return TRUE
	return FALSE

/// Extract subcategory name from full category (e.g., "Admin.Fun" -> "Fun")
/datum/statpanel_tab/dynamic/proc/get_subcategory(full_category)
	if(!full_category || !verb_category)
		return null
	var/prefix = "[verb_category]."
	if(findtext(full_category, prefix) == 1)
		return copytext(full_category, length(prefix) + 1)
	return null

/datum/statpanel_tab/dynamic/get_content(client/C)
	if(!C?.mob || !verb_category)
		return ""

	var/list/main_verbs = list() // Verbs with exact category match
	var/list/sub_verbs = list() // Assoc list: subcategory -> list of verbs

	var/list/verb_list = C.verbs + C.mob.verbs
	for(var/v in verb_list)
		var/procpath/P = v
		if(!P?.category)
			continue
		if(P.hidden)
			continue
		if(!matches_category(P.category))
			continue

		var/subcategory = get_subcategory(P.category)
		var/entry_type = findtext("[P]", "/proc/") ? ISPROC : ISVERB
		if(subcategory)
			if(!sub_verbs[subcategory])
				sub_verbs[subcategory] = list()
			sub_verbs[subcategory] += list(list(P.name, P.name, entry_type))
		else
			main_verbs += list(list(P.name, P.name, entry_type))

	if(!length(main_verbs) && !length(sub_verbs))
		return ""

	. = "<table><tr><td valign='top'><table><tr><td>"

	// Main category verbs first
	if(length(main_verbs))
		. += "<u>|- <b>[uppertext(verb_category)]</b> -|</u><br>"
		. += generateVerbList(main_verbs)
		if(length(sub_verbs))
			. += "<br>"

	// Subcategory verbs with headers
	var/list/sorted_subs = sort_list(sub_verbs)
	for(var/sub in sorted_subs)
		. += "<u>|- <b>[capitalize(sub)]</b> -|</u><br>"
		. += generateVerbList(sub_verbs[sub])
		. += "<br>"

	. += "</td></tr></table></td></tr></table>"
