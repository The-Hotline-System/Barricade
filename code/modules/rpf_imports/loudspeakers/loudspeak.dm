/obj/structure/fake_machine/announcementmicrophone
	name = "captain's microphone"
	desc = "Should work right as rain.."
	icon = 'icons/hammer/source.dmi'
	icon_state = "sound"
	anchored = TRUE
	var/id = 0 // This is for the ID system, it allows us to have multiple of these in a map.
	// IMPORTANT VARS GO UP HERE ^^

	var/broadcasting  = FALSE
	var/listening = TRUE

	var/cooldown // Cooldown for inputs

	var/datum/broadcast_template/template = /datum/broadcast_template/base

/obj/structure/fake_machine/announcementmicrophone/New()
	. = ..()
	LAZYADD(GLOB.speakers, src)

/obj/structure/fake_machine/announcementmicrophone/Initialize()
	. = ..()
	become_hearing_sensitive()
	template = new template

/obj/structure/fake_machine/announcementmicrophone/attack_hand(mob/user)
	. = ..()
	if(!cooldown)
		var/list/mobs = list()
		for(var/obj/s in AUDIOSOURCES)
			mobs |= SSloudspeak.get_mobs_around_obj(template.broadcast_range, s)
		if(!broadcasting)
			broadcasting = TRUE
			listening = TRUE
			set_cooldown(6 SECONDS)
			SSloudspeak.prep_announce(template, id, span_speaker_event("The loudspeakers blare to life."), null, null, TRUE)
			SSloudspeak.handle_playsound(template, mobs, id, template.broadcast_start_sound, template.broadcast_start_sound_volume, 0)

		else
			broadcasting = FALSE
			listening = FALSE
			set_cooldown(20 SECONDS)
			SSloudspeak.prep_announce(template, id, span_speaker_event("A sudden silence overtakes the loudspeakers."), null, null, TRUE)
			SSloudspeak.handle_playsound(template, mobs, id, template.broadcast_end_sound, template.broadcast_end_sound_volume, 0)
		playsound(src.loc, "button", 75, 1)
	update_icon()
/*
/obj/structure/fake_machine/announcementmicrophone/RightClick(mob/user)
/*
	SSloudspeak.play_broadcast(pick(/datum/broadcast/civil, /datum/broadcast/curfew, /datum/broadcast/king))
*/
	if(broadcasting)
		if(listening)
			listening = FALSE
		else
			listening = TRUE
		playsound(src.loc, "button", 75, 1)
		update_icon()
*/
/obj/structure/fake_machine/announcementmicrophone/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, list/message_mods = list(), atom/sound_loc, message_range)
	if(message_mods[WHISPER_MODE])
		return
	if(speaker == src)
		return
	if(!ishuman(speaker))
		return
	var/mob/living/carbon/human/H = speaker
	if(!broadcasting)
		return
	if(!listening)
		return
	var/usedcolor = "#567486"
	if(in_range(src, H))

		// var/ending = copytext(raw_message, -1) -- AMEND THIS / CREATE VARIABLE FOR "PUNCTUATION"
		// if(!(ending in PUNCTUATION))
		//	raw_message = "[raw_message]."

		message = replacetext(raw_message, "/", "")
		message = replacetext(raw_message, "~", "")
		message = replacetext(raw_message, "@", "")
		message = replacetext(raw_message, " i ", " I ")
		message = replacetext(raw_message, " ive ", " I've ")
		message = replacetext(raw_message, " im ", " I'm ")
		message = replacetext(raw_message, " u ", " you ")

		var/processedmsg = span_speaker_name("<span style = 'color:#[usedcolor]'>[H.real_name]</span> speaks, \"[span_speaker_text(raw_message)]\"")
		SSloudspeak.prep_announce(template, id, processedmsg, message_language, raw_message, FALSE)
/*
/obj/structure/fake_machine/announcementmicrophone/see_emote(mob/M as mob, text, var/emote_type)
	if(broadcasting)
		if(listening)
			if(emote_type != AUDIBLE_MESSAGE)
				return
			if(M in range(2, get_turf(src)))
				var/start_pos = findtext(text, "</B>") + length("</B>")
				var/output = copytext(text, start_pos)
				output = trim(output)
				var/spkrname = ageAndGender2Desc(M.age, M.gender)
				transmitemote(spkrname, output)
				return // Not sure how to fix it. Right now it spits out this: Young Woman <B>Arb. Mcintosh Willey</B> screams!
			else
				return
*/
/*
/obj/structure/fake_machine/announcementmicrophone/proc/transmitmessage(spkrname, msg, var/verbtxt)
	var/list/clients = list()
	var/this_sound = null
	mobstosendto.Cut()
	if(additional_talk_sound)
		this_sound = pick(shuffle(additional_talk_sound))
	for(var/obj/structure/fake_machine/announcementspeaker/s in speakers)
		if(id == s.id)
			for(var/mob/living/carbon/H in get_area(s))
				mobstosendto |= H
			for(var/mob/living/carbon/m in view(world.view + broadcast_range, get_turf(s)))
				if(!m.stat == UNCONSCIOUS || !m.is_deaf() || !m.stat == DEAD)
					mobstosendto |= m
					soundoverlay(s, newplane = FOOTSTEP_ALERT_PLANE)
					if(m.client)
						clients |= m.client
			// it got annoying REALLY FAST having them all being different..
			playsound(get_turf(s),this_sound , additional_talk_sound_volume, additional_talk_sound_vary, ignore_walls = FALSE, extrarange = 4)
			INVOKE_ASYNC(s, /atom/movable/proc/animate_chat, "<font color='[rune_color]'><b>[msg]", null, 0, clients, 5 SECONDS, 1)
	for(var/mob/living/carbon/m in mobstosendto)
		to_chat(m,"[chaticon("loudspeaker", classes="nosizemargin",  w=26, h=26)] <span class='[speakerstyle]'>[spkrname] [verbtxt] \"<span class='[textstyle]'>[msg]</span>\"</span>")
*/
/*
/obj/structure/fake_machine/announcementmicrophone/proc/transmitemote(spkrname, emote)
	var/list/mobstosendto = list()
	for(var/obj/structure/fake_machine/announcementspeaker/s in world)
		if(id == s.id)
			for(var/mob/living/carbon/m in view(world.view + broadcast_range, get_turf(s)))
				if(!m.stat == UNCONSCIOUS || !m.is_deaf() || !m.stat == DEAD)
					mobstosendto |= m
					soundoverlay(s, newplane = FOOTSTEP_ALERT_PLANE)
	for(var/mob/living/carbon/m in mobstosendto)
		to_chat(m,"<h2><span class='[speakerstyle]'>[spkrname] [emote]</h2>")
*/
/*
/obj/structure/fake_machine/announcementmicrophone/proc/speakmessage(var/text)
	var/turf/die = get_turf(handset)
	die.audible_message("\icon[handset] [text]",hearing_distance = 2)// TEMP HACKY FIX!!
*/

/obj/structure/fake_machine/announcementmicrophone/proc/set_cooldown(var/delay)
	cooldown = 1
	spawn(delay)
		if(cooldown)
			cooldown = 0
/*
/obj/structure/fake_machine/announcementmicrophone/update_icon()
	. = ..()
	overlays.Cut()
	if(broadcasting && !listening)
		var/image/I = image(icon=src.icon, icon_state = "mic_silent")
		//I.plane = EFFECTS_ABOVE_LIGHTING_PLANE
		overlays += I
	else if(broadcasting && listening)
		var/image/I = image(icon=src.icon, icon_state = "mic_on")
		//I.plane = EFFECTS_ABOVE_LIGHTING_PLANE
		overlays += I
*/
/obj/structure/fake_machine/announcementspeaker/
	name = "Loudspeaker"
	icon = 'icons/hammer/source.dmi'
	icon_state = "sound"
	anchored = TRUE
	//plane = AH
	var/id = 0

/obj/structure/fake_machine/announcementspeaker/Initialize()
	. = ..()
	AUDIOSOURCES |= src
