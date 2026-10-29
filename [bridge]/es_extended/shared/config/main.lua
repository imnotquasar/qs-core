Config = {}

Config.CustomInventory = GetResourceState('qs-inventory') ~= 'missing' and 'qs' or false

Config.Accounts = {
    bank = {
        label = 'Bank',
        round = true,
    },
    black_money = {
        label = 'Black Money',
        round = true,
    },
    money = {
        label = 'Cash',
        round = true,
    },
}

Config.StartingAccountMoney = { bank = 50000 }

Config.StartingInventoryItems = false

Config.MaxWeight = 24

Config.EnablePaycheck = false
Config.EnableDebug = false
Config.DefaultJobDuty = true
Config.DistanceGive = 4.0
Config.Identifier = GetConvar('esx:identifier', 'license')

Config.EnableDefaultInventory = Config.CustomInventory == false

-- Required by multicharacter identity flow when using the ESX bridge with qs-core
Config.Identity = true
