Config = {}

-- E key + reach
Config.Control = 38
Config.InteractDistance = 2.2
Config.TargetDistance = 3.5 -- cuff / escort / search reach

-- Mission Row PD
Config.Station = {
    blip = { sprite = 60, color = 29, scale = 0.9, label = 'Police Station' },
    coords = vec3(428.2, -984.5, 30.7),

    armory  = vec4(452.0, -980.1, 30.7, 90.0),
    locker  = vec4(452.5, -973.2, 30.7, 90.0),   -- evidence locker
    lab     = vec4(437.13, -996.31, 30.69, 0.0),   -- forensics lab
    garage  = vec4(454.6, -1017.4, 28.4, 90.0),
    garageSpawn = vec4(438.4, -1018.3, 27.7, 90.0),
}

-- armory items
Config.Armory = {
    { name = 'weapon_pistol', count = 1 },
    { name = 'ammo_pistol',   count = 2 },
    { name = 'armor',         count = 1 },
    { name = 'handcuffs',     count = 1 },
    { name = 'evidence_bag',  count = 5 },
    { name = 'bandage',       count = 3 },
}

Config.Garage = {
    { model = 'police',  label = 'Police Cruiser' },
    { model = 'police2', label = 'Police Buffalo' },
    { model = 'police3', label = 'Police Interceptor' },
    { model = 'policeb', label = 'Police Bike' },
}

-- fines from bank
Config.Fine = { min = 1, max = 50000 }

-- evidence
Config.Evidence = {
    lifetime = 30 * 60 * 1000,  -- ms
    maxPoints = 400,
    casingCooldown = 500,       -- ms
    maxCasingDist = 150.0,      -- max dist
    alertChance = 0.25,         -- alert chance
    alertCooldown = 15000,      -- ms
    alertDuration = 60000,
    viewDistance = 25.0,        -- view range
    collectDistance = 2.0,
}

-- casing labels
Config.WeaponLabels = {
    WEAPON_PISTOL = 'Pistol', WEAPON_COMBATPISTOL = 'Combat Pistol', WEAPON_APPISTOL = 'AP Pistol',
    WEAPON_PISTOL50 = 'Pistol .50', WEAPON_SNSPISTOL = 'SNS Pistol', WEAPON_HEAVYPISTOL = 'Heavy Pistol',
    WEAPON_MICROSMG = 'Micro SMG', WEAPON_SMG = 'SMG', WEAPON_ASSAULTSMG = 'Assault SMG', WEAPON_COMBATPDW = 'Combat PDW',
    WEAPON_ASSAULTRIFLE = 'Assault Rifle', WEAPON_CARBINERIFLE = 'Carbine Rifle', WEAPON_ADVANCEDRIFLE = 'Advanced Rifle',
    WEAPON_SPECIALCARBINE = 'Special Carbine', WEAPON_BULLPUPRIFLE = 'Bullpup Rifle',
    WEAPON_PUMPSHOTGUN = 'Pump Shotgun', WEAPON_SAWNOFFSHOTGUN = 'Sawn-off Shotgun',
    WEAPON_ASSAULTSHOTGUN = 'Assault Shotgun', WEAPON_HEAVYSHOTGUN = 'Heavy Shotgun',
    WEAPON_SNIPERRIFLE = 'Sniper Rifle', WEAPON_HEAVYSNIPER = 'Heavy Sniper', WEAPON_MARKSMANRIFLE = 'Marksman Rifle',
    WEAPON_MG = 'MG', WEAPON_COMBATMG = 'Combat MG',
}
