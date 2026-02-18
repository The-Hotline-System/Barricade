/mob/proc/overlay_fullscreen(category, type, severity)
	var/atom/movable/screen/fullscreen/screen = screens[category]
	if (!screen || screen.type != type)
		// needs to be recreated
		clear_fullscreen(category, FALSE)
		screens[category] = screen = new type()
		if(istype(screen, /atom/movable/screen/fullscreen/directional))
			var/atom/movable/screen/fullscreen/directional/dir_screen = screen
			dir_screen.set_owner(src)
	else if ((!severity || severity == screen.severity) && (!client || screen.screen_loc != "CENTER-7,CENTER-7" || screen.view == client.view))
		// doesn't need to be updated
		return screen

	screen.icon_state = "[initial(screen.icon_state)][severity]"
	screen.severity = severity
	if (client && screen.should_show_to(src))
		screen.update_for_view(client.view)
		client.screen += screen

	return screen

/mob/proc/clear_fullscreen(category, animated = 10)
	var/atom/movable/screen/fullscreen/screen = screens[category]
	if(!screen)
		return

	screens -= category

	if(animated)
		animate(screen, alpha = 0, time = animated)
		addtimer(CALLBACK(src, PROC_REF(clear_fullscreen_after_animate), screen), animated, TIMER_CLIENT_TIME)
	else
		if(client)
			client.screen -= screen
		qdel(screen)

/mob/proc/clear_fullscreen_after_animate(atom/movable/screen/fullscreen/screen)
	if(client)
		client.screen -= screen
	qdel(screen)

/mob/proc/clear_fullscreens()
	for(var/category in screens)
		clear_fullscreen(category)

/mob/proc/hide_fullscreens()
	if(client)
		for(var/category in screens)
			client.screen -= screens[category]

/mob/proc/reload_fullscreen()
	if(client)
		var/atom/movable/screen/fullscreen/screen
		for(var/category in screens)
			screen = screens[category]
			if(screen.should_show_to(src))
				screen.update_for_view(client.view)
				client.screen |= screen
			else
				client.screen -= screen

/atom/movable/screen/fullscreen
	icon = 'icons/hud/screen_full.dmi'
	icon_state = "default"
	screen_loc = "CENTER-7,CENTER-7"
	layer = FULLSCREEN_LAYER
	plane = FULLSCREEN_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/view = 7
	var/severity = 0
	var/show_when_dead = FALSE

/atom/movable/screen/fullscreen/proc/update_for_view(client_view)
	if (screen_loc == "CENTER-7,CENTER-7" && view != client_view)
		var/list/actualview = getviewsize(client_view)
		view = client_view
		transform = matrix(actualview[1]/FULLSCREEN_OVERLAY_RESOLUTION_X, 0, 0, 0, actualview[2]/FULLSCREEN_OVERLAY_RESOLUTION_Y, 0)

/atom/movable/screen/fullscreen/proc/should_show_to(mob/mymob)
	if(!show_when_dead && mymob.stat == DEAD)
		return FALSE
	return TRUE

/atom/movable/screen/fullscreen/Destroy()
	severity = 0
	. = ..()

/atom/movable/screen/fullscreen/emergency_meeting
	icon_state = "emergency_meeting"
	show_when_dead = TRUE
	layer = CURSE_LAYER
	plane = SPLASHSCREEN_PLANE

/atom/movable/screen/fullscreen/brute
	icon_state = "brutedamageoverlay"
	layer = UI_DAMAGE_LAYER
	plane = FULLSCREEN_PLANE

/atom/movable/screen/fullscreen/oxy
	icon_state = "oxydamageoverlay"
	layer = UI_DAMAGE_LAYER
	plane = FULLSCREEN_PLANE

/atom/movable/screen/fullscreen/crit
	icon_state = "passage"
	layer = CRIT_LAYER
	plane = FULLSCREEN_PLANE

/atom/movable/screen/fullscreen/crit/vision
	icon_state = "oxydamageoverlay"
	layer = BLIND_LAYER

/atom/movable/screen/fullscreen/blind
	icon_state = "blackimageoverlay"
	layer = BLIND_LAYER
	plane = FULLSCREEN_PLANE

/atom/movable/screen/fullscreen/blind/blinder
	icon_state = "blackerimageoverlay"
	layer = BLIND_LAYER + 0.01
	plane = FULLSCREEN_PLANE

/atom/movable/screen/fullscreen/curse
	icon_state = "curse"
	layer = CURSE_LAYER
	plane = FULLSCREEN_PLANE

/atom/movable/screen/fullscreen/curse/bloodlust

/atom/movable/screen/fullscreen/curse/bloodlust/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	color = color_matrix_rotate_hue(90)

/atom/movable/screen/fullscreen/ivanov_display
	icon_state = "ivanov"
	alpha = 180

/atom/movable/screen/fullscreen/impaired
	icon_state = "impairedoverlay"

/atom/movable/screen/fullscreen/flash
	icon = 'icons/hud/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "flash"

/atom/movable/screen/fullscreen/flash/over_blind
	layer = FOV_EFFECTS_LAYER

/atom/movable/screen/fullscreen/flash/black
	icon = 'icons/hud/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "black"

/atom/movable/screen/fullscreen/flash/static
	icon = 'icons/hud/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "noise"

/atom/movable/screen/fullscreen/high
	icon = 'icons/hud/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "druggy"

/atom/movable/screen/fullscreen/color_vision
	icon = 'icons/hud/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "flash"
	alpha = 80

/atom/movable/screen/fullscreen/bluespace_sparkle
	icon = 'icons/effects/effects.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "shieldsparkles"
	layer = FLASH_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	show_when_dead = TRUE

/atom/movable/screen/fullscreen/color_vision/green
	color = "#00ff00"

/atom/movable/screen/fullscreen/color_vision/red
	color = "#ff0000"

/atom/movable/screen/fullscreen/color_vision/blue
	color = "#0000ff"

/atom/movable/screen/fullscreen/cinematic_backdrop
	icon = 'icons/hud/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "flash"
	plane = SPLASHSCREEN_PLANE
	layer = CINEMATIC_LAYER
	color = "#000000"
	show_when_dead = TRUE

/atom/movable/screen/fullscreen/lighting_backdrop
	icon = 'icons/hud/screen_gen.dmi'
	icon_state = "flash"
	transform = matrix(200, 0, 0, 0, 200, 0)
	plane = LIGHTING_PLANE
	blend_mode = BLEND_OVERLAY
	show_when_dead = TRUE

//Provides darkness to the back of the lighting plane
/atom/movable/screen/fullscreen/lighting_backdrop/lit
	invisibility = INVISIBILITY_LIGHTING
	layer = BACKGROUND_LAYER+21
	color = "#000"
	show_when_dead = TRUE

//Provides whiteness in case you don't see lights so everything is still visible
/atom/movable/screen/fullscreen/lighting_backdrop/unlit
	layer = BACKGROUND_LAYER+20
	show_when_dead = TRUE

/atom/movable/screen/fullscreen/see_through_darkness
	icon_state = "nightvision"
	plane = LIGHTING_PLANE
	blend_mode = BLEND_ADD
	show_when_dead = TRUE
	alpha = 64 //Spooky darkness

/atom/movable/screen/fullscreen/bluespace_overlay
	icon = 'icons/effects/effects.dmi'
	icon_state = "mfoam"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	alpha = 80
	color = "#000050"
	blend_mode = BLEND_ADD

/atom/movable/screen/fullscreen/dither
	icon = 'goon/icons/hud/dither.dmi'
	icon_state = "dither"
	layer = DITHER_LAYER
	show_when_dead = TRUE
	screen_loc = "WEST,SOUTH to EAST,NORTH"


/atom/movable/screen/fullscreen/directional
	var/mob/owner

/atom/movable/screen/fullscreen/directional/proc/set_owner(mob/new_owner)
	if(owner)
		UnregisterSignal(owner, COMSIG_ATOM_DIR_CHANGE)

	owner = new_owner
	if(owner)
		RegisterSignal(owner, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_owner_dir_change))
		dir = owner.dir

/atom/movable/screen/fullscreen/directional/proc/on_owner_dir_change(atom/source, old_dir, new_dir)
	SIGNAL_HANDLER
	dir = new_dir

/atom/movable/screen/fullscreen/directional/Destroy()
	if(owner)
		UnregisterSignal(owner, COMSIG_ATOM_DIR_CHANGE)
		owner = null
	return ..()

/atom/movable/screen/fullscreen/directional/fov
	icon = 'icons/vision_cone.dmi'
	icon_state = "combat"
	var/image/blocker_overlay

/atom/movable/screen/fullscreen/directional/fov/set_owner(mob/new_owner)
	. = ..()
	if(!blocker_overlay)
		blocker_overlay = image(icon, src, "[icon_state]_v")
		blocker_overlay.plane = VISION_BLOCKER_PLANE
		blocker_overlay.override = TRUE
		overlays += blocker_overlay

/atom/movable/screen/fullscreen/directional/fov/on_owner_dir_change(atom/source, old_dir, new_dir)
	. = ..()
	if(blocker_overlay)
		blocker_overlay.dir = new_dir

/atom/movable/screen/fullscreen/directional/fov/Destroy()
	blocker_overlay = null
	return ..()

/mob/verb/test_fov_overlay()
	set name = "Test FOV Overlay"
	set category = "Debug"

	overlay_fullscreen("fov_test", /atom/movable/screen/fullscreen/directional/fov)
	to_chat(src, "<span class='notice'>FOV overlay applied. Use 'Clear FOV Overlay' to remove.</span>")

/mob/verb/clear_fov_overlay()
	set name = "Clear FOV Overlay"
	set category = "Debug"

	clear_fullscreen("fov_test")
	to_chat(src, "<span class='notice'>FOV overlay cleared.</span>")
