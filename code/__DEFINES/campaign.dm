// Campaign persistence defines

/// Persistence flags for atoms
#define PERSISTENCE_NONE 0
/// Marked by staff via context menu
#define PERSISTENCE_STAFF_MARKED (1<<0)
/// This atom should never persist
#define NO_PERSIST (1<<1)
/// This atom persists by default
#define PERSIST_BY_DEFAULT (1<<2)
/// Limited persist - saves location only, no vars/state
#define LIMITED_PERSIST (1<<3)

/// Maximum character slots per player
#define MAX_CHARACTER_SLOTS 3
