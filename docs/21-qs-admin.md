# 21 · qs-admin — Admin Menu

An ACE-gated admin menu (React NUI) with player management, self tools and server
tools. Player and server actions run server-side after an ACE permission check;
client-side "self" tools (noclip, godmode, etc.) run locally.

- **Resource:** `[addons]/qs-admin`.
- **Depends on:** `qs-core`, `oxmysql` (bans).
- **Permission:** ACE `command.qs` (`Config.Permission`). The shipped `server.cfg`
  grants it to `group.admin` through `add_ace group.admin command allow`.

---

## Usage

- **/admin** opens the menu (only if you pass the ACE check). It has no default key.
- **Players tab:** goto / bring / spectate / freeze / heal / revive / kill / set job /
  set group / money (add, remove or set on an account) / give item / give weapon /
  kick / ban per player. **Goto** and **spectate** close the menu.
- **Self tab:** noclip, godmode, invisible, TP-to-waypoint, fix / spawn / delete
  vehicle, clear area. Using **noclip** or **TP-to-waypoint** closes the menu.
- **Server tab:** set weather / time, announce (sent to everyone online).

What the actions do:

| Action | Effect |
|---|---|
| Goto / Bring | Teleport you to the player / the player to you (with fade). |
| Spectate | Moves you to the player, hides and freezes you and spectates them. Backspace / Esc (or spectating again) stops; you stay where you were moved. |
| Freeze / Heal / Revive | Freeze toggle; full health + 100 armour; core revive. |
| Kill | Puts the player in the core downed state (`qs:client:forceDown`). |
| Set job / Set group | Core `SetJob(id, job, grade)` / runs the core `setgroup <id> <group>` command. |
| Money | Core `AddMoney` / `RemoveMoney` / `SetMoney` on the chosen account (default `cash`). |
| Give item / Give weapon | Core `addItem` (count, default 1) / native `GiveWeaponToPed` with ammo (default 250). |
| Kick / Ban | Drop with a reason / insert into `bans` (minutes, `0` = permanent) and drop. |
| Spawn vehicle | First deletes the vehicle you are in and any vehicle touching you or the spawn point (within 3 m, skipped if another player is inside), then spawns the model 3 m in front of you, puts you in the driver seat and gives you the keys (qs-corevehiclekeys). |
| Delete vehicle / Fix vehicle | Delete the vehicle you are in or the closest within 6 m / fully repair the vehicle you are in. |
| Clear area | Clears vehicles and objects within 30 m. |
| Weather / Time | Applied on every client online at that moment. |

## Config (`config.lua`)

| Key | Default | Meaning |
|---|---|---|
| `Config.Permission` | `'command.qs'` | ACE permission required. |
| `Config.Webhook` | `''` | Optional Discord webhook to log actions (`''` = off). |
| `Config.Groups` | `user, mod, admin, superadmin` | Groups offered in the Set-Group action. |
| `Config.Weathers` | 12 presets | Weather presets in the Server tab. |

## Commands / Keys

| Command | Purpose |
|---|---|
| `/admin` | Open the admin menu (admins only). |

## Events

| Event | Side | Purpose |
|---|---|---|
| `qs-admin:action` | server | Run an admin action (`action, target, data`; ACE-checked). |
| `qs-admin:client:teleport` / `:heal` / `:freeze` / `:giveweapon` / `:announce` / `:weather` / `:time` / `:spectate` | client | Apply an action to the affected player. |

Server callbacks: `qs-admin:isAllowed`, `qs-admin:players`.

## Notes

- Noclip uses the core `ToggleNoclip` / `IsNoclipActive` exports; the core draws the
  instructional buttons.
- Every server action except goto and spectate is printed to the server console and,
  if `Config.Webhook` is set, posted to Discord.
