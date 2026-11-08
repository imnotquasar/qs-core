# 02 · qs-core — Framework core

The core. It owns identity (`citizenid`), money, jobs, gangs, metadata, the item
catalogue, inventory routing, DB persistence, callbacks, notifications, theme/colors,
admin commands, groups/permissions and the death, paycheck and bans systems.

- **Dependencies:** `oxmysql`.
- **Version:** 0.4.0.
- **UI:** notification toasts, progress bar, lockpick minigame, death screen and color picker (NUI).
- **Path:** `resources/[core]/qs-core`.

Structure:

```
qs-core/
  shared/   config, jobs, utils, locales, main, gangs, items
  server/   database, permissions, inventory, player, accounts, offline, gangs, main,
            callbacks, bans, paycheck, death, commands, colors, groups, vehicles
  client/   main, inventory, callbacks, disable, death, admin, noclip, teleport
  locales/  ar, de, en, es, fr, it, pl, pt, ru, tr
  sql/      qscore.sql
```

---

## 1. Configuration (`shared/config.lua`)

```lua
Config.Identifier      = 'license'          -- identifier linking license -> characters (don't change on a live server)
Config.MaxCharacters   = 5
Config.DefaultSpawn    = vec4(-268.4842, -957.7139, 31.2231, 205.8032)
Config.Accounts        = { cash = 500, bank = 5000, black_money = 0 }   -- accounts and starting balance
Config.SaveInterval    = 5 * 60 * 1000      -- autosave (ms)
Config.Debug           = true               -- false in production
Config.Theme           = { ... }            -- default color palette (see §10)
Config.AllowColorChange = true              -- enables /colors (per-player palette)
Config.ColorCommand    = 'colors'
Config.DefaultJob      = 'unemployed'       -- must exist in shared/jobs.lua
Config.DefaultJobGrade = 0
Config.Locale          = 'en'               -- file in locales/ (convar qs:locale overrides it)

Config.Paycheck        = { enabled = true, interval = 30*60*1000 }
Config.Death           = {
    respawnTime = 20,                       -- seconds downed before you can respawn
    loseCashOnDeath = false,
    emsCooldown = 30000,                    -- ms between "call paramedics"
    anim = { dict = 'mini@cpr@char_b@cpr_def', clip = 'cpr_pumpchest_idle' },
    hospitals = { vec4(298.6, -584.6, 43.26, 65.0), vec4(-247.6, 6331.4, 32.4, 200.0) },
}
Config.DisableWanted   = true               -- no wanted stars
Config.DisableDispatch = true               -- no NPC police/EMS dispatch
Config.EnablePvP       = true               -- force friendly fire on (false = just don't force it)
Config.DisableRain     = true               -- swaps RAIN/THUNDER/CLEARING for CLOUDS (client-side)
Config.DisablePeds     = false              -- ambient pedestrians
Config.DisableTraffic  = false              -- NPC / parked cars, garbage trucks, boats, trains
Config.Webhooks        = { money = '', admin = '', connections = '' }   -- '' = off ('connections' is currently unused)
Config.EnableBans      = true
Config.Inventory       = 'auto'             -- 'auto' | 'basic' | 'advanced' (see §3 Inventory)
```

`Config.Theme` keys: `name`, `text`, `muted`, `primary`, `primaryDim`, `accent`,
`gradientFrom`, `gradientTo`, `glow`, `border`, `panel`, and status bars `health`,
`armor`, `hunger`, `thirst`.

---

## 2. Getting the core

```lua
-- Shared object: Players, PlayerData, Config, Jobs, Gangs, Utils (+ core functions)
local Qs = exports['qs-core']:GetCoreObject()

-- Color palette (client: the player's saved palette or Config.Theme; server: Config.Theme)
local colors = exports['qs-core']:GetColors()

-- CLIENT: local player data
local data = exports['qs-core']:GetPlayerData()  -- citizenid, charinfo, money, job, gang, metadata...
```

From another resource, players fetched through `Qs.GetPlayer(src)` arrive without
methods. Use the `GetPlayer` export (§3) instead.

---

## 3. Server exports (player, money, metadata)

Use these from other resources. `GetPlayer` returns a copy of the player with every
Player method (§4) bound to the live player, so `player:addMoney(...)` works from any
resource. `player.PlayerData` is a snapshot taken at call time.

| Export | Returns / effect |
|---|---|
| `GetPlayer(src)` | Player (bound methods + `PlayerData` snapshot) \| nil |
| `GetPlayerByCitizenId(citizenid)` | Player \| nil (online only) |
| `GetPlayers()` | list of Players |
| `GetMoney(src, account)` | number |
| `AddMoney(src, account, amount, reason)` | bool |
| `RemoveMoney(src, account, amount, reason)` | bool (false if insufficient) |
| `SetMoney(src, account, amount)` | bool |
| `GetMetadata(src, key)` | any (no key → the whole table; a stored `false` comes back as `nil`) |
| `SetMetadata(src, key, value)` | bool |
| `GetInventory(src)` / `SetInventory(src, list)` | list / bool |
| `GetSkin(src)` / `SetSkin(src, skin)` | table / bool |
| `SetJob(src, name, grade?)` | bool |
| `CreateCharacter(src, charinfo, skin?, cid?)` | data \| nil, error (`no_license`, `max_characters`, `slot_taken`) |
| `LoadCharacter(src, citizenid, isNew?)` | true \| false, error (`no_license`, `not_found`, `not_owner`) |
| `GetCharacters(src)` | list (ordered by slot `cid`) |
| `DeleteCharacter(citizenid)` | — |
| `Logout(src)` | bool — saves and unloads the character (`qs:server:playerUnloaded`, `qs:client:playerUnloaded`) |

Accounts only exist if they are in `Config.Accounts`; `AddMoney`/`RemoveMoney`/`SetMoney`
return false for any other account.

### Accounts, offline players, gangs and duty

| Export | Description |
|---|---|
| `GetAccountMoney(src, account)` | `cash`/`bank` (`money` = `cash`) from the player; any other account from `metadata.accounts_extra` |
| `AddAccountMoney(src, account, amount, reason)` / `RemoveAccountMoney(...)` | bool |
| `SetAccountMoney(src, account, amount)` | bool |
| `GetOfflinePlayerByCitizenId(citizenid)` | DB row (`Offline = true`) \| nil |
| `SaveOfflinePlayer(citizenid, patch)` | bool — merges top-level fields into the DB row |
| `SetGang(src, name, grade)` / `GetGangForPlayer(src)` | bool / gang object |
| `SetJobDuty(src, onDuty)` | bool |
| `GetPlayersOnDuty(jobName)` | `sources, count` |

### Items (catalogue — single source)

| Export | Description |
|---|---|
| `RegisterItem(name, def)` | registers one item (overwrites an existing name) |
| `RegisterItems(tbl)` | registers several `{ name = def, ... }` |
| `GetItem(name)` | one def |
| `GetItems()` | the whole catalogue |
| `UpdateItemDefinition(name, def)` | replaces an existing def (false if missing) |
| `RemoveItemDefinition(name)` | removes a def |

**Def shape:** `{ label, weight, useable, description?, weapon?, ammo?, image? }`
(weight in grams; defaults `label = name`, `weight = 0`, `useable = false`). If it has
`weapon` (e.g. `'WEAPON_PISTOL'`), qs-coreinventory **equips** it on use.
The item exports exist on client and server, but each side keeps its own catalogue.

Base items: `water`, `bread`, `bandage`, `phone`, `id_card` (not useable),
`weapon_pistol`, `lockpick`, `repairkit`, `screwdriver`.

### Inventory (hybrid — routed by qs-core)

Gameplay scripts should use the **Player** object (or the qs-core item exports), not
the inventory resource directly:

| Player method | Description |
|---|---|
| `addItem(name, count, slot?, info?)` | Add item via active backend |
| `removeItem(name, count, slot?, info?)` | Remove item |
| `hasItem(name, count?)` | Ownership check |
| `canCarryItem(name, count)` | Weight/slot capacity |
| `getItemCount(name)` | Count in live inventory |
| `getSlotView()` | Live slot list |
| `getItemBySlot(slot)` | One slot |
| `setItemInfo(slot, info)` | Update metadata |
| `setBusy(ms)` | Inventory UI busy state (qs-coreinventory only) |

Backend selection: if `qs-coreinventory` is running it is always used (basic). Otherwise,
if the paid `qs-inventory` is running it is used as the advanced backend
(`Config.Inventory = 'auto'` or `'advanced'`). Do not run both.

Bridge/admin (src-first): `exports['qs-core']:AddItem(src, name, count, slot, info)`,
`RemoveItem`, `HasItem`, `CanCarryItem`, `GetItemCount`, `GetSlotView`, `GetItemBySlot`,
`SetItemInfo`, `SetBusy`, `RegisterUsableItem(item, cb)`,
`RegisterStash(id, label, slots, maxWeight, columns)` (usables/stashes are queued until a backend is up).
Client: `exports['qs-core']:HasItem(item, count?)`, `GetItemCount(item)`,
`RegisterStashZone(id, coords, opts?)`, `RemoveStashZone(id)`.
Used items: `AddEventHandler('qs:server:usedItem', function(src, item, slot, info) ... end)`.

`getInventory()` / `setInventory()` remain the **DB snapshot** — not live slots.

```lua
exports['qs-core']:RegisterItem('donut', { label = 'Donut', weight = 120, useable = true })
exports['qs-core']:RegisterItems({
    coffee   = { label = 'Coffee',   weight = 250, useable = true },
    sandwich = { label = 'Sandwich', weight = 300, useable = true },
})
```

### Jobs

| Export | Description |
|---|---|
| `RegisterJob(name, def)` | registers one job (server only) |
| `RegisterJobs(tbl)` | registers several |
| `UpdateJob(name, def)` | replaces an existing job |
| `RemoveJob(name)` | removes a job |
| `GetJobs()` | all jobs |

### Permissions, bans, death, vehicles, commands

| Export | Description |
|---|---|
| `HasPermission(src, perm \| {perms})` | bool (see §12) |
| `AddPermission(src, perm)` / `RemovePermission(src, perm)` | runtime `add_ace`/`remove_ace` for `qbcore.<perm>` and `group.<perm>` |
| `GetPermission(src)` | `{ god?, admin?, mod? }` |
| `IsPlayerBanned(licenseOrSrc)` | bool, reason |
| `AddBan(src, minutes, reason, adminName)` | bool (0/nil minutes = permanent; drops the player) |
| `RemoveBan(license)` / `ExploitBan(src, origin?)` | unban / permanent "Anti Cheat" ban |
| `SetPlayerDead(src, state)` | true = force downed, false = revive |
| `GetOwnedVehicles(citizenid)` / `GetGarageVehicles(citizenid, garage)` / `GetVehicleByPlate(plate)` / `PlateExists(plate)` | `qs_vehicles` table reads |
| `CreateOwnedVehicle(data)` / `UpdateOwnedVehicle(plate, data)` / `SetVehicleState(plate, state, garage?)` | `qs_vehicles` table writes |
| `SpawnVehicle(src, model, coords?, warp?)` | netId \| nil (server-side spawn) |
| `GetPlayerVehiclesQBShape(citizenid)` | owned vehicles in QB shape |
| `RegisterFrameworkCommand(name, help, args, argsrequired, cb, permission)` / `RefreshCommands(src)` | QB-style command + chat suggestions |

### Utility / theme

| Export | Description |
|---|---|
| `GetCoreObject()` | shared object `Qs` |
| `GetColors()` | current palette |
| `RateLimit(key, max, windowMs)` | bool (anti-spam, fixed window) |
| `RegisterGang(s)` / `GetGang(name)` / `GetGangs()` / `RemoveGang(name)` | gang catalogue (client and server) |
| `HasSavedColors()` / `SetClientColors(palette)` | (client) saved palette? / apply a palette locally |
| `Notify(msg, type, duration, title?)` | (client) toast — `success`, `error`, `info`, `primary` |
| `Progress(data)` / `CancelProgress()` / `IsBusy()` | (client) progress bar — `{ duration, label, disableMovement?, canCancel? }`, returns bool |
| `Lockpick(rounds?)` | (client) lockpick minigame (1–6 rounds, default 3), returns bool |
| `IsDead()` / `SetDownAnimPaused(state)` | (client) downed state / pause the downed anim loop |
| `ToggleNoclip(state?)` / `IsNoclipActive()` | (client) noclip |

---

## 4. Player object methods (inside qs-core)

```lua
local player = Qs.GetPlayer(src)

player:getCitizenId()            -- 'QSxxxxxx'
player:getSource()               -- number
player:getCharInfo()             -- { firstname, lastname, dob, sex, nationality }
player:getPed()

player:getMoney('bank')
player:addMoney('bank', 500, 'salary')      -- bool
player:removeMoney('cash', 100, 'shop')     -- bool
player:setMoney('cash', 0)

player:getJob()                  -- see §5
player:setJob('police', 2)       -- bool
player:setJobDuty(true)

player:getGang()                 -- { name, label, isboss, grade = { name, level } }
player:setGang('ballas', 1)

player:isDead() / player:setDead(state)

player:getMetadata('thirst')     -- (no key → the whole table)
player:setMetadata('thirst', 80)

player:getInventory() / player:setInventory(list)
player:getSkin() / player:setSkin(skin)

player:getCoords()               -- live vector4
player:emit('event', ...)        -- TriggerClientEvent to this player
player:save(await)               -- persist now (await=true on drop/stop)
player:destroy()                 -- remove from the registry (does not save)
```

The same methods are available on the object returned by `exports['qs-core']:GetPlayer(src)`.

---

## 5. Jobs — `shared/jobs.lua`

Shipped jobs: `unemployed`, `police`, `ambulance`, `hunter`, `delivery`, `miner`,
`lumberjack`, `fisher`.

```lua
Jobs['police'] = {
    label = 'Police',
    defaultDuty = false,
    grades = {
        [0] = { name = 'recruit', label = 'Recruit', salary = 500 },
        [3] = { name = 'boss', label = 'Chief', salary = 2000, isBoss = true },
    },
}
```

Normalized job object (what `getJob()` returns):

```lua
{ name, label, grade, gradeName, gradeLabel, salary, isBoss, onduty }
```

An unknown grade falls back to the job's lowest grade. On job or duty change:
`qs:server:jobChange` (server) and `qs:client:onJobUpdate` (client). Salaries are paid
automatically via **paycheck**.

---

## 6. Callbacks (client ↔ server request/response)

```lua
-- SERVER
exports['qs-core']:RegisterCallback('qs:getBalance', function(source)
    return exports['qs-core']:GetMoney(source, 'bank')
end)

-- CLIENT
exports['qs-core']:TriggerCallback('qs:getBalance', function(balance)
    print('bank', balance)
end)
```

The server handler may block (`MySQL.await`, etc.) and return several values.
QBCore-style callbacks are also available: `RegisterQBCallback(name, function(source, cb, ...))`
on the server and `TriggerQBCallback(name, cb, ...)` on the client.

---

## 7. Events

### Server

| Event | Args | Notes |
|---|---|---|
| `qs:server:playerLoaded` | `source, player` | **Live** Player (same resource). |
| `qs:server:characterLoaded` | `source, { citizenid, charinfo, isNew }` | Serializable → use it from **other resources**. |
| `qs:server:playerUnloaded` | `source, citizenid` | On `Logout` only (not on disconnect). |
| `qs:server:playerSaved` | `source, PlayerData` | After every save. |
| `qs:server:jobChange` | `source, job` | Job or duty change. |
| `qs:server:gangChange` | `source, gang` | |
| `qs:server:moneyChange` | `source, account, kind, amount, reason` | kind = `add`\|`remove` (`set` only for extra accounts). Not fired by `SetMoney`. |
| `qs:server:usedItem` | `source, item, slot, info` | Item used (relayed from the inventory backend). |
| `qs:server:catalogReady` | — | Once, shortly after qs-core starts. |

`qs:server:death` is a client → server net event sent on hospital respawn when
`loseCashOnDeath` is on (it empties `cash`); it is not a "player downed" broadcast —
listen to `qs:client:onDeath` or the `dead` state bag instead.

### Client

| Event | Args | Notes |
|---|---|---|
| `qs:client:onPlayerLoaded` | `data` | Local, after spawn. **Hook here.** |
| `qs:client:onPlayerUnloaded` | — | Local, after logout. |
| `qs:client:onJobUpdate` | `job` | Local. |
| `qs:client:onGangUpdate` / `qs:client:onDutyUpdate` | `gang` / `onDuty` | Local. |
| `qs:client:onDeath` / `qs:client:onRevive` | — | Local, downed state entered / cleared. |
| `qs:client:emsCall` | — | Local, downed player pressed G. |
| `qs:client:playerLoaded` | `data` | Raw net (prefer `onPlayerLoaded`). |
| `qs:client:notify` | `message, type, duration, title?` | Notification. |
| `qs:client:revive` / `qs:client:forceDown` | — | Net, revive / force downed. |
| `qs:job:set` / `qs:gang:set` / `qs:money:*` / `qs:metadata:set` | — | Local mirror sync. |
| `qs:clothing:apply` | `skin` | Consumed by qs-clothing. |
| `qs:client:colorsChanged` | `palette` | Theme changed; repaint your NUI. |
| `qs:client:colorsResolved` | `hasSavedColors` | Saved palette lookup finished. |

Load `data`: `{ source, citizenid, license, name, charinfo, money, job, metadata, gang, onduty, position, skin, is_dead, isNew }`.

---

## 8. Metadata

A bag of arbitrary values persisted per character. New characters start with
`hunger = 100`, `thirst = 100`, `gang` and `onduty`; extra money accounts live in
`accounts_extra`.

```lua
exports['qs-core']:SetMetadata(src, 'stress', 20)
local hunger = exports['qs-core']:GetMetadata(src, 'hunger')
```

Death is not stored in metadata: use `SetPlayerDead(src, state)` and the `dead` state bag.

Every `SetMetadata` emits `qs:metadata:set` to the client → HUD and other
resources react without coupling to the core.

---

## 9. State bags

On each loaded player (`Player(source).state`, replicated to the client):

```lua
local job = Player(source).state.job          -- server
local cid = LocalPlayer.state.citizenid       -- own client
```

Available: `citizenid`, `job`, `name`, `dead`.

---

## 10. Theme / colors

`Config.Theme` is the default palette. Each player can pick their own with `/colors`
(`Config.ColorCommand`, only if `Config.AllowColorChange`); it is saved per license in
`player_colors`. On the client `GetColors()` returns the player's palette (or
`Config.Theme`), `HasSavedColors()` reports whether one is saved and
`SetClientColors(palette)` applies one locally without saving. On the server
`GetColors()` returns `Config.Theme`. Related events: `qs:colors:request`,
`qs:colors:load`, `qs:colors:save`, `qs:colors:clear`, and on the client
`qs:client:colorsChanged` / `qs:client:colorsResolved`.

---

## 11. Utils (`Qs.Utils`)

```lua
Utils.Debug(...)                 -- print only if Config.Debug
Utils.Info(...) / Utils.Warn(...) / Utils.Error(...)
Utils.RandomCitizenId(len)       -- 'QSxxxxxx'
Utils.Clone(t)                   -- deep copy
Utils.BuildJob(name, grade)      -- normalized job object or nil
Utils.RateLimit(key, max, ms)    -- bool (anti-spam)
Utils.Log(channel, title, msg)   -- SERVER ONLY → Discord webhook
```

`RateLimit` is also exposed: `exports['qs-core']:RateLimit('use:'..src, 10, 3000)`.
`Utils.Log` uses `Config.Webhooks[channel]` (`money`|`admin`|`connections`).

Texts use `T(key, ...)` with the locale from convar `qs:locale` (fallback `Config.Locale`,
then `en`). Clients only see the convar if it is set with `setr`.

---

## 12. Commands

**Everyone** (no permission):

| Command | Effect |
|---|---|
| `/cash` | Show your balance |
| `/givemoney <amount>` | Give cash to the nearest player (3 m) |
| `/colors` | Pick your UI palette (if `Config.AllowColorChange`) |

**Admin** (the player needs ACE `command.qs`; `add_ace group.admin command allow` already covers it):

| Command | Effect |
|---|---|
| `/setjob <id> <job> [grade]` | Change job |
| `/addmoney <id> <account> <n>` / `/removemoney ...` | Give / take money |
| `/giveitem <id> <item> [n]` | Give an item |
| `/revive [id]` / `/kill [id]` | Revive / kill (default: yourself) |
| `/freeze <id>` / `/god` | Freeze / god mode |
| `/announce <msg>` | Global announcement |
| `/car <model>` / `/dv` | Spawn / delete vehicle |
| `/coords` / `/tp <x> <y> <z>` | Show coords / teleport |
| `/goto <id>` / `/bring <id>` | Go to / bring a player |
| `/kick <id> [reason]` | Kick |
| `/ban <id> <min\|0=perma> <reason>` / `/unban <license:...>` | Ban / unban |
| `/noclip` / `/tpm` | Free-fly / teleport to waypoint |
| `/setgroup <id> <group>` / `/removegroup <id>` | Persist / remove a group (`player_groups`, `add_principal`) |

Groups and `AddPermission` run `add_ace` / `add_principal` from qs-core, so the resource
needs: `add_ace resource.qs-core command.add_ace allow`, `command.remove_ace`,
`command.add_principal` and `command.remove_principal`.

`HasPermission(src, perm)` is true for `user`, or if the player has ACE `<perm>`,
`qbcore.<perm>` or `group.<perm>`; `admin`/`god`/`mod` also pass with ACE `group.admin`
or `command`.

---

## 13. Included systems

- **Paycheck** — pays the job `salary` to the bank every `Config.Paycheck.interval`.
- **Death / respawn** — you go *downed* (persisted, survives reconnect) for
  `Config.Death.respawnTime` s (on-screen countdown); then **E** respawns at the nearest
  hospital. **G** calls paramedics (`qs:client:emsCall`, cooldown `emsCooldown`). Revive
  with admin `/revive`, `SetPlayerDead(src, false)` or txAdmin **Heal** (single player or
  all). Option `loseCashOnDeath`.
- **Anti NPC police** — `DisableWanted` clears stars; `DisableDispatch` turns off
  NPC service dispatch.
- **World** — `EnablePvP`, `DisableRain`, `DisablePeds`, `DisableTraffic`.
- **Bans** — a `playerConnecting` deferral that rejects banned players (`bans`
  table).
- **Groups** — `/setgroup` stores a group per license and re-applies it on connect.

---

## 14. Database (`sql/qscore.sql`)

**`players`** — one character per row. JSON columns: `charinfo`, `money`, `job`,
`inventory`, `metadata`, `position`, `skin`; plus `is_dead`, `cid` (character slot) and
`last_updated`. PK `citizenid`, indexed by `license` and `(license, cid)`. The core adds
`cid` automatically if an older table lacks it.

**`bans`** — `id`, `license`, `name`, `reason`, `banned_by`, `expires`
(NULL = permanent), `created`.

**`player_colors`** — `license` → saved `palette`. **`player_groups`** — `license` → `group`.

**`vehicles`** — owned vehicles (`citizenid`, `license`, `plate`, `model`, `garage`,
`state`, `fuel`, `engine`, `body`, `props`).

Also created for other resources: `trunk_inventories`, `glovebox_inventories`,
`stash_inventories` (qs-coreinventory), `bank_accounts`, `bank_transactions` (qs-banking).

---

## 15. Quick recipe

```lua
-- A resource that charges for an item and delivers it (server)
RegisterNetEvent('myshop:buy', function()
    local src = source
    if exports['qs-core']:RemoveMoney(src, 'bank', 250, 'shop') then
        exports['qs-core']:AddItem(src, 'donut', 1)
        TriggerClientEvent('qs:client:notify', src, 'Purchased', 'success')
    else
        TriggerClientEvent('qs:client:notify', src, 'Insufficient funds', 'error')
    end
end)
```
