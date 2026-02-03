/// Campaign serialization helpers
/// Handles saving/loading of atoms with var state preservation

/// List of vars that are ALWAYS skipped during serialization (system/internal vars)
GLOBAL_LIST_INIT(campaign_skip_vars, list(
	"type", "parent_type", "tag", "vars", "x", "y", "z", "loc", "contents",
	"verbs", "filters", "appearance", "vis_contents", "vis_locs",
	"overlays", "underlays", "alpha", "color", "layer", "plane",
	"pixel_x", "pixel_y", "pixel_w", "pixel_z", "maptext", "maptext_x",
	"maptext_y", "maptext_width", "maptext_height", "render_target",
	"mouse_opacity", "mouse_drag_pointer", "mouse_drop_pointer",
	"mouse_drop_zone", "mouse_over_pointer", "screen_loc", "transform",
	"vis_flags", "luminosity", "infra_luminosity", "opacity", "icon",
	"icon_state", "dir", "density", "suffix", "name", "desc", "animate_movement"
))

/// Serialize an atom to a list using atom-defined save data
/proc/campaign_serialize_atom(atom/A)
	if(!A || !isatom(A))
		return null

	// Check persistence flags
	if(A.persistence_flags & NO_PERSIST)
		return null

	var/list/data = list()
	data["type"] = "[A.type]"
	data["x"] = A.x
	data["y"] = A.y
	data["z"] = A.z

	// Limited persist only saves location
	if(A.persistence_flags & LIMITED_PERSIST)
		return data

	// Get custom save data from the atom itself
	var/list/custom_data = A.get_campaign_save_data()
	if(length(custom_data))
		data["vars"] = custom_data

	// Handle storage contents recursively
	if(isitem(A))
		var/obj/item/I = A
		if(I.atom_storage)
			var/list/contents_data = list()
			for(var/obj/item/stored in I.contents)
				var/stored_data = campaign_serialize_atom(stored)
				if(stored_data)
					contents_data += list(stored_data)
			if(length(contents_data))
				data["contents"] = contents_data

	// Track made_by for player structures
	if(A.made_by)
		data["made_by"] = A.made_by

	return data

/// Deserialize an atom from saved data
/proc/campaign_deserialize_atom(list/data, atom/target_loc = null)
	if(!islist(data) || !data["type"])
		return null

	var/atom_type = text2path(data["type"])
	if(!atom_type)
		return null

	// Determine spawn location
	var/atom/spawn_loc = target_loc
	if(!spawn_loc && data["x"] && data["y"] && data["z"])
		spawn_loc = locate(data["x"], data["y"], data["z"])

	if(!spawn_loc)
		return null

	// Create the atom
	var/atom/A = new atom_type(spawn_loc)
	if(!A)
		return null

	// Apply saved vars via the atom's load proc
	if(data["vars"])
		A.apply_campaign_save_data(data["vars"])

	// Restore made_by
	if(data["made_by"])
		A.made_by = data["made_by"]

	// Restore storage contents recursively
	if(data["contents"] && isitem(A))
		var/obj/item/I = A
		if(I.atom_storage)
			for(var/list/stored_data in data["contents"])
				var/obj/item/stored = campaign_deserialize_atom(stored_data, I)
				if(stored)
					I.atom_storage.attempt_insert(stored, null, TRUE, TRUE)

	return A

/// Serialize a door's state (open/close, bolts, wires)
/proc/campaign_serialize_door(obj/machinery/door/D)
	if(!D || !istype(D))
		return null

	var/list/data = list()
	data["type"] = "[D.type]"
	data["x"] = D.x
	data["y"] = D.y
	data["z"] = D.z
	data["density"] = D.density // open/closed

	// Airlock-specific data
	if(istype(D, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/AL = D
		data["locked"] = AL.locked
		data["welded"] = AL.welded

		// Wire states
		if(AL.wires)
			var/list/wire_data = list()
			for(var/wire_type in AL.wires.wires)
				wire_data["[wire_type]"] = AL.wires.is_cut(wire_type)
			data["wires"] = wire_data

	return data

/// Deserialize a door's state
/proc/campaign_deserialize_door(obj/machinery/door/D, list/data)
	if(!D || !istype(D) || !islist(data))
		return FALSE

	// Apply open/closed state
	if(data["density"])
		if(!D.density)
			D.close()
	else
		if(D.density)
			D.open()

	// Airlock-specific
	if(istype(D, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/AL = D

		if(data["locked"])
			AL.bolt()
		else
			AL.unbolt()

		if(data["welded"])
			AL.welded = TRUE
			AL.update_appearance()

		// Restore wire states
		if(data["wires"] && AL.wires)
			var/list/wire_data = data["wires"]
			for(var/wire_name in wire_data)
				var/wire_type = text2path(wire_name)
				if(wire_type && wire_data[wire_name])
					AL.wires.cut(wire_type)

	return TRUE
