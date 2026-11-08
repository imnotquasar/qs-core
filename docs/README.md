# qs-core Documentation

Per-resource documentation for the **qs-core** framework (Quasar Framework, FiveM). Each file covers
one resource in `[core]/`, `[addons]/` or `[bridge]/` in depth: what it does, how to configure it, its
**exports**, **events**, **commands**, **callbacks** and usage examples.

> Base dependency for the whole framework: **oxmysql**. Every peripheral resource
> additionally depends on **qs-core**.

## Index

| # | Document | Resource | Summary |
|---|---|---|---|
| 01 | [01-general.md](01-general.md) | — | Architecture, boot order, i18n, theme, conventions. |
| 02 | [02-qs-core.md](02-qs-core.md) | `qs-core` | Core: Player, money, jobs, metadata, items, callbacks, commands, death, bans, paycheck. |
| 03 | [03-qs-chat.md](03-qs-chat.md) | `qs-corechat` | Chat with NUI, commands and suggestions (compatible with `chat:addMessage`). |
| 04 | [04-qs-clothing.md](04-qs-clothing.md) | `qs-clothing` | Freemode appearance, clothing editor, `ApplyAppearance`. |
| 05 | [05-qs-hud.md](05-qs-hud.md) | `qs-corehud` | HUD: id, job, money, health/armor/hunger/thirst, speedometer, voice. |
| 06 | [06-qs-intro.md](06-qs-intro.md) | `qs-intro` | Intro cinematic before multicharacter. |
| 07 | [07-qs-inventory.md](07-qs-inventory.md) | `qs-coreinventory` | Weight/slot inventory, stashes, trunk, glovebox, usable items. |
| 08 | [08-qs-multicharacter.md](08-qs-multicharacter.md) | `qs-coremulticharacter` | Character registration and selection. |
| 09 | [09-qs-needs.md](09-qs-needs.md) | `qs-needs` | Hunger and thirst (decay over time, consumables). |
| 10 | [10-qs-shops.md](10-qs-shops.md) | `qs-coreshops` | Shops with ped/blip, server-validated purchases. |
| 11 | [11-qs-weapons.md](11-qs-weapons.md) | `qs-coreweapons` | Every GTA weapon and ammo as items, throwables, no native loot. |
| 12 | [12-loadingscreen.md](12-loadingscreen.md) | `loadingscreen` | Loading screen with the core theme. |
| 13 | [13-qs-banking.md](13-qs-banking.md) | `qs-banking` | ATMs + bank branches: deposit/withdraw/transfer/history. |
| 14 | [14-qs-jobs.md](14-qs-jobs.md) | `qs-jobs` | Job center + gather/process/sell and delivery jobs. |
| 15 | [15-qs-vehiclekeys.md](15-qs-vehiclekeys.md) | `qs-corevehiclekeys` | Vehicle keys, lock/unlock, hotwire, auto-keys. |
| 16 | [16-qs-garage.md](16-qs-garage.md) | `qs-garage` | Store/take out owned vehicles with a 3D preview. |
| 17 | [17-qs-vehicleshop.md](17-qs-vehicleshop.md) | `qs-vehicleshop` | Dealership: buy vehicles from a showroom. |
| 18 | [18-qs-ambulance.md](18-qs-ambulance.md) | `qs-ambulance` | EMS job: injuries, treatment, stretcher, garage. |
| 19 | [19-qs-police.md](19-qs-police.md) | `qs-police` | Police: cuff/escort/search, fines, evidence, armory. |
| 20 | [20-qs-drugs.md](20-qs-drugs.md) | `qs-coredrugs` | Drug economy: gather → process → sell. |
| 21 | [21-qs-admin.md](21-qs-admin.md) | `qs-admin` | ACE-gated admin menu (players/self/server). |
| 22 | [22-qs-rp.md](22-qs-rp.md) | `qs-rp` | Roleplay commands: /me /do /ooc /b /try /pm /ame. |
| 23 | [23-bridges.md](23-bridges.md) | `[bridge]/*` | ESX / QBCore / progressbar / fuel / society compatibility. |

## How to read this documentation

- **Exports** are invoked as `exports['<resource>']:Function(args)`.
- Network **events** are fired with `TriggerServerEvent` / `TriggerClientEvent`
  and listened to with `RegisterNetEvent` / `AddEventHandler`.
- Naming convention: `qs:server:*` (server), `qs:client:*` (client),
  `<resource>:server:*` / `<resource>:client:*` (resource-internal).
- Text uses the global helper `T(key, ...)` and files in `locales/`.

## License

qscore is licensed under the **GNU GPL v3.0** (`GPL-3.0-only`), see [`../LICENSE`](../LICENSE).
The ESX and QBCore compatibility bridges contain code derived from ESX Legacy and
QBCore (both GPL-3.0); attribution and the list of affected files are in [`../NOTICE`](../NOTICE).
