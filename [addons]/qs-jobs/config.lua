Config = {}

-- E key + reach
Config.Control = 38
Config.InteractDistance = 2.2

-- pay account
Config.PayAccount = 'cash'

-- depletion (s)
Config.GatherCooldown = 20000

-- job center
Config.Center = {
    ped = 'a_m_m_business_01',
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    coords = vec4(-268.24, -957.29, 31.22, 205.0),
    blip = { sprite = 280, color = 3, scale = 0.75, label = 'Job Center' },
    jobs = { 'delivery', 'miner', 'lumberjack', 'fisher' },
}

-- delivery job
Config.Delivery = {
    depot = {
        ped = 's_m_m_postal_01',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        coords = vec4(60.7, 121.2, 79.1, 160.0),
        blip = { sprite = 477, color = 5, scale = 0.75, label = 'Delivery Depot' },
    },
    -- van spawns
    vanSpawns = {
        vec4(49.3, 116.7, 78.9, 250.0),
        vec4(44.5, 110.1, 78.7, 250.0),
        vec4(53.8, 123.5, 79.2, 250.0),
    },
    vanModels = { 'burrito3', 'rumpo', 'speedo' },

    stopsPerShift = 5,
    payPerStop = { min = 45, max = 65 },
    finishBonus = 150,     -- completion bonus
    deposit = 100,         -- van deposit
    deliverTime = 3500,
    anim = { dict = 'mp_common', clip = 'givetake1_a' },

    -- delivery points
    stops = {
        vec3(80.71, -1913.43, 20.99),
        vec3(148.96, -1664.41, 29.52),
        vec3(122.03, -1546.59, 29.23),
        vec3(-101.27, -1589.88, 31.44),
        vec3(-336.70, -1381.54, 31.08),
        vec3(-282.94, -1090.96, 23.97),
        vec3(-254.60, -854.52, 31.00),
    },
}

-- gather -> process -> sell jobs
Config.Jobs = {
    miner = {
        gather = {
            -- rock spots
            prop = 'prop_rock_4_e',
            perZone = 7,
            spread = 5.0,
            item = 'stone', min = 1, max = 2, time = 7000,
            bonus = { item = 'gold_nugget', chance = 0.06, count = 1 },
            anim = { dict = 'amb@world_human_hammering@male@base', clip = 'base' },
            blip = { sprite = 618, color = 21, scale = 0.7, label = 'Quarry' },
            locations = {
                vec3(2969.01, 2791.10, 40.10),
                vec3(2964.14, 2783.10, 39.50),
                vec3(2945.94, 2776.64, 39.29),
                vec3(2943.85, 2786.43, 39.96),
            },
        },
        process = {
            input = 'stone', inputAmount = 3, output = 'metal_ingot', outputAmount = 1, time = 6000,
            anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_02_inspector' },
            blip = { sprite = 436, color = 17, scale = 0.7, label = 'Foundry' },
            locations = {
                vec4(1109.1, -2007.6, 31.0, 55.0),
            },
        },
        sell = {
            ped = 's_m_y_construct_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
            coords = vec4(-349.63, -1569.86, 25.22, 296.74),
            blip = { sprite = 431, color = 5, scale = 0.7, label = 'Metal Buyer' },
            prices = {
                metal_ingot = { min = 70, max = 90 },
                gold_nugget = { min = 250, max = 350 },
            },
        },
    },

    lumberjack = {
        gather = {
            -- tree chop spots
            prop = 'prop_tree_birch_04',
            perZone = 1,
            spread = 0.0,
            item = 'wood_log', min = 1, max = 2, time = 7000,
            anim = { dict = 'melee@large_wpn@streamed_core', clip = 'ground_attack_on_spot', loop = 2500, flag = 1 },
            blip = { sprite = 285, color = 69, scale = 0.7, label = 'Forest' },
            locations = {
                vec4(-566.82, 5429.19, 61.30, 62.74),
                vec4(-580.96, 5435.26, 59.30, 77.11),
                vec4(-582.84, 5444.91, 60.41, 345.22),
                vec4(-555.85, 5456.93, 64.94, 283.49),
                vec4(-539.75, 5448.67, 68.37, 236.03),
                vec4(-531.52, 5453.36, 71.01, 296.90),
            },
        },
        process = {
            input = 'wood_log', inputAmount = 2, output = 'wood_plank', outputAmount = 1, time = 5000,
            anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_02_inspector' },
            blip = { sprite = 566, color = 21, scale = 0.7, label = 'Sawmill' },
            locations = {
                vec4(-552.19, 5327.96, 73.64, 339.70),
            },
        },
        sell = {
            ped = 's_m_m_gardener_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
            coords = vec4(126.25, -2200.65, 6.03, 2.97),
            blip = { sprite = 431, color = 69, scale = 0.7, label = 'Wood Buyer' },
            prices = {
                wood_plank = { min = 45, max = 60 },
            },
        },
    },

    fisher = {
        gather = {
            -- fishing spots
            scenario = 'WORLD_HUMAN_STAND_FISHING',
            time = 9000,
            catches = {
                { item = 'mackerel', weight = 60 },
                { item = 'bass',     weight = 30 },
                { item = 'tuna',     weight = 10 },
            },
            blip = { sprite = 68, color = 3, scale = 0.7, label = 'Fishing Spot' },
            locations = {
                vec4(-1839.80, -1259.20, 8.62, 143.66),
                vec4(-1850.74, -1250.02, 8.62, 144.16),
                vec4(-1862.48, -1240.17, 8.62, 138.80),
            },
        },
        sell = {
            ped = 'a_m_m_salton_04',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
            coords = vec4(-1845.24, -1195.88, 19.18, 152.26),
            blip = { sprite = 431, color = 3, scale = 0.7, label = 'Fish Market' },
            prices = {
                mackerel = { min = 25, max = 35 },
                bass     = { min = 50, max = 65 },
                tuna     = { min = 110, max = 150 },
            },
        },
    },
}
