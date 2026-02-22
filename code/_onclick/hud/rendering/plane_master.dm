/atom/movable/screen/plane_master
	screen_loc = "CENTER"
	icon_state = "blank"
	appearance_flags = PLANE_MASTER|NO_CLIENT_COLOR
	blend_mode = BLEND_OVERLAY
	plane = LOWEST_EVER_PLANE
	var/show_alpha = 255
	var/hide_alpha = 0

	//--rendering relay vars--
	///integer: what plane we will relay this planes render to
	var/render_relay_plane = RENDER_PLANE_GAME
	///bool: Whether this plane should get a render target automatically generated
	var/generate_render_target = TRUE
	///integer: blend mode to apply to the render relay in case you dont want to use the plane_masters blend_mode
	var/blend_mode_override
	///reference: current relay this plane is utilizing to render
	var/atom/movable/render_plane_relay/relay

/atom/movable/screen/plane_master/proc/Show(override)
	alpha = override || show_alpha

/atom/movable/screen/plane_master/proc/Hide(override)
	alpha = override || hide_alpha

//Why do plane masters need a backdrop sometimes? Read https://secure.byond.com/forum/?post=2141928
//Trust me, you need one. Period. If you don't think you do, you're doing something extremely wrong.
/atom/movable/screen/plane_master/proc/backdrop(mob/mymob)
	SHOULD_CALL_PARENT(TRUE)
	if(!isnull(render_relay_plane))
		relay_render_to_plane(mymob, render_relay_plane)

///Contains just the floor
/atom/movable/screen/plane_master/floor
	name = "floor plane master"
	plane = FLOOR_PLANE
	blend_mode = BLEND_OVERLAY

///Contains most things in the game world
/atom/movable/screen/plane_master/game_world
	name = "game world plane master"
	plane = GAME_PLANE
	blend_mode = BLEND_OVERLAY

///Relays non-visible plane content back to game plane
/atom/movable/screen/plane_master/nonvis
	name = "non-visible plane master"
	plane = NONVIS_PLANE
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/seethrough
	name = "Seethrough"
	plane = SEETHROUGH_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/massive_obj
	name = "massive object plane master"
	plane = MASSIVE_OBJ_PLANE
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/ghost
	name = "ghost plane master"
	plane = GHOST_PLANE
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_NON_GAME

/atom/movable/screen/plane_master/point
	name = "point plane master"
	plane = POINT_PLANE
	blend_mode = BLEND_OVERLAY

/**
 * Plane master handling byond internal blackness
 * vars are set as to replicate behavior when rendering to other planes
 * do not touch this unless you know what you are doing
 */
/atom/movable/screen/plane_master/blackness
	name = "darkness plane master"
	plane = BLACKNESS_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_MULTIPLY
	blend_mode_override = BLEND_OVERLAY
	appearance_flags = PLANE_MASTER | NO_CLIENT_COLOR | PIXEL_SCALE
	//byond internal end

///Contains all lighting objects
/atom/movable/screen/plane_master/lighting
	name = "lighting plane master"
	plane = LIGHTING_PLANE
	blend_mode_override = BLEND_MULTIPLY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT


/atom/movable/screen/plane_master/lighting/backdrop(mob/mymob)
	. = ..()
	mymob.overlay_fullscreen("lighting_backdrop_lit", /atom/movable/screen/fullscreen/lighting_backdrop/lit)
	mymob.overlay_fullscreen("lighting_backdrop_unlit", /atom/movable/screen/fullscreen/lighting_backdrop/unlit)

/*!
 * This system works by exploiting BYONDs color matrix filter to use layers to handle emissive blockers.
 *
 * Emissive overlays are pasted with an atom color that converts them to be entirely some specific color.
 * Emissive blockers are pasted with an atom color that converts them to be entirely some different color.
 * Emissive overlays and emissive blockers are put onto the same plane.
 * The layers for the emissive overlays and emissive blockers cause them to mask eachother similar to normal BYOND objects.
 * A color matrix filter is applied to the emissive plane to mask out anything that isn't whatever the emissive color is.
 * This is then used to alpha mask the lighting plane.
 */
/atom/movable/screen/plane_master/lighting/Initialize(mapload)
	. = ..()
	add_filter("emissives", 1, alpha_mask_filter(render_source = EMISSIVE_RENDER_TARGET, flags = MASK_INVERSE))
	add_filter("object_lighting", 2, alpha_mask_filter(render_source = O_LIGHTING_VISUAL_RENDER_TARGET, flags = MASK_INVERSE))

/atom/movable/screen/plane_master/additive_lighting
	name = "additive lighting plane master"
	plane = LIGHTING_PLANE_ADDITIVE
	blend_mode_override = BLEND_ADD
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/**
 * Handles emissive overlays and emissive blockers.
 */
/atom/movable/screen/plane_master/emissive
	name = "emissive plane master"
	plane = EMISSIVE_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = EMISSIVE_RENDER_TARGET
	render_relay_plane = null

/atom/movable/screen/plane_master/emissive/Initialize(mapload)
	. = ..()
	add_filter("em_block_masking", 1, color_matrix_filter(GLOB.em_mask_matrix))

/atom/movable/screen/plane_master/above_lighting
	name = "above lighting plane master"
	plane = ABOVE_LIGHTING_PLANE
	blend_mode = BLEND_OVERLAY

///Contains space parallax
/atom/movable/screen/plane_master/parallax
	name = "parallax plane master"
	plane = PLANE_SPACE_PARALLAX
	blend_mode = BLEND_MULTIPLY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/parallax_white
	name = "parallax whitifier plane master"
	plane = PLANE_SPACE

/atom/movable/screen/plane_master/pipecrawl
	name = "pipecrawl plane master"
	plane = PIPECRAWL_IMAGES_PLANE
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/pipecrawl/Initialize(mapload)
	. = ..()
	// Makes everything on this plane slightly brighter
	// Has a nice effect, makes thing stand out
	color = list(1.2,0,0,0, 0,1.2,0,0, 0,0,1.2,0, 0,0,0,1, 0,0,0,0)
	// This serves a similar purpose, I want the pipes to pop
	add_filter("pipe_dropshadow", 1, drop_shadow_filter(x = -1, y= -1, size = 1, color = "#0000007A"))

/atom/movable/screen/plane_master/camera_static
	name = "camera static plane master"
	plane = CAMERA_STATIC_PLANE
	blend_mode = BLEND_OVERLAY

/atom/movable/screen/plane_master/o_light_visual
	name = "overlight light visual plane master"
	plane = O_LIGHTING_VISUAL_PLANE
	render_target = O_LIGHTING_VISUAL_RENDER_TARGET
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_MULTIPLY
	blend_mode_override = BLEND_MULTIPLY

/atom/movable/screen/plane_master/runechat
	name = "runechat plane master"
	plane = RUNECHAT_PLANE
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_NON_GAME

/atom/movable/screen/plane_master/gravpulse
	name = "gravpulse plane"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = GRAVITY_PULSE_PLANE
	blend_mode = BLEND_ADD
	blend_mode_override = BLEND_ADD
	render_target = GRAVITY_PULSE_RENDER_TARGET
	render_relay_plane = null

/atom/movable/screen/plane_master/heat
	name = "heat plane"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = HEAT_PLANE
	render_target = HEAT_COMPOSITE_RENDER_TARGET
	render_relay_plane = null
	var/obj/gas_heat_object = null

/atom/movable/screen/plane_master/heat/New()
	. = ..()
	gas_heat_object = new /obj/effect/abstract/particle_emitter/heat(null, -1)
	gas_heat_object.particles?.count = 250
	gas_heat_object.particles?.spawning = 15
	add_viscontents(gas_heat_object)

/atom/movable/screen/plane_master/area
	name = "area plane"
	plane = AREA_PLANE

/atom/movable/screen/plane_master/radtext
	name = "radtext plane"
	plane = RAD_TEXT_PLANE
	render_relay_plane = RENDER_PLANE_NON_GAME

/atom/movable/screen/plane_master/balloon_chat
	name = "balloon alert plane"
	plane = BALLOON_CHAT_PLANE
	render_relay_plane = RENDER_PLANE_NON_GAME

/atom/movable/screen/plane_master/fullscreen
	name = "fullscreen alert plane"
	plane = FULLSCREEN_PLANE
	render_relay_plane = RENDER_PLANE_NON_GAME
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/hud
	name = "HUD plane"
	plane = HUD_PLANE
	render_relay_plane = RENDER_PLANE_NON_GAME

/atom/movable/screen/plane_master/above_hud
	name = "above HUD plane"
	plane = ABOVE_HUD_PLANE
	render_relay_plane = RENDER_PLANE_NON_GAME

/atom/movable/screen/plane_master/reflection
	name = "reflection plane master"
	plane = REFLECTION_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	//render_source = GAME_PLANE_RENDER_TARGET
	screen_loc = "CENTER, CENTER-1:-16"
	color = "#c4c4c4"
	///What plane we're masked by
	var/masking_plane = REFLECTIVE_PLANE_RENDER_TARGET
	var/masking_all_plane = REFLECTIVE_ALL_PLANE_RENDER_TARGET

/atom/movable/screen/plane_master/reflection/above
	name = "reflection plane above master"
	plane = REFLECTION_PLANE_ABOVE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	masking_plane = REFLECTIVE_PLANE_ABOVE_RENDER_TARGET
	masking_all_plane = REFLECTIVE_ALL_ABOVE_PLANE_RENDER_TARGET

/atom/movable/screen/plane_master/reflection/Initialize(mapload)
	. = ..()
	var/matrix/n_transform = transform
	//n_transform.Translate(0, -32)
	transform = n_transform
	add_filter("reflections masking other", 1, alpha_mask_filter(render_source = DEFILTER_MANUAL_REFLECTIVE_PLANE_MASK_RENDER_TARGET, flags = MASK_INVERSE))
	add_filter("displacement", 1.1, displacement_map_filter(render_source = REFLECTIVE_DISPLACEMENT_PLANE_RENDER_TARGET, size = 42))
	add_filter("reflections", 1.2, alpha_mask_filter(render_source = masking_plane))
	add_filter("manual reflections", 1.3, layering_filter(render_source = DEFILTER_MANUAL_REFLECTIVE_PLANE_RENDER_TARGET))
	add_filter("motion_blur", 1.4, motion_blur_filter(y = 0.7))
	add_filter("reflections full", 1.5, alpha_mask_filter(render_source = masking_all_plane))

/atom/movable/screen/plane_master/manual_reflection
	name = "manual reflection plane master"
	plane = MANUAL_REFLECTIVE_PLANE
	render_target = MANUAL_REFLECTIVE_PLANE_RENDER_TARGET
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_plane = RENDER_PLANE_GAME  // Relay to game plane for click detection

/atom/movable/screen/plane_master/manual_reflection/defilter
	name = "defilter manual reflection plane master"
	plane = DEFILTER_MANUAL_REFLECTIVE_PLANE
	render_source = MANUAL_REFLECTIVE_PLANE_RENDER_TARGET
	render_target = DEFILTER_MANUAL_REFLECTIVE_PLANE_RENDER_TARGET

/atom/movable/screen/plane_master/manual_reflection/defilter/Initialize(mapload)
	. = ..()
	// Mask manual reflections to only show on shiny tiles
	add_filter("mask_to_shiny", 1, alpha_mask_filter(render_source = REFLECTIVE_ALL_PLANE_RENDER_TARGET))
	// Then mask them by the blocker - don't show reflections where blocker is white
	add_filter("mask_by_blocker", 2, alpha_mask_filter(render_source = VISION_BLOCKER_RENDER_TARGET, flags = MASK_INVERSE))

/atom/movable/screen/plane_master/manual_reflection_mask
	name = "manual reflection mask plane master"
	plane = MANUAL_REFLECTIVE_MASK_PLANE
	render_target = MANUAL_REFLECTIVE_MASK_PLANE_RENDER_TARGET
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/plane_master/manual_reflection_mask/defilter
	name = "defilter manual reflection mask plane master"
	plane = DEFILTER_MANUAL_REFLECTIVE_MASK_PLANE
	render_source = MANUAL_REFLECTIVE_MASK_PLANE_RENDER_TARGET
	render_target = DEFILTER_MANUAL_REFLECTIVE_PLANE_MASK_RENDER_TARGET

/atom/movable/screen/plane_master/manual_reflection_mask/defilter/backdrop(mob/mymob)
	. = ..()
	remove_filter("eye_blur")
	if(istype(mymob) && mymob.eye_blurry)
		add_filter("eye_blur", 1, gauss_blur_filter(clamp(mymob.eye_blurry * 0.1, 0.6, 3)))


//
/atom/movable/screen/plane_master/reflective
	name = "reflective plane master"
	plane = REFLECTIVE_PLANE
	appearance_flags = PLANE_MASTER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = REFLECTIVE_PLANE_RENDER_TARGET

/atom/movable/screen/plane_master/reflective/Initialize(mapload)
	. = ..()
	var/matrix/n_transofrm = transform
	n_transofrm.Translate(0, 32)
	transform = n_transofrm

/atom/movable/screen/plane_master/reflective/above
	name = "reflective plane above master"
	plane = REFLECTIVE_PLANE_ABOVE
	render_target = REFLECTIVE_PLANE_ABOVE_RENDER_TARGET

/atom/movable/screen/plane_master/reflective/all
	name = "reflective all plane master"
	plane = REFLECTIVE_ALL_PLANE
	render_target = REFLECTIVE_ALL_PLANE_RENDER_TARGET

/atom/movable/screen/plane_master/reflective/all/above
	name = "reflective all above plane master"
	plane = REFLECTIVE_ALL_ABOVE_PLANE
	render_target = REFLECTIVE_ALL_ABOVE_PLANE_RENDER_TARGET

/atom/movable/screen/plane_master/reflective/displacement
	name = "reflective displacement plane master"
	plane = REFLECTIVE_DISPLACEMENT_PLANE
	render_target = REFLECTIVE_DISPLACEMENT_PLANE_RENDER_TARGET


// -- OPENSPACE SHADOWER PLANE MASTER --

/// Handles the lighting multiplier/shadower that darkens openspace areas
/// This renders above the blurred mimic content
/atom/movable/screen/plane_master/openspace_shadower
	name = "openspace shadower plane master"
	plane = OPENSPACE_SHADOWER_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

// -- OPENSPACE BLUR PLANE MASTERS --

/// Applies blur to openspace mimicked content (turfs, mobs, objs)
/// Mimics render to this plane, blur is applied, then relayed to game
/// Base plane for depth 0
/atom/movable/screen/plane_master/openspace_blur
	name = "openspace blur plane master"
	plane = OPENSPACE_BLUR_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_OVERLAY
	render_relay_plane = OPENSPACE_ZMIMIC_MASK_PLANE  // Relay to mask plane instead of game plane

/atom/movable/screen/plane_master/openspace_blur/Initialize(mapload)
	. = ..()

/atom/movable/screen/plane_master/openspace_blur/backdrop(mob/mymob)
	. = ..()
	relay_render_to_plane(mymob, render_relay_plane)
	add_filter("mimic_blur", 1, gauss_blur_filter(0.6)) // BARRICADE EDIT - Z LEVEL BLURRING VALUE, TWEAK THIS.
	// No depth darkening for base plane (depth 0)

// Create plane masters for each depth level (up to ZMIMIC_MAX_DEPTH)
/atom/movable/screen/plane_master/openspace_blur/depth1
	name = "openspace blur depth 1"
	plane = OPENSPACE_BLUR_PLANE - 1

/atom/movable/screen/plane_master/openspace_blur/depth1/backdrop(mob/mymob)
	. = ..()
	// Apply depth-based darkening matching shadower approach (BLEND_MULTIPLY style)
	// Depth 1: Slightly darker than base (0.85 = #D9D9D9)
	color = "#D9D9D9"

/atom/movable/screen/plane_master/openspace_blur/depth2
	name = "openspace blur depth 2"
	plane = OPENSPACE_BLUR_PLANE - 2

/atom/movable/screen/plane_master/openspace_blur/depth2/backdrop(mob/mymob)
	. = ..()
	// Depth 2: Similar to shadower base darkening (0.65 = #A6A6A6)
	color = "#A6A6A6"

/atom/movable/screen/plane_master/openspace_blur/depth3
	name = "openspace blur depth 3"
	plane = OPENSPACE_BLUR_PLANE - 3

/atom/movable/screen/plane_master/openspace_blur/depth3/backdrop(mob/mymob)
	. = ..()
	// Depth 3: Significantly darker (0.45 = #737373)
	color = "#737373"

/atom/movable/screen/plane_master/openspace_blur/depth4
	name = "openspace blur depth 4"
	plane = OPENSPACE_BLUR_PLANE - 4

/atom/movable/screen/plane_master/openspace_blur/depth4/backdrop(mob/mymob)
	. = ..()
	// Depth 4: Very dark (0.25 = #404040)
	color = "#404040"

/atom/movable/screen/plane_master/openspace_blur/depth5
	name = "openspace blur depth 5"
	plane = OPENSPACE_BLUR_PLANE - 5

/atom/movable/screen/plane_master/openspace_blur/depth5/backdrop(mob/mymob)
	. = ..()
	// Depth 5+: Nearly black (0.05 = #0D0D0D)
	color = "#0D0D0D"

/atom/movable/screen/plane_master/openspace_blur/depth6
	name = "openspace blur depth 6"
	plane = OPENSPACE_BLUR_PLANE - 6

/atom/movable/screen/plane_master/openspace_blur/depth6/backdrop(mob/mymob)
	. = ..()
	color = "#0D0D0D"

/atom/movable/screen/plane_master/openspace_blur/depth7
	name = "openspace blur depth 7"
	plane = OPENSPACE_BLUR_PLANE - 7

/atom/movable/screen/plane_master/openspace_blur/depth7/backdrop(mob/mymob)
	. = ..()
	color = "#0D0D0D"

/atom/movable/screen/plane_master/openspace_blur/depth8
	name = "openspace blur depth 8"
	plane = OPENSPACE_BLUR_PLANE - 8

/atom/movable/screen/plane_master/openspace_blur/depth8/backdrop(mob/mymob)
	. = ..()
	color = "#0D0D0D"

/atom/movable/screen/plane_master/openspace_blur/depth9
	name = "openspace blur depth 9"
	plane = OPENSPACE_BLUR_PLANE - 9

/atom/movable/screen/plane_master/openspace_blur/depth9/backdrop(mob/mymob)
	. = ..()
	color = "#0D0D0D"

/atom/movable/screen/plane_master/openspace_blur/depth10
	name = "openspace blur depth 10"
	plane = OPENSPACE_BLUR_PLANE - 10

/atom/movable/screen/plane_master/openspace_blur/depth10/backdrop(mob/mymob)
	. = ..()
	color = "#0D0D0D"

/// Composite plane that receives all z-mimic blur planes and relays to game
/// This plane does NOT apply FOV masking - that's handled per-item via vision_affected component
/atom/movable/screen/plane_master/openspace_zmimic_mask
	name = "openspace z-mimic composite plane master"
	plane = OPENSPACE_ZMIMIC_MASK_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/openspace_zmimic_mask/backdrop(mob/mymob)
	. = ..()
	relay_render_to_plane(mymob, render_relay_plane)
	// No FOV masking here - vision-affected items handle their own masking via silhouettes

// -- VISION MASKING PLANE MASTERS --

/// Plane for vision-affected atoms that will be masked by FOV blockers
/atom/movable/screen/plane_master/vision_affected
	name = "vision affected plane master"
	plane = VIS_PLANE
	render_target = VISION_AFFECTED_RENDER_TARGET
	blend_mode = BLEND_OVERLAY
	render_relay_plane = RENDER_PLANE_GAME

/atom/movable/screen/plane_master/vision_affected/Initialize(mapload)
	. = ..()
	// Apply vision masking to hide mobs/items covered by FOV blocker
	add_filter("fov_vision_masking", 1, alpha_mask_filter(render_source = VISION_MASK_RENDER_TARGET, flags = MASK_INVERSE))

/// Plane for vision-affected z-mimic atoms that will be masked by FOV blockers
/// These are created dynamically for each z-mimic depth level
/atom/movable/screen/plane_master/vision_affected_zmimic
	name = "vision affected z-mimic plane master"
	blend_mode = BLEND_OVERLAY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_relay_plane = OPENSPACE_ZMIMIC_MASK_PLANE  // Relay to composite plane
	/// Depth level for this plane master
	var/depth_level = 0

/atom/movable/screen/plane_master/vision_affected_zmimic/backdrop(mob/mymob)
	. = ..()
	relay_render_to_plane(mymob, render_relay_plane)
	// Apply blur for z-mimic depth
	add_filter("mimic_blur", 1, gauss_blur_filter(0.6))
	// Apply z-mimic vision masking to hide z-mimic objects covered by FOV blocker
	add_filter("fov_vision_masking_zmimic", 2, alpha_mask_filter(render_source = VISION_MASK_ZMIMIC_RENDER_TARGET, flags = MASK_INVERSE))

/// Plane for white silhouettes of mobs/items
/atom/movable/screen/plane_master/vision_silhouettes
	name = "vision silhouettes plane master"
	plane = VISION_SILHOUETTES_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = VISION_SILHOUETTES_RENDER_TARGET
	render_relay_plane = null

/// Plane for white silhouettes of z-mimic mobs/items (base plane, depth 0)
/// Additional planes are created dynamically for each depth level
/atom/movable/screen/plane_master/vision_silhouettes_zmimic
	name = "vision silhouettes z-mimic plane master"
	plane = VISION_SILHOUETTES_ZMIMIC_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = VISION_SILHOUETTES_ZMIMIC_RENDER_TARGET
	render_relay_plane = null
	/// Depth level for this plane master (0 = base)
	var/depth_level = 0

/// Plane for the FOV blocker overlay
/atom/movable/screen/plane_master/vision_blocker
	name = "vision blocker plane master"
	plane = VISION_BLOCKER_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = VISION_BLOCKER_RENDER_TARGET
	render_relay_plane = null

/// Plane for exclusions - white areas here will NOT be masked by FOV
/atom/movable/screen/plane_master/vision_exclusion
	name = "vision exclusion plane master"
	plane = VISION_EXCLUSION_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = VISION_EXCLUSION_RENDER_TARGET
	render_relay_plane = null

/// Plane for z-mimic exclusions - relays the regular exclusion for z-mimic masking
/atom/movable/screen/plane_master/vision_exclusion_zmimic
	name = "vision exclusion z-mimic plane master"
	plane = VISION_EXCLUSION_ZMIMIC_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = VISION_EXCLUSION_ZMIMIC_RENDER_TARGET
	render_relay_plane = null

/atom/movable/screen/plane_master/vision_exclusion_zmimic/Initialize(mapload)
	. = ..()
	// Layer the regular exclusion so it applies to z-mimic masking too
	add_filter("relay_exclusion", 1, layering_filter(render_source = VISION_EXCLUSION_RENDER_TARGET))

/// Plane for the final composite mask - silhouettes masked by blocker, minus exclusions
/atom/movable/screen/plane_master/vision_mask
	name = "vision mask plane master"
	plane = VISION_MASK_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = VISION_MASK_RENDER_TARGET
	render_relay_plane = null

/atom/movable/screen/plane_master/vision_mask/Initialize(mapload)
	. = ..()
	// Layer the regular silhouettes
	add_filter("add_silhouettes", 1, layering_filter(render_source = VISION_SILHOUETTES_RENDER_TARGET))
	// Mask them by the blocker - only show silhouettes where blocker is white
	add_filter("mask_by_blocker", 2, alpha_mask_filter(render_source = VISION_BLOCKER_RENDER_TARGET))
	// Remove areas marked as exclusions (inverse mask - hide where exclusions are white)
	add_filter("remove_exclusions", 3, alpha_mask_filter(render_source = VISION_EXCLUSION_RENDER_TARGET, flags = MASK_INVERSE))

/// Plane for the z-mimic composite mask - z-mimic silhouettes masked by blocker, minus exclusions
/atom/movable/screen/plane_master/vision_mask_zmimic
	name = "vision mask z-mimic plane master"
	plane = VISION_MASK_ZMIMIC_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	render_target = VISION_MASK_ZMIMIC_RENDER_TARGET
	render_relay_plane = null

/atom/movable/screen/plane_master/vision_mask_zmimic/Initialize(mapload)
	. = ..()
	var/filter_index = 1

	// Add all z-mimic silhouette planes (one for each depth level)
	// ZMIMIC_MAX_DEPTH is defined in zcopy.dm as 10
	for(var/depth = 0; depth < 10; depth++)  // 10 = ZMIMIC_MAX_DEPTH
		var/render_target = "*VISION_SILHOUETTES_ZMIMIC_[depth]"
		add_filter("add_silhouettes_zmimic_[depth]", filter_index++, layering_filter(render_source = render_target))

	// Mask them by the blocker - only show silhouettes where blocker is white
	add_filter("mask_by_blocker", filter_index++, alpha_mask_filter(render_source = VISION_BLOCKER_RENDER_TARGET))

	// Remove areas marked as exclusions (inverse mask - hide where exclusions are white)
	// Use the z-mimic exclusion render target which relays the regular exclusion
	add_filter("remove_exclusions", filter_index++, alpha_mask_filter(render_source = VISION_EXCLUSION_ZMIMIC_RENDER_TARGET, flags = MASK_INVERSE))
