/**
 * Helper defines for proximity hints
 */

/// Define a hint stage with text, image state, and optional sound
#define HINT_STAGE(text_val, image_state_val, sound_val) list("text" = text_val, "image" = image_state_val, "sound" = sound_val)

/// Preset: Tutorial hints - Normal range, requires LOS, persistent
#define HINT_PRESET_TUTORIAL list(\
	"trigger_range" = 5, \
	"removal_range" = 8, \
	"check_los" = TRUE, \
	"delete_on_pickup" = FALSE \
)

/// Preset: Pickup hints - Close range, no LOS required, deletes on pickup
#define HINT_PRESET_PICKUP list(\
	"trigger_range" = 3, \
	"removal_range" = 5, \
	"check_los" = FALSE, \
	"delete_on_pickup" = TRUE \
)

/// Preset: Proximity alerts - Far range, no LOS required, persistent
#define HINT_PRESET_PROXIMITY list(\
	"trigger_range" = 7, \
	"removal_range" = 10, \
	"check_los" = FALSE, \
	"delete_on_pickup" = FALSE \
)

/**
 * Usage Examples:
 * 
 * Single-stage hint with preset:
 * AddComponent(/datum/component/proximity_hint, "Pick this up!", preset = HINT_PRESET_PICKUP)
 * 
 * Multi-stage hint:
 * AddComponent(/datum/component/proximity_hint, stages = list(
 *     HINT_STAGE("Find the tool", "pickup_small", 'sound/effects/beepclear.ogg'),
 *     HINT_STAGE("Use the tool", "hint_small", null)
 * ))
 * 
 * Combined preset and custom params:
 * AddComponent(/datum/component/proximity_hint, 
 *     "Custom text",
 *     preset = HINT_PRESET_TUTORIAL,
 *     trigger_range = 7  // Override preset value
 * )
 */
