
/**
 * # Proximity Hint Injector
 *
 * Injects a proximity hint component into an atom on the same turf.
 */
/obj/effect/mapping_helpers/atom_injector/component_injector/proximity_hint
	name = "proximity hint injector"
	component_type = /datum/component/proximity_hint
	var/hint_text = "Sample hint text."
	var/trigger_range = 7
	var/removal_range = 8
	var/check_los = TRUE

/obj/effect/mapping_helpers/atom_injector/component_injector/proximity_hint/check_validity()
	component_args = list(hint_text, /atom/movable/screen/text/screen_text/atom_picture, trigger_range, removal_range, check_los)
	return ..()
