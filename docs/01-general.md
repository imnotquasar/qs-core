# 01 · General — qs-core Architecture

qs-core (Quasar Framework) is a **from-scratch FiveM roleplay framework** (not a fork of ESX or
QBCore). It borrows the good ideas (data-oriented player object, statebags) and
drops the weak ones (per-player closures, blocking DB calls). The core owns
identity, money, jobs, metadata, persistence and notifications; **inventory and
clothing ship as separate resources** so they can be swapped without touching the
core.

> **Single low-level dependency:** `oxmysql`.
> Every peripheral resource additionally depends on `qs-core`.

---

## 1. Framework resources

Resources live in three folders: `[core]` (required to play), `[addons]` (optional
jobs and systems) and `[bridge]` (ESX / QBCore compatibility).

| Folder | Resource | Responsibility | Depends on |
|---|---|---|---|
| `[core]` | **qs-core** | Player, money, jobs, metadata, persistence, items (catalogue), callbacks, notifications, theme, admin commands, death, paycheck, bans, i18n. | oxmysql |
| `[core]` | **qs-coreinventory** | Weight/slots, usable items, stashes, trunk, glovebox, quick slots `1-5`, item wheel on `TAB`. | qs-core, oxmysql |
| `[core]` | **qs-clothing** | Clothing definitions, apply appearance, clothing editor. | qs-core |
| `[core]` | **qs-coremulticharacter** | Character registration and selection. | qs-core |
| `[core]` | **qs-corehud** | HUD: id, job, money, health/armor/hunger/thirst, speedometer, seatbelt, voice. | qs-core |
| `[core]` | **qs-needs** | Hunger and thirst (decay; consumables restore). | qs-core |
| `[core]` | **qs-coreshops** | Shops with ped/blip; server-validated purchases. | qs-core |
| `[core]` | **qs-coreweapons** | Every GTA weapon (105) and ammo as inventory items; throwables spent when thrown; no native GTA loot. | qs-core |
| `[core]` | **qs-corechat** | Chat with suggestions and roleplay message styling (replaces the default chat). | qs-core |
| `[core]` | **qs-corevehiclekeys** | Vehicle keys, lock/unlock, hotwiring, auto-keys for owned cars. | qs-core |
| `[core]` | **qs-intro** | Intro cinematic before the character selector. | qs-core |
| `[core]` | **loadingscreen** | Loading screen with the framework name and default keys (uses the core theme). | — |
| `[addons]` | **qs-banking** | ATMs + bank branches: deposit/withdraw/transfer/history. | qs-core |
| `[addons]` | **qs-jobs** | Job center (apply) + activity jobs (gather/process/sell, delivery). | qs-core |
| `[addons]` | **qs-garage** | Store/take out owned vehicles with a 3D preview. | qs-core |
| `[addons]` | **qs-vehicleshop** | Dealership: buy vehicles from a showroom. | qs-core |
| `[addons]` | **qs-ambulance** | EMS job: injuries, treatment, stretcher, garage, self-heal. | qs-core |
| `[addons]` | **qs-police** | Police job: cuff/escort/search, fines, evidence/casings, armory. | qs-core, oxmysql |
| `[addons]` | **qs-coredrugs** | Drug economy: gather → multi-stage process → sell to dealers. | qs-core |
| `[addons]` | **qs-admin** | ACE-gated admin menu: player/self/server tools. | qs-core |
| `[addons]` | **qs-rp** | Roleplay commands: /me /do /ooc /b /try /pm /ame. | qs-core, qs-corechat |
| `[bridge]` | **es_extended** | Emulates ESX Legacy on top of qs-core (+ synced `users` table). | qs-core |
| `[bridge]` | **qb-core** | Emulates QBCore on top of qs-core. | qs-core |
| `[bridge]` | **progressbar** | Emulates `progressbar` (QB). | qs-core |
| `[bridge]` | **LegacyFuel** | LegacyFuel `GetFuel`/`SetFuel` shim. | — |
| `[bridge]` | **esx_society**, **qb-management** | Society/boss fund shims (auto-create tables). | es_extended / qs-core |
| `[bridge]` | **qb-vehiclekeys** | Forwards QB key grants to qs-corevehiclekeys. | qs-core |

`qs-inventory` (without "core") is Quasar Store's separate advanced inventory. To use it,
run it **instead of** qs-coreinventory: qs-core always prefers qs-coreinventory when it is
started, and only routes item calls to qs-inventory when qs-coreinventory is not running.

**Key principle:** the core stores `inventory`, `skin` and `metadata` as **opaque**
data (it does not interpret their content) and is the **single save path**. Each
external resource owns the *meaning* of that data and mutates it via the core's
exports.

### What you get out of the box

A complete, playable roleplay base:

- **Identity & persistence** — multicharacter, character creator, saved
  money/job/skin/inventory/position/metadata in one `players` row.
- **Economy** — cash / bank / black_money, ATMs & banking with transfers and history,
  shops, a vehicle dealership, and paycheck by job grade.
- **Vehicles** — ownership with keys, lock/unlock, hotwiring, garages with a 3D
  preview, and a dealership.
- **Jobs & activities** — a job center, civilian activity loops (gather → process →
  sell, delivery), plus **police** and **EMS** with their own tooling, and a **drug**
  economy.
- **Survival & combat** — hunger/thirst needs, an injury/treatment system, downed &
  revive.
- **Roleplay & UX** — chat with RP commands (/me /do /ooc…), a themeable HUD, a
  loading screen and intro, all UIs sharing one palette.
- **Admin** — an ACE-gated admin menu.
- **Compatibility** — ESX & QBCore bridges so purchased scripts run unmodified.

Every UI is React and reads the same theme; every resource is localised via `T()`.

---

## 2. Installation

### txAdmin (recommended)

In **txAdmin → Setup → Server Deployer**, choose **Remote URL Template** and paste:

```
https://raw.githubusercontent.com/imnotquasar/qs-core/main/qs-recipes/recipe.yaml
```

The recipe creates the database tables, writes a commented `server.cfg` and downloads
every dependency (oxmysql, ox_lib, pma-voice, bob74_ipl, the Pillbox hospital
interior, mapmanager and spawnmanager), each pinned to a tested version.

### Manual

1. Copy `[core]`, `[addons]` and `[bridge]` into `resources/`.
2. Import `[core]/qs-core/sql/qscore.sql` into your database. It creates `players`,
   `bans`, `player_colors`, `player_groups`, `trunk_inventories`,
   `glovebox_inventories`, `stash_inventories`, `vehicles`, `bank_accounts` and
   `bank_transactions`. The bridges create `users`, `owned_vehicles`,
   `society_accounts` and `management_funds` on start.
3. Install the dependencies: oxmysql, ox_lib, pma-voice, bob74_ipl, the hospital
   map and, from cfx-server-data, mapmanager and spawnmanager. Do not add
   `basic-gamemode`: its autospawn fights qs-core's downed state.
4. In `server.cfg`, start everything by name in this order (it is the same file the
   recipe writes, see `qs-recipes/server.cfg`):

```cfg
sv_enforceGameBuild 3751
set resources_useSystemChat false
set mysql_connection_string "mysql://user:password@localhost/qscore?charset=utf8mb4"
setr qs:locale "en"

add_principal group.admin group.user
add_ace group.admin command allow
add_ace group.admin command.quit deny
add_ace resource.qs-core command.add_ace allow
add_ace resource.qs-core command.remove_ace allow
add_ace resource.qs-core command.add_principal allow
add_ace resource.qs-core command.remove_principal allow

ensure mapmanager
ensure spawnmanager
ensure oxmysql
ensure ox_lib
ensure pma-voice

# [core]
ensure qs-core

# ESX / QBCore compatibility (third-party scripts go at the end of the file)
ensure [bridge]

ensure qs-coreinventory
ensure qs-clothing
ensure qs-coreweapons
ensure qs-needs
ensure qs-coreshops
ensure qs-corehud
ensure qs-corechat
ensure qs-corevehiclekeys

# [addons]
ensure qs-jobs
ensure qs-ambulance
ensure qs-police
ensure qs-coredrugs
ensure qs-vehicleshop
ensure qs-garage
ensure qs-admin
ensure qs-banking
ensure qs-rp

# player boot flow
ensure loadingscreen
ensure qs-intro
ensure qs-coremulticharacter

ensure [maps]
```

Keep the explicit list: `ensure [core]` would start the resources alphabetically, so
qs-coremulticharacter would load before qs-intro and skip the intro.

5. Do **not** run the real ESX/QBCore alongside qs-core. To use ESX/QB scripts, rely
   on the bridges (see [23-bridges.md](23-bridges.md)).

---

## 3. Player boot flow

```
Connection
   │  playerConnecting  ── qs-core checks bans (deferral)
   ▼
loadingscreen  ── shows the loading screen with the core theme
   │  loadingscreen:done
   ▼
qs-intro       ── cinematic (if Config.Enabled)
   │  qs-intro:finished
   ▼
qs-coremulticharacter ── character selection/creation
   │  qs-coremultichar:server:selectCharacter / createCharacter
   ▼
qs-core LoadCharacter ── loads data, spawns, applies skin
   │  qs:server:characterLoaded (server)  +  qs:client:onPlayerLoaded (client)
   ▼
qs-coreinventory / qs-corehud / qs-needs / … react
```

Key events to hook into:

- **Server:** `qs:server:characterLoaded(src, { citizenid, charinfo, isNew })`.
- **Client:** `qs:client:onPlayerLoaded(data)`.

---

## 4. Localization (i18n)

Convention shared by every resource:

- Each resource ships 10 languages in `locales/` (`en`, `es`, `fr`, `de`, `it`, `pt`,
  `pl`, `ru`, `tr`, `ar`) plus, in most resources, a `lang.lua` helper.
- The active language is set by the **convar** `qs:locale` (default `en`):
  ```cfg
  setr qs:locale "en"
  ```
- Global helper `T(key, ...)`:
  ```lua
  T('paycheck', 500)      -- "Paycheck received: $500"
  T('no_permission')      -- "No permission."
  ```
- Unknown keys return the key itself (never `nil`).
- To add a language: create `locales/<code>.lua` with `Locales.<code> = { ... }`,
  load it in the `fxmanifest`, and set `setr qs:locale "<code>"`.

---

## 5. Theme / colors (single palette)

qs-core is the **single source** of the palette (`Config.Theme`). Every UI fetches
it with `exports['qs-core']:GetColors()` and applies it as CSS variables. Change
`Config.Theme` and **the whole framework** reskins.

```lua
local c = exports['qs-core']:GetColors()
-- c.text, c.muted, c.primary, c.accent, c.gradientFrom, c.glow, c.border,
-- c.health, c.armor, c.hunger, c.thirst ...
```

When the theme changes, the core emits `qs:client:colorsChanged` on the client and
every interface repaints with the new palette.

---

## 6. Notifications

```lua
-- Server → one player
TriggerClientEvent('qs:client:notify', src, 'Done', 'success', 4000)
local player = exports['qs-core']:GetPlayer(src)   -- inside the core
player:emit('qs:client:notify', 'Done', 'success', 4000)

-- Client
exports['qs-core']:Notify('Message', 'info', 3000)
```

Types: `success | error | info | primary`.

---

## 7. Code conventions

- **Event namespaces:** `qs:server:*`, `qs:client:*` for the framework's public
  events; `<resource>:server:*` / `<resource>:client:*` for internal ones.
- **Cross-resource serialization:** `GetPlayer(src)` returns a **serialized copy**
  (no methods) outside qs-core. From another resource always use the core's
  **exports** (`GetMoney`, `AddMoney`, `SetMetadata`, …), not `player:method()`.
- **Statebags:** each loaded player exposes `Player(source).state` (server) /
  `LocalPlayer.state` (own client) with `citizenid`, `job`, `name`.
- **Item weight:** in grams.
- **Money:** default accounts `cash` and `bank` (`Config.Accounts`).

For the full core API, see [02-qs-core.md](02-qs-core.md).
