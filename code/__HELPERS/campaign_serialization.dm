/// Campaign serialization helpers
/// Handles saving/loading of atoms with var state preservation

/// List of vars that are ALWAYS skipped during serialization (system/internal vars)
/// List of vars that are ALWAYS skipped during serialization (system/internal vars)
GLOBAL_LIST_INIT(campaign_skip_vars, list(
	"type", "parent_type", "tag", "vars", "x", "y", "z", "loc", "contents",
	"verbs", "filters", "appearance", "vis_contents", "vis_locs",
	"overlays", "underlays", "layer", "plane",
	"pixel_x", "pixel_y", "pixel_w", "pixel_z", "maptext", "maptext_x",
	"maptext_y", "maptext_width", "maptext_height", "render_target",
	"mouse_opacity", "mouse_drag_pointer", "mouse_drop_pointer",
	"mouse_drop_zone", "mouse_over_pointer", "screen_loc", "transform",
	"vis_flags", "luminosity", "infra_luminosity", "opacity", "suffix", "animate_movement",
	"persistence_flags", "campaign_id", "made_by", "last_touched", "initialized",
	"needs_init", "fingerprints", "fingerprintshistory", "fingerprintslast",
	"fingerprintscount", "blood_DNA", "loc_connections", "comp_lookup",
	"signal_procs", "datum_components", "active_timers", "datum_flags",
	"light_system", "light_range", "light_power", "light_color", "light_on",
	"light_flags", "light_sources", "alternate_appearances", "managed_vis_contents",
	"area_attribute", "smoothing_flags", "smoothing_groups", "can_smooth_with",
	"block_air_zones", "can_be_unanchored", "damtype", "force", "flags_1",
	"flags_2", "flags_3", "item_flags", "obj_flags", "machine_flags",
	"mob_flags", "resistance_flags", "pass_flags"
))

/// Generate a deterministic signature for an atom based on type, position, and campaign seed
/proc/get_atom_signature(atom/A)
	if(!A)
		return null
	return "[A.type]_[A.x]_[A.y]_[A.z]_[SScampaign.campaign_seed]"


/// Serialize an atom to a list using atom-defined save data
/proc/campaign_serialize_atom(atom/A, ignore_persistence = FALSE)
	if(!CONFIG_GET(flag/campaign_enabled))
		return null
	if(!A || !isatom(A))
		return null

	// Check persistence flags
	if(!ignore_persistence && (A.persistence_flags & NO_PERSIST))
		return null

	// Assign a campaign ID if needed (for tracking)
	SScampaign.assign_campaign_id(A)

	var/list/data = list()
	data["t"] = "[A.type]" // type
	data["x"] = A.x
	data["y"] = A.y
	data["z"] = A.z
	data["cid"] = A.campaign_id // Campaign ID for tracking
	data["sig"] = get_atom_signature(A) // Deterministic signature for comparison

	// Limited persist only saves location
	if(A.persistence_flags & LIMITED_PERSIST)
		return data

	// For items, use compact logic for name/desc
	if(isitem(A))
		var/obj/item/I = A
		if(I.name != initial(I.name))
			data["n"] = I.name
		if(I.desc != initial(I.desc))
			data["d"] = I.desc

	// Get custom save data from the atom itself
	var/list/custom_data = A.get_campaign_save_data()
	if(length(custom_data))
		data["v"] = custom_data // vars

	// Handle storage contents recursively
	if(isitem(A))
		var/obj/item/I = A
		if(I.atom_storage)
			var/list/contents_data = list()
			for(var/obj/item/CI in A.contents)
				var/stored_data = campaign_serialize_atom(CI, ignore_persistence)
				if(stored_data)
					contents_data += list(stored_data)
			if(length(contents_data))
				data["c"] = contents_data // contents

	// Track made_by for player structures
	if(A.made_by)
		data["m"] = A.made_by

	return data

/// Deserialize an atom from saved data
/proc/campaign_deserialize_atom(list/data, atom/target_loc = null)
	if(!islist(data))
		return null
	
	// Support both long and short keys for backward compatibility
	var/type_str = data["t"] || data["type"]
	if(!type_str)
		return null

	// Check if this campaign ID was deleted
	var/saved_cid = data["cid"]
	if(saved_cid && SScampaign.is_deleted(saved_cid))
		return null // Don't respawn deleted items

	// Check if an atom with this campaign ID already exists (moved from DMM position)
	if(saved_cid)
		var/atom/movable/existing = SScampaign.find_by_campaign_id(saved_cid)
		if(existing && !QDELETED(existing))
			// Update existing atom's position and state instead of creating duplicate
			var/atom/spawn_loc = target_loc
			var/dx = data["x"]
			var/dy = data["y"]
			var/dz = data["z"]
			if(!spawn_loc && !isnull(dx) && !isnull(dy) && !isnull(dz))
				spawn_loc = locate(dx, dy, dz)
			
			if(spawn_loc && spawn_loc != existing.loc)
				existing.forceMove(spawn_loc)
			
			// Apply saved vars
			var/vars_data = data["v"] || data["vars"]
			if(vars_data)
				existing.apply_campaign_save_data(vars_data)
			return existing

	var/atom_type = text2path(type_str)
	if(!atom_type)
		return null

	// Determine spawn location
	var/atom/spawn_loc = target_loc
	var/dx = data["x"]
	var/dy = data["y"]
	var/dz = data["z"]
	if(!spawn_loc && !isnull(dx) && !isnull(dy) && !isnull(dz))
		spawn_loc = locate(dx, dy, dz)

	if(!spawn_loc)
		log_world("CAMPAIGN: Failed to find spawn location for [type_str] at [dx],[dy],[dz]")
		return null

	// Duplicate Map Item Check: Claim items already on the map (from .dmm)
	if(istype(spawn_loc, /turf))
		for(var/atom/movable/AM in spawn_loc)
			if(AM.type == atom_type && !AM.campaign_id)
				// Found a matching map item! Claim it instead of spawning a duplicate.
				AM.campaign_id = saved_cid
				SScampaign.register_campaign_atom(AM)
				
				var/vars_data = data["v"] || data["vars"]
				if(vars_data)
					AM.apply_campaign_save_data(vars_data)
				return AM

	// Create the atom
	var/atom/A = new atom_type(spawn_loc)
	if(!A)
		log_world("CAMPAIGN: Failed to instantiate [atom_type] at [spawn_loc.x],[spawn_loc.y],[spawn_loc.z]")
		return null

	// Restore campaign ID if saved
	if(saved_cid)
		A.campaign_id = saved_cid
		SScampaign.register_campaign_atom(A)
		// Update next_campaign_id to avoid collisions
		if(saved_cid >= SScampaign.next_campaign_id)
			SScampaign.next_campaign_id = saved_cid + 1

	// Restore name/desc if saved (for items)
	if(data["n"])
		A.name = data["n"]
	if(data["d"])
		A.desc = data["d"]

	// Apply saved vars via the atom's load proc
	var/vars_data = data["v"] || data["vars"]
	if(vars_data)
		A.apply_campaign_save_data(vars_data)

	// Restore made_by
	var/m_ckey = data["m"] || data["made_by"]
	if(m_ckey)
		A.made_by = m_ckey

	// Restore storage contents recursively
	var/contents_data = data["c"] || data["contents"]
	if(contents_data && isitem(A))
		var/obj/item/I = A
		if(I.atom_storage)
			for(var/list/stored_data in contents_data)
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

// ============= COMPACT SERIALIZATION =============

/// Serialize an item more compactly - only save vars that differ from initial
/proc/campaign_serialize_compact(obj/item/I, ignore_persistence = FALSE)
	if(!I || !isitem(I))
		return null
	if(!ignore_persistence && (I.persistence_flags & NO_PERSIST))
		return null

	var/list/data = list()
	data["t"] = "[I.type]" // type

	// Only save name if it differs from initial
	if(I.name != initial(I.name))
		data["n"] = I.name

	// Only save desc if it differs
	if(I.desc != initial(I.desc))
		data["d"] = I.desc

	// Save custom save data
	var/list/custom = I.get_campaign_save_data()
	if(length(custom))
		data["v"] = custom // vars

	// Handle storage contents recursively
	if(I.atom_storage)
		var/list/contents_data = list()
		for(var/obj/item/stored in I.contents)
			var/stored_data = campaign_serialize_compact(stored, ignore_persistence)
			if(stored_data)
				contents_data += list(stored_data)
		if(length(contents_data))
			data["c"] = contents_data // contents

	if(I.made_by)
		data["m"] = I.made_by

	if(I.campaign_id)
		data["cid"] = I.campaign_id

	return data

/// Deserialize an item from compact format
/proc/campaign_deserialize_compact(list/data, atom/target_loc)
	if(!islist(data) || !data["t"])
		return null

	var/atom_type = text2path(data["t"])
	if(!atom_type)
		return null

	var/obj/item/I = new atom_type(target_loc)
	if(!I)
		return null

	// Restore name/desc if saved
	if(data["n"])
		I.name = data["n"]
	if(data["d"])
		I.desc = data["d"]

	// Restore campaign ID if saved
	if(data["cid"])
		I.campaign_id = data["cid"]
		SScampaign.register_campaign_atom(I)
		if(I.campaign_id >= SScampaign.next_campaign_id)
			SScampaign.next_campaign_id = I.campaign_id + 1

	// Apply custom vars
	if(data["v"])
		I.apply_campaign_save_data(data["v"])

	// Restore made_by
	if(data["m"])
		I.made_by = data["m"]

	// Restore storage contents
	if(data["c"] && I.atom_storage)
		for(var/list/stored_data in data["c"])
			var/obj/item/stored = campaign_deserialize_compact(stored_data, I)
			if(stored)
				I.atom_storage.attempt_insert(stored, null, TRUE, TRUE)

	return I

// ============= WOUND SERIALIZATION =============

/// Serialize a wound datum to a compact list
/proc/campaign_serialize_wound(datum/wound/W)
	if(!W)
		return null

	var/list/data = list()
	data["wt"] = W.wound_type   // WOUND_CUT, WOUND_BURN, etc.
	data["dm"] = W.damage
	data["am"] = W.amount
	if(W.clamped)
		data["cl"] = 1
	if(W.salved)
		data["sv"] = 1
	if(W.disinfected)
		data["di"] = 1
	if(W.germ_level)
		data["gl"] = W.germ_level
	if(W.bleed_timer)
		data["bt"] = W.bleed_timer

	return data

/// Deserialize and create a wound on a bodypart
/proc/campaign_deserialize_wound(list/data, obj/item/bodypart/BP)
	if(!islist(data) || !data["wt"] || !BP)
		return null

	var/wound_type = data["wt"]
	var/damage = data["dm"] || 0

	// Get the proper wound type path
	var/wound_path = get_wound_type(wound_type, damage)
	if(!wound_path)
		return null

	// Create the wound with the saved damage
	var/datum/wound/W = new wound_path(damage, BP)
	if(!W)
		return null

	// Restore wound state
	if(data["am"])
		W.amount = data["am"]
	if(data["cl"])
		W.clamped = TRUE
	if(data["sv"])
		W.salved = TRUE
	if(data["di"])
		W.disinfected = TRUE
	if(data["gl"])
		W.germ_level = data["gl"]
	if(data["bt"])
		W.bleed_timer = data["bt"]

	// Add to the bodypart's wounds list
	LAZYADD(BP.wounds, W)
	BP.refresh_bleed_rate()

	return W

// ============= BODYPART SERIALIZATION =============

/// Serialize a bodypart with its wounds
/proc/campaign_serialize_bodypart(obj/item/bodypart/BP)
	if(!BP)
		return null

	var/list/data = list()
	data["z"] = BP.body_zone // zone
	data["br"] = BP.brute_dam
	data["bu"] = BP.burn_dam
	data["fl"] = BP.bodypart_flags

	// Serialize wounds
	if(LAZYLEN(BP.wounds))
		var/list/wound_data = list()
		for(var/datum/wound/W as anything in BP.wounds)
			var/w_data = campaign_serialize_wound(W)
			if(w_data)
				wound_data += list(w_data)
		if(length(wound_data))
			data["w"] = wound_data

	// Save splint if present
	if(BP.splint)
		data["sp"] = "[BP.splint.type]"

	// Save bandage if present
	if(BP.bandage)
		data["ba"] = "[BP.bandage.type]"

	return data

/// Apply saved bodypart data to an existing bodypart (does NOT replace the bodypart)
/proc/campaign_apply_bodypart_data(obj/item/bodypart/BP, list/data)
	if(!BP || !islist(data))
		return FALSE

	// Clear existing wounds first
	for(var/datum/wound/W in BP.wounds)
		qdel(W)
	LAZYCLEARLIST(BP.wounds)

	// Set damage values (wounds will add their own damage)
	// We'll rely on wound deserialization to set damage properly

	// Restore bodypart flags that should persist
	var/saved_flags = data["fl"]
	if(saved_flags)
		// Only restore certain flags that should persist (broken bones, etc)
		BP.bodypart_flags |= (saved_flags & (BP_BROKEN_BONES|BP_TENDON_CUT|BP_ARTERY_CUT|BP_CUT_AWAY))

	// Deserialize wounds
	if(data["w"])
		for(var/list/w_data in data["w"])
			campaign_deserialize_wound(w_data, BP)

	// Apply splint if saved
	if(data["sp"])
		var/splint_type = text2path(data["sp"])
		if(splint_type)
			var/obj/item/stack/splint = new splint_type()
			BP.apply_splint(splint)

	// Apply bandage if saved
	if(data["ba"])
		var/bandage_type = text2path(data["ba"])
		if(bandage_type)
			var/obj/item/stack/bandage = new bandage_type()
			BP.apply_bandage(bandage)

	BP.update_damage()
	BP.update_disabled()
	return TRUE

