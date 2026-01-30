// ============================================================================
// MC (MASTER CONTROLLER) TAB - Admin-only subsystem status display
// ============================================================================
// Displays Master Controller and subsystem statistics for admins.
// Shows tick rate, costs, tick usage, and state letters for all subsystems.
// ============================================================================

/datum/statpanel_tab/mc
	id = "mc"
	name = "MC"
	icon = "blank.png"
	priority = 10
	realtime = TRUE

/datum/statpanel_tab/mc/can_view(client/C)
	return !!C?.holder

/datum/statpanel_tab/mc/get_content(client/C)
	if(!C?.holder)
		return ""

	var/href_token = C.holder.href_token

	. = "<table><tr><td valign='top'><table><tr><td>"

	// ==================== SERVER INFO ====================
	. += "<u>|- <b>SERVER INFO</b> -|</u><br>"

	// Location (mob coordinates)
	var/turf/T = get_turf(C.mob)
	var/coord_text = T ? "[T.x], [T.y], [T.z] ([get_area_name(T)])" : "N/A"
	. += "<span class='verb'>Location:</span> <span class='verb dim'>[coord_text]</span><br>"

	// CPU
	. += "<span class='verb'>CPU:</span> <span class='verb dim'>[world.cpu]%</span><br>"

	// Instances (total atoms in world)
	var/instance_count = length(world.contents)
	. += "<span class='verb'>Instances:</span> <span class='verb dim'>[instance_count]</span><br>"

	// World Time
	. += "<span class='verb'>World Time:</span> <span class='verb dim'>[world.time] ([round(world.time / 600, 0.1)] min)</span><br>"

	// Globals (VV link)
	. += "<span class='verb'>Globals:</span> <a href='?_src_=vars;admin_token=[href_token];Vars=[REF(GLOB)]' class='verb dim'>EDIT</a><br>"

	// Configuration (VV link)
	. += "<span class='verb'>Configuration:</span> <a href='?_src_=vars;admin_token=[href_token];Vars=[REF(config)]' class='verb dim'>EDIT</a><br>"

	// Byond stats (FPS, TickCount, TickDrift)
	var/tick_count = round(world.time / world.tick_lag)
	. += "<span class='verb'>Byond:</span> <span class='verb dim'>FPS:[world.fps] TickCount:[tick_count] TickDrift:[round(Master.tickdrift,1)]([round((Master.tickdrift/(world.time/world.tick_lag))*100,0.1)]%)</span><br>"

	. += "<br>"

	// ==================== MASTER CONTROLLER ====================
	. += "<u>|- <b>MASTER CONTROLLER</b> -|</u><br>"

	// Master Controller stats
	var/mc_stat = Master.stat_entry()
	. += "<a href='?_src_=vars;admin_token=[href_token];Vars=[REF(Master)]' class='verb'>Master</a>"
	. += " <span class='verb dim'>[mc_stat]</span><br>"

	// Failsafe status
	if(Failsafe)
		var/failsafe_stat = Failsafe.stat_entry()
		. += "<a href='?_src_=vars;admin_token=[href_token];Vars=[REF(Failsafe)]' class='verb'>Failsafe</a>"
		. += " <span class='verb dim'>[failsafe_stat]</span><br>"

	. += "<br>"

	// ==================== SUBSYSTEMS ====================
	. += "<u>|- <b>SUBSYSTEMS</b> -|</u><br>"

	// Generate subsystem list
	for(var/datum/controller/subsystem/SS in Master.subsystems)
		var/state = SS.state_letter()
		var/stat_msg = SS.stat_entry()

		// Create clickable VV link for the subsystem
		var/ss_name = SS.name
		var/ss_ref = REF(SS)

		. += "<a href='?_src_=vars;admin_token=[href_token];Vars=[ss_ref]' class='verb'>[ss_name] - [state]</a>"
		. += " <span class='verb dim smaller'>[stat_msg]</span><br>"

	. += "</td></tr></table></td></tr></table>"

