#define FONT_COLOR "#ffffff"
#define FONT_STYLE "Arial Black"

/atom
	var/allowtooltip = TRUE

/turf/closed/indestructible/orange/
	canSmoothWith = null

/turf/closed/indestructible/orange/dev1
	icon = 'icons/hammer/source.dmi'
	icon_state = "devwall1-0"
	base_icon_state = "devwall1"
	name = "Dev Wall"
	desc = "A wall with pixel measurements.."

/turf/closed/indestructible/orange/dev2
	icon = 'icons/hammer/source.dmi'
	icon_state = "devwall2-0"
	base_icon_state = "devwall2"
	name = "Dev Wall"
	desc = "A wall with pixel measurements.."

/turf/closed/indestructible/orange/dev3
	icon = 'icons/hammer/source.dmi'
	icon_state = "devwall3-0"
	base_icon_state = "devwall3"
	name = "Dev Wall"
	desc = "A wall with pixel measurements.."

/turf/open/floor/orange/dev1
	icon = 'icons/hammer/source.dmi'
	icon_state = "devturf1"
	name = "Dev Turf"
	desc = "A floor with pixel measurements.."

/turf/open/floor/orange/dev12
	icon = 'icons/hammer/source.dmi'
	icon_state = "devturf2"
	name = "Dev Turf"
	desc = "A floor with pixel measurements.."

/turf/open/floor/orange/dev2
	icon = 'icons/hammer/source.dmi'
	icon_state = "devturf3"
	name = "Dev Turf"
	desc = "A floor with pixel measurements.."

/turf/open/floor/orange/dev22
	icon = 'icons/hammer/source.dmi'
	icon_state = "devturf4"
	name = "Dev Turf"
	desc = "A floor with pixel measurements.."

/obj/orange
	allowtooltip = FALSE
	layer = 9999
	mouse_opacity = 0

/obj/orange/devtext
	icon = 'icons/hammer/source.dmi'
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

/obj/orange/devtext/New()
	if(!showtext)
		qdel(src)
	var/text = "[text1]<br>[text2]<br>[text3]</div>"
	maptext = "<span style=\"[style]\">[text]</span>"
	maptext_width = 600 // sure whatever
	maptext_height = 600
	maptext_x = 32
