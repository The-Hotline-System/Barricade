/// Campaign Persistence Subsystem
/// Manages campaign state, paths, and persistent data.
SUBSYSTEM_DEF(campaign)
	name = "Campaign"
	init_order = INIT_ORDER_PERSISTENCE + 1 // After persistence
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

/datum/controller/subsystem/campaign/Initialize()
	load_config()
	load_campaign_data()
	return ..()

/datum/controller/subsystem/campaign/Shutdown()
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

/// Load campaign configuration
/datum/controller/subsystem/campaign/proc/load_config()
	var/config_path = "[base_path]/config.sav"
	if(!fexists(config_path))
		return

	var/savefile/S = new(config_path)
	S["campaign_name"] >> campaign_name
	S["last_touched_limit"] >> last_touched_limit
	S["save_storage"] >> save_storage
	S["save_item_vars"] >> save_item_vars
	S["save_structures"] >> save_structures
	S["global_permakill"] >> global_permakill

/// Save campaign configuration
/datum/controller/subsystem/campaign/proc/save_config()
	var/config_path = "[base_path]/config.sav"
	var/savefile/S = new(config_path)
	S["campaign_name"] << campaign_name
	S["last_touched_limit"] << last_touched_limit
	S["save_storage"] << save_storage
	S["save_item_vars"] << save_item_vars
	S["save_structures"] << save_structures
	S["global_permakill"] << global_permakill

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
	var/filepath = "[map_path]/structures.sav"
	if(!fexists(filepath))
		return
	var/savefile/S = new(filepath)
	var/list/structure_data
	S["structures"] >> structure_data
	if(!islist(structure_data))
		return
	for(var/list/data in structure_data)
		campaign_deserialize_atom(data)

/datum/controller/subsystem/campaign/proc/save_structures(map_path)
	if(!save_structures)
		return
	var/filepath = "[map_path]/structures.sav"
	var/list/structure_data = list()
	for(var/obj/structure/S in world)
		if(S.persistence_flags & NO_PERSIST)
			continue
		if(S.made_by) // Player-made, save separately
			continue
		if(!(S.persistence_flags & (PERSIST_BY_DEFAULT | PERSISTENCE_STAFF_MARKED)))
			continue
		var/list/data = campaign_serialize_atom(S)
		if(data)
			structure_data += list(data)
	var/savefile/SF = new(filepath)
	SF["structures"] << structure_data

/datum/controller/subsystem/campaign/proc/load_player_structures(map_path)
	var/filepath = "[map_path]/player_structures.sav"
	if(!fexists(filepath))
		return
	var/savefile/S = new(filepath)
	var/list/structure_data
	S["structures"] >> structure_data
	if(!islist(structure_data))
		return
	for(var/list/data in structure_data)
		campaign_deserialize_atom(data)

/datum/controller/subsystem/campaign/proc/save_player_structures(map_path)
	if(!save_structures)
		return
	var/filepath = "[map_path]/player_structures.sav"
	var/list/structure_data = list()
	for(var/obj/structure/S in world)
		if(S.persistence_flags & NO_PERSIST)
			continue
		if(!S.made_by) // Not player-made
			continue
		var/list/data = campaign_serialize_atom(S)
		if(data)
			structure_data += list(data)
	var/savefile/SF = new(filepath)
	SF["structures"] << structure_data

// ============= TURF PERSISTENCE =============

/datum/controller/subsystem/campaign/proc/load_turfs_changed(map_path)
	var/filepath = "[map_path]/turfs_changed.sav"
	if(!fexists(filepath))
		return
	// TODO: Implement turf loading

/datum/controller/subsystem/campaign/proc/save_turfs_changed(map_path)
	// var/filepath = "[map_path]/turfs_changed.sav"
	// TODO: Implement turf saving

// ============= DOOR PERSISTENCE =============

/datum/controller/subsystem/campaign/proc/load_doors(map_path)
	var/filepath = "[map_path]/doors.sav"
	if(!fexists(filepath))
		return
	var/savefile/S = new(filepath)
	var/list/door_data
	S["doors"] >> door_data
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
	var/filepath = "[map_path]/doors.sav"
	var/list/door_data = list()
	for(var/obj/machinery/door/D in world)
		if(D.persistence_flags & NO_PERSIST)
			continue
		var/list/data = campaign_serialize_door(D)
		if(data)
			door_data += list(data)
	var/savefile/SF = new(filepath)
	SF["doors"] << door_data

// ============= ITEM PERSISTENCE =============

/datum/controller/subsystem/campaign/proc/load_items(map_path)
	var/filepath = "[map_path]/items.sav"
	if(!fexists(filepath))
		return
	var/savefile/S = new(filepath)
	var/list/item_data
	S["items"] >> item_data
	if(!islist(item_data))
		return
	for(var/list/data in item_data)
		campaign_deserialize_atom(data)

/datum/controller/subsystem/campaign/proc/save_items(map_path)
	var/filepath = "[map_path]/items.sav"
	var/list/item_data = list()
	for(var/obj/item/I in world)
		// Skip items in player inventory
		if(ismob(I.loc))
			continue
		// Skip items in storage
		if(I.item_flags & IN_STORAGE)
			continue
		if(I.persistence_flags & NO_PERSIST)
			continue
		if(!(I.persistence_flags & (PERSIST_BY_DEFAULT | PERSISTENCE_STAFF_MARKED)))
			continue
		var/list/data = campaign_serialize_atom(I)
		if(data)
			item_data += list(data)
	var/savefile/SF = new(filepath)
	SF["items"] << item_data

// ============= STORAGE PERSISTENCE =============

/datum/controller/subsystem/campaign/proc/load_storage(map_path)
	var/struct_path = "[map_path]/storage_struct.sav"
	var/contents_path = "[map_path]/storage.sav"
	if(!fexists(struct_path))
		return
	// Load storage structures (crates, lockers, etc.)
	var/savefile/S1 = new(struct_path)
	var/list/struct_data
	S1["storage"] >> struct_data
	var/list/storage_lookup = list()
	if(islist(struct_data))
		for(var/list/data in struct_data)
			var/atom/storage_atom = campaign_deserialize_atom(data)
			if(storage_atom)
				var/key = "[storage_atom.x],[storage_atom.y],[storage_atom.z]"
				storage_lookup[key] = storage_atom
	// Load storage contents
	if(!fexists(contents_path))
		return
	var/savefile/S2 = new(contents_path)
	var/list/contents_data
	S2["contents"] >> contents_data
	if(islist(contents_data))
		for(var/storage_key in contents_data)
			var/atom/storage_atom = storage_lookup[storage_key]
			if(!storage_atom || !storage_atom.atom_storage)
				continue
			var/list/items = contents_data[storage_key]
			for(var/list/item_data in items)
				var/obj/item/I = campaign_deserialize_atom(item_data, storage_atom)
				if(I)
					storage_atom.atom_storage.attempt_insert(I, null, TRUE, TRUE)

/datum/controller/subsystem/campaign/proc/save_storage(map_path)
	if(!save_storage)
		return
	var/struct_path = "[map_path]/storage_struct.sav"
	var/contents_path = "[map_path]/storage.sav"
	var/list/struct_data = list()
	var/list/contents_data = list()
	for(var/atom/A in world)
		if(!A.atom_storage)
			continue
		if(ismob(A)) // Skip player inventories
			continue
		if(A.persistence_flags & NO_PERSIST)
			continue
		if(!(A.persistence_flags & (PERSIST_BY_DEFAULT | PERSISTENCE_STAFF_MARKED)))
			continue
		// Save structure data
		var/list/data = campaign_serialize_atom(A)
		if(data)
			struct_data += list(data)
		// Save contents
		var/key = "[A.x],[A.y],[A.z]"
		var/list/item_list = list()
		for(var/obj/item/I in A.contents)
			var/list/item_data = campaign_serialize_atom(I)
			if(item_data)
				item_list += list(item_data)
		if(length(item_list))
			contents_data[key] = item_list
	var/savefile/SF1 = new(struct_path)
	SF1["storage"] << struct_data
	var/savefile/SF2 = new(contents_path)
	SF2["contents"] << contents_data

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
	if(!player_path || !fexists("[player_path]/pos.sav"))
		return FALSE

	load_player_health(H, player_path)
	load_player_items(H, player_path)
	load_player_stats(H, player_path)
	load_player_position(H, player_path)
	load_player_vars(H, player_path)
	return TRUE

/datum/controller/subsystem/campaign/proc/save_player_health(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/health_n_wounds.sav"
	var/savefile/S = new(filepath)
	S["health"] << H.health
	S["bruteloss"] << H.getBruteLoss()
	S["fireloss"] << H.getFireLoss()
	S["toxloss"] << H.getToxLoss()
	S["oxyloss"] << H.getOxyLoss()
	// TODO: Add wound serialization

/datum/controller/subsystem/campaign/proc/load_player_health(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/health_n_wounds.sav"
	if(!fexists(filepath))
		return
	var/savefile/S = new(filepath)
	var/bruteloss, fireloss, toxloss, oxyloss
	S["bruteloss"] >> bruteloss
	S["fireloss"] >> fireloss
	S["toxloss"] >> toxloss
	S["oxyloss"] >> oxyloss
	H.adjustBruteLoss(bruteloss - H.getBruteLoss())
	H.adjustFireLoss(fireloss - H.getFireLoss())
	H.adjustToxLoss(toxloss - H.getToxLoss(), updating_health = FALSE)
	H.adjustOxyLoss(oxyloss - H.getOxyLoss(), updating_health = FALSE)
	// TODO: Add wound deserialization

/datum/controller/subsystem/campaign/proc/save_player_items(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/items.sav"
	var/savefile/S = new(filepath)

	// Save equipped items by slot
	var/list/equipped = list()
	if(H.head)
		equipped["head"] = campaign_serialize_atom(H.head)
	if(H.wear_mask)
		equipped["mask"] = campaign_serialize_atom(H.wear_mask)
	if(H.wear_neck)
		equipped["neck"] = campaign_serialize_atom(H.wear_neck)
	if(H.back)
		equipped["back"] = campaign_serialize_atom(H.back)
	if(H.wear_suit)
		equipped["suit"] = campaign_serialize_atom(H.wear_suit)
	if(H.gloves)
		equipped["gloves"] = campaign_serialize_atom(H.gloves)
	if(H.shoes)
		equipped["feet"] = campaign_serialize_atom(H.shoes)
	if(H.belt)
		equipped["belt"] = campaign_serialize_atom(H.belt)
	if(H.glasses)
		equipped["eyes"] = campaign_serialize_atom(H.glasses)
	if(H.wear_id)
		equipped["id"] = campaign_serialize_atom(H.wear_id)
	if(H.ears)
		equipped["ears"] = campaign_serialize_atom(H.ears)
	if(H.w_shirt)
		equipped["shirt"] = campaign_serialize_atom(H.w_shirt)
	if(H.w_pants)
		equipped["pants"] = campaign_serialize_atom(H.w_pants)
	if(H.s_store)
		equipped["s_store"] = campaign_serialize_atom(H.s_store)

	S["equipped"] << equipped

	// Save held items
	var/list/held = list()
	for(var/i in 1 to H.held_items.len)
		var/obj/item/I = H.held_items[i]
		if(I)
			held["[i]"] = campaign_serialize_atom(I)
	S["held"] << held

/datum/controller/subsystem/campaign/proc/load_player_items(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/items.sav"
	if(!fexists(filepath))
		return
	var/savefile/S = new(filepath)

	// Clear existing inventory first
	for(var/obj/item/I in H.contents)
		qdel(I)

	// Load equipped items
	var/list/equipped
	S["equipped"] >> equipped
	if(islist(equipped))
		if(equipped["head"])
			var/obj/item/I = campaign_deserialize_atom(equipped["head"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_HEAD, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		if(equipped["mask"])
			var/obj/item/I = campaign_deserialize_atom(equipped["mask"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_MASK, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		if(equipped["neck"])
			var/obj/item/I = campaign_deserialize_atom(equipped["neck"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_NECK, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		if(equipped["back"])
			var/obj/item/I = campaign_deserialize_atom(equipped["back"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_BACK, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		if(equipped["suit"])
			var/obj/item/I = campaign_deserialize_atom(equipped["suit"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_OCLOTHING, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		if(equipped["gloves"])
			var/obj/item/I = campaign_deserialize_atom(equipped["gloves"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_GLOVES, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		if(equipped["feet"])
			var/obj/item/I = campaign_deserialize_atom(equipped["feet"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_FEET, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		if(equipped["belt"])
			var/obj/item/I = campaign_deserialize_atom(equipped["belt"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_BELT, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		if(equipped["eyes"])
			var/obj/item/I = campaign_deserialize_atom(equipped["eyes"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_EYES, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		if(equipped["id"])
			var/obj/item/I = campaign_deserialize_atom(equipped["id"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_ID, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		if(equipped["ears"])
			var/obj/item/I = campaign_deserialize_atom(equipped["ears"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_EARS, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		if(equipped["shirt"])
			var/obj/item/I = campaign_deserialize_atom(equipped["shirt"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_SHIRT, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		if(equipped["pants"])
			var/obj/item/I = campaign_deserialize_atom(equipped["pants"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_PANTS, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		// Fallback for old saves that used "uniform"
		if(!equipped["shirt"] && equipped["uniform"])
			var/obj/item/I = campaign_deserialize_atom(equipped["uniform"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_SHIRT, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
		if(equipped["s_store"])
			var/obj/item/I = campaign_deserialize_atom(equipped["s_store"], H)
			if(I) H.equip_to_slot_if_possible(I, ITEM_SLOT_SUITSTORE, disable_warning = TRUE, bypass_equip_delay_self = TRUE)

	// Load held items
	var/list/held
	S["held"] >> held
	if(islist(held))
		for(var/slot_key in held)
			var/slot_num = text2num(slot_key)
			if(!slot_num)
				continue
			var/obj/item/I = campaign_deserialize_atom(held[slot_key], H)
			if(I)
				if(slot_num <= H.held_items.len)
					H.put_in_hand(I, slot_num)

/datum/controller/subsystem/campaign/proc/save_player_stats(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/stats.sav"
	var/savefile/S = new(filepath)
	// Save nutrition and blood
	S["nutrition"] << H.nutrition
	S["blood"] << H.blood_volume

/datum/controller/subsystem/campaign/proc/load_player_stats(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/stats.sav"
	if(!fexists(filepath))
		return
	var/savefile/S = new(filepath)
	var/nutrition, blood
	S["nutrition"] >> nutrition
	S["blood"] >> blood
	if(nutrition)
		H.nutrition = nutrition
	if(blood)
		H.blood_volume = blood

/datum/controller/subsystem/campaign/proc/save_player_position(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/pos.sav"
	var/savefile/S = new(filepath)
	S["x"] << H.x
	S["y"] << H.y
	S["z"] << H.z
	// Save map name for seamless transitions
	var/map_name = SSmapping.config?.map_name || "unknown"
	S["map"] << map_name

/datum/controller/subsystem/campaign/proc/load_player_position(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/pos.sav"
	if(!fexists(filepath))
		return
	var/savefile/S = new(filepath)
	var/px, py, pz, saved_map
	S["x"] >> px
	S["y"] >> py
	S["z"] >> pz
	S["map"] >> saved_map
	
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
	var/filepath = "[player_path]/rest_of_vars.sav"
	var/savefile/S = new(filepath)
	S["dir"] << H.dir
	S["lying"] << H.body_position
	// TODO: Add handcuffed, etc.

/datum/controller/subsystem/campaign/proc/load_player_vars(mob/living/carbon/human/H, player_path)
	var/filepath = "[player_path]/rest_of_vars.sav"
	if(!fexists(filepath))
		return
	var/savefile/S = new(filepath)
	var/pdir, plying
	S["dir"] >> pdir
	S["lying"] >> plying
	if(pdir)
		H.setDir(pdir)
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

/// Permakill a player's character slot
/datum/controller/subsystem/campaign/proc/permakill_slot(ckey, slot)
	var/player_path = get_player_path(ckey, slot)
	if(!player_path)
		return FALSE
	if(fexists(player_path))
		fdel(player_path)
	return TRUE

/// Check if a player's slot has persistence data
/datum/controller/subsystem/campaign/proc/has_persistence_data(ckey, slot)
	var/player_path = get_player_path(ckey, slot)
	if(!player_path)
		return FALSE
	return fexists("[player_path]/pos.sav")

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

