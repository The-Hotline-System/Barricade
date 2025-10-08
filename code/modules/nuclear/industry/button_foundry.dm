/obj/machinery/button/pushdown/cooperative/foundry
	name = "foundry button"
	desc = "A button that requires to be held down alongside it's peers to activate the foundry."
	id = "foundry"

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/button/pushdown/cooperative/foundry, 24)

/obj/machinery/button/pushdown/cooperative/foundry/indestructible
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/machinery/button/pushdown/cooperative/foundry/setup_device()
	return

/obj/machinery/button/pushdown/cooperative/foundry/try_activate_button(mob/user)
	for(var/obj/machinery/foundry/F in INSTANCES_OF(/obj/machinery/foundry))
		if(F.id == src.id)
			F.activate(user)
			return

/obj/machinery/button/pushdown/cooperative/foundry/try_deactivate_button()
	for(var/obj/machinery/foundry/F in INSTANCES_OF(/obj/machinery/foundry))
		if(F.id == src.id)
			F.deactivate()
			return
