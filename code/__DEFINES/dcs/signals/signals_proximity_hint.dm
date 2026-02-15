// Proximity Hint signals. Format:
// When the signal is called: (signal arguments)
// All signals send the source datum of the signal as the first argument

/// from /datum/component/proximity_hint/check_mob_distance(): (mob/M)
#define COMSIG_PROXIMITY_HINT_TRIGGERED "proximity_hint_triggered"
/// from /datum/component/proximity_hint/check_mob_distance(): (mob/M)
#define COMSIG_PROXIMITY_HINT_ENDED "proximity_hint_ended"
