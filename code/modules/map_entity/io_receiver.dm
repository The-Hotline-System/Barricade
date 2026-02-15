GLOBAL_LIST_EMPTY(io_entities_by_name)

/atom
	// IO Registration
/atom/proc/IO_register()
	if(!targetname)
		return
	var/key = lowertext(targetname)
	LAZYINITLIST(GLOB.io_entities_by_name[key])
	GLOB.io_entities_by_name[key] += src

/atom/proc/IO_unregister()
	if(!targetname)
		return
	var/key = lowertext(targetname)
	if(GLOB.io_entities_by_name[key])
		GLOB.io_entities_by_name[key] -= src
		if(!length(GLOB.io_entities_by_name[key]))
			GLOB.io_entities_by_name -= key

/atom/proc/IO_parse_connections()
	io_parsed_connections = list()

	if(connections_string)
		var/list/string_conns = splittext(connections_string, ";")
		for(var/s in string_conns)
			if(s)
				if(!io_connections)
					io_connections = list()
				io_connections += s

	if(!io_connections)
		return

	for(var/conn in io_connections)
		if(isnull(conn)) continue

		if(istext(conn))
			var/list/parts = splittext(conn, ":")
			if(length(parts) >= 3)
				var/output_name = parts[1]
				var/target = parts[2]
				var/input = parts[3]
				var/delay = length(parts) >= 4 ? text2num(parts[4]) : 0
				var/param = length(parts) >= 5 ? parts[5] : null
				LAZYINITLIST(io_parsed_connections[output_name])
				io_parsed_connections[output_name] += list(list(
					"target" = target,
					"input" = input,
					"delay" = delay,
					"param" = param
				))
		else if(islist(conn))
			var/list/C = conn
			var/output_name = C["output"]
			if(output_name)
				LAZYINITLIST(io_parsed_connections[output_name])
				io_parsed_connections[output_name] += list(list(
					"target" = C["target"],
					"input" = C["input"],
					"delay" = C["delay"] || 0,
					"param" = C["param"]
				))

/atom/proc/IO_fire_output(output_name, atom/activator, atom/caller)
	if(!io_enabled || !io_parsed_connections || !io_parsed_connections[output_name])
		return

	if(!caller)
		caller = src

	for(var/list/conn in io_parsed_connections[output_name])
		var/target_name = conn["target"]
		var/input_name = conn["input"]
		var/delay = conn["delay"]
		var/param = conn["param"]
		var/list/params = param ? list("value" = param) : null

		var/list/targets = find_io_targets(target_name)
		for(var/atom/target in targets)
			if(delay > 0)
				spawn(delay)
					if(target && !QDELETED(target))
						send_io_input(target, input_name, activator, caller, params)
			else
				send_io_input(target, input_name, activator, caller, params)

/atom/proc/IO_receive_input(input_name, atom/activator, atom/caller, list/params)
	SEND_SIGNAL(src, COMSIG_MOVABLE_IO_RECEIVE, input_name, activator, caller, params)
	return FALSE

// Helpers

/proc/IO_output(connection_string, atom/activator, atom/caller)
	var/list/parts = splittext(connection_string, ":")
	if(length(parts) < 2)
		return
	var/target_name = parts[1]
	var/input_name = parts[2]
	var/param = (length(parts) >= 3) ? parts[3] : null
	var/list/params = param ? list("value" = param) : null

	var/list/targets = find_io_targets(target_name)
	for(var/atom/target in targets)
		send_io_input(target, input_name, activator, caller, params)

/proc/send_io_input(atom/target, input_name, atom/activator, atom/caller, list/params)
	if(istype(target, /obj/effect/map_entity))
		var/obj/effect/map_entity/ME = target
		return ME.receive_input(input_name, activator, caller, params)
	else
		return target.IO_receive_input(input_name, activator, caller, params)

/proc/find_io_targets(target_name)
	if(!target_name)
		return list()
	var/key = lowertext(target_name)
	return GLOB.io_entities_by_name[key] || list()

// Legacy compat or if we need a short-hand
/proc/find_map_entities(target_name)
	return find_io_targets(target_name)
