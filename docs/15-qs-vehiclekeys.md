# 15 · qs-corevehiclekeys — Keys, Lock & Hotwire

Ownership-based vehicle access: you can only drive a car you have **keys** for.
Owned vehicles auto-grant keys; others must be **hotwired** with a lockpick
(skill minigame). Includes lock/unlock and key handover.

- **Resource:** `[core]/qs-corevehiclekeys` (formerly `qs-vehiclekeys`).
- **Depends on:** `qs-core`. The lockpick check goes through qs-core's inventory
  bridge (`qs-coreinventory` or `qs-inventory`); the carjack alert uses `qs-police`
  when it is started.
- **Minigame:** uses the core `Lockpick(rounds)` export.
- **Performance:** a single client loop that runs every 500 ms; no per-frame work.

---

## Usage

- **U** (default, `vehlock`): lock / unlock the vehicle you are in, or the closest
  vehicle within `Config.LockDistance` — only if you have its keys. It flashes the
  lights (plus the key-fob animation when on foot); the lock state is synced to all
  players.
- Sit in the **driver seat** of a car with no keys → the engine stays off and a help
  prompt is shown. If you have a **lockpick** item, press **G** (default, `hotwire`
  key mapping) to attempt a hotwire (the core lockpick minigame). Success → you get
  the keys and the engine starts. Fail → the lockpick breaks (if
  `Config.BreakLockpickOnFail`), the alarm sounds and the police are alerted
  (`qs-police`, at most once every 8 s per player).
- **/givekeys [id]** — while sitting in a vehicle you have keys for, share its keys.
  With no argument it picks the nearest player within `Config.GiveDistance`; with an
  id it targets that player id. The server only accepts targets within
  `Config.GiveDistance + 2.0` m.
- **/adminkeys [id]** — restricted server command (ACE `command.adminkeys`, covered by
  `add_ace group.admin command allow` in the shipped `server.cfg`). Gives you, or
  player `id`, the keys of the vehicle you are currently in. Does nothing from the
  server console.
- Owning a vehicle in the `qs_vehicles` table auto-grants its keys the first time you sit
  in its driver seat (one server check per plate per session).
- Keys are kept in client memory only: they are not saved and are lost on reconnect or
  resource restart (owned vehicles get them back automatically).

## Config (`config.lua`)

| Key | Default | Meaning |
|---|---|---|
| `Config.RequireKeysToDrive` | `true` | Engine forced off for a driver without keys. |
| `Config.AutoKeysForOwned` | `true` | Auto-grant keys for cars your character owns (`vehicles.citizenid`). |
| `Config.LockKey` / `Config.LockDistance` | `'U'` / `5.0` | Default key of the `vehlock` key mapping and the on-foot search radius. |
| `Config.HotwireItem` | `'lockpick'` | Item required to hotwire. |
| `Config.HotwireKey` | `'G'` | Default key for the `hotwire` key mapping; players can rebind it in FiveM settings. |
| `Config.HotwireRounds` | `3` | Lockpick minigame rounds (qs-core clamps it to 1–6). |
| `Config.BreakLockpickOnFail` | `true` | Remove one lockpick on failure. |
| `Config.GiveDistance` | `5.0` | Reach for `/givekeys` (server allows +2.0 m). |

## Commands / Keys

| Command | Default key | Permission | Purpose |
|---|---|---|---|
| `vehlock` | U | — | Lock / unlock (needs keys). |
| `hotwire` | G | — | Hotwire the keyless vehicle you are driving (needs a lockpick). |
| `/givekeys [id]` | — | — | Share the keys of the vehicle you are in. |
| `/adminkeys [id]` | — | ACE `command.adminkeys` | Give keys of the vehicle you are in to yourself or `id`. |

## Exports (client)

| Export | Purpose |
|---|---|
| `GiveKeys(plate)` | Give the local player keys for a plate. |
| `RemoveKeys(plate)` | Remove keys. |
| `HasKeys(plate)` → bool | Does the local player hold keys? |
| `GetKeys()` → table | All held plates (`{ [plate] = true }`). |

Plates are trimmed of trailing spaces. Other resources use these when they spawn a
car: qs-core `/car`, the qs-admin **Spawn Vehicle** button, qs-garage take-out and the
qs-vehicleshop delivery, the qs-police and qs-ambulance garages and the qs-jobs delivery
van all call `GiveKeys(plate)` (only if this resource is started).
There are no server exports.

## Events

| Event | Side | Purpose |
|---|---|---|
| `qs-corevehiclekeys:client:give` / `:remove` | client | Grant/remove keys locally (`plate`). |
| `vehiclekeys:client:SetOwner` | client | Key grant (`plate`); same name as qb-vehiclekeys. Used by `/givekeys` and `/adminkeys`. |
| `qs-corevehiclekeys:server:giveTo` | server | Hand keys to a target player (`target, plate`, proximity-checked). |
| `qs-corevehiclekeys:server:lockState` / `:client:lockState` | both | Broadcast a lock state (`netId, state`) to all clients. |
| `qs-corevehiclekeys:server:breakLockpick` | server | Remove one `Config.HotwireItem` from the sender. |
| `qs-corevehiclekeys:server:lockpickFail` | server | Fires the police alert on a failed hotwire (rate-limited). |

Server callback: `qs-corevehiclekeys:owns(plate)` → `true` if the plate belongs to the
caller's character.

## Notes

- The `HasKeys` export is used by **qs-coreinventory** to gate vehicle storage: the
  trunk can't be opened if the car is locked or you have no keys; the glovebox can't
  be opened without keys.
- The `lockpick` item is defined in qs-core (`shared/items.lua`); this resource does
  not register items.
