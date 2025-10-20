GLOBAL_LIST_EMPTY(speakers)
//GLOBAL_LIST_EMPTY(televisions)
//GLOBAL_LIST_EMPTY(radios)

#define AUDIOSOURCES GLOB.speakers
//#define TVSOURCES GLOB.televisions
//#define RADIOSOURCES GLOB.radios

#define PLAY_LOCAL 1
#define PLAY_AREA 0
#define PLAY_GLOBAL -1

#define ALL_SPEAKERS 0

#define SILENT null

/proc/chaticon(icon_state, target=world, icon='code/modules/rpf_imports/loudspeakers/icons/misc_chat.dmi', thissize, classes, w, h)
    return icon2html(icon, target, icon_state, realsize = thissize, extra_classes = classes)

SUBSYSTEM_DEF(loudspeak)
	name = "Announcement"
	wait = 10
	flags = SS_NO_FIRE
	priority = INIT_ORDER_LOUDSPEAK
	runlevels = RUNLEVEL_GAME
	can_fire = 0

/datum/controller/subsystem/loudspeak/Initialize()
	..()

/datum/controller/subsystem/loudspeak/proc/remove_deaf(mobs)
	for(var/mob/m in mobs)
		if(!m.can_hear())
			mobs -= m
	return mobs

/datum/controller/subsystem/loudspeak/proc/get_mobs_around_obj(range, obj)
	var/list/mobs = list()
	if (range == PLAY_GLOBAL)
		var/list/globalmobs = GLOB.mob_list
		return globalmobs
	else if(range == PLAY_AREA)
		var/area/a = get_area(obj)
		if(a)
			for(var/mob/m in a)
				mobs |= m
			return mobs
		else
			message_admins("FATAL ERROR: NO AREA AT LOUDSPEAKER")
			return null
	else if(range >= PLAY_LOCAL)
		for(var/mob/m in view(range, obj))
			mobs |= m
		return mobs

/datum/controller/subsystem/loudspeak/proc/get_clients_from_list(mobs)
	var/list/clients = list()
	for(var/mob/M in mobs)
		if(M.client)
			clients |= M
		else
			continue
	return clients


/datum/controller/subsystem/loudspeak/proc/match_speakers(id)
	if(id == ALL_SPEAKERS)
		return AUDIOSOURCES
	var/list/sources = list()
	for(var/obj/structure/fake_machine/announcementspeaker/source in AUDIOSOURCES)
		if(id == source.id)
			sources |= source
		else
			continue
	return sources

/datum/controller/subsystem/loudspeak/proc/playsound_from_speakers(var/id, var/sound, var/volume, var/variance, var/range = 5)
	if(!id == PLAY_GLOBAL)
		for(var/obj/s in match_speakers(id))
			playsound(s.loc, sound, volume, variance, extrarange = range, falloff_exponent = 1)
	else
		for(var/obj/s in AUDIOSOURCES)
			playsound(s.loc, sound, volume, variance, extrarange = range, falloff_exponent = 1)

/datum/controller/subsystem/loudspeak/proc/ping_speakers(id)
	for(var/obj/s in match_speakers(id))
		soundoverlay(s)

/datum/controller/subsystem/loudspeak/proc/handle_playsound(var/datum/broadcast_template/speakdata, var/list/mobs, var/id, var/sound = null, var/volume = 100, var/vary = 0)
	if(sound)
		ping_speakers(id)
		if(speakdata.broadcast_range <= PLAY_GLOBAL)
			for(var/mob/M in GLOB.mob_list)
				M.playsound_local(M, sound, volume, FALSE)
		else if(speakdata.broadcast_range == PLAY_AREA)
			for(var/mob/M in mobs)
				M.playsound_local(M, sound, volume, FALSE)
		else if(speakdata.broadcast_range >= PLAY_LOCAL)
			playsound_from_speakers(id, sound, volume, vary, speakdata.broadcast_range)

/datum/controller/subsystem/loudspeak/proc/prep_announce(var/datum/broadcast_template/speakdata, id, message, var/datum/language/speaking=null, raw, mute = FALSE)

	var/list/speakers = match_speakers(id)

	var/list/mobs = list()
	for(var/obj/s in speakers)
		mobs |= get_mobs_around_obj(speakdata.broadcast_range, s)
		for(var/mob/M in mobs)
			if(!M.client)
				mobs -= M
			else
				continue

	if(LAZYLEN(speakdata.additional_talk_sound) && !mute)
		SSloudspeak.handle_playsound(speakdata, mobs, id, pick_safe(speakdata.additional_talk_sound), speakdata.additional_talk_sound_volume, speakdata.additional_talk_sound_vary)
	else if(!mute)
		ping_speakers(id)

	if(isnull(message))
		return
	/*
	if(isnull(raw))
		raw = message
	*/
	announce(speakdata, speakers, message, mobs, speaking, raw)

/datum/controller/subsystem/loudspeak/proc/announce(var/datum/broadcast_template/speakdata, speakers, message, mobs, var/datum/language/speaking=null, raw)
	var/width = speakdata.width
	var/height = speakdata.height
/*
	for(var/obj/s in speakers)
		to_world(get_clients_from_list(mobs_in_view(world.view, s)))
		INVOKE_ASYNC(s, /atom/movable/proc/animate_chat, "<span class='[speakdata.speakerstyle]'>[message]</span>", null, 0, get_clients_from_list(mobs_in_view(world.view, s)), 5 SECONDS, 1)
*/
	if(raw)
		for(var/obj/speaker in speakers)
			for(var/mob/M in view(world.view, speaker))
				if(locate(M) in mobs)
					M.create_chat_message(speaker, speaking, raw, spans = list("emote"))
	for(var/mob/M in mobs)
		to_chat(M, span_speaker_event("[chaticon(speakdata.icon, M, w=width, h=height)] [message]"))

/datum/broadcast_template
	var/name = "TEST TEMPLATE" // for admin tool bs

	var/icon = "loudspeaker"
	var/width = null
	var/height = null

	var/broadcast_start_sound = list('code/modules/rpf_imports/loudspeakers/sound/effects/broadcasttest.ogg')
	var/broadcast_start_sound_volume = 85

	var/broadcast_end_sound = list('code/modules/rpf_imports/loudspeakers/sound/effects/broadcasttestend.ogg') //"feedbacknoise"
	var/broadcast_end_sound_volume = 50

	var/list/additional_talk_sound = list('code/modules/rpf_imports/loudspeakers/sound/effects/red_loudspeaker_01.ogg','code/modules/rpf_imports/loudspeakers/sound/effects/red_loudspeaker_02.ogg','code/modules/rpf_imports/loudspeakers/sound/effects/red_loudspeaker_03.ogg','code/modules/rpf_imports/loudspeakers/sound/effects/red_loudspeaker_04.ogg','code/modules/rpf_imports/loudspeakers/sound/effects/red_loudspeaker_05.ogg','code/modules/rpf_imports/loudspeakers/sound/effects/red_loudspeaker_06.ogg')//list('code/modules/rpf_imports/loudspeakers/sound/effects/megaphone_03.ogg','code/modules/rpf_imports/loudspeakers/sound/effects/megaphone_04.ogg')
	var/additional_talk_sound_vary = 0
	var/additional_talk_sound_volume = 75

	var/broadcast_range = PLAY_AREA

/*
	additional_talk_sound = list('code/modules/rpf_imports/loudspeakers/sound/effects/loudspeaker_01.ogg','code/modules/rpf_imports/loudspeakers/sound/effects/loudspeaker_02.ogg','code/modules/rpf_imports/loudspeakers/sound/effects/loudspeaker_03.ogg','code/modules/rpf_imports/loudspeakers/sound/effects/loudspeaker_04.ogg','code/modules/rpf_imports/loudspeakers/sound/effects/loudspeaker_05.ogg')
	additional_talk_sound_volume = 55
	// BLUE ^^
*/
/datum/broadcast_template/hijack
	var/startmsg = span_speaker_event("PLACEHOLDER START MESSAGE.")
	var/endmsg = span_speaker_event("PLACEHOLDER END MESSAGE.")

/datum/broadcast_template/hijack/fcastfem
	name = "Friendcast Female"
	icon = "loudspeaker"
	height = 26
	width = 26

	startmsg = span_speaker_event("STANDBY FOR A FRIENDLY MESSAGE.")
	endmsg = span_speaker_event("FRIENDLY MESSAGE CONCLUDED.")

	broadcast_start_sound = list('code/modules/rpf_imports/loudspeakers/sound/b_templates/friendcast_n2_start.ogg')
	broadcast_start_sound_volume = 85


	broadcast_end_sound = list('code/modules/rpf_imports/loudspeakers/sound/b_templates/friendcast_end.ogg') //"feedbacknoise"
	broadcast_end_sound_volume = 85

	additional_talk_sound = list('code/modules/rpf_imports/loudspeakers/sound/b_templates/fem_01.ogg','code/modules/rpf_imports/loudspeakers/sound/b_templates/fem_02.ogg','code/modules/rpf_imports/loudspeakers/sound/b_templates/fem_03.ogg','code/modules/rpf_imports/loudspeakers/sound/b_templates/fem_04.ogg','code/modules/rpf_imports/loudspeakers/sound/b_templates/fem_05.ogg')

/datum/broadcast_template/hijack/fcastmale
	name = "Friendcast Male"
	icon = "loudspeaker"
	height = 26
	width = 26

	startmsg = span_speaker_event("STANDBY FOR A FRIENDLY MESSAGE.")
	endmsg = span_speaker_event("FRIENDLY MESSAGE CONCLUDED.")

	broadcast_start_sound = list('code/modules/rpf_imports/loudspeakers/sound/b_templates/friendcast_start.ogg')
	broadcast_start_sound_volume = 85


	broadcast_end_sound = list('code/modules/rpf_imports/loudspeakers/sound/b_templates/friendcast_end.ogg') //"feedbacknoise"
	broadcast_end_sound_volume = 85

	additional_talk_sound = list('code/modules/rpf_imports/loudspeakers/sound/b_templates/male_mumble01.ogg','code/modules/rpf_imports/loudspeakers/sound/b_templates/male_mumble02.ogg','code/modules/rpf_imports/loudspeakers/sound/b_templates/male_mumble03.ogg')


/datum/broadcast_template/announcement
	broadcast_start_sound = null//'code/modules/rpf_imports/loudspeakers/sound/effects/announce.ogg'

/datum/broadcast_template/base

	name = "Standard"
	width = 26
	height = 26

/datum/broadcast_template/automated

	name = "Automated"
	width = 26
	height = 26
	additional_talk_sound = list()

/datum/broadcast_template/automated/everyone
	broadcast_range = PLAY_GLOBAL

/datum/broadcast
	var/list/dialogue = list()
	var/id = ALL_SPEAKERS
	var/datum/broadcast_template/template = /datum/broadcast_template/automated

/datum/broadcast/New()
	template = new template

/*
/datum/broadcast/checkpoint
	dialogue = list(
		list('code/modules/rpf_imports/sound/vo/broadcast/roadblocks1_start.ogg', null, null, " The loudspeakers suddenly come to life..", 1.898 SECONDS),
		list('code/modules/rpf_imports/sound/vo/broadcast/roadblocks2.ogg', "PA system", "coldly states,", "Attention, residents. Please be advised, that transit routes through the district may experience delays as a precaution.", 9.925 SECONDS),
		list('code/modules/rpf_imports/sound/vo/broadcast/roadblocks3.ogg', "PA system", "coldly states,", "Residents are reminded to carry identification, and to cooperate with any checkpoint personnel.", 8.519 SECONDS),
	)


/datum/broadcast/curfew_end
	dialogue = list(
		list('code/modules/rpf_imports/sound/vo/broadcast/curst1_start.ogg', null, null, "The loudspeakers suddenly come to life..", 2 SECONDS),
		list('code/modules/rpf_imports/sound/vo/broadcast/curst1.ogg', "PA system", "coldly states,", "Attention, residents. The nightly curfew has been lifted.", 4.989 SECONDS),
		list('code/modules/rpf_imports/sound/vo/broadcast/curst2.ogg', "PA system", "coldly states,", "Report any suspicious activity to the protectors.", 4.787 SECONDS),
		list('code/modules/rpf_imports/sound/vo/broadcast/curst3_end.ogg', "PA system", "coldly states,", "Thank you, for your cooperation.", 2.566 SECONDS),
	)
*/

/*
/datum/broadcast/curfew // sound, name, verb, text, delay // CAN HAVE NAME AND VERB AS NULL
	template = /datum/broadcast_template/automated/everyone
	dialogue = list(
		list('code/modules/rpf_imports/sound/vo/broadcast/curst1_start.ogg', null, null, null, 2 SECONDS),
		list('code/modules/rpf_imports/sound/vo/broadcast/curfewsoft_01.ogg', "UNKNOWN", "coldly speaks", "Please clear the streets, the curfew is now active. No foot traffic is allowed until curfew is lifted.", 10 SECONDS),
		list('code/modules/rpf_imports/sound/vo/broadcast/curfewsoft_02.ogg', "UNKNOWN", "coldly speaks", " All unneccessary visitation has been cancelled until further notice, unless you are otherwise authorized.", 11 SECONDS),
		list('code/modules/rpf_imports/sound/vo/broadcast/curfewsoft_03.ogg', "UNKNOWN", "coldly speaks", "Violators will be subject to interrogation, and detained when neccessary. Remember, the boldest measures are the safest.", 12 SECONDS),
		list('code/modules/rpf_imports/loudspeakers/sound/effects/owannouncer_boop_end.ogg', null, null, " The loudspeakers come to a sudden silence...", 5 SECONDS)
	)
*/
/datum/controller/subsystem/loudspeak/proc/play_broadcast(var/type)
	var/datum/broadcast/B = new type
	B.play()

/datum/broadcast/proc/play()
	for (var/i = 1; i <= length(dialogue); i++)
		var/list/mobs = list()
		for(var/obj/s in AUDIOSOURCES)
			mobs |= SSloudspeak.get_mobs_around_obj(template.broadcast_range, s)
		SSloudspeak.handle_playsound(template, mobs, id, get_sound(i), 85, 0)
		var/text = "[get_name(i)] [get_verb(i)] \"[get_text(i)]\""
		var/bother = TRUE
		if(!get_name(i) && !get_verb(i) && !get_text(i))
			bother = FALSE
		if(bother) // don't bother playing it if there's no text.
			if(!get_name(i) || !get_verb(i))
				SSloudspeak.prep_announce(template, id, get_text(i), null)
			else
				SSloudspeak.prep_announce(template, id, text, null, get_text(i), FALSE)
		sleep(get_delay(i))
	special()
	end()

/datum/broadcast/proc/special()
	return

/datum/broadcast/proc/end()
	qdel(src) // STUPID SO STUPID FUCK!!

/datum/broadcast/proc/get_sound(var/index)
	return dialogue[index][1]

/datum/broadcast/proc/get_name(var/index)
	return dialogue[index][2]

/datum/broadcast/proc/get_verb(var/index)
	return dialogue[index][3]

/datum/broadcast/proc/get_text(var/index)
	return dialogue[index][4]

/datum/broadcast/proc/get_delay(var/index)
	return dialogue[index][5]


/client/var/datum/broadcast/selected = null
/client/var/broadcast_id = ALL_SPEAKERS
/client/var/datum/broadcast_template/hijack/hijacker = null

/client/proc/broadcast_playback()
	set name = "playback broadcast"
	set desc = "redacted"
	set category = "roleplay"

	var/choice = input("Select a broadcast.") as anything in subtypesof(/datum/broadcast)
	if(!choice) return
	selected = new choice()
	selected.play()

/client/proc/broadcast_hijack()
	set name = "hijack loudspeakers"
	set desc = "redacted"
	set category = "roleplay"

	var/choice = input("Select a hijacker?:") as anything in subtypesof(/datum/broadcast_template/hijack/)
	if(!choice) return
	hijacker = new choice()

	var/list/ids = list("CANCEL", "ALL") // Start with "ALL"
	for(var/id in GLOB.speakers)
		ids |= id
	var/id = input("Choose an ID to play to:",) as anything in ids
	if(id == "CANCEL")
		return
	broadcast_id = id
	var/list/mobs = list()
	for(var/obj/s in AUDIOSOURCES)
		mobs |= SSloudspeak.get_mobs_around_obj(hijacker.broadcast_range, s)
	SSloudspeak.prep_announce(hijacker, broadcast_id, null, null, null, FALSE)
	SSloudspeak.handle_playsound(hijacker, mobs, broadcast_id, hijacker.broadcast_start_sound, hijacker.broadcast_start_sound_volume, 0)
	SSloudspeak.announce(hijacker, broadcast_id, hijacker.startmsg, mobs, null, TRUE)

/client/proc/broadcast_hijack_stop()
	set name = "end hijacking"
	set desc = "redacted"
	set category = "roleplay"
	if(!hijacker)
		to_chat(usr, span_info("Start hijacking first."))
		return
	var/list/mobs = list()
	for(var/obj/s in AUDIOSOURCES)
		mobs |= SSloudspeak.get_mobs_around_obj(hijacker.broadcast_range, s)
	SSloudspeak.prep_announce(hijacker, broadcast_id, null, null, null, FALSE)
	SSloudspeak.handle_playsound(hijacker, mobs, broadcast_id, hijacker.broadcast_end_sound, hijacker.broadcast_end_sound_volume, 0)
	SSloudspeak.announce(hijacker, broadcast_id, hijacker.endmsg, mobs, null, TRUE)
	hijacker = null

/client/proc/broadcast_hijack_speak()
	set name = "talk as hijacker"
	set desc = "redacted"
	set category = "roleplay"
	if(!hijacker)
		to_chat(usr, span_info("Start hijacking first."))
		return
	var/raw_message = input("What do you want to say?")
	if(!raw_message) return
	raw_message = replacetext(raw_message, "/", "")
	raw_message = replacetext(raw_message, "~", "")
	raw_message = replacetext(raw_message, "@", "")
	raw_message = replacetext(raw_message, " i ", " I ")
	raw_message = replacetext(raw_message, " ive ", " I've ")
	raw_message = replacetext(raw_message, " im ", " I'm ")
	raw_message = replacetext(raw_message, " u ", " you ")
	var/list/mobs = list()
	for(var/obj/s in AUDIOSOURCES)
		mobs |= SSloudspeak.get_mobs_around_obj(hijacker.broadcast_range, s)
	var/processedmsg = span_speaker_name("UNKNOWN speaks, \"[span_speaker_text(raw_message)]\"")
	SSloudspeak.handle_playsound(hijacker, mobs, broadcast_id, pick(hijacker.additional_talk_sound), hijacker.additional_talk_sound_volume, hijacker.additional_talk_sound_vary)
	SSloudspeak.announce(hijacker, broadcast_id, processedmsg, mobs, null, TRUE)





