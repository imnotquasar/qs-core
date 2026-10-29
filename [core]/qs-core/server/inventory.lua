Inventory = Inventory or {}

local backendCache
local pendingUsables = {}
local pendingStashes = {}

function Inventory.GetBackend()
    if backendCache then return backendCache.kind, backendCache.exp end

    local mode = Config.Inventory or 'auto'

    if GetResourceState('qs-coreinventory'):find('start') then
        backendCache = { kind = 'basic', exp = exports['qs-coreinventory'], name = 'qs-coreinventory' }
        return backendCache.kind, backendCache.exp
    end

    if GetResourceState('qs-inventory'):find('start') then
        local isAdvanced = mode == 'advanced' or mode == 'auto'
        backendCache = {
            kind = isAdvanced and 'advanced' or 'basic',
            exp = exports['qs-inventory'],
            name = 'qs-inventory',
        }
        return backendCache.kind, backendCache.exp
    end

    return nil, nil
end

local function warnMissing()
    Utils.Warn('Inventory backend not available (ensure qs-coreinventory or qs-inventory)')
end

local function applyUsable(item, cb)
    local _, exp = Inventory.GetBackend()
    if not exp then return false end

    local backendName = backendCache and backendCache.name
    if backendName == 'qs-inventory' then
        exp:CreateUsableItem(item, cb)
        return true
    end

    if backendName == 'qs-coreinventory' and exp.RegisterUsableItem then
        exp:RegisterUsableItem(item, cb)
        return true
    end

    return false
end

local function applyStash(id, label, slots, maxWeight, columns)
    local _, exp = Inventory.GetBackend()
    if not exp or not exp.RegisterStash then return false end
    return exp:RegisterStash(id, label, slots, maxWeight, columns)
end

local function flushPending()
    local _, exp = Inventory.GetBackend()
    if not exp then return end

    for item, cb in pairs(pendingUsables) do
        applyUsable(item, cb)
    end
    pendingUsables = {}

    for _, stash in ipairs(pendingStashes) do
        applyStash(stash.id, stash.label, stash.slots, stash.maxWeight, stash.columns)
    end
    pendingStashes = {}
end

function Inventory.AddItem(src, name, count, slot, info)
    local _, exp = Inventory.GetBackend()
    if not exp then
        warnMissing()
        return false
    end
    return exp:AddItem(src, name, count or 1, slot, info)
end

function Inventory.RemoveItem(src, name, count, slot, info)
    local _, exp = Inventory.GetBackend()
    if not exp then
        warnMissing()
        return false
    end
    return exp:RemoveItem(src, name, count or 1, slot, info)
end

function Inventory.HasItem(src, name, count)
    local kind, exp = Inventory.GetBackend()
    if not exp then return false end
    count = tonumber(count) or 1
    return exp:HasItem(src, name, count)
end

function Inventory.CanCarryItem(src, name, count)
    local _, exp = Inventory.GetBackend()
    if not exp then return false end
    return exp:CanCarryItem(src, name, count or 1)
end

function Inventory.GetItemCount(src, name)
    local kind, exp = Inventory.GetBackend()
    if not exp then return 0 end
    if kind == 'advanced' then
        if exp.GetItemTotalAmount then
            return exp:GetItemTotalAmount(src, name) or 0
        end
        return 0
    end
    return exp:GetItemCount(src, name) or 0
end

function Inventory.GetSlotView(src)
    local kind, exp = Inventory.GetBackend()
    if not exp then return {} end
    if kind == 'advanced' then
        local list = exp.GetInventory and exp:GetInventory(src)
        if type(list) ~= 'table' then return {} end
        local out = {}
        for slot, item in pairs(list) do
            if type(item) == 'table' and item.name then
                local idx = tonumber(slot) or (#out + 1)
                out[idx] = {
                    name = item.name,
                    count = item.amount or item.count or 0,
                    label = item.label or item.name,
                    info = item.info or item.metadata,
                    slot = idx,
                }
            end
        end
        return out
    end
    return exp:GetSlotView(src) or {}
end

function Inventory.GetItemBySlot(src, slot)
    local kind, exp = Inventory.GetBackend()
    if not exp then return nil end
    slot = tonumber(slot)
    if kind == 'advanced' then
        local item = exp:GetItemBySlot(src, slot)
        if not item then return nil end
        item.count = item.amount or item.count
        return item
    end
    return exp:GetItemBySlot(src, slot)
end

function Inventory.SetItemInfo(src, slot, info)
    local kind, exp = Inventory.GetBackend()
    if not exp then return false end
    if kind == 'advanced' then
        if exp.SetItemMetadata then
            return exp:SetItemMetadata(src, slot, info)
        end
        return false
    end
    return exp:SetItemInfo(src, slot, info)
end

function Inventory.SetBusy(src, ms)
    local kind, exp = Inventory.GetBackend()
    if kind == 'basic' and exp and exp.SetBusy then
        exp:SetBusy(src, ms)
    end
end

function Inventory.RegisterUsableItem(item, cb)
    local _, exp = Inventory.GetBackend()
    if not exp then
        pendingUsables[item] = cb
        return true
    end
    return applyUsable(item, cb)
end

function Inventory.RegisterStash(id, label, slots, maxWeight, columns)
    local _, exp = Inventory.GetBackend()
    if not exp or not exp.RegisterStash then
        pendingStashes[#pendingStashes + 1] = {
            id = id, label = label, slots = slots, maxWeight = maxWeight, columns = columns,
        }
        return true
    end
    return applyStash(id, label, slots, maxWeight, columns)
end

AddEventHandler('qs-inventory:usedItem', function(src, name, slot, info)
    TriggerEvent('qs:server:usedItem', src, name, slot, info)
end)

AddEventHandler('inventory:usedItem', function(a, b, c)
    if type(a) == 'string' and type(b) == 'number' then
        TriggerEvent('qs:server:usedItem', b, a, c, nil)
    elseif type(a) == 'number' and type(b) == 'string' then
        TriggerEvent('qs:server:usedItem', a, b, c, nil)
    end
end)

AddEventHandler('qs-inventory:registerUsables', function()
    flushPending()
end)

AddEventHandler('onResourceStart', function(res)
    if res == 'qs-coreinventory' or res == 'qs-inventory' then
        backendCache = nil
        flushPending()
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == 'qs-coreinventory' or res == 'qs-inventory' then
        backendCache = nil
    end
end)

CreateThread(function()
    Wait(500)
    flushPending()
end)
