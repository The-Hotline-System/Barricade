
/obj/effect/map_entity/fire_pit
	name = "Great Fire Pit"
	desc = "A massive pit of roiling flames. It seems hungry for more than just wood."
	icon = 'icons/effects/fire.dmi'
	icon_state = "t2"
	anchored = TRUE
	density = FALSE
	opacity = FALSE
	var/temperature = 500
	light_power = 1
	light_outer_range = 2
	light_inner_range = 1
	light_falloff_curve = 1
	light_color = "#ff7755"

/obj/effect/map_entity/fire_pit/Initialize()
	. = ..()
	set_light(light_outer_range, light_inner_range, light_power, light_falloff_curve, light_color, 1)
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/map_entity/fire_pit/attackby(obj/item/I, mob/user)
	if(istype(I))
		burn_object(I, user)
		return TRUE
	return ..()

/obj/effect/map_entity/fire_pit/proc/on_entered(datum/source, atom/movable/AM, oldloc)
	SIGNAL_HANDLER
	if(istype(AM, /obj/item) || istype(AM, /obj/structure/closet/crate))
		burn_object(AM)
	else if(isliving(AM))
		burn_mob(AM)


/obj/effect/map_entity/fire_pit/proc/burn_mob(atom/movable/AM)
	if(isliving(AM))
		var/mob/living/immolated = AM
		immolated.fire_act(temperature, CELL_VOLUME)
		to_chat(AM, span_danger("You step into the [src] and catch fire!"))

/obj/effect/map_entity/fire_pit/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	if(istype(AM, /obj/item))
		burn_object(AM)
	return ..()

/obj/effect/map_entity/fire_pit/proc/burn_object(atom/movable/AM, mob/user = null)
	if(!AM || QDELETED(AM)) return

	IO_output("fire_pit:OnBurn", user, src)

	if(user && istype(AM, /obj/item))
		user.dropItemToGround(AM, TRUE, TRUE)

	qdel(AM)
	do_feedback()

/obj/effect/map_entity/fire_pit/proc/do_feedback()
	// playsound(src,get_sfx("flamer_fire"), 50, 1)
