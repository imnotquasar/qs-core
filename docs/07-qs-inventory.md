# 07 · qs-coreinventory — Inventory

A **weight- and slot-based** inventory with a docked UI. It supports per-slot
metadata (`info`), usable items/weapons, a **trunk**, a **glovebox**,
**stashes** (static and runtime), **quick slots `1`–`5`** and an **item wheel**
on `TAB` that replaces GTA's weapon wheel.

- **Dependencies:** `qs-core`, `oxmysql`.
- **Version:** 0.4.0.
- **UI:** React (`web/build`).
- **Keys:** `F1` inventory (`Config.OpenKey`), `TAB` item wheel
  (`Config.RadialKey`), `1`–`5` quick slots.

The item **catalogue** is owned by `qs-core` (`RegisterItem(s)`). The player's
inventory **state** lives in the `inventory` column of `players` (opaque to the
core); qs-coreinventory computes the change and writes it via `core:SetInventory`.

> qs-core uses qs-coreinventory as its "basic" backend whenever it is started.
> `qs-inventory` (without "core") is Quasar Store's separate advanced inventory;
> qs-core only routes to it when qs-coreinventory is not running. Calling the
> item functions through `exports['qs-core']` keeps your resource working with
> either backend.

---

## 1. Configuration (`shared/config.lua`)

```lua
Config.MaxWeight = 50000    -- grams (50 kg)
Config.Slots     = 30
Config.Columns   = 5

-- trunk (standing behind a car)
Config.TrunkSlots = 10
Config.TrunkColumns = 5
Config.TrunkMaxWeight = 100000
Config.TrunkReach = 1.8          -- m to the boot
Config.TrunkCloseDistance = 5.0  -- closes past this

-- glovebox (seated in a vehicle)
Config.GloveboxSlots = 5
Config.GloveboxColumns = 5
Config.GloveboxMaxWeight = 15000

-- also via RegisterStash / OpenStash
Config.Stashes = {
    -- { id = 'town_locker', label = 'Town Locker', slots = 50, maxWeight = 200000, columns = 5 },
}

Config.DefaultStack = 64    -- unless the item overrides it (`stack`); weapons/`unique` stack to 1
Config.OpenKey = 'F1'

Config.RadialKey = 'TAB'    -- item wheel (hold, aim, release)
Config.RadialSlots = 5      -- slots 1..N shown in the wheel

Config.StartingItems = {    -- items given on new-character creation
    { name = 'water',   count = 2 },
    { name = 'bread',   count = 2 },
    { name = 'phone',   count = 1 },
    { name = 'id_card', count = 1 },
}
```

> `OpenKey` and `RadialKey` are `RegisterKeyMapping` defaults: players can rebind
> them in GTA's Settings → Key Bindings → FiveM.

---

## 2. Exports (main API)

### Server

| Export | Signature | Returns |
|---|---|---|
| `AddItem` | `AddItem(src, name, count, slot?, info?)` | bool (false if unknown / over weight / no room) |
| `RemoveItem` | `RemoveItem(src, name, count, slot?)` | bool (without `slot` it takes from the last slots first) |
| `HasItem` | `HasItem(src, name, count?)` | bool (`count` defaults to 1) |
| `GetItemCount` | `GetItemCount(src, name)` | number |
| `CanCarryItem` | `CanCarryItem(src, name, count?, info?)` | bool (weight + slot/stack room) |
| `GetInventory` | `GetInventory(src)` | raw slot array: `{ name, count, info? }` or `false` per slot |
| `GetSlotView` | `GetSlotView(src)` | per-slot view `{ slot, name, label, count, weight, useable, description, image, max, info }` or `false` |
| `GetItemBySlot` | `GetItemBySlot(src, slot)` | item with `.info` and `.slot`, or nil |
| `SetItemInfo` | `SetItemInfo(src, slot, info)` | bool (overwrites the metadata) |
| `RegisterUsableItem` | `RegisterUsableItem(name, fn)` | — |
| `RegisterStash` | `RegisterStash(id, label?, slots?, maxWeight?, columns?)` | bool (defaults `'Stash'`, 50, 100000, 5) |
| `SetBusy` | `SetBusy(src, ms)` | — (blocks item use for `ms`) |
| `IsBusy` | `IsBusy(src)` | bool |
| `createQuest` | `createQuest(...)` | `true` (compatibility stub, does nothing) |

### Client

| Export | Signature | Returns |
|---|---|---|
| `GetItemCount` | `GetItemCount(name)` | number (from the last synced snapshot) |
| `HasItem` | `HasItem(name, count?)` | bool |
| `OpenStash` | `OpenStash(id, opts?)` | bool — opens the inventory with that stash |
| `RegisterStashZone` | `RegisterStashZone(id, coords, opts?)` | bool — `opts = { radius = 2.0, stash = { label, slots, maxWeight, columns } }` |
| `RemoveStashZone` | `RemoveStashZone(id)` | bool |
| `createQuest` | `createQuest(...)` | `true` (stub) |

```lua
-- Usable item with its own effect (server)
exports['qs-coreinventory']:RegisterUsableItem('lockpick', function(src, slot, info)
    exports['qs-coreinventory']:RemoveItem(src, 'lockpick', 1, slot)
    -- ...your logic...
end)
```

> `RegisterUsableItem` handlers receive `(src, slot, info)`. Legacy ones using
> only `(src)` still work (backwards-compatible). There is **one handler per
> item**: a later registration replaces the earlier one. Handlers are kept in
> memory, so restarting qs-coreinventory drops the ones other resources
> registered until those resources are restarted too.
> `exports['qs-core']:RegisterUsableItem(name, fn)` does the same and routes to
> the active backend (queued until the inventory is up).

---

## 3. Per-slot metadata (`info`)

`info` is a free-form table persisted in the inventory JSON.

```lua
exports['qs-coreinventory']:AddItem(src, 'phone', 1, nil, { number = '555-1234' })
exports['qs-coreinventory']:AddItem(src, 'weapon_pistol', 1, 5, { serial = 'ABC123' }) -- to slot 5
exports['qs-coreinventory']:RemoveItem(src, 'phone', 1, slot)   -- slot optional
exports['qs-coreinventory']:GetItemBySlot(src, slot)            -- includes .info and .slot
exports['qs-coreinventory']:SetItemInfo(src, slot, info)        -- overwrites the metadata
exports['qs-coreinventory']:CanCarryItem(src, name, count, info)
```

- Stacks **only merge if `name` + `info` match** (different info = separate slots).
- Move / give / take / split / trunk preserve the `info`.

---

## 4. Usable items and weapons

Only items whose definition has `useable = true` can be used. The server
rate-limits use (10 per 3 s per player) and refuses it while the player is busy
(`SetBusy`, e.g. while qs-needs plays an eat/drink animation). On item use:

1. If `def.weapon` (e.g. `'WEAPON_PISTOL'`) → the client **equips** the weapon
   (`qs-inv:client:equip`, with `def.ammo` rounds the first time). Using it again
   while it is in hand **holsters** it. Nothing else fires for weapons.
2. Otherwise, if there is a `RegisterUsableItem` for that item → its handler is
   called.
3. Then `qs-inventory:usedItem(src, name, slot, info)` is fired; qs-core
   re-emits it as `qs:server:usedItem(src, name, slot, info)`, which is what
   qs-needs and qs-coreweapons listen to.

The inventory never consumes the item by itself: remove it in your handler.
Built-in handlers: `bandage` (removes 1, heals 20 HP; qs-ambulance replaces it
with its own) and `phone` (placeholder notification).

```lua
-- React to any used item (server, another resource) — works with either backend
AddEventHandler('qs:server:usedItem', function(src, name, slot, info)
    if name == 'radio' then TriggerClientEvent('myradio:toggle', src) end
end)
```

---

## 5. Containers: trunk, glovebox and stashes

Opening the inventory picks the secondary container automatically: **glovebox**
if you are in a vehicle, otherwise the **trunk** of a car you stand behind,
otherwise a **stash zone** you stand in.

- **Trunk** — on foot, within `TrunkReach` (1.8 m) of the rear of a car. The car
  must be unlocked and you need its keys (when `qs-corevehiclekeys` is running).
  The boot opens, and the trunk closes (boot shut) if you walk away
  (`TrunkCloseDistance`). 10 slots / 100 kg. Persisted by `plate` in
  `trunk_inventories`.
- **Glovebox** — seated in the vehicle, keys required; closes when you get out.
  5 slots / 15 kg. Persisted by `plate` in `glovebox_inventories`.
- **Stashes** — chests shared by `id`. Persisted in `stash_inventories`.

```lua
-- Register a stash at runtime (server)
exports['qs-coreinventory']:RegisterStash('town_locker', 'Town Locker', 50, 200000, 5)

-- Open it for this player (client)
exports['qs-coreinventory']:OpenStash('town_locker')

-- Or open it automatically when the player presses F1 within 2 m (client)
exports['qs-coreinventory']:RegisterStashZone('town_locker', vector3(215.0, -810.0, 30.7), { radius = 2.0 })
```

Stashes in `Config.Stashes` are registered automatically on boot. `OpenStash`'s
`opts` (`{ label, slots, maxWeight, columns }`) are only used when the stash id
is not registered on the server.

---

## 6. Internal events (reference)

| Event | Direction |
|---|---|
| `qs-inv:server:request` / `qs-inv:client:set` | UI sync (`set` carries the full snapshot) |
| `qs-inv:server:use` | use a slot |
| `qs-inv:server:move` / `split` / `give` / `drop` / `take` | operations |
| `qs-inv:server:openTrunk` / `openGlovebox` / `openStash` / `closeSecondary` | containers |
| `qs-inv:client:equip` / `heal` / `itembox` | client effects |
| `qs-inventory:usedItem` | used-item broadcast (server, local) |
| `qs-inventory:registerUsables` | fired ~200 ms after start (qs-core flushes queued registrations) |

> The standard use event is `qs-inventory:usedItem(src, name, slot, info)`,
> re-emitted by qs-core as `qs:server:usedItem` with the same arguments.

- **Drop** deletes the item (there is no world drop).
- **Give** targets the nearest player within 3.5 m (the server re-checks 5 m).

---

## 7. Database

The tables are created by `[core]/qs-core/sql/qscore.sql` (import it once):

| Table | Key | Content |
|---|---|---|
| `trunk_inventories` | `plate` | trunk items (JSON) |
| `glovebox_inventories` | `plate` | glovebox items (JSON) |
| `stash_inventories` | `stash` | stash items (JSON) |

Containers are saved on every change. The player inventory lives in
`players.inventory` (managed and saved by qs-core).

---

## 8. Commands / keys

| Command | Key | Effect |
|---|---|---|
| `/inventory` | `F1` | Open/close the inventory (`ESC` also closes). You can keep walking/driving while it is open. |
| `+qs-radial` | `TAB` (hold) | Item wheel: hold, aim at a slot with the mouse, release to use it. |
| `qs-hotbar-1` … `qs-hotbar-5` | `1`–`5` | Quick slots: use the item in slot 1–5. |

- **Item wheel** — shows slots `1`–`Config.RadialSlots`. GTA's own weapon wheel
  is blocked while `TAB` is held, and the quick-slot keys suppress GTA's native
  weapon-slot switching. If you release without pointing at a slot, the wheel
  closes after 1 s.
- **While dead** the inventory and the wheel cannot be opened, quick slots do
  nothing, and dying closes both. Item use is also ignored while a qs-core
  progress bar is running.
