/// Adds a silhouette overlay to the VISION_SILHOUETTES_PLANE and moves the atom to VISION_AFFECTED_PLANE
/datum/component/vision_affected
	/// The silhouette overlay for masking
	var/mutable_appearance/mask_overlay
	/// The original plane of the parent atom (to restore on removal)
	var/original_plane

/datum/component/vision_affected/Initialize()
	. = ..()
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

	var/atom/A = parent

	// Store original plane and move to VIS_PLANE
	original_plane = A.plane
	A.plane = VIS_PLANE
	// Use whiteFull for uniform silhouette masking.
	mask_overlay = mutable_appearance('icons/turf/overlays.dmi', "whiteFull", layer = A.layer)
	mask_overlay.plane = VISION_SILHOUETTES_PLANE
	mask_overlay.alpha = 255
	mask_overlay.blend_mode = BLEND_OVERLAY
	A.add_overlay(mask_overlay)

	RegisterSignal(parent, COMSIG_PARENT_QDELETING, PROC_REF(on_parent_delete))

/datum/component/vision_affected/Destroy()
	if(mask_overlay)
		var/atom/A = parent
		A.cut_overlay(mask_overlay)
		mask_overlay = null
		// Restore original plane
		A.plane = original_plane
	return ..()

/datum/component/vision_affected/proc/on_parent_delete()
	SIGNAL_HANDLER
	qdel(src)
