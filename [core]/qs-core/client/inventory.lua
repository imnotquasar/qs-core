local stashZones = {}

local function coreInventoryActive()
    return GetResourceState('qs-coreinventory'):find('start') ~= nil
end

local function advancedInventoryActive()
    return GetResourceState('qs-inventory'):find('start') ~= nil
end

local function basicExport()
    if coreInventoryActive() then return exports['qs-coreinventory'] end
    if advancedInventoryActive() then return exports['qs-inventory'] end
    return nil
end

local function nearestStashZone()
    if #stashZones == 0 then return nil end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return nil end
    local coords = GetEntityCoords(ped)
    local best, bestD
    for _, z in ipairs(stashZones) do
        local d = #(coords - z.coords)
        if d <= (z.radius or 2.0) and (not bestD or d < bestD) then
            best, bestD = z, d
        end
    end
    return best
end

local function openAdvancedStash(zone)
    local prefix = 'inventory'
    local stashId = zone.id
    TriggerServerEvent(prefix .. ':server:OpenInventory', 'stash', stashId, zone.opts or {})
    TriggerEvent(prefix .. ':client:SetCurrentStash', stashId)
end

local function registerLocalStashZone(id, coords, opts)
    if not id or not coords then return false end
    id = tostring(id)
    opts = type(opts) == 'table' and opts or {}
    local c = vector3(coords.x, coords.y, coords.z)
    for _, z in ipairs(stashZones) do
        if z.id == id then
            z.coords = c
            z.radius = tonumber(opts.radius) or z.radius or 2.0
            z.opts = opts.stash or opts
            return true
        end
    end
    stashZones[#stashZones + 1] = {
        id = id,
        coords = c,
        radius = tonumber(opts.radius) or 2.0,
        opts = opts.stash or opts,
    }
    return true
end

local function removeLocalStashZone(id)
    if not id then return false end
    id = tostring(id)
    for i = #stashZones, 1, -1 do
        if stashZones[i].id == id then
            table.remove(stashZones, i)
        end
    end
    return true
end

if advancedInventoryActive() then
    CreateThread(function()
        while true do
            local sleep = 500
            local zone = nearestStashZone()
            if zone then
                sleep = 0
                if IsControlJustPressed(0, 38) then
                    openAdvancedStash(zone)
                end
            end
            Wait(sleep)
        end
    end)
end

exports('HasItem', function(name, count)
    local exp = basicExport()
    if not exp then return false end
    local ok, result = pcall(function()
        return exp:HasItem(name, count)
    end)
    return ok and result or false
end)

exports('GetItemCount', function(name)
    local exp = basicExport()
    if not exp then return 0 end
    local ok, result = pcall(function()
        return exp:GetItemCount(name) or 0
    end)
    return ok and result or 0
end)

exports('RegisterStashZone', function(id, coords, opts)
    if coreInventoryActive() then
        return exports['qs-coreinventory']:RegisterStashZone(id, coords, opts)
    end
    if advancedInventoryActive() then
        return registerLocalStashZone(id, coords, opts)
    end
    return false
end)

exports('RemoveStashZone', function(id)
    if coreInventoryActive() then
        return exports['qs-coreinventory']:RemoveStashZone(id)
    end
    if advancedInventoryActive() then
        return removeLocalStashZone(id)
    end
    return false
end)
