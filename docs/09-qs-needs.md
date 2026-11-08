# 09 · qs-needs — Hunger & thirst

Needs system: hunger and thirst **decay** over time and are restored by
**consuming** items (food/drink) with an animation and an in-hand prop. At 0, the
player takes periodic damage. The values live in the core's **metadata**
(`hunger`, `thirst`, 0–100), so the HUD reads them without coupling.

- **Dependencies:** `qs-core` (consuming needs an inventory backend:
  qs-coreinventory or qs-inventory).
- **Version:** 0.1.0.
- **No own UI** (shown in qs-corehud; the eat/drink bar is the qs-core progress bar).

---

## 1. Configuration (`shared/config.lua`)

```lua
-- decay
NeedsConfig.DecayInterval = 60000   -- every 1 min
NeedsConfig.DecayHunger   = 1.0
NeedsConfig.DecayThirst   = 1.4

-- at 0, damage per interval (0 = off)
NeedsConfig.StarveInterval = 10000
NeedsConfig.StarveDamage   = 5

-- animations + in-hand prop (duration also blocks item use)
NeedsConfig.Anim = {
    eat   = { dict = 'mp_player_inteat@burger', anim = 'mp_player_int_eat_burger', prop = 'prop_cs_burger_01', duration = 3500, ... },
    drink = { dict = 'mp_player_intdrink', anim = 'loop_bottle', prop = 'prop_ld_flow_bottle', duration = 3000, ... },
}

-- what each consumable restores + verb (eat/drink). Items must be registered and useable.
NeedsConfig.Consumables = {
    water        = { thirst = 30, verb = 'drink' },
    bread        = { hunger = 25, verb = 'eat' },
    burger       = { hunger = 45, verb = 'eat' },
    sandwich     = { hunger = 30, verb = 'eat' },
    cola         = { thirst = 25, hunger = 5, verb = 'drink' },
    coffee       = { thirst = 15, verb = 'drink' },
    energy_drink = { thirst = 35, verb = 'drink' },
}
```

At the defaults, a full bar empties in 100 min (hunger) and ~72 min (thirst).

---

## 2. How it works

1. On boot, it registers its consumables in the core catalogue (`burger`,
   `sandwich`, `cola`, `coffee`, `energy_drink`); `water` and `bread` come from
   qs-core.
2. It listens to `qs:server:usedItem` (qs-core's re-emit of
   `qs-inventory:usedItem`). If the item is in `Consumables`:
   - Removes one from the inventory (`removeItem`); if that fails, nothing happens.
   - Marks the player busy for the animation duration, so no other item can be
     used meanwhile (qs-coreinventory).
   - Adds `hunger`/`thirst` (clamped 0–100) to the core metadata.
   - Triggers the client animation (`qs-needs:consume` → `eat`/`drink`) with a
     progress bar.
   - Notifies ("You ate …" / "You drank …").
3. A server loop decays `hunger`/`thirst` every `DecayInterval`.
4. At 0 hunger **or** 0 thirst, the client applies `StarveDamage` every
   `StarveInterval`.
5. Missing values are set to 100 when a character loads (new characters start
   at 100).

---

## 3. Events

| Event | Direction | Description |
|---|---|---|
| `qs:server:usedItem` | server | Detects consumption of a consumable. |
| `qs-needs:consume` | server → client | Plays the animation (`eat`/`drink`). |
| `qs:metadata:set` | client | The client sees `hunger`/`thirst` changes. |
| `qs:server:characterLoaded` / `qs:client:onPlayerLoaded` | — | Initializes the values on entry. |

---

## 4. Adding a consumable

Register the item in qs-core as **useable** (qs-needs does not auto-register
items), then add it to `NeedsConfig.Consumables`:

```lua
-- any server script
exports['qs-core']:RegisterItem('pizza', { label = 'Pizza', weight = 500, useable = true })
```

```lua
-- qs-needs/shared/config.lua
NeedsConfig.Consumables.pizza = { hunger = 60, verb = 'eat' }
```

To change the values from another resource, write the metadata through the
core: `exports['qs-core']:SetMetadata(src, 'hunger', 80)`.

---

## 5. HUD integration

qs-corehud reads `hunger`/`thirst` from the metadata via `qs:metadata:set`. No
extra configuration needed: on restore/decay, the HUD bars update automatically.
