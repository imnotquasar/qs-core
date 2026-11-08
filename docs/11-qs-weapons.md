# 11 · qs-coreweapons — Weapons & ammo

Turns **every GTA weapon (105)** and its ammo into **inventory items**. Using a
weapon equips it (via qs-coreinventory); using ammo loads a magazine into the
equipped weapon of that category. Throwables stack and are spent when thrown,
weapons leave the ped when their item leaves the inventory, and GTA's native
loot is switched off.

- **Dependencies:** `qs-core` (equip, weapon removal and throwable sync use
  qs-coreinventory's client events).
- **Version:** 1.0.0.
- **No own UI, keys or exports** (everything goes through the inventory: `F1`,
  the `TAB` item wheel or quick slots `1`–`5`).

On boot, it **automatically registers** every weapon and ammo item from
`config.lua` in the qs-core catalogue (all `useable`; weapons stack to 1,
throwables to `ThrowableStack`, ammo to the inventory default of 64).

---

## 1. Configuration (`config.lua`)

```lua
-- rounds per magazine: given on first equip and added per ammo item
WeaponsConfig.MagSize = {
    pistol = 12, smg = 30, rifle = 30, shotgun = 8, sniper = 10, mg = 100,
    launcher = 1, flare = 1, taser = 1,
}

-- max stack of throwables (grenades, molotovs...)
WeaponsConfig.ThrowableStack = 10

-- weapon item -> GTA weapon + category (+ optional fixed `ammo`)
WeaponsConfig.Weapons = {
    weapon_knife    = { weapon = 'WEAPON_KNIFE',    cat = 'melee',  label = 'Knife',     weight = 300 },
    weapon_pistol   = { weapon = 'WEAPON_PISTOL',   cat = 'pistol', label = 'Pistol',    weight = 1000 },
    weapon_microsmg = { weapon = 'WEAPON_MICROSMG', cat = 'smg',    label = 'Micro SMG', weight = 1800 },
    weapon_grenade  = { weapon = 'WEAPON_GRENADE',  cat = 'throwable', label = 'Grenade', weight = 400 },
    weapon_petrolcan = { weapon = 'WEAPON_PETROLCAN', cat = 'misc', ammo = 4500, label = 'Jerry Can', weight = 4000 },
    -- ... 105 weapons in total
}

-- ammo item -> category it feeds
WeaponsConfig.Ammo = {
    ammo_pistol   = { cat = 'pistol',   label = 'Pistol Ammo',     weight = 200 },
    ammo_smg      = { cat = 'smg',      label = 'SMG Ammo',        weight = 300 },
    ammo_rifle    = { cat = 'rifle',    label = 'Rifle Ammo',      weight = 400 },
    ammo_shotgun  = { cat = 'shotgun',  label = 'Shotgun Shells',  weight = 300 },
    ammo_sniper   = { cat = 'sniper',   label = 'Sniper Ammo',     weight = 500 },
    ammo_mg       = { cat = 'mg',       label = 'MG Ammo',         weight = 700 },
    ammo_launcher = { cat = 'launcher', label = 'Launcher Round',  weight = 1500 },
    ammo_flare    = { cat = 'flare',    label = 'Flare Shell',     weight = 100 },
    ammo_taser    = { cat = 'taser',    label = 'Taser Cartridge', weight = 50 },
}
```

Weapons per category:

| Category | Weapons | Examples |
|---|---|---|
| `melee` | 18 | knife, bat, crowbar, machete, nightstick, battle axe |
| `pistol` | 17 | pistol, combat pistol, AP pistol, revolvers, WM 29 |
| `smg` | 8 | micro SMG, SMG, combat PDW, machine pistol, tactical SMG |
| `shotgun` | 10 | pump, sawn-off, assault, heavy, combat shotgun |
| `rifle` | 14 | assault, carbine, special carbine, military, battle rifle |
| `mg` | 7 | MG, combat MG, Gusenberg, minigun, Widowmaker |
| `sniper` | 6 | sniper, heavy sniper, marksman, precision rifle |
| `launcher` | 8 | RPG, grenade launchers, homing, firework, railgun, EMP |
| `flare` | 1 | flare gun |
| `taser` | 1 | taser |
| `throwable` | 10 | grenade, BZ gas, tear gas, molotov, sticky bomb, mine, pipe bomb, flare, snowball, ball |
| `misc` | 5 | jerry cans, fire extinguisher, Up-n-Atomizer (fixed `ammo`) |

---

## 2. How it works

**Equip a weapon:** on using a `weapon_*`, qs-coreinventory sees the `weapon`
key in the item def and fires `qs-inv:client:equip` with the weapon and its
`ammo`: the item's own `ammo` if set, otherwise `1` for throwables, otherwise
`MagSize[cat]` (melee gets 0). The rounds are only given if the ped does not
already have that weapon. Using the item again while it is in hand holsters it.

**Load ammo:**

1. You use an `ammo_*` → `qs-inventory:usedItem` → qs-core
   `qs:server:usedItem` (server) → `qs-coreweapons:client:useAmmo`.
2. The client looks for a weapon **of that category**: first the selected weapon,
   otherwise the first of the category the ped has.
3. If it has one: `AddAmmoToPed(ped, weapon, MagSize)`, notifies *loaded* and asks
   the server to **consume** the item (`qs-coreweapons:server:consumeAmmo` →
   `removeItem`).
4. If it has no weapon of that category: notifies an error and does not consume
   ammo.

**Throwables:** they stack up to `ThrowableStack`. When one is equipped, the
ped's ammo for it is set to the item count; each throw is detected client-side
and reported (`qs-coreweapons:server:thrown`), and the server removes that many
items. If you drop/give/store the rest, the count is resynced.

**Weapon leaves the inventory → leaves the ped:** after every inventory update,
any weapon you equipped from the inventory is removed from the ped once you no
longer have its item (dropped, given, sold, moved to a trunk/stash).

**No native GTA loot:**

- No weapon drops when a ped (player or NPC) dies.
- NPCs carry no cash (`SetPedMoney 0`).
- No weapon/ammo reward when entering police or other vehicles.
- Native weapon pickups are disabled for the player (on load and revive) and
  cleared 3 s after your death.

---

## 3. Events

| Event | Direction | Args | Description |
|---|---|---|---|
| `qs:server:usedItem` | server (local) | `src, item, slot, info` | Detects ammo usage (fired by qs-core). |
| `qs-coreweapons:client:useAmmo` | server → client | `item, cat, amount` | Tries to load a magazine. |
| `qs-coreweapons:server:consumeAmmo` | client → server | `item` | Consumes 1 ammo item. |
| `qs-coreweapons:server:thrown` | client → server | `item, amount` | Removes thrown throwables (rate-limited, max `ThrowableStack` per call). |
| `qs-inv:client:set` / `qs-inv:client:equip` | client (listened) | — | Weapon removal and throwable ammo sync. |

---

## 4. Add a weapon or ammo

```lua
-- New weapon (e.g. an add-on weapon streamed by another resource)
WeaponsConfig.Weapons.weapon_custom_ar = {
    weapon = 'WEAPON_CUSTOM_AR', cat = 'rifle', label = 'Custom AR', weight = 3200,
}
```

On resource restart it auto-registers in the core catalogue. A new category
also needs a `MagSize` entry and an `WeaponsConfig.Ammo` item with the same
`cat`. To sell it, add it to `qs-coreshops` (`Config.Products.weapons`).

---

## 5. Notes

- Weapons are **items** (not a persistent loadout): the ESX bridge's
  `getLoadout()` returns `{}`, but `addWeapon/removeWeapon` work (natives).
- Ammo is not stored on the item: rounds live on the ped.
- Each weapon/ammo weight is taken from its config entry (grams).
