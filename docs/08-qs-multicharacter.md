# 08 · qs-coremulticharacter — Character selection

Character registration and selection screen (`resources/[core]/qs-coremulticharacter`,
formerly `qs-multicharacter`): lists the player's slots, allows creating (with name +
appearance via qs-clothing), selecting, deleting and logging out. Shows a preview
ped with idle poses and a depth-of-field camera.

- **Dependencies:** `qs-core`. Optional: `qs-clothing` (preview skins + creator),
  `qs-intro`, `loadingscreen`.
- **Version:** 0.2.0.
- **UI:** React (`web/build`).

It relies on the core's character exports: `GetCharacters`, `CreateCharacter`,
`LoadCharacter`, `DeleteCharacter`, `Logout`.

---

## 1. Configuration (`config.lua`)

```lua
Config.MaxCharacters = 5           -- slots shown in the selector (see Notes)
Config.Brand = 'Quasar Roleplay'   -- server name shown in the selector

Config.Locale = 'en'               -- fallback; the qs:locale convar wins when the client can read it

Config.EnableLogout = true         -- /logout returns to the selector (saves first)
Config.LogoutCommand = 'logout'

Config.Preview = {                 -- preview ped + camera
    coords       = vec4(1024.03, -3112.15, -39.00, 353.68),
    camDist      = 1.8,
    camHeight    = 0.70,
    targetHeight = 0.5,
    camSide      = 0.0,            -- lateral offset of the selection camera
    fov          = 25.0,           -- lower = closer

    dof          = true,           -- background blur
    dofNear      = 0.6,
    dofFar       = 2.4,
    dofStrength  = 1.0,

    -- the creator camera glides per clothing section:
    creatorSide   = 0.12,          -- lateral offset of the creator camera
    creatorInterp = 1200,          -- ms for the first glide into the creator
    creatorSections = {
        face        = { dist = 1.85, height = 0.66, target = 0.63, fov = 18.0 },
        upper       = { dist = 2.45, height = 0.50, target = 0.25, fov = 24.0 },
        lower       = { dist = 2.45, height = 0.10, target = -0.35, fov = 30.0 },
        accessories = { dist = 2.60, height = 0.30, target = 0.15, fov = 35.0 },
    },
}

Config.Poses = {                   -- random idles for the preview ped (empty = none)
    { dict = 'anim@heists@heist_corona@team_idles@male_a', clip = 'idle' },
    ...                            -- male_b, male_c, male_d
}
```

---

## 2. Flow

```
qs-intro:finished / playerSpawned / 2 s fallback
        │  (fires loadingscreen:finish, hides HUD + chat)
        ▼
qs-coremultichar:server:getCharacters  ──►  qs-coremultichar:client:setCharacters(chars, max)
        │  (the player chooses)
        ├─ create:  qs-clothing OpenCreator → qs-coremultichar:server:createCharacter(charinfo, skin)
        │             └► core:CreateCharacter → core:LoadCharacter(isNew=true)
        ├─ select:  qs-coremultichar:server:selectCharacter(citizenid)
        │             └► core:LoadCharacter
        ├─ delete:  qs-coremultichar:server:deleteCharacter(citizenid)
        └─ quit:    qs-coremultichar:server:quit  (DropPlayer)
        │
        ▼
qs:client:onPlayerLoaded  (the world starts; HUD/chat show up again)
```

While `qs-intro` is running, the selector waits for `qs-intro:finished`. There is no
spawn selector: the character appears at its saved position (new characters at
qs-core's `Config.DefaultSpawn`).

**Creation validation (server):** `firstname`/`lastname` required (max 30 chars);
`dob` trimmed to 10; `sex` normalized to `male`/`female`; `nationality` max 40.
Errors return `qs-coremultichar:client:error` with a code: `invalid_input`,
`no_license`, `max_characters`, `not_found`, `not_owner`.

**Deletion (server):** only characters returned by the player's own
`GetCharacters` can be deleted; the list is re-sent afterwards.

---

## 3. Events

### Server (listened)

| Event | Args | Description |
|---|---|---|
| `qs-coremultichar:server:getCharacters` | — | Returns the character list. |
| `qs-coremultichar:server:createCharacter` | `charinfo, skin` | Creates and loads a new character. |
| `qs-coremultichar:server:selectCharacter` | `citizenid` | Loads an existing character. |
| `qs-coremultichar:server:deleteCharacter` | `citizenid` | Deletes one of the player's own characters. |
| `qs-coremultichar:server:logout` | — | Returns to the selector (saves first). Ignored if `Config.EnableLogout = false`. |
| `qs-coremultichar:server:quit` | — | Disconnect (`Left the game.`). |

### Client (listened)

| Event | Args | Description |
|---|---|---|
| `qs-coremultichar:client:setCharacters` | `characters, max` | Renders the selector. |
| `qs-coremultichar:client:error` | `code` | Shows a creation/load error. |
| `qs-intro:finished` | — | The intro ended; opens the selector. |
| `playerSpawned` | — | Opens the selector (if no intro is pending). |
| `qs:client:onPlayerLoaded` | `data` | A character entered; closes the selector. |
| `qs:client:onPlayerUnloaded` | — | Returned to the selector. |
| `qs:clothing:section` | `sectionKey` | Moves the creator camera per clothing section. |

### Client (fired)

| Event | Args | Description |
|---|---|---|
| `qs-corehud:display` | `false` / `true` | Hides the HUD while selecting; shows it again on load. |
| `qs:chat:display` | `false` / `true` | Same for the chat. |
| `loadingscreen:finish` | — | Closes the loading screen when the selector opens. |

---

## 4. Commands

| Command | Effect |
|---|---|
| `/logout` | Saves and returns to the selector (if `Config.EnableLogout`). Configurable via `Config.LogoutCommand`. Only works with a character loaded. |

---

## 5. Notes

- The initial appearance is designed with the **qs-clothing** creator; the
  resulting skin is sent alongside the `charinfo` in `createCharacter`. Without
  qs-clothing the character is created with no skin.
- `Config.MaxCharacters` here only sets how many slots the selector shows. The
  limit that is actually enforced is **qs-core** `Config.MaxCharacters` (both are 5
  by default — keep them equal).
- Characters live in the `players` table (through qs-core); deleting a character
  removes its `players` row.
