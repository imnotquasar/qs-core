<h1 align="center">qs-core</h1>

<p align="center">
  <b>The first multi-framework for FiveM: ESX, QBCore and qs-core in one hyper-optimized core.</b>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-blue" alt="License: GPL-3.0"></a>
  <img src="https://img.shields.io/badge/FiveM-OneSync-orange" alt="FiveM OneSync">
  <img src="https://img.shields.io/badge/txAdmin-recipe-green" alt="txAdmin recipe">
</p>

---

**Forget about framework limits.** Choosing between ESX and QBCore used to mean
giving up half of the scripts on the market. qs-core is the first multi-framework:
one core that speaks **ESX**, **QBCore** and its own API at the same time, so every
script you own runs on the same server, with the same players, the same money and
the same inventory, without touching a single line of its code.

It is not a fork. qs-core is written from scratch and ships a complete, playable
base (characters, inventory, jobs, police, EMS, banking, vehicles and more) with a
single shared UI theme, all ready to deploy from txAdmin in one click.

## Why qs-core

- **All in one.** ESX scripts, QBCore scripts and qs-core scripts side by side on a
  single server. No more "this script is only for QB", no more rewriting resources,
  no more maintaining two frameworks.
- **One player, one truth.** Every bridge reads and writes the same qs-core player:
  a job set by an ESX script is the job a QBCore script sees, and money earned in
  one is spent in the other.
- **Hyper-optimized, very low resmon.** qs-core is built to stay out of your frame
  budget: logic is event-driven, nothing runs every frame while idle, and the few
  per-frame tasks (holding the item wheel, getting into a vehicle) only run for as
  long as they are needed.
- **Ready in one click.** A txAdmin recipe sets up the database, `server.cfg` and
  every dependency, pinned to tested versions.
- **Open source.** GPL-3.0: read it, change it, ship it.

## Features

- **Characters** – multicharacter selection and creation, intro cinematic, clothing editor.
- **Inventory** – weight and slot based, stashes, trunks, gloveboxes, quick slots `1-5` and an item wheel on `TAB`.
- **Weapons** – every GTA weapon as an item (105), ammo by type and throwables that are spent when thrown.
- **Economy** – cash, bank and black money, ATMs and bank branches with transfers and history, shops, a vehicle dealership and paychecks by job grade.
- **Vehicles** – ownership and keys, lock/unlock, hotwiring, garages with a 3D preview.
- **Jobs** – job center, gather / process / sell activities, police (cuffs, fines, evidence, armory), EMS (injuries, treatment, stretcher) and a drug economy.
- **Survival** – hunger and thirst, downed state and revive.
- **Roleplay** – custom chat with `/me`, `/do`, `/ooc` and more, HUD with health, armour, hunger, thirst, money, job and a speedometer.
- **Administration** – ACE based admin menu, integrated with the txAdmin menu (Heal also revives).
- **One theme** – every interface reads the same palette, so a single change reskins the whole server.
- **Localized** – English, Spanish, French, German, Italian, Portuguese, Polish, Russian, Turkish and Arabic.

## How the multi-framework works

qs-core ships two bridge resources named `es_extended` and `qb-core`. Scripts find
them exactly as they would find the real frameworks:

```lua
local ESX = exports['es_extended']:getSharedObject()   -- ESX scripts
local QBCore = exports['qb-core']:GetCoreObject()      -- QBCore scripts
```

Behind those objects, every call is answered by qs-core, so a player has **one**
character, **one** wallet and **one** inventory no matter which framework a script
was written for.

| Covered by the bridges | |
|---|---|
| Player object | money and accounts, jobs, gangs, metadata, character info |
| Items | usable items, add / remove / check, per-item metadata |
| Server logic | callbacks, commands, common events (`esx:playerLoaded`, `QBCore:Server:PlayerLoaded`…) |
| Database | `users` (ESX) and `players` (QBCore) tables, owned vehicle tables |
| Client helpers | ESX `Game`, `UI.Menu`, `Streaming`; QBCore `Functions` (progress bars, vehicle properties…) |
| Ecosystem | `esx_society`, `qb-management`, `qb-vehiclekeys`, `progressbar`, `LegacyFuel` |

Libraries such as `ox_lib`, `qb-target`, `qb-menu`, `qb-input` and `PolyZone` work
as they are.

**Not covered yet:** Qbox-only scripts (`qbx_core`), scripts that call the exports of
`qb-inventory` or `ox_inventory` directly, and scripts that edit money or jobs with raw
SQL on the `users` table (qs-core keeps that table in sync in one direction only).

## Installation

### txAdmin (recommended)

1. In **txAdmin → Setup → Server Deployer**, choose **Remote URL Template**.
2. Paste:

   ```
   https://raw.githubusercontent.com/imnotquasar/qs-core/main/qs-recipes/recipe.yaml
   ```

3. Fill in your server details and deploy. The recipe sets up the database,
   `server.cfg` and every dependency for you.

### Manual

See [`qs-recipes/README.md`](qs-recipes/README.md#manual-install).

## Requirements

- A recent FXServer artifact with game build **3751** support
- MySQL 8.0+ or MariaDB 10.4+
- OneSync
- [oxmysql](https://github.com/overextended/oxmysql) and [pma-voice](https://github.com/AvarianKnight/pma-voice)
  (installed by the recipe)

## Default controls

| Key | Action |
|---|---|
| `F1` | Inventory |
| `TAB` (hold) | Item wheel |
| `1` – `5` | Use quick slot |
| `E` | Interact |
| `U` | Lock / unlock vehicle |
| `G` | Hotwire |
| `B` | Seatbelt |
| `T` | Chat |
| `F6` | Admin menu (admins only) |

Players can rebind them in **Settings → Key Bindings → FiveM**.

## Repository layout

```
qs-core/
├── [core]/        qs-core and the resources required to play
├── [addons]/      jobs, police, EMS, banking, garages, admin… (optional)
├── [bridge]/      ESX and QBCore compatibility
├── qs-recipes/    txAdmin recipe and server.cfg template
├── LICENSE
└── NOTICE
```

## Contributing

Issues and pull requests are welcome. Keep changes focused, match the style of the
surrounding code and test them on a running server before opening a pull request.

## License

qs-core is licensed under the **GNU General Public License v3.0** (`GPL-3.0-only`).
The ESX and QBCore bridges contain code derived from
[ESX Legacy](https://github.com/esx-framework/esx_core) and
[QBCore](https://github.com/qbcore-framework/qb-core), both GPL-3.0. See
[`NOTICE`](NOTICE) for attribution and third-party licenses.

qs-core is not affiliated with or endorsed by the ESX or QBCore projects.
