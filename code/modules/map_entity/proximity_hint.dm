/**
 * # Proximity Hint Map Entity
 *
 * A specialized map entity that manages a proximity hint component.
 * Supports the IO system for being enabled, disabled, or triggered.
 */
/obj/effect/map_entity/proximity_hint
	name = "proximity_hint"
	icon = 'icons/hammer/source.dmi'
	icon_state = "hint_small"
	
	/// The text to display in the hint
	var/hint_text = "Sample hint text."
	/// Image state for the hint icon
	var/image_state_val
	/// Sound to play when hint appears
	var/hint_sound
	/// Distance at which the hint triggers
	var/trigger_range = 7
	/// Distance at which the hint is removed
	var/removal_range = 8
	/// Whether to require line-of-sight (view() check)
	var/check_los = TRUE
	
	/// Multi-stage configuration: list(HINT_STAGE("text", "image", 'sound'), ...)
	var/list/hint_stages_config = list()
	
	/// Reference to the internal component
	var/datum/component/proximity_hint/hint_comp

/obj/effect/map_entity/proximity_hint/Initialize(mapload)
	. = ..()
	
	// Use multi-stage configuration if provided
	if(length(hint_stages_config))
		hint_comp = AddComponent(/datum/component/proximity_hint, \
			stages = hint_stages_config, \
			trigger_range = trigger_range, \
			removal_range = removal_range, \
			check_los = check_los)
	else
		// Single-stage mode
		hint_comp = AddComponent(/datum/component/proximity_hint, \
			hint_text, \
			/atom/movable/screen/text/screen_text/atom_picture, \
			trigger_range, \
			removal_range, \
			check_los, \
			image_state = image_state_val, \
			hint_sound = hint_sound)
	
	if(!io_enabled)
		hint_comp.disable()
		
	RegisterSignal(hint_comp, COMSIG_PROXIMITY_HINT_TRIGGERED, PROC_REF(on_hint_triggered))
	RegisterSignal(hint_comp, COMSIG_PROXIMITY_HINT_ENDED, PROC_REF(on_hint_ended))

/*
Inputs:
Enable - Enables the hint system
Disable - Disables the hint system
Toggle - Toggles the enabled state
ForceStart/ForceEnd - Synonyms for Enable/Disable
UpdateText - Updates the hint text. Requires 'value' param.
AdvanceStage - Advances to the next stage in multi-stage hints

Outputs:
OnTrigger - Fired when a hint is shown to someone (activator is the mob)
OnTriggerEnd - Fired when a hint is removed from someone (activator is the mob)
*/
/obj/effect/map_entity/proximity_hint/receive_input(input_name, atom/activator, atom/caller, list/params)
	// Handle ForceStart/ForceEnd as synonyms for Enable/Disable before calling base
	// The base class handles Enable/Disable/Toggle and sets 'enabled'
	var/handled_by_base = FALSE
	switch(lowertext(input_name))
		if("forcestart")
			input_name = "Enable"
			handled_by_base = ..(input_name, activator, caller, params)
		if("forceend")
			input_name = "Disable"
			handled_by_base = ..(input_name, activator, caller, params)
		if("updatetext")
			var/new_text = params?["value"] || hint_text
			hint_comp.set_hint_text(new_text)
			return TRUE
		else
			handled_by_base = ..(input_name, activator, caller, params)

	if(handled_by_base)
		// If base class handled Enable/Disable/Toggle, update the component state
		if(io_enabled)
			hint_comp?.enable()
		else
			hint_comp?.disable()
		return TRUE
	return FALSE

/obj/effect/map_entity/proximity_hint/proc/on_hint_triggered(datum/source, mob/M)
	SIGNAL_HANDLER
	fire_output("OnTrigger", M, src)

/obj/effect/map_entity/proximity_hint/proc/on_hint_ended(datum/source, mob/M)
	SIGNAL_HANDLER
	fire_output("OnTriggerEnd", M, src)
