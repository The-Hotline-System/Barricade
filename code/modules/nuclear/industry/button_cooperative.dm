/obj/machinery/button/pushdown/cooperative
	name = "cooperative pushdown button"
	desc = "A button that requires to be held down. All buttons with the same ID must be pressed to activate the device."
	//skin = "foundry"

	canMouseDown = TRUE

	/// The ID that this button shares with other pushdown buttons.
	id = 0
		// All buttons with the same ID must be pressed to activate the device.
		// It's also passed down to the conroller inside.

	/// Holding the button down? Not sure? Let's check.
	var/active = FALSE

	/// successfully activated the device it's linked to?
	var/success_active = FALSE

/obj/machinery/button/pushdown/cooperative/Initialize(mapload, ndir, built)
	. = ..()
	SET_TRACKING(__TYPE__)

/obj/machinery/button/pushdown/cooperative/Destroy()
	UNSET_TRACKING(__TYPE__)
	. = ..()

/obj/machinery/button/pushdown/cooperative/proc/success_others()
	for(var/obj/machinery/button/pushdown/cooperative/M in INSTANCES_OF(__TYPE__))
		if(M.id == src.id)
			M.success_active = TRUE

/obj/machinery/button/pushdown/cooperative/proc/unsuccess_others()
	for(var/obj/machinery/button/pushdown/cooperative/M in INSTANCES_OF(__TYPE__))
		if(M.id == src.id)
			M.success_active = FALSE

/obj/machinery/button/pushdown/cooperative/button_down(mob/user)
	. = ..()
	active = TRUE
	var/linked_buttons = 0
	var/pushed_linked_buttons = 0
	for(var/obj/machinery/button/pushdown/cooperative/M in INSTANCES_OF(__TYPE__))
		if(M.id == src.id)
			linked_buttons++
			if(M.active)
				pushed_linked_buttons++
	if(linked_buttons == pushed_linked_buttons)
		try_activate_button(user)
		success_others()

/obj/machinery/button/pushdown/cooperative/button_up()
	. = ..()
	active = FALSE
	if(success_active)
		try_deactivate_button()

/obj/machinery/button/pushdown/cooperative/proc/try_deactivate_button()
	unsuccess_others()
	return
