/*
GLOBAL_LIST_EMPTY(CellDoors)

/obj/structure/door/bars/cell
	name = "cell door"

/obj/structure/door/bars/cell/Initialize()
	GLOB.CellDoors += src
	. = ..()

/obj/structure/door/bars/cell/Destroy()
	GLOB.CellDoors -= src
	. = ..()
*/
/obj/effect/announcement_controller
	icon = 'icons/hammer/source.dmi'
	icon_state = "missingasset"
	anchored = TRUE
	alpha = 125

/obj/effect/announcement_controller/Initialize()
	// GLOB.TodUpdate += src
	. = ..()

/obj/effect/announcement_controller/proc/update_tod(todd)
	switch(todd)
		if("dawn")	SSloudspeak.play_broadcast(/datum/broadcast/dawn)
		if("day")	SSloudspeak.play_broadcast(/datum/broadcast/day)
		if("dusk")	SSloudspeak.play_broadcast(/datum/broadcast/dusk)
		if("night")	SSloudspeak.play_broadcast(/datum/broadcast/night)
	return

/obj/effect/announcement_controller/Destroy()
	// GLOB.TodUpdate -= src
	return ..()

/datum/broadcast/dawn
	dialogue = list(
		list('code/modules/rpf_imports/loudspeakers/sound/effects/announce_edited.ogg', null, null, span_speaker_event("The loudspeakers play a melodious chime, signifying that an announcement is beginning."), 2 SECONDS),
		list('code/modules/rpf_imports/loudspeakers/sound/vo/bcast/morning_count.ogg', span_speaker_name("PA system"), span_speaker_name("coldly states,"), span_speaker_text("Step out of your cells for the morning count"), 3.5 SECONDS)
		)

/datum/broadcast/dawn/special()
	. = ..()
	// for(var/obj/structure/door/D in GLOB.CellDoors)
	//	D.Open()
	//	D.locked = FALSE

/datum/broadcast/day
	dialogue = list(
		list('code/modules/rpf_imports/loudspeakers/sound/effects/announce_edited.ogg', null, null, span_speaker_event("The loudspeakers play a melodious chime, signifying that it is now the day."), 2 SECONDS),
		)

/datum/broadcast/dusk
	dialogue = list(
		list('code/modules/rpf_imports/loudspeakers/sound/effects/announce_edited.ogg', null, null, span_speaker_event("The loudspeakers play a melodious chime, signifying that an announcement is beginning."), 2 SECONDS),
		list('code/modules/rpf_imports/loudspeakers/sound/vo/bcast/1min_lockdown.ogg', span_speaker_name("PA system"), span_speaker_name("coldly states,"), span_speaker_text("Attention. Attention. One minute till lockdown. Return to your cells."), 30 SECONDS),
		list('code/modules/rpf_imports/loudspeakers/sound/vo/bcast/30sec_lockdown.ogg', span_speaker_name("PA system"), span_speaker_name("coldly states,"), span_speaker_text("Attention. Attention. Thirty seconds till lockdown. Return to your cells."), 30 SECONDS),
		list('code/modules/rpf_imports/loudspeakers/sound/vo/bcast/night_lockdown.ogg', span_speaker_name("PA system"), span_speaker_name("coldly states,"), span_speaker_text("The nightly lockdown is now in effect."), 2 SECONDS),
		list(null, null, null, "The speakers are silent once more.", 0.25 SECONDS)
	)

/datum/broadcast/dusk/special()
	. = ..()
	// for(var/obj/structure/door/D in GLOB.CellDoors)
	//	D.Close()
	//	D.locked = TRUE

/datum/broadcast/night
	dialogue = list(
		list('code/modules/rpf_imports/loudspeakers/sound/effects/announce_edited.ogg', null, null, "The loudspeakers suddenly come to life..", 1.898 SECONDS),
		list('code/modules/rpf_imports/loudspeakers/sound/vo/bcast/tod/night.ogg', "PA system", "coldly states,", "Night", 3 SECONDS),
		list(null, null, null, "The speakers are silent once more.", 1 SECONDS)
		)
