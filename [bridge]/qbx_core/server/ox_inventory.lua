local defaultItems = require 'shared.ox_items'

local QS_INVENTORY_EXPORTS = {
    GetCurrentWeapon = true, CanCarryItem = true, SetMetadata = true, AddItem = true, RemoveItem = true,
    Items = true, GetSlot = true, GetSlotWithItem = true, GetSlotIdWithItem = true, GetSlotsWithItem = true,
    SetItem = true, GetItem = true, Search = true, ClearInventory = true, RegisterStash = true,
    RegisterShop = true, GetInventoryItems = true, Inventory = true, CustomDrop = true,
}

local stashes, shops, hooks, drops = {}, {}, {}, {}
local hookId, dropId = 0, 0

local function advancedInventory()
    return GetResourceState('qs-inventory'):find('start') ~= nil
end

local function coreInventory()
    return exports['qs-coreinventory']
end

local function register(name, fn)
    AddEventHandler(('__cfx_export_ox_inventory_%s'):format(name), function(setCB)
        if advancedInventory() and QS_INVENTORY_EXPORTS[name] then return end
        setCB(fn)
    end)
end

local function registerDefaultItems()
    if advancedInventory() then return end
    local known = core:GetItems() or {}
    local missing = {}
    for name, item in pairs(defaultItems) do
        if not known[name] then
            missing[name] = {
                label = item.label, weight = item.weight, useable = item.useable, unique = item.unique,
                description = item.description, weapon = item.type == 'weapon' and name:upper() or nil,
            }
        end
    end
    if next(missing) then core:RegisterItems(missing) end
end

CreateThread(registerDefaultItems)
AddEventHandler('qs:server:catalogReady', registerDefaultItems)

local function oxItemDefinition(name, def)
    return {
        name = name,
        label = def.label or name,
        weight = def.weight or 0,
        stack = not def.unique,
        close = true,
        description = def.description,
        client = { image = def.image },
        weapon = def.weapon and true or nil,
    }
end

local function Items(name)
    local catalog = core:GetItems() or {}
    if name then
        local def = catalog[name]
        return def and oxItemDefinition(name, def) or nil
    end
    local out = {}
    for itemName, def in pairs(catalog) do out[itemName] = oxItemDefinition(itemName, def) end
    return out
end

local function oxSlot(slot, item)
    local def = core:GetItem(item.name) or {}
    return {
        name = item.name,
        label = item.label or def.label or item.name,
        count = item.count or item.amount or 0,
        slot = tonumber(item.slot) or slot,
        metadata = item.info or item.metadata or {},
        weight = def.weight or 0,
        stack = not def.unique,
        close = true,
        description = def.description,
    }
end

local function playerSlots(inv)
    local out = {}
    for slot, item in pairs(core:GetSlotView(inv) or {}) do
        if type(item) == 'table' and item.name then
            local index = tonumber(slot) or item.slot
            out[index] = oxSlot(index, item)
        end
    end
    return out
end

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

local function slotsWith(inv, name, metadata)
    local out = {}
    for _, item in pairs(playerSlots(inv)) do
        if item.name == name and metadataMatches(metadata, item.metadata) then out[#out + 1] = item end
    end
    table.sort(out, function(a, b) return a.slot < b.slot end)
    return out
end

local function countOf(inv, name, metadata)
    local total = 0
    for _, item in ipairs(slotsWith(inv, name, metadata)) do total = total + item.count end
    return total
end

local function GetItemCount(inv, name, metadata)
    return countOf(tonumber(inv), name, metadata)
end

local function AddItem(inv, item, count, metadata, slot, cb)
    count = tonumber(count) or 1
    local ok
    if type(inv) == 'string' and not tonumber(inv) then
        ok = coreInventory():AddToStash(inv, item, count, metadata)
    else
        ok = core:AddItem(tonumber(inv), item, count, slot, metadata)
    end
    ok = ok and true or false
    if cb then cb(ok, not ok and 'inventory_full' or nil) end
    return ok, not ok and 'inventory_full' or nil
end

local function RemoveItem(inv, item, count, metadata, slot)
    inv = tonumber(inv)
    count = tonumber(count) or 1
    if slot or metadata == nil then return core:RemoveItem(inv, item, count, slot) and true or false end
    local remaining = count
    for _, entry in ipairs(slotsWith(inv, item, metadata)) do
        local take = math.min(remaining, entry.count)
        if take > 0 and core:RemoveItem(inv, item, take, entry.slot) then remaining = remaining - take end
        if remaining <= 0 then return true end
    end
    return remaining < count
end

local function Search(inv, search, item, metadata)
    inv = tonumber(inv)
    if search ~= 'slots' and search ~= 'count' and search ~= 1 and search ~= 2 then return false end
    local wantSlots = search == 'slots' or search == 1
    local function one(name)
        if wantSlots then return slotsWith(inv, name, metadata) end
        return countOf(inv, name, metadata)
    end
    if type(item) == 'table' then
        local out = {}
        for _, name in ipairs(item) do out[name] = one(name) end
        return out
    end
    return one(item)
end

local function GetItem(inv, item, metadata, returnsCount)
    inv = tonumber(inv)
    local count = countOf(inv, item, metadata)
    if returnsCount then return count end
    local def = oxItemDefinition(item, core:GetItem(item) or {})
    def.count = count
    return def
end

local function GetSlot(inv, slot)
    local item = core:GetItemBySlot(tonumber(inv), tonumber(slot))
    if not item then return nil end
    return oxSlot(tonumber(slot), item)
end

local function GetSlotWithItem(inv, name, metadata)
    return slotsWith(tonumber(inv), name, metadata)[1]
end

local function GetSlotIdWithItem(inv, name, metadata)
    local item = GetSlotWithItem(inv, name, metadata)
    return item and item.slot or nil
end

local function GetSlotsWithItem(inv, name, metadata)
    return slotsWith(tonumber(inv), name, metadata)
end

local function SetMetadata(inv, slot, metadata)
    return core:SetItemInfo(tonumber(inv), tonumber(slot), metadata) and true or false
end

local function CanCarryItem(inv, item, count)
    return core:CanCarryItem(tonumber(inv), item, tonumber(count) or 1) and true or false
end

local function ClearInventory(inv, keep)
    return coreInventory():ClearInventory(inv, keep)
end

local function GetInventoryItems(inv)
    return playerSlots(tonumber(inv))
end

local function SetItem(inv, item, count, metadata)
    inv = tonumber(inv)
    count = tonumber(count) or 0
    local current = countOf(inv, item, metadata)
    if current < count then return AddItem(inv, item, count - current, metadata) end
    if current > count then return RemoveItem(inv, item, current - count, metadata) end
    return true
end

local function GetCurrentWeapon(inv)
    inv = tonumber(inv)
    local ped = GetPlayerPed(inv)
    if ped == 0 then return nil end
    local weapon = GetSelectedPedWeapon(ped)
    if not weapon or weapon == `WEAPON_UNARMED` then return nil end
    for _, item in pairs(playerSlots(inv)) do
        if joaat(item.name) == weapon then return item end
    end
    return nil
end

local function RegisterStash(id, label, slots, maxWeight, owner, groups, coords)
    id = tostring(id)
    stashes[id] = { id = id, label = label or id, slots = tonumber(slots) or 50, maxWeight = tonumber(maxWeight) or 100000, owner = owner, groups = groups, coords = coords }
    if not advancedInventory() and owner ~= true and type(owner) ~= 'string' then
        core:RegisterStash(id, stashes[id].label, stashes[id].slots, stashes[id].maxWeight, 5)
    end
    return true
end

local function groupAllowed(src, groups)
    if not groups then return true end
    if type(groups) == 'table' and next(groups) == nil then return true end
    return exports.qbx_core:HasGroup(src, groups) == true
end

local function RegisterShop(shopType, properties)
    if type(shopType) ~= 'string' or type(properties) ~= 'table' then return false end
    local items = {}
    for _, entry in ipairs(properties.inventory or {}) do
        if entry.name then items[#items + 1] = { name = entry.name, price = entry.price or 0, grade = entry.grade } end
    end
    local locations = {}
    for _, coords in ipairs(properties.locations or {}) do locations[#locations + 1] = coords end
    shops[shopType] = properties
    if GetResourceState('qs-coreshops'):find('start') then
        exports['qs-coreshops']:RegisterShop({
            name = 'ox_' .. shopType,
            label = properties.name or shopType,
            items = items,
            locations = locations,
            canUse = function(src) return groupAllowed(src, properties.groups) end,
        })
    end
    return true
end

local function registerHook(event, cb)
    hookId = hookId + 1
    hooks[#hooks + 1] = { id = hookId, event = event, cb = cb, resource = GetInvokingResource() }
    return hookId
end

local function removeHooks(id)
    local resource = GetInvokingResource()
    for i = #hooks, 1, -1 do
        if hooks[i].resource == resource and (not id or hooks[i].id == id) then table.remove(hooks, i) end
    end
end

AddEventHandler('onResourceStop', function(resource)
    for i = #hooks, 1, -1 do
        if hooks[i].resource == resource then table.remove(hooks, i) end
    end
end)

local function hooksAllow(event, payload)
    for _, hook in ipairs(hooks) do
        if hook.event == event then
            local ok, response = pcall(hook.cb, payload)
            if ok and response == false then return false end
        end
    end
    return true
end

local function openStashFor(src, data, forced)
    local id = type(data) == 'table' and data.id or data
    if id == nil then return false end
    id = tostring(id)
    local stash = stashes[id]
    if not stash then return false end
    if not forced and not groupAllowed(src, stash.groups) then return false end
    local fullId = id
    local owner = (type(data) == 'table' and data.owner) or stash.owner
    if owner == true then
        local player = core:GetPlayer(src)
        if not player then return false end
        fullId = id .. ':' .. (player.citizenid or player.PlayerData.citizenid)
    elseif type(owner) == 'string' then
        fullId = id .. ':' .. owner
    end
    if not hooksAllow('openInventory', { source = src, inventoryId = fullId, inventoryType = 'stash' }) then return false end
    core:RegisterStash(fullId, stash.label, stash.slots, stash.maxWeight, 5)
    TriggerClientEvent('qbx_core:client:oxOpenStash', src, fullId)
    TriggerEvent('ox_inventory:openedInventory', src, fullId)
    return true
end

local function canSearchPlayer(src, target)
    if exports.qbx_core:HasPermission(src, 'admin') then return true end
    local srcPed, targetPed = GetPlayerPed(src), GetPlayerPed(target)
    if srcPed == 0 or targetPed == 0 or #(GetEntityCoords(srcPed) - GetEntityCoords(targetPed)) > 4.0 then return false end
    local actor, victim = exports.qbx_core:GetPlayer(src), exports.qbx_core:GetPlayer(target)
    if not actor or not victim then return false end
    if actor.PlayerData.job.type == 'leo' and actor.PlayerData.job.onduty then return true end
    local meta = victim.PlayerData.metadata
    return meta.isdead == true or meta.inlaststand == true or meta.ishandcuffed == true
end

local function openFor(src, inv, data, forced)
    if inv == 'stash' then return openStashFor(src, data, forced) end
    if inv == 'player' then
        local target = tonumber(type(data) == 'table' and data.id or data)
        if not target or target == src then return false end
        if not forced and not canSearchPlayer(src, target) then return false end
        return coreInventory():OpenPlayerFor(src, target)
    end
    if inv == 'shop' then
        local shopType = type(data) == 'table' and data.type or data
        if not shops[shopType] or not GetResourceState('qs-coreshops'):find('start') then return false end
        return exports['qs-coreshops']:OpenShop(src, 'ox_' .. shopType)
    end
    return false
end

RegisterNetEvent('qbx_core:server:oxOpen', function(inv, data)
    openFor(source, inv, data, false)
end)

RegisterNetEvent('qbx_core:server:oxClosed', function()
    TriggerEvent('ox_inventory:closedInventory', source)
end)

local function forceOpenInventory(src, inv, data)
    if advancedInventory() then
        TriggerClientEvent('qbx_core:client:oxForceOpen', src, inv, data)
        return true
    end
    return openFor(tonumber(src), inv, data, true)
end

local function CustomDrop(prefix, items, coords, slots, maxWeight)
    if type(items) ~= 'table' or not coords then return nil end
    dropId = dropId + 1
    local id = ('%s_%d_%d'):format(prefix or 'drop', os.time(), dropId)
    core:RegisterStash(id, prefix or 'Drop', tonumber(slots) or math.max(#items, 10), tonumber(maxWeight) or 1000000, 5)
    Wait(0)
    for _, entry in ipairs(items) do
        coreInventory():AddToStash(id, entry[1] or entry.name, entry[2] or entry.count or 1, entry[3] or entry.metadata)
    end
    drops[id] = { x = coords.x, y = coords.y, z = coords.z }
    TriggerClientEvent('qbx_core:client:oxDrop', -1, id, drops[id])
    SetTimeout(30 * 60 * 1000, function()
        drops[id] = nil
        TriggerClientEvent('qbx_core:client:oxDropRemove', -1, id)
    end)
    return id
end

AddEventHandler('qs:server:characterLoaded', function(src)
    for id, coords in pairs(drops) do TriggerClientEvent('qbx_core:client:oxDrop', src, id, coords) end
end)

register('Items', Items)
register('AddItem', AddItem)
register('RemoveItem', RemoveItem)
register('Search', Search)
register('GetItem', GetItem)
register('GetItemCount', GetItemCount)
register('GetSlot', GetSlot)
register('GetSlotWithItem', GetSlotWithItem)
register('GetSlotIdWithItem', GetSlotIdWithItem)
register('GetSlotsWithItem', GetSlotsWithItem)
register('SetMetadata', SetMetadata)
register('CanCarryItem', CanCarryItem)
register('ClearInventory', ClearInventory)
register('GetInventoryItems', GetInventoryItems)
register('SetItem', SetItem)
register('GetCurrentWeapon', GetCurrentWeapon)
register('RegisterStash', RegisterStash)
register('RegisterShop', RegisterShop)
register('registerHook', registerHook)
register('removeHooks', removeHooks)
register('forceOpenInventory', forceOpenInventory)
register('CustomDrop', CustomDrop)
