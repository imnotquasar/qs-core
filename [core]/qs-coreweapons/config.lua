WeaponsConfig = {}

-- rounds per magazine
WeaponsConfig.MagSize = {
    pistol   = 12,
    smg      = 30,
    rifle    = 30,
    shotgun  = 8,
    sniper   = 10,
    mg       = 100,
    launcher = 1,
    flare    = 1,
    taser    = 1,
}

WeaponsConfig.ThrowableStack = 10

-- weapon items
WeaponsConfig.Weapons = {
    -- melee
    weapon_dagger        = { weapon = 'WEAPON_DAGGER',        cat = 'melee', label = 'Antique Cavalry Dagger', weight = 600 },
    weapon_bat           = { weapon = 'WEAPON_BAT',           cat = 'melee', label = 'Baseball Bat',      weight = 1000 },
    weapon_bottle        = { weapon = 'WEAPON_BOTTLE',        cat = 'melee', label = 'Broken Bottle',     weight = 300 },
    weapon_crowbar       = { weapon = 'WEAPON_CROWBAR',       cat = 'melee', label = 'Crowbar',           weight = 1500 },
    weapon_flashlight    = { weapon = 'WEAPON_FLASHLIGHT',    cat = 'melee', label = 'Flashlight',        weight = 500 },
    weapon_golfclub      = { weapon = 'WEAPON_GOLFCLUB',      cat = 'melee', label = 'Golf Club',         weight = 1000 },
    weapon_hammer        = { weapon = 'WEAPON_HAMMER',        cat = 'melee', label = 'Hammer',            weight = 800 },
    weapon_hatchet       = { weapon = 'WEAPON_HATCHET',       cat = 'melee', label = 'Hatchet',           weight = 1200 },
    weapon_knuckle       = { weapon = 'WEAPON_KNUCKLE',       cat = 'melee', label = 'Brass Knuckles',    weight = 300 },
    weapon_knife         = { weapon = 'WEAPON_KNIFE',         cat = 'melee', label = 'Knife',             weight = 300 },
    weapon_machete       = { weapon = 'WEAPON_MACHETE',       cat = 'melee', label = 'Machete',           weight = 1000 },
    weapon_switchblade   = { weapon = 'WEAPON_SWITCHBLADE',   cat = 'melee', label = 'Switchblade',       weight = 200 },
    weapon_nightstick    = { weapon = 'WEAPON_NIGHTSTICK',    cat = 'melee', label = 'Nightstick',        weight = 700 },
    weapon_wrench        = { weapon = 'WEAPON_WRENCH',        cat = 'melee', label = 'Pipe Wrench',       weight = 1500 },
    weapon_battleaxe     = { weapon = 'WEAPON_BATTLEAXE',     cat = 'melee', label = 'Battle Axe',        weight = 2000 },
    weapon_poolcue       = { weapon = 'WEAPON_POOLCUE',       cat = 'melee', label = 'Pool Cue',          weight = 600 },
    weapon_stone_hatchet = { weapon = 'WEAPON_STONE_HATCHET', cat = 'melee', label = 'Stone Hatchet',     weight = 1200 },
    weapon_candycane     = { weapon = 'WEAPON_CANDYCANE',     cat = 'melee', label = 'Candy Cane',        weight = 400 },

    -- pistols
    weapon_pistol        = { weapon = 'WEAPON_PISTOL',        cat = 'pistol', label = 'Pistol',           weight = 1000 },
    weapon_pistol_mk2    = { weapon = 'WEAPON_PISTOL_MK2',    cat = 'pistol', label = 'Pistol Mk II',     weight = 1000 },
    weapon_combatpistol  = { weapon = 'WEAPON_COMBATPISTOL',  cat = 'pistol', label = 'Combat Pistol',    weight = 1000 },
    weapon_appistol      = { weapon = 'WEAPON_APPISTOL',      cat = 'pistol', label = 'AP Pistol',        weight = 1100 },
    weapon_pistol50      = { weapon = 'WEAPON_PISTOL50',      cat = 'pistol', label = 'Pistol .50',       weight = 1300 },
    weapon_snspistol     = { weapon = 'WEAPON_SNSPISTOL',     cat = 'pistol', label = 'SNS Pistol',       weight = 800 },
    weapon_snspistol_mk2 = { weapon = 'WEAPON_SNSPISTOL_MK2', cat = 'pistol', label = 'SNS Pistol Mk II', weight = 800 },
    weapon_heavypistol   = { weapon = 'WEAPON_HEAVYPISTOL',   cat = 'pistol', label = 'Heavy Pistol',     weight = 1200 },
    weapon_vintagepistol = { weapon = 'WEAPON_VINTAGEPISTOL', cat = 'pistol', label = 'Vintage Pistol',   weight = 900 },
    weapon_marksmanpistol= { weapon = 'WEAPON_MARKSMANPISTOL',cat = 'pistol', label = 'Marksman Pistol',  weight = 1500 },
    weapon_revolver      = { weapon = 'WEAPON_REVOLVER',      cat = 'pistol', label = 'Heavy Revolver',   weight = 1500 },
    weapon_revolver_mk2  = { weapon = 'WEAPON_REVOLVER_MK2',  cat = 'pistol', label = 'Heavy Revolver Mk II', weight = 1500 },
    weapon_doubleaction  = { weapon = 'WEAPON_DOUBLEACTION',  cat = 'pistol', label = 'Double-Action Revolver', weight = 1200 },
    weapon_ceramicpistol = { weapon = 'WEAPON_CERAMICPISTOL', cat = 'pistol', label = 'Ceramic Pistol',   weight = 800 },
    weapon_navyrevolver  = { weapon = 'WEAPON_NAVYREVOLVER',  cat = 'pistol', label = 'Navy Revolver',    weight = 1400 },
    weapon_gadgetpistol  = { weapon = 'WEAPON_GADGETPISTOL',  cat = 'pistol', label = 'Perico Pistol',    weight = 1000 },
    weapon_pistolxm3     = { weapon = 'WEAPON_PISTOLXM3',     cat = 'pistol', label = 'WM 29 Pistol',     weight = 1100 },
    weapon_flaregun      = { weapon = 'WEAPON_FLAREGUN',      cat = 'flare',  label = 'Flare Gun',        weight = 800 },
    weapon_stungun       = { weapon = 'WEAPON_STUNGUN',       cat = 'taser',  label = 'Taser',            weight = 600 },

    -- smgs
    weapon_microsmg      = { weapon = 'WEAPON_MICROSMG',      cat = 'smg',    label = 'Micro SMG',        weight = 1800 },
    weapon_smg           = { weapon = 'WEAPON_SMG',           cat = 'smg',    label = 'SMG',              weight = 2200 },
    weapon_smg_mk2       = { weapon = 'WEAPON_SMG_MK2',       cat = 'smg',    label = 'SMG Mk II',        weight = 2200 },
    weapon_assaultsmg    = { weapon = 'WEAPON_ASSAULTSMG',    cat = 'smg',    label = 'Assault SMG',      weight = 2400 },
    weapon_combatpdw     = { weapon = 'WEAPON_COMBATPDW',     cat = 'smg',    label = 'Combat PDW',       weight = 2600 },
    weapon_machinepistol = { weapon = 'WEAPON_MACHINEPISTOL', cat = 'smg',    label = 'Machine Pistol',   weight = 1500 },
    weapon_minismg       = { weapon = 'WEAPON_MINISMG',       cat = 'smg',    label = 'Mini SMG',         weight = 1600 },
    weapon_tecpistol     = { weapon = 'WEAPON_TECPISTOL',     cat = 'smg',    label = 'Tactical SMG',     weight = 1600 },

    -- shotguns
    weapon_pumpshotgun     = { weapon = 'WEAPON_PUMPSHOTGUN',     cat = 'shotgun', label = 'Pump Shotgun',    weight = 3000 },
    weapon_pumpshotgun_mk2 = { weapon = 'WEAPON_PUMPSHOTGUN_MK2', cat = 'shotgun', label = 'Pump Shotgun Mk II', weight = 3000 },
    weapon_sawnoffshotgun  = { weapon = 'WEAPON_SAWNOFFSHOTGUN',  cat = 'shotgun', label = 'Sawn-off Shotgun', weight = 2600 },
    weapon_assaultshotgun  = { weapon = 'WEAPON_ASSAULTSHOTGUN',  cat = 'shotgun', label = 'Assault Shotgun', weight = 3600 },
    weapon_bullpupshotgun  = { weapon = 'WEAPON_BULLPUPSHOTGUN',  cat = 'shotgun', label = 'Bullpup Shotgun', weight = 3200 },
    weapon_musket          = { weapon = 'WEAPON_MUSKET',          cat = 'shotgun', label = 'Musket',          weight = 3500 },
    weapon_heavyshotgun    = { weapon = 'WEAPON_HEAVYSHOTGUN',    cat = 'shotgun', label = 'Heavy Shotgun',   weight = 3800 },
    weapon_dbshotgun       = { weapon = 'WEAPON_DBSHOTGUN',       cat = 'shotgun', label = 'Double Barrel Shotgun', weight = 2800 },
    weapon_autoshotgun     = { weapon = 'WEAPON_AUTOSHOTGUN',     cat = 'shotgun', label = 'Sweeper Shotgun', weight = 3000 },
    weapon_combatshotgun   = { weapon = 'WEAPON_COMBATSHOTGUN',   cat = 'shotgun', label = 'Combat Shotgun',  weight = 3400 },

    -- rifles
    weapon_assaultrifle      = { weapon = 'WEAPON_ASSAULTRIFLE',      cat = 'rifle', label = 'Assault Rifle',      weight = 3200 },
    weapon_assaultrifle_mk2  = { weapon = 'WEAPON_ASSAULTRIFLE_MK2',  cat = 'rifle', label = 'Assault Rifle Mk II', weight = 3200 },
    weapon_carbinerifle      = { weapon = 'WEAPON_CARBINERIFLE',      cat = 'rifle', label = 'Carbine Rifle',      weight = 3400 },
    weapon_carbinerifle_mk2  = { weapon = 'WEAPON_CARBINERIFLE_MK2',  cat = 'rifle', label = 'Carbine Rifle Mk II', weight = 3400 },
    weapon_advancedrifle     = { weapon = 'WEAPON_ADVANCEDRIFLE',     cat = 'rifle', label = 'Advanced Rifle',     weight = 3300 },
    weapon_specialcarbine    = { weapon = 'WEAPON_SPECIALCARBINE',    cat = 'rifle', label = 'Special Carbine',    weight = 3500 },
    weapon_specialcarbine_mk2= { weapon = 'WEAPON_SPECIALCARBINE_MK2',cat = 'rifle', label = 'Special Carbine Mk II', weight = 3500 },
    weapon_bullpuprifle      = { weapon = 'WEAPON_BULLPUPRIFLE',      cat = 'rifle', label = 'Bullpup Rifle',      weight = 3300 },
    weapon_bullpuprifle_mk2  = { weapon = 'WEAPON_BULLPUPRIFLE_MK2',  cat = 'rifle', label = 'Bullpup Rifle Mk II', weight = 3300 },
    weapon_compactrifle      = { weapon = 'WEAPON_COMPACTRIFLE',      cat = 'rifle', label = 'Compact Rifle',      weight = 2800 },
    weapon_militaryrifle     = { weapon = 'WEAPON_MILITARYRIFLE',     cat = 'rifle', label = 'Military Rifle',     weight = 3600 },
    weapon_heavyrifle        = { weapon = 'WEAPON_HEAVYRIFLE',        cat = 'rifle', label = 'Heavy Rifle',        weight = 3800 },
    weapon_tacticalrifle     = { weapon = 'WEAPON_TACTICALRIFLE',     cat = 'rifle', label = 'Service Carbine',    weight = 3300 },
    weapon_battlerifle       = { weapon = 'WEAPON_BATTLERIFLE',       cat = 'rifle', label = 'Battle Rifle',       weight = 3900 },

    -- machine guns
    weapon_mg            = { weapon = 'WEAPON_MG',            cat = 'mg', label = 'MG',                weight = 5000 },
    weapon_combatmg      = { weapon = 'WEAPON_COMBATMG',      cat = 'mg', label = 'Combat MG',         weight = 5400 },
    weapon_combatmg_mk2  = { weapon = 'WEAPON_COMBATMG_MK2',  cat = 'mg', label = 'Combat MG Mk II',   weight = 5400 },
    weapon_gusenberg     = { weapon = 'WEAPON_GUSENBERG',     cat = 'mg', label = 'Gusenberg Sweeper', weight = 4500 },
    weapon_raycarbine    = { weapon = 'WEAPON_RAYCARBINE',    cat = 'mg', label = 'Unholy Hellbringer', weight = 5000 },

    -- snipers
    weapon_sniperrifle       = { weapon = 'WEAPON_SNIPERRIFLE',       cat = 'sniper', label = 'Sniper Rifle',        weight = 4000 },
    weapon_heavysniper       = { weapon = 'WEAPON_HEAVYSNIPER',       cat = 'sniper', label = 'Heavy Sniper',        weight = 5000 },
    weapon_heavysniper_mk2   = { weapon = 'WEAPON_HEAVYSNIPER_MK2',   cat = 'sniper', label = 'Heavy Sniper Mk II',  weight = 5000 },
    weapon_marksmanrifle     = { weapon = 'WEAPON_MARKSMANRIFLE',     cat = 'sniper', label = 'Marksman Rifle',      weight = 3800 },
    weapon_marksmanrifle_mk2 = { weapon = 'WEAPON_MARKSMANRIFLE_MK2', cat = 'sniper', label = 'Marksman Rifle Mk II', weight = 3800 },
    weapon_precisionrifle    = { weapon = 'WEAPON_PRECISIONRIFLE',    cat = 'sniper', label = 'Precision Rifle',     weight = 4200 },

    -- heavy
    weapon_rpg               = { weapon = 'WEAPON_RPG',               cat = 'launcher', label = 'RPG',                    weight = 8000 },
    weapon_grenadelauncher   = { weapon = 'WEAPON_GRENADELAUNCHER',   cat = 'launcher', label = 'Grenade Launcher',       weight = 6000 },
    weapon_grenadelauncher_smoke = { weapon = 'WEAPON_GRENADELAUNCHER_SMOKE', cat = 'launcher', label = 'Smoke Grenade Launcher', weight = 6000 },
    weapon_compactlauncher   = { weapon = 'WEAPON_COMPACTLAUNCHER',   cat = 'launcher', label = 'Compact Grenade Launcher', weight = 3500 },
    weapon_hominglauncher    = { weapon = 'WEAPON_HOMINGLAUNCHER',    cat = 'launcher', label = 'Homing Launcher',        weight = 9000 },
    weapon_firework          = { weapon = 'WEAPON_FIREWORK',          cat = 'launcher', label = 'Firework Launcher',      weight = 5000 },
    weapon_railgun           = { weapon = 'WEAPON_RAILGUN',           cat = 'launcher', label = 'Railgun',                weight = 9000 },
    weapon_emplauncher       = { weapon = 'WEAPON_EMPLAUNCHER',       cat = 'launcher', label = 'Compact EMP Launcher',   weight = 3500 },
    weapon_minigun           = { weapon = 'WEAPON_MINIGUN',           cat = 'mg',       label = 'Minigun',                weight = 12000 },
    weapon_rayminigun        = { weapon = 'WEAPON_RAYMINIGUN',        cat = 'mg',       label = 'Widowmaker',             weight = 12000 },

    -- throwables
    weapon_grenade       = { weapon = 'WEAPON_GRENADE',       cat = 'throwable', label = 'Grenade',         weight = 400 },
    weapon_bzgas         = { weapon = 'WEAPON_BZGAS',         cat = 'throwable', label = 'BZ Gas',          weight = 400 },
    weapon_smokegrenade  = { weapon = 'WEAPON_SMOKEGRENADE',  cat = 'throwable', label = 'Tear Gas',        weight = 400 },
    weapon_molotov       = { weapon = 'WEAPON_MOLOTOV',       cat = 'throwable', label = 'Molotov Cocktail', weight = 600 },
    weapon_stickybomb    = { weapon = 'WEAPON_STICKYBOMB',    cat = 'throwable', label = 'Sticky Bomb',     weight = 500 },
    weapon_proxmine      = { weapon = 'WEAPON_PROXMINE',      cat = 'throwable', label = 'Proximity Mine',  weight = 600 },
    weapon_pipebomb      = { weapon = 'WEAPON_PIPEBOMB',      cat = 'throwable', label = 'Pipe Bomb',       weight = 500 },
    weapon_flare         = { weapon = 'WEAPON_FLARE',         cat = 'throwable', label = 'Flare',           weight = 200 },
    weapon_snowball      = { weapon = 'WEAPON_SNOWBALL',      cat = 'throwable', label = 'Snowball',        weight = 100 },
    weapon_ball          = { weapon = 'WEAPON_BALL',          cat = 'throwable', label = 'Ball',            weight = 100 },

    -- misc
    weapon_petrolcan        = { weapon = 'WEAPON_PETROLCAN',        cat = 'misc', ammo = 4500, label = 'Jerry Can',          weight = 4000 },
    weapon_hazardcan        = { weapon = 'WEAPON_HAZARDCAN',        cat = 'misc', ammo = 4500, label = 'Hazardous Jerry Can', weight = 4000 },
    weapon_fertilizercan    = { weapon = 'WEAPON_FERTILIZERCAN',    cat = 'misc', ammo = 4500, label = 'Fertilizer Can',     weight = 4000 },
    weapon_fireextinguisher = { weapon = 'WEAPON_FIREEXTINGUISHER', cat = 'misc', ammo = 2000, label = 'Fire Extinguisher',  weight = 4500 },
    weapon_raypistol        = { weapon = 'WEAPON_RAYPISTOL',        cat = 'misc', ammo = 1,    label = 'Up-n-Atomizer',      weight = 1200 },
}

-- ammo items
WeaponsConfig.Ammo = {
    ammo_pistol   = { cat = 'pistol',   label = 'Pistol Ammo',      weight = 200 },
    ammo_smg      = { cat = 'smg',      label = 'SMG Ammo',         weight = 300 },
    ammo_rifle    = { cat = 'rifle',    label = 'Rifle Ammo',       weight = 400 },
    ammo_shotgun  = { cat = 'shotgun',  label = 'Shotgun Shells',   weight = 300 },
    ammo_sniper   = { cat = 'sniper',   label = 'Sniper Ammo',      weight = 500 },
    ammo_mg       = { cat = 'mg',       label = 'MG Ammo',          weight = 700 },
    ammo_launcher = { cat = 'launcher', label = 'Launcher Round',   weight = 1500 },
    ammo_flare    = { cat = 'flare',    label = 'Flare Shell',      weight = 100 },
    ammo_taser    = { cat = 'taser',    label = 'Taser Cartridge',  weight = 50 },
}
