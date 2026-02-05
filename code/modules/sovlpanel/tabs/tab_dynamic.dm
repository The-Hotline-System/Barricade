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

		// Replace spaces with dashes in verb names so BYOND can process them properly
		var/verb_command = P.name
		if(entry_type == ISVERB)
			verb_command = replacetext(verb_command, " ", "-")

		if(subcategory)
			if(!sub_verbs[subcategory])
				sub_verbs[subcategory] = list()
			sub_verbs[subcategory] += list(list(verb_command, P.name, entry_type))
		else
			main_verbs += list(list(verb_command, P.name, entry_type))

	if(!length(main_verbs) && !length(sub_verbs))
		return ""

	// Sort verb lists alphabetically before generating HTML
	if(length(main_verbs))
		sort_verb_list(main_verbs)
	for(var/subcategory in sub_verbs)
		sort_verb_list(sub_verbs[subcategory])

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

/// Sort a list of verb entries alphabetically by display name (case-insensitive)
/// Handles edge cases: empty lists, null values, single-item lists
/// @param verb_list - List of verb entries in format [name, display_name, entry_type]
/// @return The same list, sorted in-place
/datum/statpanel_tab/dynamic/proc/sort_verb_list(list/verb_list)
	// Handle edge cases: null, empty, or single-item lists
	if(!verb_list || length(verb_list) <= 1)
		return verb_list

	// Sort using case-insensitive comparison of display names
	sortTim(verb_list, GLOBAL_PROC_REF(cmp_verb_entry_asc))
	return verb_list

/// Comparison function for verb entries - sorts by display name (case-insensitive)
/// @param a - First verb entry [name, display_name, entry_type]
/// @param b - Second verb entry [name, display_name, entry_type]
/// @return Comparison result for sortTim
/proc/cmp_verb_entry_asc(list/a, list/b)
	// Extract display names (element 2 of each entry)
	var/display_a = a?[2] || ""
	var/display_b = b?[2] || ""

	// Use sorttext for case-insensitive alphabetical comparison
	// sorttext(b, a) returns positive if b > a (ascending order)
	return sorttext(display_b, display_a)
