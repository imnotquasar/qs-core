# 14 · qs-jobs — Job Center & Civilian Jobs

Two things in one resource (`resources/[addons]/qs-jobs`):

1. **Job Center** — a ped/NUI where players browse and **apply** for civilian jobs.
2. **Activity jobs** — gather → process → sell loops (**miner**, **lumberjack**, and
   **fisher**, which has no process step) and a **delivery** job (van run around the city).

Jobs themselves (labels, grades, salaries) are defined in **`qs-core/shared/jobs.lua`**;
this resource only handles *getting* a job and *doing* the work. Setting a job uses
the core export `SetJob` (always grade 0). Paychecks are paid by qs-core, not here.

- **Depends on:** `qs-core` (items go through qs-core's inventory layer —
  qs-coreinventory, or qs-inventory when installed).

---

## Usage

- Go to the **Job Center** ped (public blip), press **E** → pick a job → you're
  assigned it via `exports['qs-core']:SetJob(src, job, 0)`. **Quit job** sets you back
  to `unemployed`. The listed paycheck is the job's grade-0 salary from qs-core.
- For an activity job (you must hold that job): go to a **gather** spot and press **E**
  (the spot is then depleted for `Config.GatherCooldown`), take the raw item to a
  **process** spot, then **sell** at the buyer ped — selling sells everything you carry
  that the buyer accepts, in one go.

  | Job | Gather | Process | Sell |
  |---|---|---|---|
  | `miner` | Quarry rocks → 1–2 `stone` (6 % chance of a `gold_nugget`) | Foundry: 3 `stone` → 1 `metal_ingot` | `metal_ingot` $70–90, `gold_nugget` $250–350 |
  | `lumberjack` | Paleto forest trees → 1–2 `wood_log` | Sawmill: 2 `wood_log` → 1 `wood_plank` | `wood_plank` $45–60 |
  | `fisher` | Fishing spots → 1 fish (`mackerel` 60 % / `bass` 30 % / `tuna` 10 %) | — | `mackerel` $25–35, `bass` $50–65, `tuna` $110–150 |

- **Delivery:** at the depot press **E** to start a shift — a **$100 deposit** is taken
  from cash and a van spawns. Deliver packages to 5 random marked points ($45–65 each,
  paid on the spot), then go back to the depot and press **E** to end the shift: the
  deposit is refunded, plus a **$150 bonus** if every package was delivered. The van is
  removed wherever it is; it does not have to be returned.

All pay goes to `cash`. Progress bars can be cancelled with **X**.

## Config (`config.lua`)

| Key | Meaning |
|---|---|
| `Config.Control` / `Config.InteractDistance` | Interact key (E) and reach (2.2 m). |
| `Config.PayAccount` | Account activity/delivery pay lands in, and the van deposit is taken from (`cash`). |
| `Config.GatherCooldown` | ms a gather spot is depleted after harvesting (20000, client-side). |
| `Config.Center` | Job Center ped, coords, blip and `jobs` — the job keys offered (`delivery`, `miner`, `lumberjack`, `fisher`). |
| `Config.Delivery` | Depot ped/blip, van spawns, van models, `stopsPerShift` (5), `payPerStop` (45–65), `finishBonus` (150), `deposit` (100), `deliverTime` (3500 ms), anim, delivery points. |
| `Config.Jobs` | Activity job definitions: `gather` (prop, props per zone, spread, item/min/max or weighted `catches`, optional `bonus`, time, anim or scenario, blip, locations), optional `process` (input/output and amounts, time, anim, blip, locations), `sell` (ped, blip, `prices` min–max per item). |

To offer another civilian job at the Job Center, define it in `qs-core/shared/jobs.lua`
(or register it at runtime with `exports['qs-core']:RegisterJob(name, def)`) **and** add
its key to `Config.Center.jobs` — only keys in that list are shown. An activity loop for
it needs an entry in `Config.Jobs` with the same key.

## Items

Registered by this resource (not usable): `stone`, `metal_ingot`, `gold_nugget`,
`wood_log`, `wood_plank`, `mackerel`, `bass`, `tuna`.

## Events

| Event | Side | Purpose |
|---|---|---|
| `qs-jobs:server:openCenter` / `qs-jobs:client:openCenter` | both | Open the job center UI. |
| `qs-jobs:server:apply` / `qs-jobs:client:applied` | both | Apply for (or quit) a job. |
| `qs-jobs:server:gather` | server | Grant a gathered item. |
| `qs-jobs:server:process` | server | Consume input, give processed output. |
| `qs-jobs:server:sell` | server | Sell goods at the job's buyer. |
| `qs-jobs:server:startShift` / `qs-jobs:client:shiftStarted` | both | Start a delivery shift (deposit, stops, van). |
| `qs-jobs:server:deliver` / `qs-jobs:client:delivered` | both | Delivery drop. |
| `qs-jobs:server:endShift` / `qs-jobs:client:shiftEnded` | both | End the delivery shift (refund, bonus, remove van). |

No exports and no commands.

## Notes

- Blips for job locations are gated by the job (only shown when you hold the job);
  the Job Center blip is always shown.
- Changing job mid-shift ends the delivery shift (deposit refunded, no bonus);
  disconnecting mid-shift forfeits the deposit.
- Every check uses the job name only; on-duty status is not used.
