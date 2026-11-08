# 18 · qs-ambulance — EMS Job

Medical job (`resources/[addons]/qs-ambulance`): an **injury system** (per body zone:
bleeding / bruising / burning), diagnosis and treatment by medics, a paid **self-heal**
point, a free **supply cabinet**, an **EMS garage**, EMS **alerts**, and a **stretcher**
you carry like a box to move downed patients.

- **Depends on:** `qs-core`. Job `ambulance` (in `qs-core/shared/jobs.lua`). Items go
  through qs-core's inventory layer (qs-coreinventory, or qs-inventory when installed).
- **Map:** the default hospital, supply and garage coordinates are at Pillbox Hill and
  need the interior from `resources/[maps]/hospital_map` (started by `ensure [maps]`).

---

## Usage

- **Injuries** are applied by damage: falls and vehicles bruise, fire burns, and a ped
  attacker's weapon decides the type (see `Config.DamageCategories`; anything else
  bleeds). Each hit raises that zone's level (1–4). Untreated injuries cause passive
  effects every 5 s (bleed drain, limp, screen blur).
- **Medics** (`ambulance` job; duty is not checked):
  - Press **E** next to a downed player, or use **/diagnose** (nearest player, or
    yourself), to open the injury report.
  - Drag the matching item onto a zone: **bandage** → bleeding, **icepack** → bruising,
    **burn cream** → burning (6 s each, one item per treatment).
  - Treating every injury of a **downed** patient revives them and pays the medic
    `Config.ReviveReward` in cash.
  - **Supply cabinet**: E for free bandages / ice packs / burn cream (60 s cooldown).
  - **EMS garage**: on foot E spawns the ambulance, in a vehicle E stores it.
  - Medics get an alert (notification + blip) when someone goes down or calls EMS.
- **Hospital ped** (anyone): press **E** and pay $250 cash for a full heal (health and
  all injuries).
- **Bandage** (anyone): using it lowers your worst bleeding by one level and restores
  25 HP.
- **/stretcher** — deploy (and pick up) your stretcher, or remove it if you already have
  one. Near a stretcher: **E** move / drop, **G** load / unload the nearest downed
  player, **H** put it into a nearby ambulance (or store it when no ambulance is near).

## Config (`config.lua`)

Key blocks: `Config.Hospital` (self-heal ped, price, time), `Config.BodyRegions` /
`Config.Regions` (bone→zone map), `Config.TreatmentItems` (injury→item),
`Config.TreatmentTime`, `Config.TreatDistance`, `Config.DamageCategories`
(weapon→injury type), `Config.Effects` (passive effects), `Config.BandageHeal` /
`Config.BandageTime`, `Config.AlertDuration`, `Config.Supplies` (cabinet items and
cooldown), `Config.Garage` (vehicle), `Config.ReviveReward`, `Config.Stretcher` (prop,
anims, offsets, keys, per-model attach point).

## Commands

| Command | Purpose |
|---|---|
| `/diagnose` | Inspect a nearby patient's injuries (or your own). |
| `/stretcher` | Deploy / remove your stretcher. |

Both require the `ambulance` job; there are no key mappings.

## Items

`icepack` and `burn_cream` are registered here; `bandage` is a qs-core base item whose
use is handled here.

## Notes

- Blips: the hospital blip is public; the EMS garage blip only shows for the
  `ambulance` job. The supply cabinet has no blip.
- Downed state, respawn and the "call EMS" key (**G** while downed) are driven by
  qs-core (`qs-core/client/death.lua`, `Config.Death`). qs-ambulance listens to it to
  alert medics and revives patients with `qs:client:revive`.
- The txAdmin menu **Heal** also revives a downed player (handled in qs-core).
- Injuries are kept in server memory; respawning does not clear them — the hospital
  self-heal or a medic does.
