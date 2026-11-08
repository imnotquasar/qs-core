# 16 · qs-garage — Player Garage

Store and take out owned vehicles. Each garage is an interaction point with a
rotating **3D preview** of the selected car and a take-out button; the list carries
each car's state, fuel, engine and body condition. Vehicles live in the core
`qs_vehicles` table.

- **Resource:** `[addons]/qs-garage`.
- **Depends on:** `qs-core` (keys via `qs-corevehiclekeys` when it is started).
- **UI:** React NUI.

---

## Usage

- Every garage has a **Garage** blip on the map. Walk to the garage point on foot and
  press **E** → the menu lists your vehicles registered to that garage (stored or out).
- Select a car → it fades in at the garage's preview point and turns on a turntable;
  switching cars **cross-fades** the preview vehicle.
- **Take out** spawns it at the garage's spawn point, applies its saved mods, fuel and
  damage, gives you the keys (via qs-corevehiclekeys) and puts you in the driver seat.
  It is refused if a car with that plate is already in the world near you.
- Drive an owned car to **any** garage point and press **E** from the driver seat to
  store it there (its fuel, engine/body health and mods are saved, and the vehicle is
  removed).

## Config (`config.lua`)

| Key | Default | Meaning |
|---|---|---|
| `Config.OpenKey` / `Config.InteractDistance` | `38` (E) / `3.0` | Interact control and reach. |
| `Config.Camera` | `dist 5.2, side 1.6, height 0.3, target 0.2, fov 32.0, turntable 12.0` | Preview camera (`turntable` = rotation speed in degrees per second). |
| `Config.Garages` | `{}` | Each: `{ id, label, coords = vec4, preview = vec4, spawn = vec4, blip }`. `id` matches `vehicles.garage`. |

The 31 default garages are in `qs-garage/garages.lua` (loaded after `config.lua`),
which appends them to `Config.Garages` from a compact list
`{ name, menu = vec3, spawn = vec4, preview = vec4 }`. The id is generated from the
name (`Legion Square` → `legion_square`) and every generated garage gets the same blip
(sprite 357, colour 3, scale 0.5). Add your own garages either to that list or as full
entries in `Config.Garages`.

## Server (callbacks / events)

- Callback `qs-garage:list(garageId)` → the player's vehicles registered to that
  garage (`plate, model, state, fuel, engine, body, props`).
- Callback `qs-garage:takeout(garageId, plate)` → checks ownership and garage, sets
  `state = 0`, returns the vehicle data.
- Callback `qs-garage:store(garageId, plate, fuel, engine, body, props)` → checks
  ownership and saves the vehicle to that garage with `state = 1`.
- Take-out and store are rate-limited to one call per 1.2 s per player.
- NUI callbacks (client): `select`, `takeout`, `close`.

## Notes

- There is no job filtering: every garage and blip is visible to everyone.
- Vehicles bought at qs-vehicleshop are registered to `Config.DefaultGarage`
  (`legion`), which is not one of the generated garage ids, so a new car only shows up
  in a garage after you have stored it somewhere.
- Uses the exact same preview camera code as **qs-vehicleshop** for a consistent look.
