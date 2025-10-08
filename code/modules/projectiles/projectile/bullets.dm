/obj/projectile/bullet
	name = "bullet"
	icon_state = "bullet"
	damage = 50 // lowered to 50
	damage_type = BRUTE
	nodamage = FALSE
	armor_flag = PUNCTURE
	hitsound_wall = SFX_RICOCHET
	sharpness = SHARP_POINTY
	impact_effect_type = /obj/effect/temp_visual/impact_effect
	shrapnel_type = /obj/item/shrapnel/bullet
	embedding = list(embed_chance=20, fall_chance=0, jostle_chance=0, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.5, pain_mult=3, rip_time=10)
	embed_adjustment_tile = 3

	light_system = OVERLAY_LIGHT
	light_outer_range = 1.5
	light_power = 0.8
	light_color = COLOR_MUZZLE_FLASH
	light_on = TRUE

	muzzle_flash_color_override = COLOR_MUZZLE_FLASH
	hitscan_light_color_override = COLOR_BLACK
	impact_light_color_override = COLOR_BLACK

	hitscan_light_intensity = 0
	impact_light_intensity = 0

	muzzle_type = /obj/effect/projectile/muzzle/bullet
	tracer_type = /obj/effect/projectile/tracer/bullet
	impact_type = /obj/effect/projectile/impact/bullet

	hitscan = TRUE

/obj/projectile/bullet/smite
	name = "divine retribution"
	damage = 10
