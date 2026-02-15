/atom/movable/screen/picture
	plane = 1000
	alpha = 200
	plane = ABOVE_HUD_PLANE

/atom/movable/screen/text/screen_text/atom_picture/
	screen_loc = "SOUTH+2,CENTER-2"
	style_open = "<span class='maptext' style='font-size:20pt;color:#ffffff' valign='middle'>"
	style_close = "</span>"

	var/image_file = 'icons/hammer/source.dmi'
	var/image_to_play_offset_y = 16
	var/image_to_play_offset_x = -32	
	var/image_state = "hint_small"
	sound_effect = 'sound/effects/beepclear.ogg'
	auto_end = FALSE
	use_queue = FALSE

	play_delay = 0.5
	letters_per_update = 3
	var/datum/weakref/tracking_target_ref

	var/min_pixel_x = 60
	var/max_pixel_x = 460
	var/min_pixel_y = -10
	var/max_pixel_y = 430
	var/safe_zone_margin = 16

/atom/movable/screen/text/screen_text/atom_picture/special(var/client/player)
	var/atom/movable/picture = new /atom/movable/screen/picture
	picture.icon = image_file
	picture.icon_state = image_state
	picture.pixel_x = image_to_play_offset_x
	picture.pixel_y = image_to_play_offset_y
	vis_contents += picture
	var/matrix/last = new
	var/matrix/M = new
	M.Scale(0.5,0.5)
	picture.transform = M
	animate(picture, transform = last, time = 0.4 SECONDS, easing = SINE_EASING)

	if(tracking_target_ref)
		tracking_loop()

/atom/movable/screen/text/screen_text/atom_picture/proc/tracking_loop()
	set waitfor = FALSE
	while(tracking_target_ref && owner_ref && !QDELETED(src))
		var/client/owner = owner_ref.resolve()
		var/atom/movable/target = tracking_target_ref.resolve()
		if(!owner || !target || !holder)
			break

		var/turf/target_turf = get_turf(target)
		var/turf/source_turf = get_turf(owner.mob)

		var/is_held_by_owner = (target.loc == owner.mob)
		var/should_hide = (target_turf.z != source_turf.z) || (ismob(target.loc) && !is_held_by_owner)
		var/target_alpha = 0

		var/target_x
		var/target_y

		if(is_held_by_owner && target.screen_loc)
			var/list/pixels = parse_screen_loc_to_pixels(target.screen_loc)
			target_x = pixels["x"]
			target_y = pixels["y"]
		else
			var/dx = (target_turf.x - source_turf.x) * world.icon_size + target.pixel_x - owner.pixel_x
			var/dy = (target_turf.y - source_turf.y) * world.icon_size + target.pixel_y - owner.pixel_y

			target_x = dx + 288
			target_y = dy + 240

		if(!should_hide || findtext(image_state, "_small"))
			target_x -= 32
		else
			target_x -= 16

		var/clamped_x = clamp(target_x, min_pixel_x, max_pixel_x)
		var/clamped_y = clamp(target_y, min_pixel_y, max_pixel_y)

		if(!should_hide)
			var/max_a = initial(alpha) || 255
			var/dist = get_dist(source_turf, target_turf)
			if(!is_held_by_owner && dist <= 3)
				target_alpha = (max_a * 0.5) + ((dist / 3) ** 2) * (max_a * 0.5)
			else
				target_alpha = max_a

			var/outside_safe_zone = (target_x < (min_pixel_x + safe_zone_margin) || target_x > (max_pixel_x - safe_zone_margin) || target_y < (min_pixel_y + safe_zone_margin) || target_y > (max_pixel_y - safe_zone_margin))
			
			if(outside_safe_zone)
				if(src.transform.a != 0) 
					var/matrix/M = matrix()
					M.Scale(0, 0)
					animate(src, transform = M, time = 1 SECOND, easing = SINE_EASING, flags = ANIMATION_PARALLEL)
			else if(src.transform.a == 0)
				animate(src, transform = matrix(), time = 1 SECOND, easing = SINE_EASING, flags = ANIMATION_PARALLEL)
		else
			target_alpha = 0

		animate(src, pixel_x = clamped_x, pixel_y = clamped_y, alpha = target_alpha, time = 1 SECOND, easing = SINE_EASING, flags = ANIMATION_PARALLEL)

		stoplag(1)

/atom/movable/screen/text/screen_text/atom_picture/proc/parse_screen_loc_to_pixels(screen_loc)
	var/static/list/horizontal_keywords = list("WEST" = 1, "EAST" = 18, "CENTER" = 9)
	var/static/list/vertical_keywords = list("SOUTH" = 1, "NORTH" = 15, "CENTER" = 8)

	var/list/parts = splittext(screen_loc, ",")
	var/list/result = list("x" = 0, "y" = 0)

	for(var/i in 1 to 2)
		var/coord_str = parts[i]
		var/tile = 0
		var/pixel = 0

		var/colon_pos = findtext(coord_str, ":")
		if(colon_pos)
			pixel = text2num(copytext(coord_str, colon_pos + 1))
			coord_str = copytext(coord_str, 1, colon_pos)

		var/keywords = (i == 1) ? horizontal_keywords : vertical_keywords
		var/found_keyword = FALSE
		for(var/k in keywords)
			if(findtext(coord_str, k))
				tile = keywords[k]
				found_keyword = TRUE
				
				var/plus_pos = findtext(coord_str, "+")
				var/minus_pos = findtext(coord_str, "-")
				if(plus_pos)
					tile += text2num(copytext(coord_str, plus_pos + 1))
				else if(minus_pos)
					tile -= text2num(copytext(coord_str, minus_pos + 1))
				break
		
		if(!found_keyword)
			tile = text2num(coord_str)

		var/final_pixel = (tile - 1) * 32 + pixel
		
		if(i == 1)
			result["x"] = final_pixel + 16
		else
			result["y"] = final_pixel + 16

	return result
