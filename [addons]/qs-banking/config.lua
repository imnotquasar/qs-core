Config = {}

-- E key + reach
Config.OpenKey = 38
Config.InteractDistance = 1.6

-- transfer fee (0.02 = 2%)
Config.TransferFee = 0.0

-- history rows
Config.HistoryLimit = 25

-- ATM props
Config.ATMModels = {
    `prop_atm_01`, `prop_atm_02`, `prop_atm_03`, `prop_fleeca_atm`,
}

-- bank branches
Config.Banks = {
    { coords = vec4(149.5513, -1042.1570, 29.3680, 341.6520),  ped = 'U_M_M_BankMan', scenario = 'WORLD_HUMAN_CLIPBOARD' },
    { coords = vec4(-1211.8585, -331.9854, 37.7809, 28.5983),  ped = 'U_M_M_BankMan', scenario = 'WORLD_HUMAN_CLIPBOARD' },
    { coords = vec4(-2961.0720, 483.1107, 15.6970, 88.1986),   ped = 'U_M_M_BankMan', scenario = 'WORLD_HUMAN_CLIPBOARD' },
    { coords = vec4(-112.2223, 6471.1128, 31.6267, 132.7517),  ped = 'U_M_M_BankMan', scenario = 'WORLD_HUMAN_CLIPBOARD' },
    { coords = vec4(313.8176, -280.5338, 54.1647, 339.1609),   ped = 'U_M_M_BankMan', scenario = 'WORLD_HUMAN_CLIPBOARD' }, -- Pacific Standard
    { coords = vec4(-351.3247, -51.3466, 49.0365, 339.3305),   ped = 'U_M_M_BankMan', scenario = 'WORLD_HUMAN_CLIPBOARD' },
    { coords = vec4(1174.9718, 2708.2034, 38.0879, 178.2974),  ped = 'U_M_M_BankMan', scenario = 'WORLD_HUMAN_CLIPBOARD' },
    { coords = vec4(247.0348, 225.1851, 106.2875, 158.7528),   ped = 'U_M_M_BankMan', scenario = 'WORLD_HUMAN_CLIPBOARD' },
}

Config.Blip = { sprite = 108, color = 2, scale = 0.6, label = 'Bank' }
