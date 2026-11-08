# 05 · qs-corehud — HUD

Player HUD (`resources/[core]/qs-corehud`, formerly `qs-hud`): server id, job,
money, health/armor/hunger/thirst, stamina, speedometer (driver only), seatbelt,
voice and players online. Hides the native zone/street popups and the vanilla
health/armor bars.

- **Dependencies:** `qs-core`. Optional: `pma-voice` (voice mode indicator), a fuel
  resource (speedometer; the bundled `[bridge]/LegacyFuel` works out of the box).
- **Version:** 0.5.0.
- **UI:** React (`web/build`).

It exposes no exports; it is fed by core events.

---

## 1. Configuration (`config.lua`)

```lua
Config.UpdateInterval = 250 -- ms (bar refresh)

Config.Show = {
    stamina = true,
    voice   = true,   -- "talking" indicator (the voice mode comes from pma-voice)
}

Config.HideGameText = true  -- hides zone/street/vehicle popups near the minimap

Config.Vehicle = {
    unit     = 'kmh',       -- 'kmh' | 'mph'
    interval = 90,          -- refresh ms while driving
    seatbelt = true,
    beltKey  = 'B',

    -- fuel resource: uses its export if running, otherwise the native
    fuelResource = 'LegacyFuel', -- ps-fuel, cdn-fuel, ox_fuel...
    fuelExport   = 'GetFuel',
}
```

---

## 2. What it shows

| Element | Source |
|---|---|
| Server ID | `GetPlayerServerId` |
| Job | `data.job` (label, else name, else "Civilian") |
| Cash / Bank | `data.money` + `qs:money:*` events |
| Health / Armor | ped natives |
| Hunger / Thirst | metadata `hunger` / `thirst` (`qs:metadata:set` event) |
| Stamina | native (if `Config.Show.stamina`; underwater air while swimming) |
| Voice | talking via `NetworkIsPlayerTalking` (if `Config.Show.voice`) + mode from `pma-voice:setTalkingMode` |
| Speedometer / fuel / engine / street / seatbelt | only as the vehicle's driver |
| Online / max | `qs-corehud:counts` event (server; max = `sv_maxclients`) |

When money is received, the HUD does a *burst* that hides the native money HUD
(components 3 and 4) for a few seconds to avoid overlap. The HUD also hides itself
while the pause menu is open and while the player is dead.

---

## 3. Events

### Client (listened)

| Event | Description |
|---|---|
| `qs:client:onPlayerLoaded` | Shows the HUD and loads initial data. |
| `qs:client:onJobUpdate` | Refreshes the job. |
| `qs:client:onDeath` / `qs:client:onRevive` | Hides / shows the HUD. |
| `qs:money:add` / `qs:money:remove` / `qs:money:set` | Updates cash/bank. |
| `qs:metadata:set` | Updates hunger/thirst. |
| `qs-corehud:display` | `TriggerEvent('qs-corehud:display', false)` hides the HUD and radar; `true` shows them (ignored while dead). |
| `qs-corehud:normalizeMinimap` | Re-fits the minimap (fired by qs-ambulance). |
| `qs:client:colorsChanged` | Repaints the theme. |
| `pma-voice:setTalkingMode` | Changes the voice mode indicator. |
| `qs-corehud:counts` | Receives `{ online, max }`. |

### Server

| Event | Description |
|---|---|
| `qs-corehud:request` | The client requests the player count. |
| `qs:server:playerLoaded` | Re-broadcasts the count to everyone. |
| `playerDropped` | Re-broadcasts the count to everyone. |

The count is also re-broadcast every 60 s.

---

## 4. Commands / keys

| Keymapping | Key | Effect |
|---|---|---|
| `+qsbelt` | `B` (config) | Toggles the seatbelt indicator (driver only) with a notification. It is visual: there is no ejection logic. Resets when you leave the driver seat. |

---

## 5. Hide the HUD temporarily

```lua
TriggerEvent('qs-corehud:display', false)  -- hide (cinematics, menus)
TriggerEvent('qs-corehud:display', true)   -- show
```

---

## 6. Integrate fuel from another resource

Set `Config.Vehicle.fuelResource` and `fuelExport`. If that resource is running,
the HUD calls `exports[fuelResource]:<fuelExport>(veh)` (e.g.
`exports['LegacyFuel']:GetFuel(veh)`) and uses the result if it is a number;
otherwise it uses the native `GetVehicleFuelLevel`.
