Config = {}

-- E key + reach (m)
Config.Control = 38
Config.InteractDistance = 2.2
Config.TreatDistance = 4.5 -- treat reach (m)

-- hospital self-heal
Config.Hospital = {
    ped = 's_m_m_doctor_01',
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    coords = vec4(308.2, -595.4, 43.28, 10.0),
    price = 250,
    time = 5000,
    blip = { sprite = 61, color = 2, scale = 0.75, label = 'Hospital' },
}

-- injury regions -> bones
Config.BodyRegions = {
    head      = { marker = 31086, bones = { 31086, 12844, 35731, 65068, 39317 } },
    body      = { marker = 24818, bones = { 0, 24816, 24817, 24818, 23553, 24819, 11816, 57597, 23639, 6442 } },
    left_arm  = { marker = 61163, bones = { 64729, 45509, 61163, 18905, 4089, 4090, 4137, 4138, 4153, 4154 } },
    right_arm = { marker = 28252, bones = { 10706, 28252, 40269, 28422, 57005, 64016, 58866, 64017, 58867 } },
    left_leg  = { marker = 63931, bones = { 63931, 2108, 65478, 14201, 58271 } },
    right_leg = { marker = 36864, bones = { 36864, 51826, 20781, 35502, 52301 } },
}
Config.Regions = { 'head', 'body', 'left_arm', 'right_arm', 'left_leg', 'right_leg' }

-- injury -> treatment item
Config.TreatmentItems = {
    bleeding = 'bandage',
    bruising = 'icepack',
    burning  = 'burn_cream',
}
Config.TreatmentTime = 6000 -- ms

-- damage type by weapon
Config.DamageCategories = {
    bruising = {
        'WEAPON_UNARMED', 'WEAPON_FALL', 'WEAPON_BAT', 'WEAPON_CROWBAR', 'WEAPON_GOLFCLUB',
        'WEAPON_HAMMER', 'WEAPON_KNUCKLE', 'WEAPON_NIGHTSTICK', 'WEAPON_WRENCH', 'WEAPON_POOLCUE',
        'WEAPON_FLASHLIGHT', 'WEAPON_RAMMED_BY_CAR', 'WEAPON_RUN_OVER_BY_CAR',
    },
    burning = {
        'WEAPON_MOLOTOV', 'WEAPON_FIRE', 'WEAPON_FLARE', 'WEAPON_PETROLCAN',
        'WEAPON_FLAREGUN', 'WEAPON_EXPLOSION',
    },
}

-- injury effects
Config.Effects = {
    interval = 5000,    -- ms
    bleedDamage = true, -- drains hp
    legLimp = true,     -- limp
    burnBlur = true,    -- screen blur
}

-- self-use bandage
Config.BandageHeal = 25   -- health restored
Config.BandageTime = 3500 -- ms

Config.AlertDuration = 60000 -- ms

-- medic supplies
Config.Supplies = {
    coords = vec4(306.9, -601.3, 43.28, 70.0),
    items = {
        { name = 'bandage',    count = 3 },
        { name = 'icepack',    count = 2 },
        { name = 'burn_cream', count = 2 },
    },
    cooldown = 60000, -- ms
}

-- EMS garage
Config.Garage = {
    coords = vec4(295.51, -606.76, 43.33, 89.63), -- interaction point
    spawn  = vec4(281.83, -604.14, 43.13, 91.99), -- spawn point
    model  = 'ambulance',
    blip   = { sprite = 357, color = 2, scale = 0.7, label = 'EMS Garage' },
}

Config.ReviveReward = 250 -- revive reward (0 = off)

-- stretcher
Config.Stretcher = {
    model = `v_med_bed1`,

    carryAnim   = { dict = 'anim@heists@box_carry@', clip = 'idle' },
    carryOffset = vec3(-0.032, 1.8, -0.23), -- carry offset

    patientAnim   = { dict = 'anim@gangops@morgue@table@', clip = 'body_search' },
    patientOffset = vec3(0.0, 0.0, 1.3), -- patient offset

    disabledControls = { 75, 22, 23, 24, 25, 140, 141, 142 }, -- disabled controls

    keys = { action = 38, patient = 47, store = 74 }, -- E move/drop, G load/unload, H store

    -- stretcher attach per model
    vehicleOffsets = {
        [`ambulance`] = { coords = vec3(0.15, -3.0, 0.97), rotation = vec3(-1.3, 0.0, 90.0) },
    },
}
