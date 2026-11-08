# 19 · qs-police — Police Job

Law-enforcement toolkit (`resources/[addons]/qs-police`): **Mission Row** station
(armory, evidence locker, forensics lab, garage), **cuff / escort / put-in-car /
search** actions, **fines**, **impound**, and a bullet-casing / blood **evidence**
system with map markers. Optimised to sit near 0.00 resmon when idle (threads gate on
being armed / holding the police job / being near evidence).

- **Depends on:** `qs-core`, `oxmysql`. Job `police` (in `qs-core/shared/jobs.lua`).
  Items and the evidence stash go through qs-core's inventory layer (qs-coreinventory,
  or qs-inventory when installed).

---

## Usage

- With the `police` job (duty is not checked), interact at the station with **E**:
  - **Armory** — take weapons/armor/tools for free (fixed amount per take).
  - **Evidence locker** — shared stash `police_evidence` (50 slots). With
    qs-coreinventory, open your inventory while standing at the locker; with
    qs-inventory, press E there.
  - **Forensics lab** — analyze collected **blood** samples to get the owner's name.
  - **Garage** — on foot, spawn a police vehicle; as driver of a vehicle, store it.
- Commands act on the **nearest player**: `/cuff` (needs `handcuffs`), `/escort`,
  `/putincar`, `/outcar` (target must be cuffed), `/search` (confiscating needs the
  target cuffed).
- `/fine <amount> [reason]` — comes straight out of the target's **bank**
  (`Config.Fine` range).
- `/impound` — removes the nearest vehicle within 5 m.
- `armor` is usable: 3 s, then full body armor.
- Firing a weapon drops **bullet casings** at the bullet impact point (or the shooter's
  position when nothing was hit) and may raise a "Shots fired" alert to police; a
  player who **dies** leaves a **blood** sample with their DNA. Police see casing/blood ground markers within `viewDistance`; collect them
  with **E** (needs an `evidence_bag`, one is used per sample) and analyze blood in the lab.

## Commands

| Command | Purpose |
|---|---|
| `/cuff` | Cuff / uncuff the nearest person. |
| `/escort` | Escort / release the nearest cuffed person. |
| `/putincar` | Put the nearest cuffed person in the nearest vehicle. |
| `/outcar` | Take the nearest cuffed person out of a vehicle. |
| `/search` | Search the nearest person (confiscate from the UI). |
| `/fine <amount> [reason]` | Fine the nearest person (bank). |
| `/impound` | Remove the nearest vehicle. |

All require the `police` job; there are no key mappings.

## Config (`config.lua`)

| Key | Meaning |
|---|---|
| `Config.Control` / `Config.InteractDistance` | Interact key (E) and reach. |
| `Config.TargetDistance` | Cuff / escort / search reach (3.5 m). |
| `Config.Station` | Station blip and coords for `armory`, `locker`, `lab`, `garage`, `garageSpawn`. |
| `Config.Armory` | Items (and count per take) officers can take: pistol, pistol ammo, armor, handcuffs, evidence bags, bandages. |
| `Config.Garage` | Police vehicles in the garage menu (`police`, `police2`, `police3`, `policeb`). |
| `Config.Fine` | `{ min, max }` fine range (1–50000). |
| `Config.Evidence` | `lifetime`, `maxPoints`, `casingCooldown`, `maxCasingDist`, `alertChance`, `alertCooldown`, `alertDuration`, `viewDistance`, `collectDistance`. |
| `Config.WeaponLabels` | Weapon name → label shown on collected casings. |

## Items

Registered by this resource: `handcuffs`, `evidence_bag`, `evidence` (collected sample,
carries the weapon / DNA / time / location in its info), `armor` (usable).

## Exports (server)

| Export | Purpose |
|---|---|
| `Alert(coords, label)` | Broadcast a dispatch alert (notification + flashing blip for 60 s) to every player with the `police` job. `coords` must be a plain table `{ x, y, z }` (a `vector3` is ignored); `label` defaults to "Shots fired". Used by qs-corevehiclekeys (carjack) and other resources. |

```lua
exports['qs-police']:Alert({ x = c.x, y = c.y, z = c.z }, 'Store robbery')
```

## Events (selection)

`qs-police:client:cuffed`, `:escorted`, `:putInCar`, `:outCar`, `:useArmor`,
`:evidence` / `:evidenceRemoved`, `:alert`, `:openUI` / `:updateUI`.
The cuffed state is also exposed as the replicated state bag `Player(src).state.cuffed`.

## Notes

- Everything is job-gated on the `police` job name (on-duty status is not checked):
  the garage blip, station points, commands, evidence markers and alerts. The station
  blip is public.
- Evidence lives in server memory (cap `maxPoints`, expires after `lifetime`). The lab
  reads `players.charinfo` to name offline DNA owners.
