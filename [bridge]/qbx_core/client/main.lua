QBX = QBX or {}
QBX.PlayerData = {}
QBX.Shared = require 'shared.main'
QBX.IsLoggedIn = false

local QB_FIELDS = { 'money', 'metadata', 'items', 'charinfo', 'position', 'name', 'license', 'source', 'optin' }

local function withGroups(data)
    if not data.jobs then
        data.jobs = {}
        if data.job and data.job.name and data.job.name ~= 'unemployed' then data.jobs[data.job.name] = data.job.grade and data.job.grade.level or 0 end
    end
    if not data.gangs then
        data.gangs = {}
        if data.gang and data.gang.name and data.gang.name ~= 'none' then data.gangs[data.gang.name] = data.gang.grade and data.gang.grade.level or 0 end
    end
    return data
end

RegisterNetEvent('QBCore:Player:SetPlayerData', function(value)
    if type(value) ~= 'table' or not value.citizenid then return end
    if value.jobs then
        QBX.PlayerData = value
        return
    end
    if QBX.PlayerData.citizenid == value.citizenid and QBX.PlayerData.jobs then
        for _, key in ipairs(QB_FIELDS) do
            if value[key] ~= nil then QBX.PlayerData[key] = value[key] end
        end
    else
        QBX.PlayerData = withGroups(value)
    end
    TriggerEvent('qbx_core:client:playerDataUpdated', QBX.PlayerData)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBX.IsLoggedIn = true
    NetworkSetFriendlyFireOption(GlobalState.PVPEnabled ~= false)
    SetCanAttackFriendly(cache.ped, GlobalState.PVPEnabled ~= false, false)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    QBX.IsLoggedIn = false
    QBX.PlayerData = {}
end)

RegisterNetEvent('qbx_core:client:notify', function(data)
    if type(data) ~= 'table' then return end
    exports['qs-core']:Notify(data.description or data.title or '', data.type or 'info', data.duration or 5000, data.description and data.title or nil)
end)

RegisterNetEvent('qbx_core:client:setVehicleProperties', function(netId, props)
    if not props then return end
    local deadline = GetGameTimer() + 10000
    while not NetworkDoesEntityExistWithNetworkId(netId) and GetGameTimer() < deadline do Wait(50) end
    local vehicle = NetToVeh(netId)
    if vehicle == 0 or NetworkGetEntityOwner(vehicle) ~= cache.playerId then return end
    lib.setVehicleProperties(vehicle, props)
end)

AddStateBagChangeHandler('PVPEnabled', 'global', function(_, _, value)
    NetworkSetFriendlyFireOption(value ~= false)
    SetCanAttackFriendly(cache.ped, value ~= false, false)
end)

AddStateBagChangeHandler('hunger', ('player:%s'):format(cache.serverId), function(_, _, value)
    TriggerEvent('hud:client:UpdateNeeds', value, LocalPlayer.state.thirst)
end)

AddStateBagChangeHandler('thirst', ('player:%s'):format(cache.serverId), function(_, _, value)
    TriggerEvent('hud:client:UpdateNeeds', LocalPlayer.state.hunger, value)
end)

AddStateBagChangeHandler('stress', ('player:%s'):format(cache.serverId), function(_, _, value)
    TriggerEvent('hud:client:UpdateStress', value)
end)

lib.callback.register('qbx_core:client:setHealth', function(health)
    SetEntityHealth(cache.ped, health)
end)

lib.callback.register('qbx_core:client:getVehicleClasses', function()
    local classes = {}
    for _, hash in pairs(GetAllVehicleModels()) do
        classes[joaat(hash)] = GetVehicleClassFromName(hash)
    end
    return classes
end)

lib.callback.register('qbx_core:client:getVehiclesInRadius', function(radius)
    local out = {}
    for _, vehicle in ipairs(lib.getNearbyVehicles(GetEntityCoords(cache.ped), radius or 5.0, true)) do
        out[#out + 1] = NetworkGetNetworkIdFromEntity(vehicle.vehicle)
    end
    return out
end)

local function GetPlayerData()
    return QBX.PlayerData
end

local function HasPrimaryGroup(filter)
    if not QBX.PlayerData.citizenid then return false end
    return HasPlayerGotGroup(filter, QBX.PlayerData, true)
end

local function HasGroup(filter)
    if not QBX.PlayerData.citizenid then return false end
    return HasPlayerGotGroup(filter, QBX.PlayerData)
end

local function GetGroups()
    if not QBX.PlayerData.citizenid then return {} end
    return GetPlayerGroups(QBX.PlayerData)
end

local NOTIFY_TYPES = { inform = 'info', info = 'info', primary = 'primary', success = 'success', error = 'error', warning = 'warning', warn = 'warning' }

local function Notify(text, notifyType, duration, subTitle)
    local title, description
    if type(text) == 'table' then
        title, description = text.text, text.caption
    elseif subTitle then
        title, description = text, subTitle
    else
        description = text
    end
    exports['qs-core']:Notify(description or title or '', NOTIFY_TYPES[notifyType or 'inform'] or 'info', duration or 5000, description and title or nil)
end

local function HasItem(items, amount)
    amount = amount or 1
    if type(items) == 'table' then
        if items[1] ~= nil then
            for _, name in ipairs(items) do
                if not exports['qs-core']:HasItem(name, amount) then return false end
            end
        else
            for name, count in pairs(items) do
                if not exports['qs-core']:HasItem(name, count) then return false end
            end
        end
        return true
    end
    return exports['qs-core']:HasItem(items, amount) and true or false
end

exports('GetPlayerData', GetPlayerData)
exports('HasPrimaryGroup', HasPrimaryGroup)
exports('HasGroup', HasGroup)
exports('GetGroups', GetGroups)
exports('Notify', Notify)
exports('HasItem', HasItem)
exports('GetJobs', function() return GlobalState.qbxJobs or {} end)
exports('GetGangs', function() return GlobalState.qbxGangs or {} end)
exports('GetJob', function(name) return (GlobalState.qbxJobs or {})[name] end)
exports('GetGang', function(name) return (GlobalState.qbxGangs or {})[name] end)
exports('GetVehiclesByName', function(key) return key and QBX.Shared.Vehicles[key] or QBX.Shared.Vehicles end)
exports('GetVehiclesByHash', function(key) return key and QBX.Shared.VehicleHashes[key] or QBX.Shared.VehicleHashes end)
exports('GetVehiclesByCategory', function() return qbx.table.mapBySubfield(QBX.Shared.Vehicles, 'category') end)
exports('GetWeapons', function(key) return key and QBX.Shared.Weapons[key] or QBX.Shared.Weapons end)
exports('GetLocations', function() return QBX.Shared.Locations end)

CreateThread(function()
    if LocalPlayer.state.isLoggedIn then
        QBX.IsLoggedIn = true
        local core = exports['qb-core']:GetCoreObject({ 'Functions' })
        local data = core.Functions.GetPlayerData()
        if type(data) == 'table' and data.citizenid then QBX.PlayerData = withGroups(data) end
    end
end)
