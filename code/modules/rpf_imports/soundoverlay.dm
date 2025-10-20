/proc/soundoverlay(var/obj/where, var/iconfile, var/iconstate, var/howlong, var/newplane)
	if(!where)
		return

	if(!newplane)
		newplane = FOOTSTEP_ALERT_PLANE
	if(!iconfile)
		iconfile = 'icons/effects/footstepsound.dmi'
	if(!iconstate)
		iconstate = "default"
	if(!howlong)
		howlong = 4
	var/list/clients_to_show = list()

	for(var/mob/living/carbon/human/H in view(world.view, get_turf(where)))
		clients_to_show += H.client
	if(!length(clients_to_show))
		return
	if(ishuman(where))
		var/mob/living/carbon/human/H = where
		clients_to_show -= H.client
	var/image/I = image(iconfile, loc = get_turf(where), icon_state = iconstate, pixel_x = where.pixel_x, pixel_y = where.pixel_y)
	I.plane = newplane
	flick_overlay(I, clients_to_show, howlong)
