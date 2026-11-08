# 04 · qs-clothing — Clothing & appearance

Freemode appearance (`mp_m_freemode_01` / `mp_f_freemode_01` peds): defines the
clothing categories and tattoos, applies the skin on spawn, provides an **editor**
with a side panel and front camera, and adds **clothing / barber / tattoo stores**
on the map.

- **Dependencies:** `qs-core`.
- **Version:** 0.2.0.
- **UI:** React (`web/build`), right-side panel.
- **Access:** `E` at a store opens the editor for that store type; `/clothing`
  (admins, ACE `command.qs`) opens it with every section.

The skin is **opaque** to the core (the `skin` column in `players`). qs-clothing
owns its meaning.

---

## 1. Configuration (`shared/config.lua`)

```lua
Config.EditOnNewCharacter = true   -- open the editor on a new character's first spawn
                                   -- (only when qs-coremulticharacter is NOT running)

Config.Cam = {
    side = -0.08,                  -- shifts the ped left (room for the panel)
    sections = {                   -- camera framing per section
        face        = { dist = 1.85, height = 0.66, target = 0.63, fov = 18.0 },
        upper       = { dist = 2.45, height = 0.50, target = 0.25, fov = 24.0 },
        lower       = { dist = 2.45, height = 0.10, target = -0.35, fov = 30.0 },
        accessories = { dist = 2.60, height = 0.30, target = 0.15, fov = 35.0 },
        tattoos     = { dist = 2.55, height = 0.35, target = 0.20, fov = 32.0 },
    },
}

Config.StoreTypes = {              -- editor sections allowed per store + blip
    clothing = { enabled = { 'upper', 'lower', 'accessories' }, blip = { sprite = 73, color = 3,  size = 0.6, label = 'Clothing Store' } },
    barber   = { enabled = { 'face' },                          blip = { sprite = 71, color = 25, size = 0.6, label = 'Barber' } },
    tattoo   = { enabled = { 'tattoos' },                       blip = { sprite = 75, color = 1,  size = 0.6, label = 'Tattoo Parlor' } },
}

Config.Stores = {                  -- 14 clothing, 7 barber, 6 tattoo locations
    { type = 'clothing', coords = vector3(72.3, -1399.1, 28.4) },
    ...
}

Config.StoreKey = 38               -- E
Config.StoreDistance = 3.0         -- prompt radius (m)
```

---

## 2. Clothing definition (`shared/clothing.lua`)

- `Clothing.Models` — models per sex.
- `Clothing.Sections` — editor tabs: `face`, `upper`, `lower`, `accessories`, `tattoos`.
- `Clothing.Categories` — each garment with:
  `{ key, label, kind, id, max, section }`, where `kind` is:
  - `component` — `SetPedComponentVariation` (hair, torso, top, legs, shoes, mask, bag, undershirt).
  - `overlay` — `SetPedHeadOverlay` (beard; `texture` is the colour).
  - `prop` — `SetPedPropIndex` (hat, glasses).
  - `tattoo` — one entry per collection (`tat_business`, `tat_hipster`, `tat_biker`,
    `tat_airraces`, `tat_beach`, `tat_festive`, `tat_gunrunning`, `tat_ie`,
    `tat_lowrider2`, `tat_lowrider`); the names live in `Clothing.Tattoos`.
- `Clothing.DefaultSkin(sex)` — generates a base skin (components and tattoos at 0,
  props/overlays at -1, textures at 0).

**Skin shape:**

```lua
{
  sex = 'male',
  hair  = { drawable = 3,  texture = 0 },
  top   = { drawable = 11, texture = 2 },
  hat   = { drawable = -1, texture = 0 },  -- -1 = no prop
  beard = { drawable = -1, texture = 0 },  -- -1 = no beard
  tat_biker = { drawable = 4, texture = 0 }, -- tattoo index in the collection, 0 = none
  ...
}
```

---

## 3. Exports (client)

| Export | Signature | Description |
|---|---|---|
| `ApplyAppearance` | `ApplyAppearance(skin, sex?)` | Sets the ped model and applies each category of the skin (and tattoos). If `skin` is empty it uses `DefaultSkin(sex)`; `skin.sex` wins over `sex`. Returns `true`. |
| `OpenCreator` | `OpenCreator(sex, cb)` | Opens the editor in **creator** mode (default skin, tattoos disabled). `cb(skin)` is called when it closes. Used by qs-coremulticharacter. |
| `IsCreatorOpen` | `IsCreatorOpen()` | `true` while the creator is open. |

```lua
-- Re-apply an appearance manually (client)
exports['qs-clothing']:ApplyAppearance(skin, 'female')
```

On spawn, **the core** calls `exports['qs-clothing']:ApplyAppearance(skin, sex)`
before positioning the ped. The `qs:clothing:apply` event is what `SetSkin` uses
to re-apply a skin later.

---

## 4. Persisting the appearance (recommended)

From the server use the core export, which stores and re-applies:

```lua
exports['qs-core']:SetSkin(src, skin)   -- updates the player data and emits qs:clothing:apply
local skin = exports['qs-core']:GetSkin(src)
```

`SetSkin` writes to `players.skin` on the core's next save (autosave, logout or
disconnect).

The editor, on save, fires `qs-clothing:server:save` → the server calls
`core:SetSkin` and notifies the player. Cancelling restores the previous look.

---

## 5. Events

| Event | Direction | Description |
|---|---|---|
| `qs:clothing:apply` | server → client | The core sends the skin; the client applies it. |
| `qs-clothing:client:open` | server → client | Opens the editor. `opts = { disabled = { sections }, defaultSection, strip }`. |
| `qs-clothing:server:save` | client → server | Saves the edited skin (→ `core:SetSkin`). |
| `qs:client:onPlayerLoaded` | local | On spawn; auto-opens the editor if `EditOnNewCharacter`, the char is new, has no skin and multicharacter is not running. |
| `qs:client:colorsChanged` | local | Repaints the editor theme. |
| `qs:clothing:section` | local (fired) | Creator mode only: the player changed section. |
| `qs-clothing:creatorClosed` | local (fired) | Creator closed: `skin, saved`. |

---

## 6. Commands / keys

| Command | Key | Effect |
|---|---|---|
| — | `E` (`Config.StoreKey`) | At a store: opens the editor with that store's sections (tattoo parlors undress the ped while editing). Stores are free. |
| `/clothing` | — | Admin (ACE `command.qs`): opens the editor with every section, tattoos included. |

---

## 7. Multicharacter integration

During character creation, qs-coremulticharacter calls `OpenCreator(sex, cb)`; the
creator fires `qs:clothing:section` so the selector moves its own camera per
section, and the skin passed to `cb` is sent with the new character.
