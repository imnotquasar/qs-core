local core = exports['qs-core']

function BridgeQsItemFromQB(name, it)
    return {
        label = it.label or name,
        weight = tonumber(it.weight) or 0,
        useable = it.useable or false,
        description = it.description,
        unique = it.unique or false,
        image = it.image,
        weapon = (it.type == 'weapon') and name:upper() or nil,
    }
end

function BridgeQsJobFromQB(name, j)
    local grades = {}
    for k, g in pairs(j.grades or {}) do
        local lvl = tonumber(k) or 0
        grades[lvl] = {
            name = (g.name or ('grade' .. lvl)):lower(),
            label = g.name or ('Grade ' .. lvl),
            salary = tonumber(g.payment) or 0,
            isBoss = g.isboss or false,
        }
    end
    if not next(grades) then grades[0] = { name = 'employee', label = 'Employee', salary = 0 } end
    return { label = j.label or name, defaultDuty = j.defaultDuty ~= false, grades = grades }
end

function BridgeQbItemFromDef(name, def)
    return {
        name = name,
        label = def.label or name,
        weight = def.weight or 0,
        type = def.weapon and 'weapon' or 'item',
        image = def.image or (name .. '.png'),
        unique = def.unique or (def.weapon ~= nil),
        useable = def.useable or false,
        shouldClose = true,
        combinable = nil,
        description = def.description or '',
        ammotype = def.ammo and 'AMMO_PISTOL' or nil,
    }
end

function BridgeSyncSharedCatalog()
    local reg = {}
    for name, it in pairs(QBCore.Shared.Items) do
        if not core:GetItem(name) then reg[name] = BridgeQsItemFromQB(name, it) end
    end
    if next(reg) then core:RegisterItems(reg) end

    local qsJobs = core:GetJobs() or {}
    local jreg = {}
    for name, j in pairs(QBCore.Shared.Jobs) do
        if not qsJobs[name] then jreg[name] = BridgeQsJobFromQB(name, j) end
    end
    if next(jreg) then core:RegisterJobs(jreg) end

    local qsGangs = core:GetGangs() or {}
    for name, g in pairs(QBCore.Shared.Gangs) do
        if not qsGangs[name] then core:RegisterGang(name, g) end
    end

    for name, def in pairs(core:GetItems() or {}) do
        if not QBCore.Shared.Items[name] then QBCore.Shared.Items[name] = BridgeQbItemFromDef(name, def) end
    end

    for name, j in pairs(core:GetJobs() or {}) do
        if not QBCore.Shared.Jobs[name] then
            local grades = {}
            for lvl, g in pairs(j.grades or {}) do
                grades[tostring(lvl)] = { name = g.label or g.name, payment = g.salary or 0, isboss = g.isBoss or false }
            end
            QBCore.Shared.Jobs[name] = { label = j.label or name, defaultDuty = j.defaultDuty ~= false, offDutyPay = false, grades = grades }
        end
    end

    for name, g in pairs(core:GetGangs() or {}) do
        if not QBCore.Shared.Gangs[name] then QBCore.Shared.Gangs[name] = g end
    end
end

AddEventHandler('qs:server:catalogReady', function()
    BridgeSyncSharedCatalog()
end)

local inventoryItems = {}
local pushedItems = {}

local function itemDiffers(a, b)
    for _, key in ipairs({ 'label', 'weight', 'type', 'image', 'unique', 'useable', 'description' }) do
        if a[key] ~= b[key] then return true end
    end
    return false
end

local function syncInventoryItems()
    if GetResourceState('qs-inventory') ~= 'started' then return end
    local ok, list = pcall(function() return exports['qs-inventory']:GetItemList() end)
    if not ok or type(list) ~= 'table' then return end

    local changed, removed = {}, {}
    for name, it in pairs(list) do
        if type(name) == 'string' and type(it) == 'table' then
            local current = QBCore.Shared.Items[name]
            local item = {}
            for k, v in pairs(current or {}) do item[k] = v end
            item.name = name
            item.label = it.label or item.label or name
            item.weight = tonumber(it.weight) or item.weight or 0
            item.type = it.type or item.type or 'item'
            item.image = it.image or item.image or (name .. '.png')
            item.unique = it.unique or false
            item.useable = it.useable or false
            item.description = it.description or item.description or ''
            if item.shouldClose == nil then item.shouldClose = true end
            if not current then inventoryItems[name] = true end
            if not current or itemDiffers(current, item) then
                QBCore.Shared.Items[name] = item
                changed[name] = item
                pushedItems[name] = item
            end
        end
    end

    for name in pairs(inventoryItems) do
        if not list[name] then
            QBCore.Shared.Items[name] = nil
            inventoryItems[name] = nil
            pushedItems[name] = nil
            removed[#removed + 1] = name
        end
    end

    if next(changed) then
        TriggerClientEvent('QBCore:Client:OnSharedUpdateMultiple', -1, 'Items', changed)
    end
    for _, name in ipairs(removed) do
        TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Items', name, nil)
    end
    if next(changed) or #removed > 0 then
        TriggerEvent('QBCore:Server:UpdateObject')
    end
end

local syncQueued = false

AddEventHandler('qs:server:itemsUpdated', function()
    if syncQueued then return end
    syncQueued = true
    SetTimeout(250, function()
        syncQueued = false
        syncInventoryItems()
    end)
end)

AddEventHandler('qs:server:playerLoaded', function(src)
    if next(pushedItems) then
        TriggerClientEvent('QBCore:Client:OnSharedUpdateMultiple', src, 'Items', pushedItems)
    end
end)

CreateThread(function()
    if GetResourceState('qs-core') == 'started' then
        BridgeSyncSharedCatalog()
    end
end)
