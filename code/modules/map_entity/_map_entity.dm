// Obsolete, moved to io_receiver.dm

// Debug mode - set to 1 to enable visual feedback and logging
#define MAP_ENTITY_DEBUG 0

// Debug flash colors
#define MAP_ENTITY_COLOR_OUTPUT "#00ff73"  // Green - sending output
#define MAP_ENTITY_COLOR_INPUT "#ffae00"   // Yellow - receiving input
#define MAP_ENTITY_COLOR_SEQUENCE "#FF00FF" // Purple - executing sequence

/obj/effect/map_entity
	name = "map_entity"
	desc = "A map entity for level scripting."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "landmark2"
	anchored = TRUE
	density = FALSE
	var/start_disabled = FALSE
	var/is_brush = FALSE
	var/list/brush_neighbors

// Flash the entity with a debug color briefly
/atom/proc/debug_flash(flash_color)
#if MAP_ENTITY_DEBUG
	var/debug_old_color = color
	animate(src, color = flash_color, time = 0.5)
	animate(color = debug_old_color, time = 5)
#endif

// Log debug message to admins
/obj/effect/map_entity/proc/debug_log(message)
#if MAP_ENTITY_DEBUG
	message_admins("MapEntity [src] ([targetname]) [message]")
#endif

/obj/effect/map_entity/ex_act()
	return FALSE

/obj/effect/map_entity/Initialize()
	. = ..()
	if(!MAP_ENTITY_DEBUG && !is_type_in_list(src, list(/obj/effect/map_entity/fire_pit))) // weather_mask was in this list.
		invisibility = 101

	if(start_disabled)
		io_enabled = FALSE
	if(is_brush)
		spawn(1)
			connect_brush_neighbors()
	spawn(2)
		IO_fire_output("OnSpawn", null, src)

/obj/effect/map_entity/Destroy()
	IO_unregister()
	if(brush_neighbors)
		for(var/obj/effect/map_entity/E in brush_neighbors)
			LAZYREMOVE(E.brush_neighbors, src)
		brush_neighbors = null
	return ..()

/obj/effect/map_entity/proc/fire_output(output_name, atom/activator, atom/caller)
	IO_fire_output(output_name, activator, caller)

	if(is_brush && brush_neighbors)
		for(var/obj/effect/map_entity/neighbor in brush_neighbors)
			neighbor.fire_output_local(output_name, activator, caller)

/obj/effect/map_entity/proc/fire_output_local(output_name, atom/activator, atom/caller)
	IO_fire_output(output_name, activator, caller)

/*
Inputs:
Enable - Enables the entity
Disable - Disables the entity
Toggle - Toggles the enabled state
Kill - Deletes the entity

Outputs:
OnSpawn - Fired when the entity initializes
*/
/obj/effect/map_entity/proc/receive_input(input_name, atom/activator, atom/caller, list/params)
	. = IO_receive_input(input_name, activator, caller, params)
	if(input_name != "OnSpawn")
		debug_flash(MAP_ENTITY_COLOR_INPUT)
		debug_log("received input: [input_name] from [caller]")


	if(!io_enabled && input_name != "Enable")
		return FALSE

	switch(lowertext(input_name))
		if("enable")
			io_enabled = TRUE
			return TRUE
		if("disable")
			io_enabled = FALSE
			return TRUE
		if("toggle")
			io_enabled = !io_enabled
			return TRUE
		if("kill")
			qdel(src)
			return TRUE
	return FALSE

/obj/effect/map_entity/proc/connect_brush_neighbors()
	if(!is_brush || !name)
		return
	LAZYINITLIST(brush_neighbors)
	for(var/dir in ALL_CARDINALS)
		var/turf/T = get_step(src, dir)
		if(!T)
			continue
		for(var/obj/effect/map_entity/E in T)
			if(E == src || !E.is_brush)
				continue
			if(lowertext(E.name) != lowertext(name))
				continue
			brush_neighbors |= E
			LAZYINITLIST(E.brush_neighbors)
			E.brush_neighbors |= src

/obj/effect/map_entity/proc/add_connection(output_name, target_name, input_name, delay = 0)
	LAZYINITLIST(io_parsed_connections[output_name])
	io_parsed_connections[output_name] += list(list(
		"target" = target_name,
		"input" = input_name,
		"delay" = delay
	))

/obj/effect/map_entity/proc/clear_connections(output_name)
	if(io_parsed_connections)
		io_parsed_connections -= output_name

/obj/effect/map_entity/proc/get_entity_info()
	return "[type] (targetname: [targetname], enabled: [io_enabled], brush: [is_brush])"
