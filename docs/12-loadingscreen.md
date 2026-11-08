# 12 · loadingscreen — Loading screen

The server loading screen (`resources/[core]/loadingscreen`) with the player's
**saved colour palette** (same palette as the rest of the UIs). It uses
`loadscreen_manual_shutdown`, so it decides when to close (when it receives the
finish signal, or 12 s after spawn as a fallback) with an exit (outro) animation.

- **Dependencies:** none hard; consumes the core's `qs:colors:*` if present.
- **Version:** 1.0.0.
- **Assets:** `index.html`, `config.js` (plain HTML, not React; no build step).

---

## 1. How it works

1. On boot, the client requests the saved palette (`qs:colors:request`) up to 24
   times (every 200 ms) while it hasn't received it; when it arrives
   (`qs:colors:load`) or changes (`qs:client:colorsChanged`), it sends it to the
   loader (`{ action = 'theme', data = palette }`).
2. When the world is ready:
   - `loadingscreen:finish` (manual) → starts the outro. In the normal boot it is
     fired by **qs-intro** (when the cinematic plays) or by
     **qs-coremulticharacter** when the selector opens.
   - or `playerSpawned` → after 12 s it fires `finish` (fallback).
3. The outro (`{ action = 'outro' }`) runs ~1.7 s and then closes the screen
   (`ShutdownLoadingScreen` + `ShutdownLoadingScreenNui`) and fires
   `loadingscreen:done` (a 2.5 s fallback closes it if the page does not answer).

`loadingscreen:done` tells the resource that asked for the close (qs-intro or
qs-coremulticharacter) that the screen is gone; they wait for it up to 6 s.

---

## 2. Events

| Event | Direction | Description |
|---|---|---|
| `qs:colors:request` | client → server | Requests the saved palette. |
| `qs:colors:load` | server → client | Receives the palette. |
| `qs:client:colorsChanged` | local | Updates the loader theme. |
| `loadingscreen:finish` | local | Starts the outro and the close (manual). |
| `loadingscreen:done` | local | The screen closed (fired again immediately if `finish` arrives after the close). |
| `playerSpawned` | local | Fallback: closes after 12 s. |

---

## 3. Customization

- **Content / branding (`config.js`):** just edit and restart the resource.

  ```js
  window.LOADING_CONFIG = {
    name: 'QSCORE',                    // big title
    subtitle: 'Roleplay Framework',    // tagline
    about: 'Open-source roleplay framework · runs ESX & QBCore scripts', // one-line description
    keys: [                            // key hints (display only)
      { key: 'F1', label: 'Inventory' },
      { key: 'TAB', label: 'Item wheel' },
      { key: '1-5', label: 'Quick slots' },
      { key: 'E', label: 'Interact' },
      { key: 'U', label: 'Lock vehicle' },
      { key: 'B', label: 'Seatbelt' },
      { key: 'G', label: 'Hotwire' },
      { key: 'T', label: 'Chat' },
    ],
    tips: [ /* rotating lines at the bottom */ ],
    tipInterval: 5.2,                  // seconds between tips
  };
  ```

  The `keys` list does not bind anything: if you change a key in
  qs-coreinventory, qs-corevehiclekeys, qs-corehud or qs-corechat, update it here
  by hand.
- **Theme:** the player's saved palette (`primary`, `accent`, `glow`, `border`) is
  applied when it arrives. Without one, the built-in blue colours are used (the
  same as qs-core's default `Config.Theme`); changing `Config.Theme` in qs-core
  does not recolour the loading screen.
- **Fallback timing:** the auto-close 12 s after `playerSpawned` is in
  `client.lua` (`Wait(12000)`).

---

## 4. Force the close from another resource

```lua
TriggerEvent('loadingscreen:finish')   -- starts the outro and closes
```

> It is a `loadscreen`, not a `ui_page`: it has no commands or key mappings (the
> `keys` in `config.js` are only hints).
