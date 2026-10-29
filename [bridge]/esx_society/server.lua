local ESX = exports['es_extended']:getSharedObject()

local societies = {}
local money = {}

CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `society_accounts` (
            `name`   VARCHAR(64) NOT NULL,
            `money`  INT NOT NULL DEFAULT 0,
            PRIMARY KEY (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    Wait(500)
    local rows = MySQL.query.await('SELECT name, money FROM society_accounts') or {}
    for _, r in ipairs(rows) do money[r.name] = tonumber(r.money) or 0 end
end)

local function saveAccount(account)
    MySQL.query(
        'INSERT INTO society_accounts (name, money) VALUES (?, ?) ON DUPLICATE KEY UPDATE money = VALUES(money)',
        { account, money[account] or 0 }
    )
end

local function getMoney(account) return money[account] or 0 end

local function addMoney(account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end
    money[account] = getMoney(account) + amount
    saveAccount(account)
end

local function removeMoney(account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end
    money[account] = math.max(0, getMoney(account) - amount)
    saveAccount(account)
end

RegisterNetEvent('esx_society:registerSociety', function(name, label, account, datastore, jobs, data)
    societies[name] = {
        name = name,
        label = label or name,
        account = account or name,
        datastore = datastore or name,
        jobs = jobs,
        data = data or {},
    }
end)

local function getSociety(name)
    return societies[name] or { name = name, label = name, account = name, datastore = name }
end

ESX.RegisterServerCallback('esx_society:getSociety', function(source, cb, name)
    cb(getSociety(name))
end)

ESX.RegisterServerCallback('esx_society:getSocieties', function(source, cb)
    local list = {}
    for _, s in pairs(societies) do list[#list + 1] = s end
    cb(list)
end)

ESX.RegisterServerCallback('esx_society:getSocietyMoney', function(source, cb, society)
    cb(getMoney(society))
end)

RegisterNetEvent('esx_society:addMoney', function(society, amount) addMoney(society, amount) end)
RegisterNetEvent('esx_society:removeMoney', function(society, amount) removeMoney(society, amount) end)

exports('getSociety', getSociety)
exports('getSocietyMoney', getMoney)
exports('addMoney', addMoney)
exports('removeMoney', removeMoney)
