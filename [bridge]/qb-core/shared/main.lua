-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from QBCore (https://github.com/qbcore-framework/qb-core)
-- Copyright (C) QBCore Framework and contributors
-- Modified for qscore in 2026: adapted to run on top of qs-core. See NOTICE.

QBCore.Shared = QBCore.Shared or {}
QBCore.Shared.ForceJobDefaultDutyAtLogin = true
QBShared = QBCore.Shared

QBCore.ClientCallbacks = QBCore.ClientCallbacks or {}
QBCore.ServerCallbacks = QBCore.ServerCallbacks or {}
QBCore.Functions = QBCore.Functions or {}
QBCore.Commands = QBCore.Commands or { List = {} }
QBCore.Players = QBCore.Players or {}
QBCore.PlayersByCitizenId = QBCore.PlayersByCitizenId or {}
QBCore.Player_Buckets = QBCore.Player_Buckets or {}
QBCore.Entity_Buckets = QBCore.Entity_Buckets or {}
QBCore.UsableItems = QBCore.UsableItems or {}

---@param filters ('Config'|'Shared'|'ClientCallbacks'|'ServerCallbacks'|'PlayerData'|'Functions'|'Players'|'PlayersByCitizenId'|'Player_Buckets'|'Entity_Buckets'|'UsableItems'|'Commands')[]?
---@return table
local function GetCoreObject(filters)
    if not filters then return QBCore end
    local results = {}
    for i = 1, #filters do
        local key = filters[i]
        if QBCore[key] then
            results[key] = QBCore[key]
        end
    end
    return results
end

exports('GetCoreObject', GetCoreObject)

---@param namespace 'Vehicles' | 'VehicleHashes' | 'Items' | 'Gangs' | 'Jobs' | 'Locations' | 'Weapons' | 'StarterItems'
---@param item string?
---@return table?
function GetShared(namespace, item)
    local ns = QBCore.Shared[namespace]
    if not ns then return nil end
    return item and ns[item] or ns
end

exports('GetShared', GetShared)

AddEventHandler('QBCore:GetObject', function(cb)
    if type(cb) == 'function' then cb(QBCore) end
end)
