/// Campaign Persistence Subsystem
/// Manages campaign state, paths, and persistent data.
SUBSYSTEM_DEF(campaign)
	name = "Campaign"
	init_order = INIT_ORDER_CAMPAIGN // Loads before mapping to prepare persistent seed
	flags = SS_NO_FIRE

	/// Current campaign name/ID
	var/campaign_name = "default"
	/// Maximum last-touched items to save per player
	var/last_touched_limit = 50
	/// Whether to save storage contents
	var/save_storage = TRUE
	/// Whether to save item vars
	var/save_item_vars = TRUE
	/// Whether to save player-made structures
	var/save_structures = TRUE
	/// Global permakill toggle - all deaths become permanent
	var/global_permakill = FALSE

	/// Base path for campaign data
	var/base_path = "data/campaign"

	/// Next unique campaign ID to assign
	var/next_campaign_id = 1
	/// List of campaign IDs that have been deleted (to prevent respawn)
	var/list/deleted_ids = list()
	/// Lookup table: campaign_id -> atom reference (for updating existing atoms)
	var/list/campaign_id_lookup = list()
	/// Prototype cache: typepath -> atom prototype (for default comparison)
	var/list/prototype_cache = list()
	/// Persistent seed for deterministic atom signatures
	var/campaign_seed
	/// Cache of saved atom signatures for comparison during map loading
	var/list/saved_signatures = list()
	/// Tracks which ckey+slot combos have been used this round (prevents double-join)
	var/list/slots_used_this_round = list()


/datum/controller/subsystem/campaign/Initialize()
	if(!CONFIG_GET(flag/campaign_enabled))
		log_world("CAMPAIGN: Disabled via config, skipping initialization.")
		return ..()
	load_config()
	RegisterSignal(SSmapping, COMSIG_GLOB_MAPPING_INITIALIZED, PROC_REF(on_mapping_initialized))
	return ..()

/// Handler for mapping initialization - triggers ground item loading
/datum/controller/subsystem/campaign/proc/on_mapping_initialized(datum/source)
	SIGNAL_HANDLER
	if(!CONFIG_GET(flag/campaign_enabled))
		return
	load_campaign_data()
	log_world("CAMPAIGN: Mapping initialized, loading persistence data.")

/datum/controller/subsystem/campaign/Shutdown()
	if(!CONFIG_GET(flag/campaign_enabled))
		return
	save_campaign_data()

/// Returns the full path for the current campaign
/datum/controller/subsystem/campaign/proc/get_campaign_path()
	return "[base_path]/[campaign_name]"

/// Returns the player save path for a ckey and slot
/datum/controller/subsystem/campaign/proc/get_player_path(ckey, slot)
	if(!ckey || !slot)
		return null
	var/first_letter = copytext(ckey, 1, 2)
	return "[get_campaign_path()]/players/[first_letter]/[ckey]/[slot]"

/// Returns the map save path for the current map
/datum/controller/subsystem/campaign/proc/get_map_path()
	var/map_name = SSmapping.config?.map_name || "unknown"
	return "[get_campaign_path()]/map/[map_name]"

/// Check if a player has saved data for a specific slot
/datum/controller/subsystem/campaign/proc/has_save(ckey, slot)
	var/player_path = get_player_path(ckey, slot)
	if(!player_path)
		return FALSE
	return fexists("[player_path]/pos.sav")

/// Assign a unique campaign ID to an atom if it doesn't have one
/datum/controller/subsystem/campaign/proc/assign_campaign_id(atom/A)
	if(!A)
		return
	if(A.campaign_id)
		return A.campaign_id // Already has an ID
	A.campaign_id = next_campaign_id++
	register_campaign_atom(A)
	return A.campaign_id

/// Register an atom in the lookup table
/datum/controller/subsystem/campaign/proc/register_campaign_atom(atom/A)
	if(!A?.campaign_id)
		return
	campaign_id_lookup["[A.campaign_id]"] = A

/// Unregister an atom from the lookup (call on destroy)
/datum/controller/subsystem/campaign/proc/unregister_campaign_atom(atom/A)
	if(!A?.campaign_id)
		return
	campaign_id_lookup -= "[A.campaign_id]"

/// Mark a campaign ID as deleted (so it won't respawn from saves)
/datum/controller/subsystem/campaign/proc/mark_deleted(campaign_id)
	if(!campaign_id)
		return
	deleted_ids["[campaign_id]"] = TRUE

/// Check if a campaign ID has been marked as deleted
/datum/controller/subsystem/campaign/proc/is_deleted(campaign_id)
	if(!campaign_id)
		return FALSE
	return deleted_ids["[campaign_id]"]

/// Find an existing atom by its campaign ID
/datum/controller/subsystem/campaign/proc/find_by_campaign_id(campaign_id)
	if(!campaign_id)
		return null
	return campaign_id_lookup["[campaign_id]"]

/// Get or create a prototype for a type (used for persistence comparison)
/datum/controller/subsystem/campaign/proc/get_prototype(atom_type)
	if(!atom_type)
		return null
	var/atom/P = prototype_cache[atom_type]
	if(!P)
		P = new atom_type(null)
		prototype_cache[atom_type] = P
	return P

/// Load campaign configuration (JSON format)
/datum/controller/subsystem/campaign/proc/load_config()
	var/config_path = "[base_path]/config.json"
	if(!fexists(config_path))
		// Generate new seed for fresh campaign
		campaign_seed = rand(1, 999999999)
		log_world("CAMPAIGN: No config found, generated new seed: [campaign_seed]")
		return

	var/json_text = file2text(config_path)
	if(!json_text)
		campaign_seed = rand(1, 999999999)
		return

	var/list/data = json_decode(json_text)
	if(!islist(data))
		campaign_seed = rand(1, 999999999)
		return

	campaign_name = data["campaign_name"] || campaign_name
	last_touched_limit = data["last_touched_limit"] || last_touched_limit
	save_storage = data["save_storage"] || save_storage
	save_item_vars = data["save_item_vars"] || save_item_vars
	save_structures = data["save_structures"] || save_structures
	global_permakill = data["global_permakill"] || global_permakill
	next_campaign_id = data["next_campaign_id"] || next_campaign_id
	campaign_seed = data["campaign_seed"] || rand(1, 999999999)

	var/list/saved_deleted = data["deleted_ids"]
	if(islist(saved_deleted))
		deleted_ids = saved_deleted

	log_world("CAMPAIGN: Loaded config with seed: [campaign_seed]")

/// Save campaign configuration (JSON format)
/datum/controller/subsystem/campaign/proc/save_config()
	var/config_path = "[base_path]/config.json"
	var/list/data = list(
		"campaign_name" = campaign_name,
		"last_touched_limit" = last_touched_limit,
		"save_storage" = save_storage,
		"save_item_vars" = save_item_vars,
		"save_structures" = save_structures,
		"global_permakill" = global_permakill,
		"next_campaign_id" = next_campaign_id,
		"campaign_seed" = campaign_seed,
		"deleted_ids" = deleted_ids
	)
	var/json_text = json_encode(data)
	fdel(config_path)
	text2file(json_text, config_path)

/// Load all campaign data (map + players)
/datum/controller/subsystem/campaign/proc/load_campaign_data()
	load_map_data()

/// Save all campaign data (map + players)
/datum/controller/subsystem/campaign/proc/save_campaign_data()
	save_config()
	save_map_data()
	save_all_player_data()

/// Load map persistence data
/datum/controller/subsystem/campaign/proc/load_map_data()
	var/map_path = get_map_path()
	if(!map_path)
		return

	load_structures(map_path)
	load_player_structures(map_path)
	load_turfs_changed(map_path)
	load_doors(map_path)
	load_items(map_path)
	load_storage(map_path)

/// Save map persistence data
/datum/controller/subsystem/campaign/proc/save_map_data()
	var/map_path = get_map_path()
	if(!map_path)
		return

	save_structures(map_path)
	save_player_structures(map_path)
	save_turfs_changed(map_path)
	save_doors(map_path)
	save_items(map_path)
	save_storage(map_path)

// ============= STRUCTURE PERSISTENCE =============

/datum/controller/subsystem/campaign/proc/load_structures(map_path)
	var/filepath = "[map_path]/structures.json"
	if(!fexists(filepath))
		return
	var/json_text = file2text(filepath)
	if(!json_text)
		return
	var/list/structure_data = json_decode(json_text)
	if(!islist(structure_data))
		return
	for(var/list/data in structure_data)
		campaign_deserialize_atom(data)

/datum/controller/subsystem/campaign/proc/save_structures(map_path)
	if(!save_structures)
		return
	var/filepath = "[map_path]/structures.json"
	var/list/structure_data = list()
	for(var/obj/structure/S in world)
		if(S.made_by) // Player-made, save separately
			continue
		// Save ALL structures on the map regardless of persistence flags
		var/list/data = campaign_serialize_atom(S, ignore_persistence = TRUE)
		if(data)
			structure_data += list(data)
	if(length(structure_data))
		fdel(filepath)
		text2file(json_encode(structure_data), filepath)
	else if(fexists(filepath))
		fdel(filepath)

/datum/controller/subsystem/campaign/proc/load_player_structures(map_path)
	var/filepath = "[map_path]/player_structures.json"
	if(!fexists(filepath))
		return
	var/json_text = file2text(filepath)
	if(!json_text)
		return
	var/list/structure_data = json_decode(json_text)
	if(!islist(structure_data))
		return
	for(var/list/data in structure_data)
		campaign_deserialize_atom(data)

/datum/controller/subsystem/campaign/proc/save_player_structures(map_path)
	if(!save_structures)
		return
	var/filepath = "[map_path]/player_structures.json"
	var/list/structure_data = list()
	for(var/obj/structure/S in world)
		if(!S.made_by) // Not player-made
			continue
		// Save ALL player-made structures regardless of persistence flags
		var/list/data = campaign_serialize_atom(S, ignore_persistence = TRUE)
		if(data)
			structure_data += list(data)
	if(length(structure_data))
		fdel(filepath)
		text2file(json_encode(structure_data), filepath)
	else if(fexists(filepath))
		fdel(filepath)

// ============= TURF PERSISTENCE =============

/datum/controller/subsystem/campaign/proc/load_turfs_changed(map_path)
	var/filepath = "[map_path]/turfs.json"
	if(!fexists(filepath))
		return
	// TODO: Implement turf loading from JSON

/datum/controller/subsystem/campaign/proc/save_turfs_changed(map_path)
	// TODO: Implement turf saving to JSON
	pass()

// ============= DOOR PERSISTENCE =============

/datum/controller/subsystem/campaign/proc/load_doors(map_path)
	var/filepath = "[map_path]/doors.json"
	if(!fexists(filepath))
		return
	var/json_text = file2text(filepath)
	if(!json_text)
		return
	var/list/door_data = json_decode(json_text)
	if(!islist(door_data))
		return
	// Build a lookup of doors by position
	var/list/door_lookup = list()
	for(var/obj/machinery/door/D in world)
		var/key = "[D.x],[D.y],[D.z]"
		door_lookup[key] = D
	// Apply saved states
	for(var/list/data in door_data)
		var/key = "[data["x"]],[data["y"]],[data["z"]]"
		var/obj/machinery/door/D = door_lookup[key]
		if(D)
			campaign_deserialize_door(D, data)

/datum/controller/subsystem/campaign/proc/save_doors(map_path)
	var/filepath = "[map_path]/doors.json"
	var/list/door_data = list()
	for(var/obj/machinery/door/D in world)
		// Save ALL doors regardless of persistence flags
		var/list/data = campaign_serialize_door(D) // Doors have their own serializer
		if(data)
			door_data += list(data)
	if(length(door_data))
		fdel(filepath)
		text2file(json_encode(door_data), filepath)
	else if(fexists(filepath))
		fdel(filepath)

// ============= ITEM PERSISTENCE =============

/datum/controller/subsystem/campaign/proc/load_items(map_path)
	var/filepath = "[map_path]/items.json"
	if(!fexists(filepath))
		return
	var/json_text = file2text(filepath)
	if(!json_text)
		return
	var/list/item_data = json_decode(json_text)
	if(!islist(item_data))
		return
	for(var/list/data in item_data)
		campaign_deserialize_atom(data)

/datum/controller/subsystem/campaign/proc/save_items(map_path)
	var/filepath = "[map_path]/items.json"
	var/list/item_data = list()
	for(var/obj/item/I in world)
		// Skip items in player inventory or storage
		if(ismob(I.loc) || (I.item_flags & IN_STORAGE))
			continue
		// Skip bodyparts (they're handled by health serialization)
		if(istype(I, /obj/item/bodypart))
			continue
		// Save ALL items on the map regardless of persistence flags
		var/list/data = campaign_serialize_atom(I, ignore_persistence = TRUE)
		if(data)
			item_data += list(data)
	
	if(length(item_data))
		fdel(filepath)
		text2file(json_encode(item_data), filepath)
	else if(fexists(filepath))
		fdel(filepath)

// ============= STORAGE PERSISTENCE =============

/datum/controller/subsystem/campaign/proc/load_storage(map_path)
	var/struct_path = "[map_path]/storage.json"
	if(!fexists(struct_path))
		return
	var/json_text = file2text(struct_path)
	if(!json_text)
		return
	var/list/struct_data = json_decode(json_text)
	if(islist(struct_data))
		for(var/list/data in struct_data)
			campaign_deserialize_atom(data)

/datum/controller/subsystem/campaign/proc/save_storage(map_path)
	if(!save_storage)
		return
	var/struct_path = "[map_path]/storage.json"
	var/list/struct_data = list()
	for(var/atom/A in world)
		if(!A.atom_storage)
			continue
		if(ismob(A)) // Skip player inventories
			continue
		// Save ALL storage objects regardless of persistence flags (recursively includes contents)
		var/list/data = campaign_serialize_atom(A, ignore_persistence = TRUE)
		if(data)
			struct_data += list(data)

	if(length(struct_data))
		fdel(struct_path)
		text2file(json_encode(struct_data), struct_path)
	else if(fexists(struct_path))
		fdel(struct_path)

// ============= PLAYER PERSISTENCE =============

/datum/controller/subsystem/campaign/proc/save_all_player_data()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!H.ckey)
			continue
		save_player_data(H)

/datum/controller/subsystem/campaign/proc/save_player_data(mob/living/carbon/human/H)
	if(!H || !H.ckey || !H.client?.prefs)
		return FALSE

	var/slot = H.client.prefs.default_slot
	var/player_path = get_player_path(H.ckey, slot)
	if(!player_path)
		return FALSE

	save_player_health(H, player_path)
	save_player_items(H, player_path)
	save_player_stats(H, player_path)
	save_player_position(H, player_path)
	save_player_vars(H, player_path)
	return TRUE

/datum/controller/subsystem/campaign/proc/load_player_data(mob/living/carbon/human/H, ckey, slot)
	var/player_path = get_player_path(ckey, slot)
	if(!player_path || !fexists("[player_path]/pos.json"))
		return FALSE

	// Check if this slot was already used this round
	var/slot_key = "[ckey]_[slot]"
	if(slots_used_this_round[slot_key])
		return FALSE // Already used this slot this round

	// Mark slot as used this round
	slots_used_this_round[slot_key] = TRUE

	load_player_health(H, player_path)
	load_player_items(H, player_path)
	load_player_stats(H, player_path)
	load_player_position(H, player_path)
	load_player_vars(H, player_path)
	return TRUE

/// Helper to peek at a player's saved job type without loading everything
/datum/controller/subsystem/campaign/proc/get_saved_job_type(ckey, slot)
	var/player_path = get_player_path(ckey, slot)
	if(!player_path)
		return null
	var/filepath = "[player_path]/vars.json"
	if(!fexists(filepath))
		return null
	var/json_text = file2text(filepath)
	if(!json_text)
		return null
	var/list/data = json_decode(json_text)
	if(!islist(data))
		return null
	var/job_type_str = data["job_type"]
	if(job_type_str)
		return text2path(job_type_str)
	return null

/datum/controller/subsystem/campaign/proc/save_player_health(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/health.json"
	var/list/data = list()
	data["health"] = H.health
	data["toxloss"] = H.getToxLoss()
	data["oxyloss"] = H.getOxyLoss()
	data["blood"] = H.blood_volume

	// Save all bodyparts with their wounds
	var/list/bodyparts_data = list()
	var/list/zones_present = list()
	for(var/obj/item/bodypart/BP as anything in H.bodyparts)
		zones_present += BP.body_zone
		var/bp_data = campaign_serialize_bodypart(BP)
		if(bp_data)
			bodyparts_data += list(bp_data)
	data["bodyparts"] = bodyparts_data
	data["zones"] = zones_present // Track which limbs exist

	fdel(filepath)
	text2file(json_encode(data), filepath)

/datum/controller/subsystem/campaign/proc/load_player_health(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/health.json"
	if(!fexists(filepath))
		return
	var/json_text = file2text(filepath)
	if(!json_text)
		return
	var/list/data = json_decode(json_text)
	if(!islist(data))
		return

	// Remove missing limbs based on saved zones
	var/list/zones_present = data["zones"]
	if(islist(zones_present))
		for(var/obj/item/bodypart/BP as anything in H.bodyparts)
			if(!(BP.body_zone in zones_present))
				// This limb was missing in the save - remove it
				BP.drop_limb(special = TRUE, dismembered = TRUE)

	// Apply bodypart data (wounds, damage)
	var/list/bodyparts_data = data["bodyparts"]
	if(islist(bodyparts_data))
		for(var/list/bp_data in bodyparts_data)
			var/zone = bp_data["z"]
			if(!zone)
				continue
			var/obj/item/bodypart/BP = H.get_bodypart(zone)
			if(BP)
				campaign_apply_bodypart_data(BP, bp_data)

	// Load tox/oxy separately (not tied to bodyparts)
	var/toxloss = data["toxloss"]
	var/oxyloss = data["oxyloss"]
	if(toxloss)
		H.adjustToxLoss(toxloss - H.getToxLoss(), updating_health = FALSE)
	if(oxyloss)
		H.adjustOxyLoss(oxyloss - H.getOxyLoss(), updating_health = FALSE)

	// Load blood volume
	var/blood = data["blood"]
	if(blood)
		H.blood_volume = blood

	H.updatehealth()


/datum/controller/subsystem/campaign/proc/save_player_items(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/items.json"
	var/list/data = list()

	// Save equipped items by slot using compact format
	var/list/equipped = list()
	if(H.head)
		equipped["hd"] = campaign_serialize_compact(H.head, ignore_persistence = TRUE)
	if(H.wear_mask)
		equipped["mk"] = campaign_serialize_compact(H.wear_mask, ignore_persistence = TRUE)
	if(H.wear_neck)
		equipped["nk"] = campaign_serialize_compact(H.wear_neck, ignore_persistence = TRUE)
	if(H.back)
		equipped["bk"] = campaign_serialize_compact(H.back, ignore_persistence = TRUE)
	if(H.wear_suit)
		equipped["st"] = campaign_serialize_compact(H.wear_suit, ignore_persistence = TRUE)
	if(H.gloves)
		equipped["gl"] = campaign_serialize_compact(H.gloves, ignore_persistence = TRUE)
	if(H.shoes)
		equipped["ft"] = campaign_serialize_compact(H.shoes, ignore_persistence = TRUE)
	if(H.belt)
		equipped["bt"] = campaign_serialize_compact(H.belt, ignore_persistence = TRUE)
	if(H.glasses)
		equipped["ey"] = campaign_serialize_compact(H.glasses, ignore_persistence = TRUE)
	if(H.wear_id)
		equipped["id"] = campaign_serialize_compact(H.wear_id, ignore_persistence = TRUE)
	if(H.ears)
		equipped["er"] = campaign_serialize_compact(H.ears, ignore_persistence = TRUE)
	if(H.w_shirt)
		equipped["sh"] = campaign_serialize_compact(H.w_shirt, ignore_persistence = TRUE)
	if(H.w_pants)
		equipped["pn"] = campaign_serialize_compact(H.w_pants, ignore_persistence = TRUE)
	if(H.s_store)
		equipped["ss"] = campaign_serialize_compact(H.s_store, ignore_persistence = TRUE)
	if(H.l_store)
		equipped["lp"] = campaign_serialize_compact(H.l_store, ignore_persistence = TRUE)
	if(H.r_store)
		equipped["rp"] = campaign_serialize_compact(H.r_store, ignore_persistence = TRUE)

	data["eq"] = equipped

	// Save held items
	var/list/held = list()
	for(var/i in 1 to H.held_items.len)
		var/obj/item/I = H.held_items[i]
		if(I)
			held["[i]"] = campaign_serialize_compact(I, ignore_persistence = TRUE)
	data["hl"] = held

	fdel(filepath)
	text2file(json_encode(data), filepath)

/datum/controller/subsystem/campaign/proc/load_player_items(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/items.json"
	if(!fexists(filepath))
		return
	var/json_text = file2text(filepath)
	if(!json_text)
		return
	var/list/data = json_decode(json_text)
	if(!islist(data))
		return

	// Clear existing inventory first (except bodyparts)
	for(var/obj/item/I in H.contents)
		if(!istype(I, /obj/item/bodypart))
			qdel(I)

	// Load equipped items
	var/list/equipped = data["eq"]
	if(islist(equipped))
		// Helper to load with fallback: new key, legacy key, slot
		var/list/slot_mappings = list(
			list("hd", "head", ITEM_SLOT_HEAD),
			list("mk", "mask", ITEM_SLOT_MASK),
			list("nk", "neck", ITEM_SLOT_NECK),
			list("bk", "back", ITEM_SLOT_BACK),
			list("st", "suit", ITEM_SLOT_OCLOTHING),
			list("gl", "gloves", ITEM_SLOT_GLOVES),
			list("ft", "feet", ITEM_SLOT_FEET),
			list("bt", "belt", ITEM_SLOT_BELT),
			list("ey", "eyes", ITEM_SLOT_EYES),
			list("id", "id", ITEM_SLOT_ID),
			list("er", "ears", ITEM_SLOT_EARS),
			list("sh", "shirt", ITEM_SLOT_SHIRT),
			list("pn", "pants", ITEM_SLOT_PANTS),
			list("ss", "s_store", ITEM_SLOT_SUITSTORE),
			list("lp", "l_pocket", ITEM_SLOT_LPOCKET),
			list("rp", "r_pocket", ITEM_SLOT_RPOCKET)
		)

		for(var/list/mapping in slot_mappings)
			var/new_key = mapping[1]
			var/legacy_key = mapping[2]
			var/slot = mapping[3]
			var/item_data = equipped[new_key] || equipped[legacy_key]
			if(item_data)
				var/obj/item/I = campaign_deserialize_compact(item_data, H)
				if(I)
					H.equip_to_slot_if_possible(I, slot, disable_warning = TRUE, bypass_equip_delay_self = TRUE)

	// Load held items
	var/list/held = data["hl"]
	if(islist(held))
		for(var/slot_key in held)
			var/slot_num = text2num(slot_key)
			if(!slot_num)
				continue
			var/obj/item/I = campaign_deserialize_compact(held[slot_key], H)
			if(I && slot_num <= H.held_items.len)
				H.put_in_hand(I, slot_num)

/datum/controller/subsystem/campaign/proc/save_player_stats(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/stats.json"
	var/list/data = list()
	data["nutrition"] = H.nutrition
	data["blood"] = H.blood_volume
	fdel(filepath)
	text2file(json_encode(data), filepath)

/datum/controller/subsystem/campaign/proc/load_player_stats(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/stats.json"
	if(!fexists(filepath))
		return
	var/json_text = file2text(filepath)
	if(!json_text)
		return
	var/list/data = json_decode(json_text)
	if(!islist(data))
		return
	var/nutrition = data["nutrition"]
	var/blood = data["blood"]
	if(nutrition)
		H.nutrition = nutrition
	if(blood)
		H.blood_volume = blood

/datum/controller/subsystem/campaign/proc/save_player_position(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/pos.json"
	var/list/data = list()
	data["x"] = H.x
	data["y"] = H.y
	data["z"] = H.z
	// Save map name for seamless transitions
	data["map"] = SSmapping.config?.map_name || "unknown"
	fdel(filepath)
	text2file(json_encode(data), filepath)

/datum/controller/subsystem/campaign/proc/load_player_position(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/pos.json"
	if(!fexists(filepath))
		return
	var/json_text = file2text(filepath)
	if(!json_text)
		return
	var/list/data = json_decode(json_text)
	if(!islist(data))
		return
	var/px = data["x"]
	var/py = data["y"]
	var/pz = data["z"]
	var/saved_map = data["map"]
	
	var/current_map = SSmapping.config?.map_name || "unknown"
	
	// Check if maps differ
	if(saved_map && saved_map != current_map)
		// Look for pos_shift entity that handles this source map
		var/obj/effect/map_entity/campaign_pos_shift/shifter = get_campaign_pos_shift(saved_map)
		if(shifter)
			// Apply shift to coordinates
			var/list/shifted = shifter.apply_shift(px, py, pz)
			px = shifted["x"]
			py = shifted["y"]
			pz = shifted["z"]
			var/turf/T = locate(px, py, pz)
			if(T)
				H.forceMove(T)
				return
		// No pos_shift for this source map - fall back to job/latejoin spawn
		spawn_at_job_or_latejoin(H)
		return
	
	// Same map or no saved map - use saved position directly
	var/turf/T = locate(px, py, pz)
	if(T)
		H.forceMove(T)

/datum/controller/subsystem/campaign/proc/save_player_vars(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/vars.json"
	var/list/data = list()
	data["dir"] = H.dir
	data["lying"] = H.body_position
	// Save job assignment
	if(H.mind?.assigned_role)
		data["job_type"] = "[H.mind.assigned_role.type]"
		data["job_title"] = H.mind.assigned_role.title
	fdel(filepath)
	text2file(json_encode(data), filepath)

/datum/controller/subsystem/campaign/proc/load_player_vars(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/vars.json"
	if(!fexists(filepath))
		return
	var/json_text = file2text(filepath)
	if(!json_text)
		return
	var/list/data = json_decode(json_text)
	if(!islist(data))
		return
	var/pdir = data["dir"]
	if(pdir)
		H.setDir(pdir)
	// Restore job assignment from saved data
	var/job_type_str = data["job_type"]
	if(job_type_str && H.mind)
		var/job_type = text2path(job_type_str)
		if(job_type)
			var/datum/job/saved_job = SSjob.GetJobType(job_type)
			if(saved_job)
				H.mind.set_assigned_role(saved_job)
	// TODO: Apply lying, handcuffed, etc.

// ============= CAMPAIGN MANAGEMENT =============

/// Wipe all data for the current campaign
/datum/controller/subsystem/campaign/proc/reset_campaign()
	var/campaign_path = get_campaign_path()
	if(fexists(campaign_path))
		fdel(campaign_path)
	log_admin("Campaign [campaign_name] has been reset.")

/// Set the campaign ID/name
/datum/controller/subsystem/campaign/proc/set_campaign_id(new_name)
	if(!new_name)
		return FALSE
	campaign_name = new_name
	save_config()
	return TRUE

/// Permakill a player's character slot - backs up data before deletion
/datum/controller/subsystem/campaign/proc/permakill_slot(ckey, slot)
	var/player_path = get_player_path(ckey, slot)
	if(!player_path)
		return FALSE
	if(!fexists(player_path))
		return FALSE

	// Backup the slot data before deleting
	backup_slot(ckey, slot)

	// Delete the original
	fdel(player_path)
	return TRUE

/// Backup a player's character slot to the backup folder
/datum/controller/subsystem/campaign/proc/backup_slot(ckey, slot)
	var/player_path = get_player_path(ckey, slot)
	if(!player_path || !fexists(player_path))
		return FALSE

	// Create backup path with timestamp
	var/timestamp = time2text(world.realtime, "YYYY-MM-DD_hh-mm-ss")
	var/backup_base = "[get_campaign_path()]/backup/[ckey]"
	var/backup_path = "[backup_base]/slot[slot]_[timestamp]"

	// Copy all files from player_path to backup_path
	for(var/filename in flist(player_path + "/"))
		var/source = "[player_path]/[filename]"
		var/dest = "[backup_path]/[filename]"
		if(fexists(source))
			var/content = file2text(source)
			if(content)
				text2file(content, dest)

	log_world("CAMPAIGN: Backed up [ckey] slot [slot] to [backup_path]")
	return TRUE

/// Check if a slot was already used this round
/datum/controller/subsystem/campaign/proc/is_slot_used_this_round(ckey, slot)
	var/slot_key = "[ckey]_[slot]"
	return !!slots_used_this_round[slot_key]

/// Check if a player's slot has persistence data
/datum/controller/subsystem/campaign/proc/has_persistence_data(ckey, slot)
	var/player_path = get_player_path(ckey, slot)
	if(!player_path)
		return FALSE
	return fexists("[player_path]/pos.json")

/// Spawn a player at their job spawn point or a latejoin marker
/// Used when loading a player from a different map without a pos_shift entity
/datum/controller/subsystem/campaign/proc/spawn_at_job_or_latejoin(mob/living/carbon/human/H)
	if(!H || !H.mind)
		return FALSE
	
	var/datum/job/J = H.mind.assigned_role
	if(!J)
		return FALSE

	// Try roundstart spawn point first
	var/turf/spawn_point = J.get_roundstart_spawn_point()
	if(spawn_point)
		H.forceMove(get_turf(spawn_point))
		return TRUE

	// Fallback to latejoin spawn point
	spawn_point = J.get_latejoin_spawn_point()
	if(spawn_point)
		H.forceMove(get_turf(spawn_point))
		return TRUE

	return FALSE

