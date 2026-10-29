# qscore

A modern, from-scratch FiveM roleplay framework core. Not a fork of ESX or
QBCore — it borrows the good ideas (data-oriented player object, statebags) and
drops the weak ones (per-player closures, blocking DB calls). The core owns
identity, money, jobs, metadata, persistence and notifications; **inventory and
clothing ship as separate resources** (`qs-coreinventory`, `qs-clothing`) so they
can be swapped or extended without touching the core. Only dependency is oxmysql.

## Resources

| Resource | Responsibility |
|---|---|
| `qs-core` | Player object, money/jobs/metadata, persistence, inventory routing, notifications, character API |
| `qs-coremulticharacter` | Registration + selection screen |
| `qs-coreinventory` | Item catalogue, weight rules, usable items, bottom-right UI (basic path) |
| `qs-clothing` | Appearance definitions, spawn apply, side-panel editor |

Commercial **advanced inventory** (`qs-inventory` with ESX `CustomInventory = 'qs'`)
is supported via the core adapter — gameplay scripts still call `player:addItem()`.

## Controls

- **F1** — toggle inventory (provided by `qs-coreinventory`)
- **F2** — open clothing editor (provided by `qs-clothing`)
- **ESC** — close any open UI

## Install (default qscore stack)

1. Import `qs-core/sql/qscore.sql` into your database.
2. Ensure `oxmysql`, `qs-core`, `qs-coreinventory`, `qs-clothing`, then
   `qs-coremulticharacter`.
3. Do **not** run `qs-coreinventory` and commercial `qs-inventory` together.

### Inventory backend (`shared/config.lua`)

```lua
Config.Inventory = 'auto' -- 'auto' | 'basic' | 'advanced'
```

| Mode | Ensure | Routing |
|---|---|---|
| Default | `qs-core`, `qs-coreinventory` | `player:addItem()` → basic |
| ESX advanced | `qs-core`, commercial `qs-inventory` | Set `Config.Inventory = 'advanced'` |

## Hybrid inventory API

**Gameplay scripts (preferred):**

```lua
local core = exports['qs-core']
local player = core:GetPlayer(src)
if not player:canCarryItem('burger', 1) then return end
player:addItem('burger', 1)
```

**Bridge / admin:**

```lua
exports['qs-core']:AddItem(src, name, count, slot, info)
exports['qs-core']:RegisterStash(id, label, slots, maxWeight, columns)
```

**Client:**

```lua
exports['qs-core']:HasItem('lockpick', 1)
exports['qs-core']:GetItemCount('water')
```

**Used items:** `AddEventHandler('qs:server:usedItem', ...)`

| Method | Meaning |
|---|---|
| `player:getInventory()` / `setInventory()` | DB column snapshot |
| `player:getSlotView()` | Live slot list |
