Config = {}

Config.OpenControl = 38 -- E
Config.InteractDistance = 2.2
Config.BuyDistance = 5.0 -- buy reach

Config.PayAccount = 'cash' -- or bank

-- shop products
Config.Products = {
    normal = {
        { name = 'water',        price = 4 },
        { name = 'bread',        price = 6 },
        { name = 'sandwich',     price = 9 },
        { name = 'burger',       price = 12 },
        { name = 'cola',         price = 5 },
        { name = 'coffee',       price = 4 },
        { name = 'energy_drink', price = 8 },
        { name = 'bandage',      price = 25 },
    },
    liquor = {
        { name = 'cola',         price = 5 },
        { name = 'coffee',       price = 4 },
        { name = 'energy_drink', price = 8 },
        { name = 'water',        price = 4 },
    },
    hardware = {
        { name = 'lockpick',    price = 35 },
        { name = 'screwdriver', price = 20 },
        { name = 'repairkit',   price = 250 },
    },
    medical = {
        { name = 'bandage',    price = 25 },
        { name = 'icepack',    price = 40 },
        { name = 'burn_cream', price = 45 },
    },
    -- from qs-weapons
    weapons = {
        { name = 'weapon_pistol',        price = 750 },
        { name = 'weapon_combatpistol',  price = 1200 },
        { name = 'weapon_appistol',      price = 2000 },
        { name = 'weapon_pistol50',      price = 2500 },
        { name = 'weapon_snspistol',     price = 1000 },
        { name = 'weapon_heavypistol',   price = 2200 },
        { name = 'weapon_microsmg',      price = 3500 },
        { name = 'weapon_smg',           price = 4000 },
        { name = 'weapon_assaultsmg',    price = 4500 },
        { name = 'weapon_combatpdw',     price = 4200 },
        { name = 'weapon_assaultrifle',  price = 7500 },
        { name = 'weapon_carbinerifle',  price = 8500 },
        { name = 'weapon_advancedrifle', price = 8000 },
        { name = 'weapon_specialcarbine',price = 9000 },
        { name = 'weapon_bullpuprifle',  price = 8000 },
        { name = 'weapon_pumpshotgun',   price = 4000 },
        { name = 'weapon_sawnoffshotgun',price = 3500 },
        { name = 'weapon_assaultshotgun',price = 6000 },
        { name = 'weapon_heavyshotgun',  price = 6500 },
        { name = 'weapon_sniperrifle',   price = 12000 },
        { name = 'weapon_heavysniper',   price = 20000 },
        { name = 'weapon_marksmanrifle', price = 11000 },
        { name = 'weapon_mg',            price = 15000 },
        { name = 'weapon_combatmg',      price = 18000 },
        -- ammo
        { name = 'ammo_pistol',  price = 40 },
        { name = 'ammo_smg',     price = 60 },
        { name = 'ammo_rifle',   price = 80 },
        { name = 'ammo_shotgun', price = 50 },
        { name = 'ammo_sniper',  price = 120 },
        { name = 'ammo_mg',      price = 150 },
        { name = 'bandage',      price = 25 },
    },
}

Config.Shops = {
    {
        name = 'supermarket',
        label = '24/7 Supermarket',
        ped = 'mp_m_shopkeep_01',
        scenario = 'WORLD_HUMAN_STAND_MOBILE',
        blip = { sprite = 52, color = 2, scale = 0.6 },
        items = Config.Products.normal,
        locations = {
            vec4(24.47, -1346.62, 29.5, 271.66),
            vec4(-3039.54, 584.38, 7.91, 17.27),
            vec4(-3242.97, 1000.01, 12.83, 357.57),
            vec4(1728.07, 6415.63, 35.04, 242.95),
            vec4(1959.82, 3740.48, 32.34, 301.57),
            vec4(549.13, 2670.85, 42.16, 99.39),
            vec4(2677.47, 3279.76, 55.24, 335.08),
            vec4(2556.66, 380.84, 108.62, 356.67),
            vec4(372.66, 326.98, 103.57, 253.73),
        },
    },
    {
        name = 'ltd',
        label = 'LTD Gasoline',
        ped = 'mp_m_shopkeep_01',
        scenario = 'WORLD_HUMAN_STAND_MOBILE',
        blip = { sprite = 52, color = 46, scale = 0.6 },
        items = Config.Products.normal,
        locations = {
            vec4(-47.02, -1758.23, 29.42, 45.05),
            vec4(-706.06, -913.97, 19.22, 88.04),
            vec4(-1820.02, 794.03, 138.09, 135.45),
            vec4(1164.71, -322.94, 69.21, 101.72),
            vec4(1697.87, 4922.96, 42.06, 324.71),
        },
    },
    {
        name = 'liquor',
        label = "Rob's Liquor",
        ped = 'mp_m_shopkeep_01',
        scenario = 'WORLD_HUMAN_STAND_MOBILE',
        blip = { sprite = 52, color = 7, scale = 0.6 },
        items = Config.Products.liquor,
        locations = {
            vec4(-1221.58, -908.15, 12.33, 35.49),
            vec4(-1486.59, -377.68, 40.16, 139.51),
            vec4(-2966.39, 391.42, 15.04, 87.48),
            vec4(1165.17, 2710.88, 38.16, 179.43),
            vec4(1134.2, -982.91, 46.42, 277.24),
        },
    },
    {
        name = 'hardware',
        label = 'Hardware Store',
        ped = 'mp_m_waremech_01',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        blip = { sprite = 402, color = 5, scale = 0.8 },
        items = Config.Products.hardware,
        locations = {
            vec4(45.68, -1749.04, 29.61, 53.13),
            vec4(2747.71, 3472.85, 55.67, 255.08),
            vec4(-421.83, 6136.13, 31.88, 228.2),
        },
    },
    {
        name = 'ambulance_supplies',
        label = 'Medical Supplies',
        ped = 's_m_m_paramedic_01',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        blip = { sprite = 51, color = 1, scale = 0.7 },
        job = 'ambulance', -- medic only
        items = Config.Products.medical,
        locations = {
            vec4(316.76, -589.04, 43.29, 178.47),
        },
    },
    {
        name = 'ammunation',
        label = 'Ammunation',
        ped = 's_m_y_ammucity_01',
        scenario = 'WORLD_HUMAN_COP_IDLES',
        blip = { sprite = 110, color = 1, scale = 0.6 },
        -- job = 'police', -- job gate
        items = Config.Products.weapons,
        locations = {
            vec4(-661.96, -933.53, 21.83, 177.05),
            vec4(809.68, -2159.13, 29.62, 1.43),
            vec4(1692.67, 3761.38, 34.71, 227.65),
            vec4(-331.23, 6085.37, 31.45, 228.02),
            vec4(253.63, -51.02, 69.94, 72.91),
            vec4(23.0, -1105.67, 29.8, 162.91),
            vec4(2567.48, 292.59, 108.73, 349.68),
            vec4(-1118.59, 2700.05, 18.55, 221.89),
            vec4(841.92, -1035.32, 28.19, 1.56),
            vec4(-1304.19, -395.12, 36.7, 75.03),
            vec4(-3173.31, 1088.85, 20.84, 244.18),
        },
    },
}
