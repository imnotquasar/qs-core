-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from QBCore (https://github.com/qbcore-framework/qb-core)
-- Copyright (C) QBCore Framework and contributors
-- Modified for qscore in 2026: adapted to run on top of qs-core. See NOTICE.

local core = exports['qs-core']

local function SetMethod(methodName, handler)
    if type(methodName) ~= 'string' then return false, 'invalid_method_name' end
    if QBCore.Functions[methodName] ~= nil then return false, 'method_exists' end
    QBCore.Functions[methodName] = handler
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.SetMethod = SetMethod
exports('SetMethod', SetMethod)

local function SetField(fieldName, data)
    if type(fieldName) ~= 'string' then return false, 'invalid_field_name' end
    if QBCore[fieldName] ~= nil then return false, 'field_exists' end
    QBCore[fieldName] = data
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.SetField = SetField
exports('SetField', SetField)

local function AddJob(jobName, job)
    if type(jobName) ~= 'string' then return false, 'invalid_job_name' end
    if QBCore.Shared.Jobs[jobName] then return false, 'job_exists' end
    QBCore.Shared.Jobs[jobName] = job
    core:RegisterJob(jobName, BridgeQsJobFromQB(jobName, job))
    TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Jobs', jobName, job)
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.AddJob = AddJob
exports('AddJob', AddJob)

local function AddJobs(jobs)
    for key, value in pairs(jobs) do
        if type(key) ~= 'string' then return false, 'invalid_job_name', value end
        if QBCore.Shared.Jobs[key] then return false, 'job_exists', value end
    end
    for key, value in pairs(jobs) do
        QBCore.Shared.Jobs[key] = value
        core:RegisterJob(key, BridgeQsJobFromQB(key, value))
    end
    TriggerClientEvent('QBCore:Client:OnSharedUpdateMultiple', -1, 'Jobs', jobs)
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.AddJobs = AddJobs
exports('AddJobs', AddJobs)

local function RemoveJob(jobName)
    if type(jobName) ~= 'string' then return false, 'invalid_job_name' end
    if not QBCore.Shared.Jobs[jobName] then return false, 'job_not_exists' end
    QBCore.Shared.Jobs[jobName] = nil
    core:RemoveJob(jobName)
    TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Jobs', jobName, nil)
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.RemoveJob = RemoveJob
exports('RemoveJob', RemoveJob)

local function UpdateJob(jobName, job)
    if type(jobName) ~= 'string' then return false, 'invalid_job_name' end
    if not QBCore.Shared.Jobs[jobName] then return false, 'job_not_exists' end
    QBCore.Shared.Jobs[jobName] = job
    core:UpdateJob(jobName, BridgeQsJobFromQB(jobName, job))
    TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Jobs', jobName, job)
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.UpdateJob = UpdateJob
exports('UpdateJob', UpdateJob)

local function AddItem(itemName, item)
    if type(itemName) ~= 'string' then return false, 'invalid_item_name' end
    if QBCore.Shared.Items[itemName] then return false, 'item_exists' end
    QBCore.Shared.Items[itemName] = item
    core:RegisterItem(itemName, BridgeQsItemFromQB(itemName, item))
    TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Items', itemName, item)
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.AddItem = AddItem
exports('AddItem', AddItem)

local function UpdateItem(itemName, item)
    if type(itemName) ~= 'string' then return false, 'invalid_item_name' end
    if not QBCore.Shared.Items[itemName] then return false, 'item_not_exists' end
    QBCore.Shared.Items[itemName] = item
    core:UpdateItemDefinition(itemName, BridgeQsItemFromQB(itemName, item))
    TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Items', itemName, item)
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.UpdateItem = UpdateItem
exports('UpdateItem', UpdateItem)

local function AddItems(items)
    for key, value in pairs(items) do
        if type(key) ~= 'string' then return false, 'invalid_item_name', value end
        if QBCore.Shared.Items[key] then return false, 'item_exists', value end
    end
    for key, value in pairs(items) do
        QBCore.Shared.Items[key] = value
        core:RegisterItem(key, BridgeQsItemFromQB(key, value))
    end
    TriggerClientEvent('QBCore:Client:OnSharedUpdateMultiple', -1, 'Items', items)
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.AddItems = AddItems
exports('AddItems', AddItems)

local function RemoveItem(itemName)
    if type(itemName) ~= 'string' then return false, 'invalid_item_name' end
    if not QBCore.Shared.Items[itemName] then return false, 'item_not_exists' end
    QBCore.Shared.Items[itemName] = nil
    core:RemoveItemDefinition(itemName)
    TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Items', itemName, nil)
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.RemoveItem = RemoveItem
exports('RemoveItem', RemoveItem)

local function AddGang(gangName, gang)
    if type(gangName) ~= 'string' then return false, 'invalid_gang_name' end
    if QBCore.Shared.Gangs[gangName] then return false, 'gang_exists' end
    QBCore.Shared.Gangs[gangName] = gang
    core:RegisterGang(gangName, gang)
    TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Gangs', gangName, gang)
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.AddGang = AddGang
exports('AddGang', AddGang)

local function AddGangs(gangs)
    for key, value in pairs(gangs) do
        if type(key) ~= 'string' then return false, 'invalid_gang_name', value end
        if QBCore.Shared.Gangs[key] then return false, 'gang_exists', value end
    end
    for key, value in pairs(gangs) do
        QBCore.Shared.Gangs[key] = value
        core:RegisterGang(key, value)
    end
    TriggerClientEvent('QBCore:Client:OnSharedUpdateMultiple', -1, 'Gangs', gangs)
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.AddGangs = AddGangs
exports('AddGangs', AddGangs)

local function RemoveGang(gangName)
    if type(gangName) ~= 'string' then return false, 'invalid_gang_name' end
    if not QBCore.Shared.Gangs[gangName] then return false, 'gang_not_exists' end
    QBCore.Shared.Gangs[gangName] = nil
    core:RemoveGang(gangName)
    TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Gangs', gangName, nil)
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.RemoveGang = RemoveGang
exports('RemoveGang', RemoveGang)

local function UpdateGang(gangName, gang)
    if type(gangName) ~= 'string' then return false, 'invalid_gang_name' end
    if not QBCore.Shared.Gangs[gangName] then return false, 'gang_not_exists' end
    QBCore.Shared.Gangs[gangName] = gang
    core:RegisterGang(gangName, gang)
    TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Gangs', gangName, gang)
    TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

QBCore.Functions.UpdateGang = UpdateGang
exports('UpdateGang', UpdateGang)

local resourceName = GetCurrentResourceName()

local function GetCoreVersion(invokingResource)
    local resourceVersion = GetResourceMetadata(resourceName, 'version')
    if invokingResource and invokingResource ~= '' then
        print(('%s called qbcore version check: %s'):format(invokingResource or 'Unknown Resource', resourceVersion))
    end
    return resourceVersion
end

QBCore.Functions.GetCoreVersion = GetCoreVersion
exports('GetCoreVersion', GetCoreVersion)

local function ExploitBan(playerId, origin)
    return core:ExploitBan(playerId, origin)
end

exports('ExploitBan', ExploitBan)

AddEventHandler('QBCore:Server:UpdateObject', function()
    TriggerClientEvent('QBCore:Client:UpdateObject', -1)
end)
