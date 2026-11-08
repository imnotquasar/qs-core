# 20 · qs-coredrugs — Drug Economy

Illegal economy loop (`resources/[addons]/qs-coredrugs`, formerly `qs-drugs`): **gather**
raw material at fields, **process** it into packaged product at a lab (multi-stage with
hand props, animations and particles), then **sell** packages to NPC dealers for dirty
cash. Three drugs ship by default: **weed**, **cocaine** and **meth**.

- **Depends on:** `qs-core` (items go through qs-core's inventory layer —
  qs-coreinventory, or qs-inventory when installed).

---

## Usage

- Anyone can take part (no job required); fields, labs and dealers all have public blips.
- Go to a **gather** zone (scattered harvestable props), press **E** to collect the
  raw item (weed leaf / coca leaf / chemicals).
- Take the raw item to a **process** table and press **E** → a realistic multi-step
  process runs (e.g. trim → weigh → pack), each stage with a prop in hand and its own
  progress (cancelling any stage gives nothing); it consumes the input and outputs the
  packaged drug.

  | Drug | Gather | Process | Dealer price |
  |---|---|---|---|
  | Weed | 1–3 `weed_leaf` | 3 → 1 `weed_baggie` | $55–85 |
  | Cocaine | 1–2 `coca_leaf` | 4 → 1 `cocaine_baggie` | $120–180 |
  | Meth | 1–2 `meth_chem` | 4 → 1 `meth_baggie` | $150–210 |

- Sell packages to an **NPC dealer** (paid into `black_money`). Prices are rolled each
  time you open the dealer, and a dealer buys at most `Config.SellLimitPerVisit` (25)
  packages per visit.

## Config (`config.lua`)

| Key | Meaning |
|---|---|
| `Config.Control` / `Config.InteractDistance` | Interact key (E) and reach (2.0 m). |
| `Config.SellAccount` | Account sales pay into (`black_money`). |
| `Config.SellLimitPerVisit` | Max packages a dealer buys per visit. |
| `Config.HarvestPerZone` / `Config.HarvestSpread` | Harvest props scattered per gather zone (8) + radius (3.5 m). |
| `Config.Drugs` | Per-drug `label` and `gather` / `process` / `sell` definitions (items, item labels/weights, props, anims, **stages**, blips, locations, price range). |
| `Config.Dealer` | NPC dealer ped, scenario, blip and locations. |

Each drug's `process.stages` is an array of `{ label, time, anim = {dict,clip},
prop = {model, bone, pos, rot}, ptfx = {asset, name, bone, offset, scale} }`, where
`label` is a locale key (`stage_trim`, `stage_weigh`, …). If a drug has no `stages`, it
falls back to a single animation for `process.time`. Set a `blip` to `false` to hide it.

The raw and packaged items are registered automatically from `Config.Drugs`.

## Events

| Event | Side | Purpose |
|---|---|---|
| `qs-coredrugs:server:gather` | server | Grant a harvested item. |
| `qs-coredrugs:server:process` | server | Consume input, give packaged output. |
| `qs-coredrugs:server:sell` / `:openDealer` / `:closeDealer` | server | Dealer buy flow. |
| `qs-coredrugs:client:openDealer` / `:updateDealer` | client | Dealer NUI. |

No exports and no commands.

## Notes

- Process **tables** spawn at the exact configured coordinate (no ground-snap), so set
  the `z` to the floor height.
- There is no police integration (no alerts) and harvest props do not deplete.
