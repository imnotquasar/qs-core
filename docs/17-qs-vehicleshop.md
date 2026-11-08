# 17 · qs-vehicleshop — Dealership

Buy vehicles from a showroom. A rotating **3D preview** shows the selected model;
buying charges the player, registers the car in the core `qs_vehicles` table, delivers it
and hands over the keys.

- **Resource:** `[addons]/qs-vehicleshop`.
- **Depends on:** `qs-core` (keys via `qs-corevehiclekeys` when it is started).
- **UI:** React NUI (same camera code as qs-garage).

---

## Usage

- Find the **Dealership** blip, walk up to the salesman ped and press **E** → browse
  categories/vehicles. Your cash and bank balances are sent to the menu.
- Selecting a model cross-fades the preview car. **Buy** deducts the price (from the
  first account in `Config.PayAccounts` that can afford it), registers the car with a
  new unique plate (`QS` + 5 letters/digits), spawns it at the delivery point, gives
  keys (qs-corevehiclekeys) and puts you in the driver seat.
- The price always comes from the server-side `Config.Vehicles`, and the server checks
  you are within `Config.InteractDistance + 10.0` m of a dealership.

## Config (`config.lua`)

| Key | Default | Meaning |
|---|---|---|
| `Config.OpenKey` / `Config.InteractDistance` | `38` (E) / `2.5` | Interact control and reach. |
| `Config.PayAccounts` | `{ 'bank', 'cash' }` | Accounts tried in order. |
| `Config.DefaultGarage` | `'legion'` | Garage id (`vehicles.garage`) a bought car is registered to. |
| `Config.Camera` | `dist 5.2, side 1.6, height 0.3, target 0.0, fov 32.0, turntable 12.0` | Showroom camera. |
| `Config.Locations` | 1 dealership | Dealership points: `{ ped, coords = vec4, preview = vec4, spawn = vec4, blip }`. |
| `Config.Categories` / `Config.Vehicles` | 6 categories, 21 vehicles | Catalogue grouped by category id (`{ model, label, price }`). The first vehicle of the first category is the initial preview. |

## Server (callbacks)

- Callback `qs-vehicleshop:buy(model)` → validates model, proximity and money
  (rate-limited to one call per 1.5 s), creates the owned vehicle, returns
  `{ ok = true, plate, model, account, price }` or `{ ok = false, msg }` with
  `msg = 'money' | 'far' | 'invalid' | 'plate'`.
- NUI callbacks (client): `preview`, `buy`, `close`.

## Notes

- `preview`/`spawn` coords use `vec4(x, y, z, heading)`, same convention as garages —
  the camera is placed in front of the `preview` point.
- New cars are saved with `state = 0` (out) in `Config.DefaultGarage`. The default
  `'legion'` is not one of qs-garage's generated ids (e.g. `legion_square`), so the car
  only appears in a garage list after you store it at a garage.
- The delivery spot is not cleared before spawning.
