Config = {}

-- E key + reach
Config.Control = 38
Config.InteractDistance = 2.0

-- sale account
Config.SellAccount = 'black_money'

-- dealer buy limit per visit
Config.SellLimitPerVisit = 25

-- props per gather zone + spread
Config.HarvestPerZone = 8
Config.HarvestSpread = 3.5

-- drugs
Config.Drugs = {
    -- marijuana
    weed = {
        label = 'Marijuana',
        gather = {
            item = 'weed_leaf', min = 1, max = 3, time = 6000, weight = 80, label = 'Weed Leaf',
            prop = 'prop_weed_01', -- harvestable prop
            anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' },
            blip = { sprite = 496, color = 25, scale = 0.67, label = 'Weed Field' }, -- false to hide
            locations = {
                vec3(2215.28, 5601.64, 54.16),
                vec3(2213.56, 5592.15, 53.84),
                vec3(2214.78, 5570.91, 53.83),
            },
        },
        process = {
            input = 'weed_leaf', inputAmount = 3, output = 'weed_baggie', outputAmount = 1,
            time = 8000, weight = 120, label = 'Bag of Weed',
            prop = 'prop_table_03', -- lab table
            anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_02_inspector' },
            stages = {
                { label = 'stage_trim',  time = 4500, anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_02_inspector' },
                  prop = { model = 'bkr_prop_weed_bud_01a', bone = 18905, pos = vec3(0.04, 0.02, -0.02), rot = vec3(10.0, 0.0, 0.0) } },
                { label = 'stage_weigh', time = 4000, anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_02_inspector' },
                  prop = { model = 'bkr_prop_weed_bag_01a', bone = 18905, pos = vec3(0.03, 0.0, -0.02), rot = vec3(0.0, 90.0, 0.0) } },
                { label = 'stage_pack',  time = 4000, anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_02_inspector' },
                  prop = { model = 'bkr_prop_weed_bag_01a', bone = 57005, pos = vec3(0.12, 0.02, 0.0), rot = vec3(0.0, 90.0, 0.0) } },
            },
            blip = { sprite = 499, color = 25, scale = 0.6, label = 'Weed Lab' }, -- false to hide
            locations = {
                vec4(2431.66, 4963.72, 41.85, 128.81),
            },
        },
        sell = { item = 'weed_baggie', min = 55, max = 85 },
    },

    -- cocaine
    cocaine = {
        label = 'Cocaine',
        gather = {
            item = 'coca_leaf', min = 1, max = 2, time = 6500, weight = 60, label = 'Coca Leaf',
            prop = 'prop_plant_cane_02b', -- harvestable prop
            anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' },
            blip = { sprite = 51, color = 2, scale = 0.6, label = 'Coca Field' }, -- false to hide
            locations = {
                vec3(-1580.56, 2090.45, 70.13),
                vec3(-1587.06, 2096.18, 69.07),
                vec3(-1569.37, 2095.65, 69.93),
            },
        },
        process = {
            input = 'coca_leaf', inputAmount = 4, output = 'cocaine_baggie', outputAmount = 1,
            time = 9000, weight = 100, label = 'Bag of Cocaine',
            prop = 'prop_table_03', -- lab table
            anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_02_inspector' },
            stages = {
                { label = 'stage_cut',   time = 5000, anim = { dict = 'amb@world_human_hammering@male@base', clip = 'base' },
                  prop = { model = 'p_ld_coke_block', bone = 57005, pos = vec3(0.13, 0.02, 0.0), rot = vec3(0.0, 0.0, 0.0) } },
                { label = 'stage_weigh', time = 4500, anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_02_inspector' },
                  prop = { model = 'bkr_prop_coke_baggy_01', bone = 18905, pos = vec3(0.03, 0.0, -0.02), rot = vec3(0.0, 90.0, 0.0) } },
                { label = 'stage_pack',  time = 4000, anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_02_inspector' },
                  prop = { model = 'bkr_prop_coke_baggy_01', bone = 57005, pos = vec3(0.12, 0.02, 0.0), rot = vec3(0.0, 90.0, 0.0) } },
            },
            blip = { sprite = 499, color = 2, scale = 0.6, label = 'Cocaine Lab' }, -- false to hide
            locations = {
                vec4(1394.46, 3609.29, 34.38, 289.78),
            },
        },
        sell = { item = 'cocaine_baggie', min = 120, max = 180 },
    },

    -- methamphetamine
    meth = {
        label = 'Metha',
        gather = {
            item = 'meth_chem', min = 1, max = 2, time = 7000, weight = 90, label = 'Chemicals',
            prop = 'prop_barrel_exp_01a', -- harvestable prop
            anim = { dict = 'amb@prop_human_bum_bin@base', clip = 'base' },
            blip = { sprite = 499, color = 5, scale = 0.6, label = 'Chemical Supply' }, -- false to hide
            locations = {
                vec3(866.88, -3043.81, 5.88),
                vec3(858.79, -3048.88, 5.74),
                vec3(857.02, -3041.38, 5.74),
            },
        },
        process = {
            input = 'meth_chem', inputAmount = 4, output = 'meth_baggie', outputAmount = 1,
            time = 10000, weight = 110, label = 'Bag of Meth',
            prop = 'prop_table_03', -- lab table
            anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_02_inspector' },
            stages = {
                { label = 'stage_cook',  time = 6000, anim = { dict = 'amb@world_human_welding@male@base', clip = 'base' },
                  prop = { model = 'bkr_prop_meth_bag_01a', bone = 57005, pos = vec3(0.12, 0.0, 0.0), rot = vec3(0.0, 90.0, 0.0) },
                  ptfx = { asset = 'core', name = 'exp_grd_bzgas_smoke', bone = 57005, offset = vec3(0.0, 0.25, 0.1), scale = 0.4 } },
                { label = 'stage_weigh', time = 4500, anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_02_inspector' },
                  prop = { model = 'bkr_prop_meth_bag_01a', bone = 18905, pos = vec3(0.03, 0.0, -0.02), rot = vec3(0.0, 90.0, 0.0) } },
                { label = 'stage_pack',  time = 4500, anim = { dict = 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', clip = 'weed_spraybottle_stand_spraying_02_inspector' },
                  prop = { model = 'bkr_prop_meth_bag_01a', bone = 57005, pos = vec3(0.12, 0.02, 0.0), rot = vec3(0.0, 90.0, 0.0) } },
            },
            blip = { sprite = 499, color = 5, scale = 0.6, label = 'Meth Lab' }, -- false to hide
            locations = {
                vec4(1392.62, 3615.39, 38.44, 16.47)
            },
        },
        sell = { item = 'meth_baggie', min = 150, max = 210 },
    },
}

-- dealers
Config.Dealer = {
    ped = 'g_m_y_mexgoon_01',
    scenario = 'WORLD_HUMAN_DRUG_DEALER',
    blip = { sprite = 51, color = 1, scale = 0.5, label = 'Dealer' }, -- false to hide
    locations = {
        vec4(114.26, -1961.07, 21.33, 21.78),
        vec4(1214.39, -1644.12, 48.65, 30.35),
    },
}
