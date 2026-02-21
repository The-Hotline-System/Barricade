# Datumized Intent System

## Overview

This system separates combat mode from intent selection, creating a more flexible and extensible interaction framework. Instead of combat mode automatically switching between help/harm, players explicitly choose their intent which determines interaction behavior.

## Key Changes

### Before (Combat Mode System)

- Combat mode ON = Harm intent
- Combat mode OFF = Help intent
- Limited to binary choice
- Tightly coupled with click handling

### After (Datumized Intent System)

- Combat mode is separate from intent
- Intents are datum objects with defined behaviors
- Four base intents: Help, Disarm, Grab, Harm
- Easily extensible for new intents

## Architecture

### Base Datum: `/datum/intent`

Defines the interface for all intents:

- `on_close_range_interact()` - Handles close range (adjacent) left click interactions - THIS IS WHERE BEHAVIORS GO
- `on_ranged_interact()` - Handles ranged left click interactions
- `on_close_range_secondary()` - Handles close range (adjacent) right click interactions
- `on_ranged_secondary()` - Handles ranged right click interactions
- `on_object_interact()` - Handles interactions with objects
- `get_screentip_text()` - Provides contextual tooltips

Note: `on_unarmed_attack()` is deprecated and should not be used.

### Intent Types

#### Help Intent (`/datum/intent/help`)

- Non-aggressive, allows passing through mobs
- Performs CPR on unconscious targets
- Gentle interactions (pat, hug, nuzzle, help up)
- Directly calls `help_shake_act()` on carbon targets

#### Disarm Intent (`/datum/intent/disarm`)

- Aggressive, blocks movement
- Pushes and disarms targets
- Defensive combat option
- Directly calls `disarm()` on carbon targets

#### Grab Intent (`/datum/intent/grab`)

- Non-aggressive, doesn't block movement
- Initiates grabs on targets
- For restraining without harm
- Directly calls `try_make_grab()` on living targets

#### Harm Intent (`/datum/intent/harm`)

- Aggressive, blocks movement
- Attacks to cause damage
- Primary offensive option
- Checks for martial arts, then calls appropriate attack proc (attack_hand, attack_paw, attack_animal)

## Usage

### Setting Intent

```dm
mob.set_intent(GLOB.intent_harm)
// or
mob.set_intent(/datum/intent/harm)
```

### Cycling Intent

```dm
mob.cycle_intent()
```

### Checking Intent

```dm
if(mob.is_intent_aggressive())
    // Handle aggressive behavior
```

## Integration Points

### Click Handling

The intent system integrates at the click level in `ClickOn()`:

1. When a living mob clicks without an item in hand
2. Check if they have `uses_intents` enabled and a valid `a_intent`
3. Call the appropriate intent proc based on:
    - Range (close/ranged)
    - Click type (left/right)
4. If intent handles it (returns TRUE), stop processing
5. Otherwise, fall through to default `UnarmedAttack()` behavior

This architecture ensures intents intercept clicks before they reach the attack chain, providing clean separation of concerns.

**Key locations:**

- Intent handling: `code/_onclick/click.dm` in `ClickOn()` proc
- Intent definitions: `code/datums/intent/` folder
- Intent procs: Called directly from click handler, not from `UnarmedAttack()`

### AI/NPC Targeting

NPCs can check `is_intent_aggressive()` to determine threat level:

```dm
if(target.is_intent_aggressive())
    // Treat as hostile
```

## Extending the System

### Creating New Intents

1. Create a new intent datum:

```dm
/datum/intent/custom
    name = "Custom"
    desc = "A custom intent"
    icon_state = "custom"

/datum/intent/custom/on_close_range_interact(mob/living/user, atom/target, list/modifiers)
    // Custom close range left click behavior - IMPLEMENT THE ACTUAL BEHAVIOR HERE
    if(!isliving(target))
        return FALSE

    var/mob/living/living_target = target
    user.visible_message(span_notice("[user] does something custom to [living_target]!"))
    // Do the actual thing here, don't defer
    living_target.adjustBruteLoss(5)
    return TRUE // Handled

/datum/intent/custom/on_ranged_interact(mob/living/user, atom/target, list/modifiers)
    // Custom ranged left click behavior
    user.visible_message(span_notice("[user] gestures at [target]!"))
    return TRUE // Handled

/datum/intent/custom/on_close_range_secondary(mob/living/user, atom/target, list/modifiers)
    // Custom close range right click behavior
    return FALSE // Not handled, use default

/datum/intent/custom/on_ranged_secondary(mob/living/user, atom/target, list/modifiers)
    // Custom ranged right click behavior
    return FALSE // Not handled, use default
```

2. Add to global list:

```dm
GLOBAL_DATUM(intent_custom, /datum/intent/custom)
```

3. Initialize in `initialize_intents()`:

```dm
GLOB.intent_custom = new /datum/intent/custom()
GLOB.all_intents += GLOB.intent_custom
```

4. Add to mob's possible intents:

```dm
mob.possible_a_intents += GLOB.intent_custom
```

### Species-Specific Intents

Species can override `initialize_intents()` to provide custom intent lists:

```dm
/mob/living/carbon/human/initialize_intents()
    . = ..()
    if(dna?.species?.type == /datum/species/custom)
        possible_a_intents += GLOB.intent_custom
```

## Migration Notes

### Replacing `combat_mode` Checks

**Old:**

```dm
if(mob.combat_mode)
    // Aggressive behavior
```

**New:**

```dm
if(mob.is_intent_aggressive())
    // Aggressive behavior
```

### Replacing Intent Checks

**Old:**

```dm
if(mob.a_intent == INTENT_HARM)
    // Harm behavior
```

**New:**

```dm
if(mob.a_intent == GLOB.intent_harm)
    // Harm behavior
```

## Signals

- `COMSIG_MOB_INTENT_CHANGED` - Fired when intent changes
    - Args: (old_intent, new_intent)

## Future Enhancements

- Context-sensitive intents (different options based on target)
- Intent-specific animations
- Intent combos (chaining intents for special moves)
- Mood/trait-based intent modifications
- Species-unique intents
