# qs-core · txAdmin recipe

Installs a ready-to-play qs-core server from txAdmin in a few minutes: database,
`server.cfg`, the framework and every dependency.

## Install with txAdmin

1. Open **txAdmin → Setup → Server Deployer** and choose **Remote URL Template**.
2. Paste this URL:

   ```
   https://raw.githubusercontent.com/imnotquasar/qs-core/main/qs-recipes/recipe.yaml
   ```

3. Fill in your server name, license key and database credentials, then deploy.

The recipe creates the database tables, writes `server.cfg` (with comments explaining
every section) and downloads:

| Folder | Contents | Source |
|---|---|---|
| `[core]` | qs-core and the resources needed to play | this repository |
| `[addons]` | jobs, police, EMS, banking, garages, admin… | this repository |
| `[bridge]` | ESX / QBCore compatibility | this repository |
| `[standalone]` | oxmysql 2.14.3, ox_lib 3.39.0, pma-voice 6.6.2 | their own repositories |
| `[maps]` | bob74_ipl 2.7.1, Pillbox hospital interior | their own repositories |
| `[cfx-default]` | mapmanager, spawnmanager | citizenfx/cfx-server-data |

Third-party downloads are pinned to a fixed commit or release, so a change upstream
never breaks a new install.

## After deploying

- Join the server: txAdmin already made you an admin (admin menu with **/admin**).
- Change the language in `server.cfg` with `setr qs:locale "en"`.
- Add ESX or QBCore scripts at the end of `server.cfg` (`[bridge]` starts right after `qs-core`).

## Manual install

1. Copy `[core]`, `[addons]` and `[bridge]` into your `resources` folder.
2. Import `[core]/qs-core/sql/qscore.sql` into your database.
3. Install oxmysql, ox_lib, pma-voice, bob74_ipl, the hospital map and, from
   cfx-server-data, mapmanager and spawnmanager. Do not add `basic-gamemode`: its
   autospawn fights qs-core's downed state.
4. Copy `qs-recipes/server.cfg` to your server folder and replace the `{{...}}` placeholders.

Resources are started by name in boot order, so keep the `ensure` list in `server.cfg`
as it is instead of replacing it with `ensure [core]`.

## Requirements

- A recent FXServer artifact with game build **3751** support
- MySQL 8.0+ or MariaDB 10.4+
- OneSync (enabled by the recipe)

## License

GNU GPL v3.0 (`GPL-3.0-only`), see [`LICENSE`](../LICENSE). The ESX/QBCore bridges
include code derived from ESX Legacy and QBCore (GPL-3.0); see [`NOTICE`](../NOTICE).
