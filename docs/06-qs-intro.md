# 06 · qs-intro — Intro cinematic

A cinematic that plays **before the character selector** for players who have
**not yet chosen their UI colours**: a fixed camera and a ped that walks from one
point to another, turns to camera and crosses its arms, with optional blur. Then a
colour picker opens; the chosen palette is saved and used by the HUD, menus and notifications.
Players who already have a saved palette skip straight to the multicharacter
screen.

- **Dependencies:** `qs-core`.
- **Version:** 1.0.0.
- **UI:** React (`web/build`) for the overlay (colour picker: presets or custom
  primary/accent).

---

## 1. Configuration (`config.lua`)

```lua
Config.Enabled = true      -- false = skip the intro (go straight to multichar)
Config.Dof = true          -- camera blur

Config.Cam = {             -- fixed camera; line up the ped path so it reads left → right
    pos  = vec3(1000.46, -3108.20, -38.80),
    look = vec3(997.54, -3108.59, -38.80),
    fov  = 25.0,           -- lower = closer
}

Config.Ped = {             -- the actor
    model  = 'mp_m_freemode_01',
    start  = vec4(997.92, -3112.22, -39.00, 7.86),  -- x,y,z,heading
    finish = vec3(997.76, -3107.55, -39.00),
    speed  = 1.0,          -- 1 walk, 2 run
    pose   = { dict = 'anim@heists@heist_corona@single_team', anim = 'single_team_loop_boss' },
                           -- idle at the finish while the picker is open (false = none)
    components = { ... },  -- outfit (use /introoutfit to capture it)
    props = { ... },
}

Config.Scene = {           -- your real body hides here while the area streams in
    hide = vec3(1001.46, -3108.20, -39.00),
}
```

---

## 2. Flow

```
playerSpawned (or 1.5 s after start) ─► qs:colors:request
                                         │
          saved palette ◄────────────────┤──────────────► no palette (or no answer in 6 s)
               │                                               │
     apply it, no cinematic                     cinematic + loadingscreen:finish
               │                                               │  walk, turn, cross arms, colour picker
               │                                               │  confirm → qs:colors:save
               ▼                                               ▼
                         qs-intro:finished  ─►  qs-coremulticharacter starts
```

The intro itself asks the loading screen to close (`loadingscreen:finish`, waiting
up to 6 s for `loadingscreen:done`) once its scene is ready.

If `Config.Enabled = false`, on `playerSpawned` it fires `qs-intro:finished`
directly.

---

## 3. Events

| Event | Direction | Description |
|---|---|---|
| `qs:colors:request` | client → server | Asks qs-core for the saved palette. |
| `qs:colors:load` | server → client | The saved palette (or `false`); decides skip vs cinematic. |
| `qs:colors:save` | client → server | Saves the palette chosen in the picker. |
| `loadingscreen:finish` | local (fired) | Closes the loading screen when the cinematic starts. |
| `qs-intro:finished` | local (fired) | The intro finished → multicharacter can start. |
| `playerSpawned` | local | Starts the palette check (or, when disabled, fires `qs-intro:finished`). |

---

## 4. Commands

| Command | Effect |
|---|---|
| `/introoutfit` | Dumps your ped's current outfit (components/props) to the console, ready to paste into `Config.Ped`. Notifies when done. |
| `/introreset` | Clears your saved colour palette (`qs:colors:clear`), so the intro plays again on your next connect. |

---

## 5. Customize the intro ped

1. Dress in-game as you want the actor to look.
2. Run `/introoutfit`.
3. Copy the `components`/`props` block printed in the console into `Config.Ped`.
4. Adjust `Config.Cam` and `Config.Ped.start/finish` to frame the walk.

> To skip the intro entirely, set `Config.Enabled = false`. To see it again
> yourself, run `/introreset` and reconnect.
