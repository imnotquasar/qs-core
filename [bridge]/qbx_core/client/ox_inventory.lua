local defaultItems = require 'shared.ox_items'

local QS_INVENTORY_EXPORTS = { Items = true, Search = true, getCurrentWeapon = true, openInventory = true, setStashTarget = true }

local slots = {}
local counts = {}
local maxWeight, weight = 0, 0

local function advancedInventory()
    return GetResourceState('qs-inventory'):find('start') ~= nil
end

local function register(name, fn)
    AddEventHandler(('__cfx_export_ox_inventory_%s'):format(name), function(setCB)
        if advancedInventory() and QS_INVENTORY_EXPORTS[name] then return end
        setCB(fn)
    end)
end

local function oxItem(name, def)
    return {
        name = name,
        label = def.label or name,
        weight = def.weight or 0,
        stack = not def.unique,
        close = true,
        description = def.description,
        weapon = def.type == 'weapon' or nil,
    }
end

RegisterNetEvent('qs-inv:client:set', function(data)
    if not data or not data.items then return end
    maxWeight, weight = data.maxWeight or 0, data.weight or 0
    local nextSlots, nextCounts, changes = {}, {}, {}
    for index = 1, data.slots or #data.items do
        local item = data.items[index]
        if type(item) == 'table' and item.name then
            nextSlots[index] = {
                name = item.name, label = item.label or item.name, count = item.count or 0, slot = index,
                metadata = item.info or {}, weight = item.weight or 0,
            }
            nextCounts[item.name] = (nextCounts[item.name] or 0) + (item.count or 0)
        end
        local before, after = slots[index], nextSlots[index]
        if (before and before.name) ~= (after and after.name) or (before and before.count) ~= (after and after.count) then
            changes[index] = after or false
        end
    end
    slots = nextSlots
    for name, count in pairs(nextCounts) do
        if counts[name] ~= count then TriggerEvent('ox_inventory:itemCount', name, count) end
    end
    for name in pairs(counts) do
        if not nextCounts[name] then TriggerEvent('ox_inventory:itemCount', name, 0) end
    end
    counts = nextCounts
    if next(changes) then TriggerEvent('ox_inventory:updateInventory', changes) end
end)

local function metadataMatches(expected, actual)
    if expected == nil then return true end
    if type(expected) == 'string' then expected = { type = expected } end
    if type(expected) ~= 'table' then return false end
    actual = actual or {}
    for key, value in pairs(expected) do
        if actual[key] ~= value then return false end
    end
    return true
end

local function find(name, metadata)
    local out = {}
    for _, item in pairs(slots) do
        if item.name == name and metadataMatches(metadata, item.metadata) then out[#out + 1] = item end
    end
    table.sort(out, function(a, b) return a.slot < b.slot end)
    return out
end

local function Search(search, item, metadata)
    if search ~= 'slots' and search ~= 'count' and search ~= 1 and search ~= 2 then return false end
    local wantSlots = search == 'slots' or search == 1
    local function one(name)
        local found = find(name, metadata)
        if wantSlots then return found end
        local total = 0
        for _, entry in ipairs(found) do total = total + entry.count end
        return total
    end
    if type(item) == 'table' then
        local out = {}
        for _, name in ipairs(item) do out[name] = one(name) end
        return out
    end
    return one(item)
end

local function Items(name)
    if name then
        local def = defaultItems[name]
        return def and oxItem(name, def) or nil
    end
    local out = {}
    for itemName, def in pairs(defaultItems) do out[itemName] = oxItem(itemName, def) end
    return out
end

local function GetPlayerItems()
    if advancedInventory() then
        local names, out = {}, {}
        for name in pairs(defaultItems) do names[#names + 1] = name end
        for _, found in pairs(exports.ox_inventory:Search('slots', names) or {}) do
            for _, item in ipairs(found) do out[#out + 1] = item end
        end
        return out
    end
    return slots
end

local function getCurrentWeapon()
    local weapon = GetSelectedPedWeapon(cache.ped)
    if not weapon or weapon == `WEAPON_UNARMED` then return nil end
    for _, item in pairs(slots) do
        if joaat(item.name) == weapon then return item end
    end
    return nil
end

local function openInventory(inv, data)
    if inv == nil or inv == 'player' and data == nil then
        ExecuteCommand('inventory')
        return
    end
    TriggerServerEvent('qbx_core:server:oxOpen', inv, data)
end

local function openNearbyInventory()
    local id = lib.getClosestPlayer(GetEntityCoords(cache.ped), 2.5, false)
    if not id then return end
    local target = GetPlayerServerId(id)
    if advancedInventory() then
        exports.ox_inventory:openInventory('player', target)
        return
    end
    TriggerServerEvent('qbx_core:server:oxOpen', 'player', target)
end

RegisterNetEvent('qbx_core:client:oxOpenStash', function(id)
    exports['qs-coreinventory']:OpenStash(id)
end)

RegisterNetEvent('qbx_core:client:oxForceOpen', function(inv, data)
    exports.ox_inventory:openInventory(inv, data)
end)

RegisterNetEvent('qbx_core:client:oxDrop', function(id, coords)
    if GetResourceState('qs-coreinventory'):find('start') then
        exports['qs-coreinventory']:RegisterStashZone(id, coords, { radius = 2.0 })
    end
end)

RegisterNetEvent('qbx_core:client:oxDropRemove', function(id)
    if GetResourceState('qs-coreinventory'):find('start') then
        exports['qs-coreinventory']:RemoveStashZone(id)
    end
end)

AddEventHandler('qs-inv:client:opened', function()
    TriggerEvent('ox_inventory:openedInventory')
end)

AddEventHandler('qs-inv:client:closed', function()
    TriggerServerEvent('qbx_core:server:oxClosed')
    TriggerEvent('ox_inventory:closedInventory')
end)

RegisterNetEvent('qs-inv:client:equip', function(weapon)
    if advancedInventory() then return end
    TriggerEvent('ox_inventory:currentWeapon', { name = weapon, metadata = {} })
end)

AddEventHandler('ox_inventory:disarm', function()
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    TriggerEvent('ox_inventory:currentWeapon', nil)
end)

register('Search', Search)
register('Items', Items)
register('GetPlayerItems', GetPlayerItems)
register('GetPlayerWeight', function() return weight end)
register('GetPlayerMaxWeight', function() return maxWeight end)
register('GetSlotIdWithItem', function(name, metadata) local found = find(name, metadata)[1]; return found and found.slot or nil end)
register('GetSlotWithItem', function(name, metadata) return find(name, metadata)[1] end)
register('GetSlotsWithItem', function(name, metadata) return find(name, metadata) end)
register('getCurrentWeapon', getCurrentWeapon)
register('openInventory', openInventory)
register('openNearbyInventory', openNearbyInventory)
register('closeInventory', function()
    if GetResourceState('qs-coreinventory'):find('start') then exports['qs-coreinventory']:CloseInventory() end
end)
register('displayMetadata', function() end)
register('setStashTarget', function() end)
