# 23 · [bridge] — ESX / QBCore compatibility

qs-core speaks **ESX** and **QBCore** through the bridge resources in
`resources/[bridge]/`. They emulate each framework's core object (and a few common
sub-resources) on top of qscore, so you can run purchased ESX/QB scripts **without
touching their code**. `es_extended` and `qb-core` run **at the same time**, so ESX and
QB scripts can share one server.

| Bridge resource | Emulates | How scripts find it |
|---|---|---|
| `es_extended` | ESX Legacy | `exports['es_extended']:getSharedObject()`, event `esx:getSharedObject`, `@es_extended/imports.lua`, `@es_extended/locale.lua` |
| `qb-core` | QBCore | `exports['qb-core']:GetCoreObject()`, `exports['qb-core']:GetShared()`, event `QBCore:GetObject`, `@qb-core/shared/locale.lua` |
| `qbx_core` | Qbox (qbx_core 1.23.0) | `exports.qbx_core:*`, `@qbx_core/modules/lib.lua`, `@qbx_core/modules/playerdata.lua`, `require '@qbx_core.modules.hooks'`… **Opt-in**, see [section 5](#5-qbox-qbx_core) |
| `progressbar` | progressbar (QB) | `exports['progressbar']:Progress(...)` (+ `ProgressWithStartEvent`, `ProgressWithTickEvent`, `ProgressWithStartAndTick`, `isDoingSomething`) |
| `LegacyFuel` | LegacyFuel | `GetFuel` / `SetFuel` client exports (used by qs-corehud too) |
| `esx_society` | esx_society | society accounts (`society_accounts` table, created on start) |
| `qb-management` | qb-management | boss/gang funds (`management_funds` table, created on start) |
| `qb-vehiclekeys` | qb-vehiclekeys | forwards key grants to **qs-corevehiclekeys** (local key list if it is not started) |

**Usage:** drop the purchased ESX/QB script into its own folder (e.g. `[thirdparty]`) and start it **after**
the bridges: `server.cfg` starts `[bridge]` right after `qs-core`, so add your scripts at the end of the file. Do not run the real ESX/QBCore at the same time:
the bridges use the resource names `es_extended` and `qb-core`.

---

## 1. What is mapped

### Player
`xPlayer` and `Player.Functions` cover the common API (money, items, job, metadata,
notifications); see [Known limits](#3-known-limits) for what is stubbed.

- **Money:** `money → cash`, `bank`. Other accounts — `black_money` (ESX) and
  `crypto` (QB) — live in metadata `accounts_extra` and **persist**.
- **Items:** delegated to qs-core's inventory backend (qs-coreinventory; per-item
  `slot`/`info` supported on the QB side). If the paid **qs-inventory** is present,
  `es_extended` switches to it automatically (`Config.CustomInventory = 'qs'`).
  Items made or changed in qs-inventory's in-game creator are picked up live: qs-core
  copies qs-inventory's item list into its catalog once the creator items are loaded
  and on every `qs-inventory:itemListUpdated`, then fires `qs:server:itemsUpdated`.
  `es_extended` refreshes `ESX.Items` (and fires `esx:itemsUpdated`, which updates the
  `ESX.Items` copy of every server script using `@es_extended/imports.lua`); `qb-core`
  adds/updates/removes them in `QBCore.Shared.Items` on the server and on every client.
- **Job:** qs jobs; unknown ones auto-register with generic grades (ESX 0–3, QB 0–4,
  the last one is boss). **Gangs (QB)** in metadata `gang`.
- **Metadata**, **charinfo** (`dob/sex` ↔ `birthdate/gender`), **coords**, `kick`,
  `notify`.
- The ESX `identifier` is the **citizenid** (consistent with how the bridge exposes
  players and looks them up).

### Events
Derived from qs's native events (`qs:server:characterLoaded`, `qs:server:jobChange`,
`qs:server:moneyChange`, `qs:server:gangChange`, `qs:client:onPlayerLoaded`,
`qs:job:set`, `qs:money:*`, `qs:metadata:set`, `qs-inv:client:set`):

- **ESX:** `esx:playerLoaded`, `esx:setJob`, `esx:setAccountMoney`,
  `esx:add/removeInventoryItem`, `esx:onPlayerLogout`, `esx:playerDropped`,
  `esx:onPlayerDeath`, `esx:showNotification`…
- **QBCore:** `QBCore:Server:PlayerLoaded`, `QBCore:Server:OnJobUpdate`,
  `QBCore:Server:OnMoneyChange`, `QBCore:Server:OnGangUpdate`,
  `QBCore:Client:OnPlayerLoaded`, `QBCore:Client:OnJobUpdate`, `QBCore:Client:SetDuty`,
  `QBCore:Player:SetPlayerData`, `QBCore:Notify`…
- Not emitted: `QBCore:Client:OnPlayerUnload`, `QBCore:Client:OnMoneyChange`.
  `QBCore:Server:OnPlayerUnload` fires on disconnect only.

### Callbacks / usable items / commands
- ESX `RegisterServerCallback`/`TriggerServerCallback`, QB `CreateCallback`/`TriggerCallback`
  and `CreateClientCallback`/`TriggerClientCallback` (callback style, not await style).
- `ESX.RegisterUsableItem` dispatches from qs-core's `qs:server:usedItem` (fired by
  `qs-inventory:usedItem`); `CreateUseableItem` registers through qs-core's inventory
  backend. Both mark the item usable in the qs-core catalogue (an unknown item gets a
  bare entry). With the paid qs-inventory, ESX items are registered in qs-inventory and
  QB items are resolved through `QBCore.Functions.CanUseItem`.
- `ESX.RegisterCommand` (ACE groups + chat suggestions) and `QBCore.Commands.Add`
  (qs-core permissions + chat suggestions).

### Shared (QB) & client utilities
- `Shared.Items/Jobs/Gangs` are synced **both ways** with the qs-core catalogue on the
  **server**. On the **client** they only hold what is in the bridge files (plus
  `AddItem`/`AddJob`… made at runtime), so add script-required items/jobs/gangs in
  `qb-core/shared/*.lua`. `Shared.Vehicles` is empty; `Shared.Weapons` is a fixed list.
- ESX `Game`/`Streaming`/`UI.Menu` (`UI.Menu` needs a menu resource such as
  `esx_menu_default`); QB `Progressbar`, `SpawnVehicle`, `Get/SetVehicleProperties`,
  `GetClosest*`…

### SQL — `users` and `players`
- **`players`** is qs-core's own table, created by `[core]/qs-core/sql/qscore.sql`
  (no bridge creates it). Its column names follow QB (`citizenid`, `license`,
  `charinfo`, `money`, `job`, `metadata`, `inventory`, `position`), but the gang lives
  in `metadata.gang` and the JSON uses qs-core shapes.
- **`users` (ESX)** is created on start and **kept in sync** from qs-core: on player
  load and on every save (`qs:server:playerSaved`: autosave, disconnect, logout) the
  columns ESX itself saves (`accounts`, `group`, `job`, `job_grade`, `position`,
  `inventory`, `metadata`) are upserted. `firstname`, `lastname`, `dateofbirth`, `sex`
  and `skin` are only written when the row is first created; after that they belong to
  the scripts that own them in ESX (esx_identity, qs-appearance, skinchanger…) and the
  sync never overwrites them. When qs-clothing saves an outfit it fires
  `qs-clothing:server:skinSaved`, and `es_extended` writes that skin to `users.skin`.
  The sync only touches those columns, so **custom columns
  other scripts add to `users` are preserved** and stay usable. `loadout` is never written.
  `phone_number` is created (added to an existing table too) for phone scripts and is
  never written by the sync.
- **Raw SQL writes to `users` while the player is offline** are read back, like ESX does:
  `updated_at` (auto-updated by MySQL) is compared with `qs_synced_at` (set by the sync).
  When a player connects, each of their characters whose row was changed by another
  script gets the changed ESX columns (`accounts`, `group`, `job`/`job_grade`, name, date
  of birth, sex, `position`, `metadata`) copied into `players` before the character
  loads. `inventory` and `skin` are never imported. Online writes to the columns ESX
  saves are overwritten by the next save, exactly as in ESX.
- `vehicles` (ESX) is the vehicle catalogue (`name`, `model`, `price`, `category`), as in
  esx_vehicleshop. `es_extended` creates it on start and fills it when it is empty.
- `owned_vehicles` (ESX) is created on start but stays **empty**: qs-core keeps owned vehicles
  in its own `qs_vehicles` table (an older `vehicles` table of qs-core is renamed on start).
  `player_vehicles` (QB) is **not** created.

---

## 2. Ecosystem that needs NO bridge

`qb-menu`, `qb-input`, `qb-target`, `PolyZone`, `ox_lib`, `esx_menu_default`…
**install them as-is**: they only consume the core object we already emulate.

## 3. Known limits

- Qbox (`qbx_core`) is supported through the opt-in `qbx_core` bridge; see [section 5](#5-qbox-qbx_core) for its own limits.
- Scripts that call `qb-inventory` exports directly are not covered, and `ox_inventory` exports
  only while the `qbx_core` bridge or qs-inventory is started.
  (`es_extended` keeps an ox_inventory mode in code, but it is never selected
  automatically and qs-core has no ox backend.)
- Raw SQL writes to `users` for an online player are not read back; they are overwritten
  by the next save (same as ESX).
- Scripts that use SQL on `player_vehicles` / `owned_vehicles` (garages, vehicle shops)
  do not work: the first table does not exist and the second is empty.
- `xPlayer.getLoadout()` returns `{}` and `hasWeapon()` returns `false` (weapons are
  items in qscore); `addWeapon` / `removeWeapon` work through natives only (the weapon
  is not an item and is not saved). Weapon components/tints are not implemented.
- `ESX.CreatePickup` does not create world pickups (no-op with a warning).
  `ESX.SavePlayer`/`SavePlayers` only run the callback (qs-core saves on its own).
- Not provided: `esx_addonaccount` / `esx_datastore`, the esx_society and qb-management
  boss menus, await-style callbacks, ESX weapon helpers (`ESX.GetWeaponList`…).

## 4. How to use an ESX/QB script

1. Install its ecosystem dependencies (`ox_lib`, `qb-menu`, etc.) with no bridge. Do not
   install the real `esx_identity`: `es_extended` already provides its registration callback.
2. Place the script in its own folder, e.g. `resources/[thirdparty]/`.
3. `ensure` the script **after** the bridges (`es_extended` / `qb-core`).
4. If the script needs items/jobs, add them to the qs-core catalogue or to the bridge
   files (`es_extended/config/items.lua`, `qb-core/shared/items.lua`,
   `qb-core/shared/jobs.lua`, `qb-core/shared/gangs.lua`). Unknown items make
   `getInventoryItem` return `nil`.

## 5. Qbox (`qbx_core`)

`[bridge]/qbx_core` reproduces the public API of **qbx_core 1.23.0** on top of qs-core, so
Qbox scripts run unchanged. It is **opt-in**: `server.cfg` has `stop qbx_core` right after
`ensure [qs]`; remove that line only if you run Qbox scripts.

> qs-inventory switches to its Qbox mode as soon as a resource named `qbx_core` is started
> (`Config.QBX`): it then reads items from its own `shared/items.lua` instead of
> `QBCore.Shared.Items`, and the cash item is called `money`. That is why the bridge is
> not started by default.

**Requirements:** `qs-core`, the `qb-core` bridge (it is a dependency: QBCore events such
as `QBCore:Server:PlayerLoaded`, `QBCore:Client:OnJobUpdate` or
`QBCore:Player:SetPlayerData` are fired once, by `qb-core`, exactly as on a real Qbox server
where `qbx_core` *is* `qb-core`), `ox_lib` and `oxmysql`. The bridge does **not**
`provide 'qb-core'`; `exports['qb-core']:GetCoreObject()` keeps coming from the `qb-core` bridge.

### What is mapped

- **Player object** (`exports.qbx_core:GetPlayer`, `GetPlayerByCitizenId`, `GetPlayerByUserId`,
  `GetPlayerByPhone`, `GetQBPlayers`, `GetOfflinePlayer`, `SearchPlayers`, `GetPlayersData`):
  `PlayerData` in Qbox shape (`job`/`gang` with `bankAuth`, `jobs`/`gangs` maps, `money`
  `cash`/`bank`/`crypto`, `charinfo` with `birthdate`/`gender`/`backstory`, Qbox default
  `metadata`, `userId`, `lastLoggedOut`, `items`) and every `Player.Functions` wrapper.
  Offline players are read from and saved to `players` through qs-core.
- **Exports**: every server and client export of qbx_core 1.23.0, including `SetJob`,
  `SetGang`, `SetJobDuty`, `AddPlayerToJob` / `RemovePlayerFromJob` / `SetPlayerPrimaryJob`
  (and the gang versions), `SetMetadata` (`'a.b'` keys, needs clamped 0–100), `GetMetadata`,
  `SetCharInfo`, `SetPlayerData`, `UpdatePlayerData`, `Add/Remove/Set/GetMoney`, `Login`,
  `Logout`, `Save`, `SaveOffline`, `DeleteCharacter`, `GenerateUniqueIdentifier`,
  `HasPrimaryGroup`, `HasGroup`, `GetGroups`, `IsGradeBoss`, `GetGroupMembers`,
  `GetDutyCountJob` / `GetDutyCountType`, buckets, permissions, bans, `Notify`,
  `CreateUseableItem` / `CanUseItem`, jobs and gangs (`GetJobs`, `CreateJob(s)`,
  `RemoveJob`, `CreateGangs`, `RemoveGang`, `Upsert*`, `Remove*Grade`), vehicles and weapons
  (`GetVehiclesByName/Hash/Category`, `GetWeapons`, `GetVehicleClass`, `CreateSessionId`,
  `EnablePersistence` / `DisablePersistence`, `DeleteVehicle`), `SetField`,
  `registerHook` / `removeHooks` (money hooks `addMoney`, `removeMoney`, `setMoney`).
  `HasItem` is added on both sides (used by `modules/utils.lua`).
- **Multiple jobs/gangs**: memberships live in the `qbx_player_groups` table (created on
  start, same columns as Qbox's `player_groups`; qs-core already uses the name
  `player_groups` for permission groups). The primary job/gang stays the qs-core one.
  Convars `qbx:max_jobs_per_player`, `qbx:max_gangs_per_player`, `qbx:setjob_replaces` and
  `qbx:setgang_replaces` work as in Qbox, also when the job is changed by qs-core or by a QB script.
- **Events**: `qbx_core:server/client:onGroupUpdate`, `qbx_core:server/client:onSetMetaData`,
  `qbx_core:server/client:onJobUpdate` / `onGangUpdate`, `qbx_core:server/client:playerLoggedOut`,
  `QBCore:Client:OnMoneyChange`, `QBCore:Server:SetDuty`, `qb-phone:client:RemoveBankMoney`,
  `QBCore:Server/Client:OnPermissionUpdate`, `QBCore:Server:CloseServer` / `OpenServer`.
- **Statebags**: `isLoggedIn`, `hunger` / `thirst` / `stress` (both ways: a script that sets
  the statebag updates the qs-core metadata), `canUseWeapons`, `loadInventory`, `instance`;
  `GlobalState.PlayerCount`, `MaxPlayers`, `PVPEnabled`.
- **Character callbacks** for external multicharacter scripts: `qbx_core:server:getCharacters`,
  `getPreviewPedData`, `loadCharacter`, `createCharacter` (gives `starterItems`),
  `deleteCharacter`; plus `qbx_core:server:getGroups` and the client callbacks
  `qbx_core:client:setHealth`, `getVehicleClasses`, `getVehiclesInRadius`.
- **Files other scripts load**: `modules/lib.lua` (the `qbx` global), `modules/playerdata.lua`
  (`QBX.PlayerData`, kept in Qbox shape), `modules/hooks.lua`, `modules/logger.lua`,
  `modules/utils.lua`, `shared/*.lua` (`shared/jobs.lua` / `shared/gangs.lua` return the live
  qs-core jobs/gangs), `config/client.lua`, `config/shared.lua`, `data/nationalities.lua`, locales.
- **`ox_inventory`**: the bridge does `provide 'ox_inventory'`, so scripts that depend on it start,
  and answers its API on both inventories. Server: `Items`, `AddItem`, `RemoveItem`, `Search`, `GetItem`,
  `GetItemCount`, `GetSlot`, `GetSlotWithItem`, `GetSlotIdWithItem`, `GetSlotsWithItem`, `SetMetadata`,
  `CanCarryItem`, `ClearInventory`, `GetInventoryItems`, `SetItem`, `GetCurrentWeapon`, `RegisterStash`,
  `RegisterShop`, `CustomDrop`, `forceOpenInventory`, `registerHook`, `removeHooks`. Client: `Items`,
  `Search`, `GetPlayerItems`, `GetPlayerWeight`, `GetPlayerMaxWeight`, `GetSlot*`, `getCurrentWeapon`,
  `openInventory`, `openNearbyInventory`, `closeInventory`, `displayMetadata`. Events:
  `ox_inventory:itemCount`, `updateInventory`, `currentWeapon`, `disarm`, `openedInventory`, `closedInventory`.
  With `qs-coreinventory` the items of `shared/ox_items.lua` are added to the catalogue. With
  **qs-inventory** its own compatibility layer answers first, so update it to the version with the fixed layer.
- **`chat`**: `qs-corechat` does `provide 'chat'` and answers `exports.chat:addMessage` and
  `registerMessageHook`, and fires `chatMessage`.
- **Commands** that qs-core does not already have: `/job`, `/gang`, and for admins
  (`command.qs` ACE) `/setgang`, `/addjob`, `/removejob`, `/changejob`, `/setmoney`, `/togglepvp`.
  `/setjob`, `/car`, `/dv`, `/tp`, `/tpm` and the other admin commands are qs-core's own.

### Limits

- `players` keeps the qs-core columns: there is no `gang` column (the gang is in
  `metadata.gang`) and the JSON uses qs-core shapes. Scripts that run raw SQL on Qbox's
  `players`, `player_groups` or `users` (userId) tables are not covered; userIds are kept in
  `qbx_users`.
- Qbox's own character menu, spawn selector, queue, paycheck loop, hunger/thirst loop and
  vehicle persistence are not reproduced: qs-core, qs-coremulticharacter and qs-needs do
  those jobs. `useExternalCharacters`-style multicharacter scripts work through the callbacks above.
- `Player.Functions.SetInventory`, `GetCardSlot`, `AddField` and `AddMethod` raise an error,
  as in Qbox.
- Money hooks only run for changes made through the `qbx_core` exports / player functions,
  not for changes made by qs-core or the ESX/QB bridges.
- `ox_inventory` hooks: `registerHook` accepts every event, but only `openInventory` is fired,
  and only on `qs-coreinventory`. `swapItems`, `createItem`, `buyItem` and the others never fire.
- `qs-coreinventory` has no world drops: `CustomDrop` creates a stash zone at the coordinates that
  disappears after 30 minutes. Shops need `qs-coreshops`; `license` and `grade` on shop items are ignored.
- The chat theme of `qbx_chat_theme` is not applied: `qs-corechat` keeps its own interface.
- Scripts that pick the framework themselves may choose ESX first, because `es_extended`
  keeps running next to `qbx_core` (`Renewed-Banking` does this).
- While `qbx_core` is started, `players.citizenid` and `players.license` use `utf8mb4_unicode_ci`
  (as Qbox) so scripts can add foreign keys to them. qs-core changes the table on start; on that
  first start a script creating such a key at the same moment can still fail once, a restart
  clears it. Without `qbx_core` the table keeps the database default.
- Accounts follow qs-core rules: `bank` cannot go below 0 either (Qbox only blocks `cash`
  and `crypto`), and `metadata.isdead` is qs-core's `is_dead` (`SetMetadata('isdead', v)`
  calls `SetPlayerDead`).
- The client job/gang catalogue (`GetJobs`, `GetGangs`, `require '@qbx_core.shared.jobs'`)
  is published through `GlobalState.qbxJobs` / `GlobalState.qbxGangs`.
