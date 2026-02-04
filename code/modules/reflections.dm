/obj/reflection
	vis_flags = VIS_INHERIT_ICON|VIS_INHERIT_ICON_STATE|VIS_INHERIT_DIR|VIS_INHERIT_LAYER|VIS_UNDERLAY
	appearance_flags = PIXEL_SCALE
	plane = REFLECTION_PLANE
	mouse_opacity = 0
	pixel_y = -44
	zmm_flags = ZMM_IGNORE

/obj/reflection/New(loc,mob/owner)
	owner.vis_contents += src

/obj/item
	has_reflection = TRUE

/obj/structure
	has_reflection = TRUE

/obj/machinery
	has_reflection = TRUE

/atom
	///Reflective overlay
	var/mutable_appearance/reflection
	var/mutable_appearance/reflection_displacement
	var/mutable_appearance/total_reflection_mask
	var/shine = SHINE_MATTE

/mob/living
	var/obj/effect/reflection_visual/reflective_mask
	var/obj/effect/reflection_visual/reflective_icon

/obj/effect/reflection_visual
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	zmm_flags = ZMM_IGNORE
	// Explicitly do NOT inherit plane - we want to stay on our assigned plane
	vis_flags = VIS_INHERIT_ID | VIS_INHERIT_DIR

/obj/effect/reflection_visual/mask
	plane = MANUAL_REFLECTIVE_MASK_PLANE

/obj/effect/reflection_visual/reflection
	plane = MANUAL_REFLECTIVE_PLANE

/mob/living/update_overlays()
	. = ..()
	update_reflection()

/mob/living/update_icons()
	. = ..()
	update_reflection()

/mob/living/Initialize()
	. = ..()
	create_reflection()
	// Update reflection when items are equipped or unequipped (includes picking up/dropping from hands)
	RegisterSignal(src, COMSIG_MOB_EQUIPPED_ITEM, PROC_REF(on_item_equipped))
	RegisterSignal(src, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(on_item_unequipped))

/mob/living/proc/create_reflection()
	//Add custom reflection image - this should copy full appearance
	reflective_icon = new /obj/effect/reflection_visual/reflection(src)
	reflective_icon.appearance = appearance
	reflective_icon.dir = dir
	//transform stuff
	var/matrix/n_transform = reflective_icon.transform
	n_transform.Scale(1, -1)
	reflective_icon.transform = n_transform
	//filters
	var/icon/I = icon('icons/turf/overlays.dmi', "partialOverlay")
	I.Flip(NORTH)
	reflective_icon.filters += filter(type = "alpha", icon = I)
	vis_contents += reflective_icon
	reflective_icon.vis_flags = VIS_INHERIT_DIR
	reflective_icon.plane = MANUAL_REFLECTIVE_PLANE
	// update_vision_cone()

/mob/living/carbon/human/dummy/update_reflection()
	return

/mob/living/proc/on_item_equipped(datum/source, obj/item/equipped_item, slot)
	SIGNAL_HANDLER
	// Defer the update to next tick to ensure appearance is fully updated
	addtimer(CALLBACK(src, PROC_REF(update_reflection)), 0, TIMER_UNIQUE | TIMER_OVERRIDE)

/mob/living/proc/on_item_unequipped(datum/source, obj/item/unequipped_item, force, atom/newloc, no_move, invdrop, silent)
	SIGNAL_HANDLER
	// Defer the update to next tick to ensure appearance is fully updated
	addtimer(CALLBACK(src, PROC_REF(update_reflection)), 0, TIMER_UNIQUE | TIMER_OVERRIDE)

/mob/living/proc/update_reflection()
	if(!reflective_icon)
		create_reflection()
		return

	// Update reflection icon with full appearance
	reflective_icon.appearance = appearance
	reflective_icon.vis_flags = VIS_INHERIT_DIR
	reflective_icon.plane = MANUAL_REFLECTIVE_PLANE
	reflective_icon.pixel_y = -32
	//transform stuff
	var/matrix/n_transform = reflective_icon.transform
	n_transform.Scale(1, -1)
	reflective_icon.transform = n_transform
	//filters
	var/icon/I = icon('icons/turf/overlays.dmi', "partialOverlay")
	I.Flip(NORTH)
	reflective_icon.filters = list()
	reflective_icon.filters += filter(type = "alpha", icon = I)
	// update_vision_cone()

