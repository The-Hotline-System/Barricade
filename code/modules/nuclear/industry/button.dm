/obj/machinery/button/pushdown
	name = "pushdown button"
	desc = "A button that requires to be held down."
	//skin = "foundry"

	canMouseDown = TRUE

	/// Who's holding the button down.
	var/mob/interacting

	/// Sound to play when the button is pressed.
	var/press_sound = 'sound/machines/button/base/down.ogg'

	/// Sound to play when the button is released.
	var/release_sound = 'sound/machines/button/base/up.ogg'

/obj/machinery/button/pushdown/attack_hand(mob/user, list/modifiers)
	return
/*
/obj/machinery/button/pushdown/try_activate_button()
*/

/obj/machinery/button/pushdown/proc/button_down(mob/user)
	if(press_sound)
		playsound(src, press_sound, 75, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	//color = COLOR_GREEN

/obj/machinery/button/pushdown/proc/button_up()
	if(release_sound)
		playsound(src, release_sound, 75, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	//color = COLOR_WHITE

/obj/machinery/button/pushdown/onMouseDown(object, location, params, mob)
	. = ..()
	if(interacting)
		return
	interacting = usr
	button_down(mob)

/obj/machinery/button/pushdown/onMouseUp()
	. = ..()
	button_up()

	interacting = null

/obj/machinery/button/pushdown/process()
	. = ..()
	if(!interacting)
		STOP_PROCESSING(SSfastprocess, src)
