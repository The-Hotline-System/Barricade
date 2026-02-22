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


// Screen-based FOV cone holder that tracks mob position via pixel offsets
/atom/movable/screen/fov_cone_holder
	icon = null
	screen_loc = "CENTER-7,CENTER-7"
	plane = FULLSCREEN_PLANE
	layer = FULLSCREEN_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

	/// The mob we're following
	var/mob/follow_target
	/// The FOV cone visual container
	var/atom/movable/screen/fov_cone_container/container

/atom/movable/screen/fov_cone_holder/Initialize(mapload)
	. = ..()
	// Create the container that holds the actual visuals
	container = new(src)
	vis_contents += container

// Container for the actual FOV visuals - this is what gets transformed
/atom/movable/screen/fov_cone_container
	icon = 'icons/vision_cone.dmi'
	icon_state = ""
	plane = FULLSCREEN_PLANE
	layer = FULLSCREEN_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	// Prevent vis_contents from inheriting this holder's plane
	vis_flags = VIS_INHERIT_ID | VIS_INHERIT_LAYER

	/// The FOV cone visual
	var/atom/movable/screen/fov_cone/cone
	/// The vision blocker visual
	var/atom/movable/screen/fov_blocker/blocker
	/// The FOV exclusion visual (prevents mob from being masked)
	var/atom/movable/screen/fov_exclusion/exclusion

/atom/movable/screen/fov_cone_container/Initialize(mapload)
	. = ..()
	// Create the cone and blocker as children
	cone = new(src)
	blocker = new(src)
	exclusion = new(src)
	vis_contents += cone
	vis_contents += blocker
	vis_contents += exclusion

/atom/movable/screen/fov_cone_container/Destroy()
	if(cone)
		qdel(cone)
		cone = null
	if(blocker)
		qdel(blocker)
		blocker = null
	if(exclusion)
		qdel(exclusion)
		exclusion = null
	return ..()

/atom/movable/screen/fov_cone_container/proc/update_dir(new_dir)
	if(cone)
		cone.dir = new_dir
	if(blocker)
		blocker.dir = new_dir

/atom/movable/screen/fov_cone_container/proc/hide(animation_time = 5)
	if(cone)
		animate(cone, alpha = 0, time = animation_time)
	if(blocker)
		animate(blocker, alpha = 0, time = animation_time)

/atom/movable/screen/fov_cone_container/proc/show(animation_time = 1)
	if(cone)
		animate(cone, alpha = 255, time = animation_time)
	if(blocker)
		animate(blocker, alpha = 255, time = animation_time)

/atom/movable/screen/fov_cone_container/proc/update(new_icon_state)
	if(cone)
		cone.icon_state = new_icon_state
	if(blocker)
		blocker.icon_state = "[new_icon_state]_v"

/atom/movable/screen/fov_cone_holder/proc/set_follow_target(mob/target)
	if(follow_target)
		UnregisterSignal(follow_target, list(COMSIG_MOVABLE_MOVED, COMSIG_ATOM_DIR_CHANGE))

	follow_target = target

	if(follow_target)
		RegisterSignal(follow_target, COMSIG_MOVABLE_MOVED, PROC_REF(on_target_moved))
		RegisterSignal(follow_target, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_target_dir_change))
		update_position()
		update_dir(follow_target.dir)

/atom/movable/screen/fov_cone_holder/proc/on_target_moved(atom/movable/source, atom/oldloc, direction, forced)
	SIGNAL_HANDLER
	update_position()

/atom/movable/screen/fov_cone_holder/proc/on_target_dir_change(atom/source, old_dir, new_dir)
	SIGNAL_HANDLER
	update_dir(new_dir)

/atom/movable/screen/fov_cone_holder/proc/update_position()
	if(!follow_target?.client || !container)
		return

	// Don't update position if distance looking is active (living mobs only)
	if(isliving(follow_target))
		var/mob/living/L = follow_target
		if(L.look_updown)
			return

	// Calculate offset: mob pixel position minus client view offset
	// This keeps the cone centered on the mob regardless of view shifts
	container.pixel_x = follow_target.pixel_x - follow_target.client.pixel_x
	container.pixel_y = follow_target.pixel_y - follow_target.client.pixel_y

/atom/movable/screen/fov_cone_holder/proc/animate_position(client_target_x, client_target_y, time, easing)
	if(!follow_target?.client || !container)
		return

	// Calculate the container offset using the same logic as update_position
	// Container offset = mob pixel position - client view offset
	var/target_x = follow_target.pixel_x - client_target_x
	var/target_y = follow_target.pixel_y - client_target_y

	animate(container, pixel_x = target_x, pixel_y = target_y, time = time, easing = easing)

/atom/movable/screen/fov_cone_holder/proc/update_dir(new_dir)
	if(container)
		container.update_dir(new_dir)

/atom/movable/screen/fov_cone_holder/proc/hide(animation_time = 5)
	if(container)
		container.hide(animation_time)

/atom/movable/screen/fov_cone_holder/proc/show(animation_time = 1)
	if(container)
		container.show(animation_time)

/atom/movable/screen/fov_cone_holder/proc/update(new_icon_state)
	if(container)
		container.update(new_icon_state)

/atom/movable/screen/fov_cone_holder/Destroy()
	if(follow_target)
		UnregisterSignal(follow_target, list(COMSIG_MOVABLE_MOVED, COMSIG_ATOM_DIR_CHANGE))
		follow_target = null
	if(container)
		qdel(container)
		container = null
	return ..()

// The actual FOV cone visual (screen object)
/atom/movable/screen/fov_cone
	icon = 'icons/vision_cone.dmi'
	icon_state = "combat"
	plane = FULLSCREEN_PLANE
	layer = FULLSCREEN_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_ID | VIS_INHERIT_LAYER

// The vision blocker overlay (screen object)
/atom/movable/screen/fov_blocker
	icon = 'icons/vision_cone.dmi'
	icon_state = "combat_v"
	plane = VISION_BLOCKER_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_ID | VIS_INHERIT_LAYER

// Screen object for FOV exclusion - prevents mob from being masked by FOV
/atom/movable/screen/fov_exclusion
	icon = 'icons/exclude.dmi'
	icon_state = "exclude"
	plane = VISION_EXCLUSION_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_ID | VIS_INHERIT_LAYER
