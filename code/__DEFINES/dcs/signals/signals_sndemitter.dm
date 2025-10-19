// sound emitter signals. Format:
// When the signal is called: (signal arguments)
// All signals send the source datum of the signal as the first argument


/// Raised when a sound emitter's sound was updated.
/// From base of /datum/sound_emitter/proc/play_once(): (sound/S, interrupt = FALSE)
#define COMSIG_EMITTER_SND_UPDATED "emitter_snd_updated"

/// Raised when a sound emitter started playing a sound.
#define COMSIG_EMITTER_SND_STARTED "emitter_snd_started"

/// Raised when a sound emitter stopped playing a sound.
#define COMSIG_EMITTER_SND_STOPPED "emitter_snd_stopped"

/// Raised when a sound was pushed.
#define COMSIG_EMITTER_SND_PUSHED "emitter_snd_pushed"
