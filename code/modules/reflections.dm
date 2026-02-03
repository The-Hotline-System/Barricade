/obj/reflection
	vis_flags = VIS_INHERIT_ICON|VIS_INHERIT_ICON_STATE|VIS_INHERIT_DIR|VIS_INHERIT_LAYER|VIS_UNDERLAY
	appearance_flags = PIXEL_SCALE
	plane = REFLECTION_PLANE
	mouse_opacity = 0
	pixel_y = -44

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
	var/mutable_appearance/reflective_mask
	var/mutable_appearance/reflective_icon

/mob/living/update_overlays()
	. = ..()
	update_reflection()

/mob/living/update_icon()
	. = ..()
	update_reflection()

/mob/living/Initialize()
	. = ..()
	create_reflection()

/mob/living/proc/create_reflection()
	//Add custom reflection mask
	var/mutable_appearance/MA = new()
	//appearance stuff
	MA.appearance = appearance
	if(render_target)
		MA.render_source = render_target
	MA.plane = MANUAL_REFLECTIVE_MASK_PLANE
	reflective_mask = MA
	add_overlay(MA)

	//Add custom reflection image
	var/mutable_appearance/MAM = new()
	//appearance stuff
	MAM.appearance = appearance
	if(render_target)
		MAM.render_source = render_target
	MAM.plane = MANUAL_REFLECTIVE_PLANE
	//transform stuff
	var/matrix/n_transform = MAM.transform
	n_transform.Scale(1, -1)
	MAM.transform = n_transform
	MAM.vis_flags = VIS_INHERIT_DIR
	//filters
	var/icon/I = icon('icons/turf/overlays.dmi', "partialOverlay")
	I.Flip(NORTH)
	MAM.filters += filter(type = "alpha", icon = I)
	reflective_icon = MAM
	add_overlay(reflective_icon)
	// update_vision_cone()

/mob/living/carbon/human/dummy/update_reflection()
	return

/mob/living/proc/update_reflection()
	if(!reflective_icon)
		create_reflection()
	cut_overlay(reflective_icon)
	reflective_icon.appearance = appearance
	if(render_target)
		reflective_icon.render_source = render_target
	reflective_icon.plane = MANUAL_REFLECTIVE_PLANE
	reflective_icon.pixel_y -= 32
	//transform stuff
	var/matrix/n_transform = reflective_icon.transform
	n_transform.Scale(1, -1)
	reflective_icon.transform = n_transform
	reflective_icon.vis_flags = VIS_INHERIT_DIR
	//filters
	var/icon/I = icon('icons/turf/overlays.dmi', "partialOverlay")
	I.Flip(NORTH)
	reflective_icon.filters += filter(type = "alpha", icon = I)
	add_overlay(reflective_icon)
	// update_vision_cone()
