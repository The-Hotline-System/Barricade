#define FONT_COLOR "#ffffff"
#define FONT_STYLE "Arial Black"

/atom
	var/allowtooltip = TRUE

/turf/closed/indestructible/hammereditor/
	canSmoothWith = null

/turf/closed/indestructible/hammereditor/dev1
	icon = 'icons/hammer/source.dmi'
	icon_state = "devwall1-0"
	base_icon_state = "devwall1"
	name = "Dev Wall"
	desc = "A wall with pixel measurements.."

/turf/closed/indestructible/hammereditor/dev2
	icon = 'icons/hammer/source.dmi'
	icon_state = "devwall2-0"
	base_icon_state = "devwall2"
	name = "Dev Wall"
	desc = "A wall with pixel measurements.."

/turf/closed/indestructible/hammereditor/dev3
	icon = 'icons/hammer/source.dmi'
	icon_state = "devwall3-0"
	base_icon_state = "devwall3"
	name = "Dev Wall"
	desc = "A wall with pixel measurements.."

/turf/open/floor/hammereditor/dev1
	icon = 'icons/hammer/source.dmi'
	icon_state = "devturf1"
	name = "Dev Turf"
	desc = "A floor with pixel measurements.."

/turf/open/floor/hammereditor/dev12
	icon = 'icons/hammer/source.dmi'
	icon_state = "devturf2"
	name = "Dev Turf"
	desc = "A floor with pixel measurements.."

/turf/open/floor/hammereditor/dev2
	icon = 'icons/hammer/source.dmi'
	icon_state = "devturf3"
	name = "Dev Turf"
	desc = "A floor with pixel measurements.."

/turf/open/floor/hammereditor/dev22
	icon = 'icons/hammer/source.dmi'
	icon_state = "devturf4"
	name = "Dev Turf"
	desc = "A floor with pixel measurements.."

/obj/hammereditor
	allowtooltip = FALSE
	layer = 9999
	mouse_opacity = 0


/obj/hammereditor/New()
	layer = -9999
	icon_state = ""
	name = ""
	desc = ""

/obj/hammereditor/nodraw
	icon = 'icons/hammer/source.dmi' // noone gets through this
	icon_state = "nodraw"
	alpha = 0
	density = 1
	opacity = 0
	anchored = 1

/obj/hammereditor/playerclip
	icon = 'icons/hammer/source.dmi'
	icon_state = "playerclip"
	alpha = 255
	density = 1
	opacity = 0
	anchored = 1
	// throwpass = TRUE
/*
/obj/hammereditor/playerclip/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)//So bullets will fly over and stuff.
	if(air_group || (height==0))
		return 1
	if(istype(mover, /obj/item))
		return 1
	else
		return 0
*/
/obj/hammereditor/bulletclip
	icon = 'icons/hammer/source.dmi' // noone gets through this
	icon_state = "block_bullets"
	anchored = 1
	alpha = 0
	density = 1
	opacity = 0
	// throwpass = TRUE - FIND TG EQUIVALENT
/*
/obj/hammereditor/bulletclip/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)//So bullets will fly over and stuff.
	if(air_group || (height==0)) return 1
	if(istype(mover,/obj/item/projectile))
		return 0
	if(istype(mover) && mover.checkpass(PASS_FLAG_TABLE))
		return 1
	if(istype(mover, /mob/living))
		return 1
*/
/obj/hammereditor/ghostclip
	icon = 'icons/hammer/source.dmi' // noone gets through this
	icon_state = "ghostclip"
	// atom_flags = ATOM_FLAG_GHOSTCLIP - FIND TG EQUIVALENT
	anchored = 1
	alpha = 0
	density = 0
	opacity = 0

/obj/hammereditor/devtext
	icon = 'icons/hammer/source.dmi' // noone gets through this
	icon_state = "dev_text"
	desc = "Think of it as like.. code comments, but in maps!"
	layer = 9999
	anchored = 1
	plane = ABOVE_LIGHTING_PLANE
	var/style = "font-family: 'Fixedsys'; -dm-text-outline: 1 black; font-size: 1px;"
	var/text1
	var/text2
	var/text3
	var/showtext = TRUE

/obj/hammereditor/devtext/New()
	if(!showtext)
		qdel(src)
	var/text = "[text1]<br>[text2]<br>[text3]</div>"
	maptext = "<span style=\"[style]\">[text]</span>"
	maptext_width = 600 // sure whatever
	maptext_height = 600
	maptext_x = 32

// phase it out, it sucks, or redo it (note to self)
/obj/hammereditor/sound_probe // This lets us set an area to have a specific ambience (echo) just by placing this object inside of it.
	icon = 'icons/hammer/source.dmi'
	name = "Sound Probe"
	icon_state = "sound"   // Update with the correct icon state
	var/sound_env
	var/list/ambience
	var/music
/* REWRITE THIS TO USE PROPER TG AREA STUFF LATER
/obj/hammereditor/sound_probe/Initialize()
	var/area/A = get_area(src)
	if (A)
		if(sound_env)
			A.sound_env = sound_env
		if (ambience)
			A.forced_ambience = ambience
		if (music)
			if(music == "none")
				A.music = null
			else
				A.music = music
	qdel(src)

*/ // REWRITE THESE
// World decor
/*
/obj/hammereditor/nodraw/deco
	icon = 'icons/obj/worldbuilding.dmi'
	alpha = 255
	plane = ABOVE_OBJ_PLANE
/obj/hammereditor/nodraw/deco/New()
	return

/obj/hammereditor/nodraw/deco/bars
	icon_state = "bars"

/obj/hammereditor/nodraw/deco/shadowpaint
	icon_state = "shadow"

/obj/hammereditor/nodraw/deco/shutter_half
	icon_state = "mostly_open_shuitter"

/obj/hammereditor/nodraw/deco/shutter_quarter
	icon_state = "slightly_open_shutter"
*/
