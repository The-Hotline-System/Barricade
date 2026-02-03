/// Campaign admin verbs for managing persistence data

/client/proc/campaign_reset()
	set category = "Campaign"
	set name = "Reset Campaign"
	set desc = "Wipe ALL data for the current campaign. THIS IS IRREVERSIBLE!"

	if(!check_rights(R_ADMIN))
		return

	var/confirm = tgui_alert(usr, "Are you SURE you want to wipe all campaign data for '[SScampaign.campaign_name]'? This cannot be undone!", "Confirm Campaign Reset", list("Yes", "No"))
	if(confirm != "Yes")
		return

	SScampaign.reset_campaign()
	message_admins("[key_name_admin(usr)] has reset the campaign '[SScampaign.campaign_name]'.")
	log_admin("[key_name(usr)] reset campaign '[SScampaign.campaign_name]'.")

/client/proc/campaign_set_id()
	set category = "Campaign"
	set name = "Set Campaign ID"
	set desc = "Change the current campaign name/ID."

	if(!check_rights(R_ADMIN))
		return

	var/new_name = input(usr, "Enter new campaign ID/name:", "Set Campaign ID", SScampaign.campaign_name) as text|null
	if(!new_name)
		return

	var/old_name = SScampaign.campaign_name
	SScampaign.set_campaign_id(new_name)
	message_admins("[key_name_admin(usr)] has changed the campaign ID from '[old_name]' to '[new_name]'.")
	log_admin("[key_name(usr)] changed campaign ID from '[old_name]' to '[new_name]'.")

/client/proc/campaign_manual_save()
	set category = "Campaign"
	set name = "Manual Save"
	set desc = "Force a save of all persistent objects."

	if(!check_rights(R_ADMIN))
		return

	SScampaign.save_campaign_data()
	message_admins("[key_name_admin(usr)] has triggered a manual campaign save.")
	log_admin("[key_name(usr)] triggered manual campaign save.")
	to_chat(usr, span_notice("Campaign data saved."))

/client/proc/campaign_permakill_slot()
	set category = "Campaign"
	set name = "Permakill Slot"
	set desc = "Wipe a player's character slot persistence data."

	if(!check_rights(R_ADMIN))
		return

	var/target_ckey = input(usr, "Enter the ckey of the player:", "Permakill Slot") as text|null
	if(!target_ckey)
		return

	var/target_slot = input(usr, "Enter the slot number to permakill (1-3):", "Permakill Slot", 1) as num|null
	if(!target_slot || target_slot < 1 || target_slot > MAX_CHARACTER_SLOTS)
		to_chat(usr, span_warning("Invalid slot number."))
		return

	var/confirm = tgui_alert(usr, "Are you SURE you want to permakill [target_ckey]'s slot [target_slot]? This will wipe their character data!", "Confirm Permakill", list("Yes", "No"))
	if(confirm != "Yes")
		return

	if(SScampaign.permakill_slot(target_ckey, target_slot))
		message_admins("[key_name_admin(usr)] has permakilled [target_ckey]'s character slot [target_slot].")
		log_admin("[key_name(usr)] permakilled [target_ckey] slot [target_slot].")
		to_chat(usr, span_notice("Permakilled [target_ckey]'s slot [target_slot]."))
	else
		to_chat(usr, span_warning("Failed to permakill slot. Check that the path exists."))

/client/proc/campaign_toggle_global_permakill()
	set category = "Campaign"
	set name = "Toggle Global Permakill"
	set desc = "Toggle whether all player deaths are permanent."

	if(!check_rights(R_ADMIN))
		return

	SScampaign.global_permakill = !SScampaign.global_permakill
	SScampaign.save_config()

	var/status = SScampaign.global_permakill ? "ENABLED" : "DISABLED"
	message_admins("[key_name_admin(usr)] has [status] global permakill mode.")
	log_admin("[key_name(usr)] [status] global permakill mode.")
	to_chat(usr, span_notice("Global permakill is now [status]."))

/client/proc/campaign_mark_persistent()
	set category = "Campaign"
	set name = "Mark Persistent"
	set desc = "Mark an object as persistent (staff-marked)."

	if(!check_rights(R_ADMIN))
		return

	var/atom/target = usr.client?.holder?.marked_datum
	if(!target)
		to_chat(usr, span_warning("Mark an object first using the VV marking tool."))
		return

	target.persistence_flags |= PERSISTENCE_STAFF_MARKED
	target.made_by = usr.ckey
	to_chat(usr, span_notice("Marked [target] as persistent. Made by: [target.made_by]"))
	log_admin("[key_name(usr)] marked [target] ([target.type]) as persistent.")

/client/proc/campaign_unmark_persistent()
	set category = "Campaign"
	set name = "Unmark Persistent"
	set desc = "Remove staff-marked persistence from an object."

	if(!check_rights(R_ADMIN))
		return

	var/atom/target = usr.client?.holder?.marked_datum
	if(!target)
		to_chat(usr, span_warning("Mark an object first using the VV marking tool."))
		return

	target.persistence_flags &= ~PERSISTENCE_STAFF_MARKED
	to_chat(usr, span_notice("Removed staff-marked persistence from [target]."))
	log_admin("[key_name(usr)] unmarked [target] ([target.type]) from persistence.")
