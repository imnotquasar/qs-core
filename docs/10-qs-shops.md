# 10 · qs-coreshops — Shops

Shops with a ped, blip and interaction zone. Opens a purchase UI when you press
`E` near the ped. **All purchases are validated on the server**: proximity, job,
product list, carry capacity and balance.

- **Dependencies:** `qs-core` (items are delivered through qs-core, so any
  inventory backend works).
- **Version:** 1.0.0.
- **UI:** React (`web/build`).
- **Interaction:** `E` (control 38).

Purchasable items must exist in the **qs-core catalogue**; products whose item
is not registered are hidden from the shop.

---

## 1. Configuration (`config.lua`)

```lua
Config.OpenControl = 38        -- E
Config.InteractDistance = 2.2
Config.BuyDistance = 5.0       -- the server re-validates this distance on open and on purchase
Config.PayAccount = 'cash'     -- 'cash' | 'bank'

-- product lists per type. names must exist in qs-core.
Config.Products = {
    normal   = { { name = 'water', price = 4 }, { name = 'bread', price = 6 }, ... },
    liquor   = { ... },
    hardware = { { name = 'lockpick', price = 35 }, ... },
    medical  = { { name = 'bandage', price = 25 }, { name = 'icepack', price = 40 }, { name = 'burn_cream', price = 45 } },
    weapons  = { { name = 'weapon_pistol', price = 750 }, { name = 'ammo_pistol', price = 40 }, ... },
}

-- shops: ped, blip, products and locations
Config.Shops = {
    {
        name = 'supermarket',
        label = '24/7 Supermarket',
        ped = 'mp_m_shopkeep_01',
        scenario = 'WORLD_HUMAN_STAND_MOBILE',
        blip = { sprite = 52, color = 2, scale = 0.6 },
        items = Config.Products.normal,
        -- job = 'police',        -- (optional) restrict the shop to a job
        locations = { vec4(24.47, -1346.62, 29.5, 271.66), ... },
    },
    -- ltd, liquor, hardware, ambulance_supplies, ammunation...
}
```

Included shops: `supermarket`, `ltd`, `liquor`, `hardware`,
`ambulance_supplies` (job `ambulance`, sells `Config.Products.medical`) and
`ammunation` (24 weapons + ammo; its `job = 'police'` line is commented out).

> `icepack` and `burn_cream` are registered by qs-ambulance; without it they do
> not show up in Medical Supplies.

---

## 2. How it works

1. The client creates peds/blips/zones for each `location`. Shops with a `job`
   only show their blips and prompt to players with that job.
2. Near the ped, `E` opens the shop → `qs-coreshops:server:open(name)`.
3. The server validates job and proximity and returns the view with prices and the
   current balance (`qs-coreshops:client:open`). The HUD is hidden while the
   shop is open.
4. On purchase → `qs-coreshops:server:buy(name, item, count)`. The server:
   - Re-validates job and proximity (`BuyDistance`).
   - `count` between 1 and 100.
   - Checks the item is in that shop's list (the price always comes from the
     config).
   - Checks `CanCarryItem` (weight/slots).
   - Checks balance in `PayAccount`.
   - Charges (`RemoveMoney`, reason `shop:<name>`) and delivers (`AddItem`); if
     `AddItem` fails, it **refunds**.
   - Returns the new balance (`qs-coreshops:client:cash`).

---

## 3. Events

| Event | Direction | Args | Description |
|---|---|---|---|
| `qs-coreshops:server:open` | client → server | `name` | Requests opening a shop. |
| `qs-coreshops:client:open` | server → client | `{ name, label, items, cash }` | Opens the UI. |
| `qs-coreshops:server:buy` | client → server | `name, item, count` | Validated purchase. |
| `qs-coreshops:client:cash` | server → client | `newBalance` | Refreshes the balance in the UI. |
| `qs:client:colorsChanged` | local | — | Repaints the theme. |

---

## 4. Add a shop / product

```lua
-- New product in an existing list
Config.Products.normal[#Config.Products.normal + 1] = { name = 'donut', price = 3 }

-- New shop
Config.Shops[#Config.Shops + 1] = {
    name = 'coffee',
    label = 'Bean Machine',
    ped = 'a_f_y_business_01',
    scenario = 'WORLD_HUMAN_STAND_MOBILE',
    blip = { sprite = 52, color = 25, scale = 0.6 },
    items = { { name = 'coffee', price = 4 }, { name = 'sandwich', price = 9 } },
    locations = { vec4(-630.0, 233.0, 81.8, 180.0) },
}
```

`ped`, `scenario`, `blip` and `job` are optional. Restart qs-coreshops to apply
(there is no runtime export to add shops).

> Any `name` used must be registered in qs-core (`RegisterItem`). Weapons/ammo are
> registered by `qs-coreweapons`, food/drinks by qs-core and `qs-needs`.

---

## 5. Restrict a shop to a job

Add `job = 'police'` to the shop (e.g. Ammunation). Only players with that job
see its blips and prompt, and the server rejects opening and purchasing if the
player does not have that job (duty status is not checked).
