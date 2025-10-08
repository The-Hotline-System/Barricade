/obj/machinery/foundry
	name = "foundry"
	desc = "A large industrial furnace used for melting metals."
	icon = 'icons/obj/64x48.dmi'
	icon_state = "foundry"
	density = TRUE
	anchored = TRUE

	var/temperature = 0 // Current temperature of the foundry in Celsius.
	var/max_temperature = 200 // Maximum temperature the foundry can reach in Celsius.
	var/overheat_warn_temperature = 160 // The temp we get the warning at before the overheat
	var/heat_rate = 20 // How much the temperature increases per tick when the foundry is on.
	var/cool_rate = 10 // How much the temperature decreases per tick when the foundry is off.
	var/active = FALSE // Is the foundry currently active?
	var/overheat_threshold = 200 // Temperature at which the foundry will overheat and potentially explode.

	var/time_before_temp_drops = 5 SECONDS // Time in seconds before the temperature starts to drop after being turned off.
	var/time_since_turned_off = 0 // Time since the foundry was turned off.

	var/time_when_to_stop_processing = 0

	var/time_before_processing_stop = 5 SECONDS // Time in seconds before processing stops after being turned off and having reached 0 temp

	/// Sound to play when the foundry is active.
	var/active_sound = null // 'sound/machines/foundry/active.ogg'

	/// Sound to play when the foundry is deactivated.
	var/deactivate_sound = null // 'sound/machines/foundry/deactivate.ogg'

	/// Sound to play when the foundry overheats.
	var/overheat_sound = null // 'sound/machines/foundry/overheat.ogg'

	/// Sound to play when the foundry is about to overheat.
	var/warning_sound = null // 'sound/machines/foundry/warning.ogg'

	/// ID to link us to a button.
	var/id = "foundry"

	var/image/flame
	var/image/bulb

/obj/machinery/foundry/Initialize(mapload)
	. = ..()
	SET_TRACKING(__TYPE__)
	update_appearance()

/obj/machinery/foundry/Destroy()
	UNSET_TRACKING(__TYPE__)
	. = ..()


/obj/machinery/foundry/update_overlays()
	. = ..()
	cut_overlays()
	if(!bulb)
		bulb = image('icons/obj/64x48.dmi', icon_state="foundry_1")
	if(active)
		bulb.icon_state = "foundry_1"
	else
		bulb.icon_state = "foundry_0"
	if(!flame)
		flame = image('icons/obj/64x48.dmi', icon_state="flame_o")
	flame.alpha = round((temperature / max_temperature) * max_temperature)
	. += flame
	. += bulb

/obj/machinery/foundry/process()
	if(active)

	// Overheat logic start
		if(temperature >= overheat_warn_temperature)
			if(warning_sound)
				playsound(src, warning_sound, 75, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
		else if(temperature >= overheat_threshold)
			visible_message(span_danger("The [src] has overheated and tis is a dev message!"))
			if(overheat_sound)
				playsound(src, overheat_sound, 75, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
			explosion(src, 4, 2, 6, 0, 3)
		else if(temperature < max_temperature)
			temperature += heat_rate
			if(temperature > max_temperature)
				temperature = max_temperature
	// Overheat logic end
		visible_message(span_notice("The [src] is now at [temperature]°C."))

	else
		if(world.time < time_since_turned_off + time_before_temp_drops)
			return
		if(temperature > 0)
			temperature -= cool_rate
			if(temperature < 0)
				temperature = 0
		if(temperature == 0)
			time_when_to_stop_processing = world.time + time_before_processing_stop
	if(world.time < time_when_to_stop_processing && time_when_to_stop_processing)
		STOP_PROCESSING(SSmachines, src)
		time_when_to_stop_processing = 0
	update_appearance()
	return TRUE

/obj/machinery/foundry/proc/activate()
	if(!active)
		active = TRUE
		update_appearance()
		if(active_sound)
			playsound(src, active_sound, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
		visible_message(span_notice("The [src] hums to life."))
		if(!CHECK_BITFIELD(datum_flags, DF_ISPROCESSING))
			START_PROCESSING(SSmachines, src)

/obj/machinery/foundry/proc/deactivate()
	if(active)
		active = FALSE
		update_appearance()
		time_since_turned_off = world.time
		if(deactivate_sound)
			playsound(src, deactivate_sound, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
		visible_message(span_notice("The [src] powers down."))
