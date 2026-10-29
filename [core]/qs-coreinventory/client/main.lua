local inv = { slots = Config.Slots, columns = Config.Columns, items = {}, weight = 0, maxWeight = Config.MaxWeight }
local isOpen = false
local themeSent = false
local secondary = nil
local autoContext = true
local pendingStash = nil
local stashZones = {}
local radialOpen = false
local radialReleased = false

local function radialItems()
    local list = {}
    for i = 1, Config.RadialSlots do
        local it = inv.items and inv.items[i]
        list[i] = type(it) == 'table' and it or false
    end
    return list
end

local function send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local function sendTheme()
    local colors = exports['qs-core']:GetColors()
    if colors then
        send('theme', colors)
        themeSent = true
    end
end

AddEventHandler('qs:client:colorsChanged', function() sendTheme() end)

RegisterNetEvent('qs-inv:client:set', function(data)
    if data then inv = data end
    if isOpen then send('set', inv) end
    if radialOpen then send('radial:set', { items = radialItems() }) end
end)

exports('GetItemCount', function(name)
    local total = 0
    for _, it in ipairs(inv.items or {}) do
        if type(it) == 'table' and it.name == name then total = total + (it.count or 0) end
    end
    return total
end)

exports('HasItem', function(name, count)
    return exports['qs-coreinventory']:GetItemCount(name) >= (tonumber(count) or 1)
end)

RegisterNetEvent('qs-inv:client:itembox', function(data)
    if data then send('itembox', data) end
end)

local function trim(s) return s and s:match('^%s*(.-)%s*$') or nil end

local function shutBootFor(sec)
    if sec and sec.kind == 'trunk' and sec.veh and DoesEntityExist(sec.veh) then
        SetVehicleDoorShut(sec.veh, 5, false)
    end
end

local function closeInventory()
    if not isOpen then return end
    isOpen = false
    if secondary then
        shutBootFor(secondary)
        TriggerServerEvent('qs-inv:server:closeSecondary')
        secondary = nil
    end
    inv.secondary = nil
    autoContext = true
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    send('close')
end

local function nearestTrunk()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return nil end
    local coords = GetEntityCoords(ped)
    local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 3.5, 0, 71)
    if not veh or veh == 0 then return nil end
    local mn = GetModelDimensions(GetEntityModel(veh))
    local rear = GetOffsetFromEntityInWorldCoords(veh, 0.0, mn.y - 0.5, 0.0)
    if #(coords - rear) <= Config.TrunkReach then
        return veh, trim(GetVehicleNumberPlateText(veh))
    end
    return nil
end

local function hasVehKeys(plate)
    if GetResourceState('qs-corevehiclekeys') ~= 'started' then return true end
    return exports['qs-corevehiclekeys']:HasKeys(plate) == true
end

local trunkBlockNotified = 0
local function trunkBlocked()
    if GetGameTimer() - trunkBlockNotified > 3000 then
        trunkBlockNotified = GetGameTimer()
        exports['qs-core']:Notify(T('trunk_locked'), 'error', 2500)
    end
end

local function openTrunkFor(veh, plate)
    if GetVehicleDoorLockStatus(veh) == 2 or not hasVehKeys(plate) then
        trunkBlocked()
        return
    end
    secondary = { kind = 'trunk', id = plate, veh = veh }
    TriggerServerEvent('qs-inv:server:openTrunk', plate)
    SetVehicleDoorOpen(veh, 5, false, false)
end

local function openGloveboxFor(veh, plate)
    if not hasVehKeys(plate) then
        trunkBlocked()
        return
    end
    secondary = { kind = 'glovebox', id = plate, veh = veh }
    TriggerServerEvent('qs-inv:server:openGlovebox', plate)
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

local function openStashZoneFor(zone)
    secondary = { kind = 'stash', id = zone.id, coords = zone.coords, radius = zone.radius }
    TriggerServerEvent('qs-inv:server:openStash', zone.id, zone.opts)
end

local function tryAutoOpenSecondary()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        local plate = trim(GetVehicleNumberPlateText(veh))
        if plate then openGloveboxFor(veh, plate) end
        return
    end
    local veh, plate = nearestTrunk()
    if plate then
        openTrunkFor(veh, plate)
        return
    end
    local zone = nearestStashZone()
    if zone then openStashZoneFor(zone) end
end

local function closeSecondary(notify, msg)
    if not secondary then return end
    shutBootFor(secondary)
    secondary = nil
    TriggerServerEvent('qs-inv:server:closeSecondary')
    inv.secondary = nil
    if isOpen then send('set', inv) end
    if notify then exports['qs-core']:Notify(msg or T('storage_closed'), 'error', 3000) end
end

local function proximityLoop()
    CreateThread(function()
        local closeDist = Config.TrunkCloseDistance or 5.0
        while isOpen do
            Wait(300)
            local ped = PlayerPedId()
            if secondary then
                if secondary.kind == 'trunk' then
                    local veh = secondary.veh
                    if not veh or not DoesEntityExist(veh)
                        or #(GetEntityCoords(ped) - GetEntityCoords(veh)) > closeDist then
                        closeSecondary(true, T('trunk_far'))
                    end
                elseif secondary.kind == 'glovebox' then
                    if not IsPedInAnyVehicle(ped, false) then
                        closeSecondary(true, T('glovebox_left'))
                    end
                elseif secondary.kind == 'stash' and secondary.coords then
                    if #(GetEntityCoords(ped) - secondary.coords) > (secondary.radius or closeDist) then
                        closeSecondary(true)
                    end
                end
            end
        end
    end)
end

local MOVE_CONTROLS = {
    30, 31, 32, 33, 34, 35,
    21, 22,
    59, 60,
    71, 72, 76,
}

local function openLoop()
    CreateThread(function()
        while isOpen do
            Wait(0)
            DisableAllControlActions(0)
            for i = 1, #MOVE_CONTROLS do
                EnableControlAction(0, MOVE_CONTROLS[i], true)
            end
            if IsDisabledControlJustReleased(0, 322) then
                closeInventory()
            end
        end
    end)
end

local function openInventory()
    if isOpen then return end
    if exports['qs-core']:IsDead() then return end
    if not themeSent then sendTheme() end
    isOpen = true

    inv.secondary = nil
    secondary = nil

    if pendingStash then
        autoContext = false
        secondary = { kind = 'stash', id = pendingStash.id }
        TriggerServerEvent('qs-inv:server:openStash', pendingStash.id, pendingStash.opts)
        pendingStash = nil
    else
        autoContext = true
        tryAutoOpenSecondary()
    end

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    send('open', inv)
    send('locale', Locales[GetConvar('qs:locale', 'en')] or Locales.en or {})
    openLoop()
    proximityLoop()
end

RegisterCommand('inventory', function()
    if isOpen then closeInventory() else openInventory() end
end, false)

exports('OpenStash', function(id, opts)
    if isOpen or not id then return false end
    pendingStash = { id = tostring(id), opts = type(opts) == 'table' and opts or nil }
    openInventory()
    return true
end)

exports('RegisterStashZone', function(id, coords, opts)
    if not id or not coords then return false end
    id = tostring(id)
    opts = type(opts) == 'table' and opts or {}
    local c = vector3(coords.x, coords.y, coords.z)
    for _, z in ipairs(stashZones) do
        if z.id == id then
            z.coords = c
            z.radius = tonumber(opts.radius) or z.radius or 2.0
            z.opts = opts.stash
            return true
        end
    end
    stashZones[#stashZones + 1] = {
        id = id,
        coords = c,
        radius = tonumber(opts.radius) or 2.0,
        opts = opts.stash,
    }
    return true
end)

exports('RemoveStashZone', function(id)
    if not id then return false end
    id = tostring(id)
    for i = #stashZones, 1, -1 do
        if stashZones[i].id == id then table.remove(stashZones, i) end
    end
    if secondary and secondary.kind == 'stash' and secondary.id == id then
        closeSecondary(false)
    end
    return true
end)

RegisterKeyMapping('inventory', 'Toggle inventory', 'keyboard', Config.OpenKey)

local wheelBlockUntil = 0
local wheelBurstRunning = false
local function blockWheelBurst()
    wheelBlockUntil = GetGameTimer() + 500
    if wheelBurstRunning then return end
    wheelBurstRunning = true
    CreateThread(function()
        while GetGameTimer() < wheelBlockUntil do
            BlockWeaponWheelThisFrame()
            HudWeaponWheelIgnoreSelection()
            Wait(0)
        end
        wheelBurstRunning = false
    end)
end

local function requestUse(slot)
    if exports['qs-core']:IsBusy() or exports['qs-core']:IsDead() then return end
    TriggerServerEvent('qs-inv:server:use', slot)
end

for i = 1, 5 do
    RegisterCommand('qs-hotbar-' .. i, function()
        blockWheelBurst()
        requestUse(i)
    end, false)
    RegisterKeyMapping('qs-hotbar-' .. i, ('Use inventory slot %d'):format(i), 'keyboard', tostring(i))
end

local RADIAL_BLOCKED = { 1, 2, 14, 15, 16, 17, 24, 25, 37, 99, 100, 115, 116, 140, 141, 142, 257, 263 }

local function closeRadial()
    if not radialOpen then return end
    radialOpen = false
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    send('radial:close')
end

local function releaseRadial()
    if not radialOpen or radialReleased then return end
    radialReleased = true
    send('radial:release')
    SetTimeout(1000, function()
        if radialOpen and radialReleased then closeRadial() end
    end)
end

local function openRadial()
    blockWheelBurst()
    if radialOpen or isOpen or IsPauseMenuActive() or IsNuiFocused() then return end
    if exports['qs-core']:IsDead() then return end
    if not themeSent then sendTheme() end
    radialOpen = true
    radialReleased = false
    send('locale', Locales[GetConvar('qs:locale', 'en')] or Locales.en or {})
    send('radial:open', { items = radialItems() })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SetCursorLocation(0.5, 0.5)
    CreateThread(function()
        while radialOpen do
            BlockWeaponWheelThisFrame()
            HudWeaponWheelIgnoreSelection()
            for i = 1, #RADIAL_BLOCKED do DisableControlAction(0, RADIAL_BLOCKED[i], true) end
            if IsDisabledControlJustReleased(0, 37) then releaseRadial() end
            Wait(0)
        end
    end)
end

RegisterCommand('+qs-radial', openRadial, false)
RegisterCommand('-qs-radial', releaseRadial, false)
RegisterKeyMapping('+qs-radial', 'Item wheel', 'keyboard', Config.RadialKey)

RegisterNUICallback('radial:select', function(data, cb)
    cb('ok')
    closeRadial()
    local slot = tonumber(data and data.slot)
    if slot and slot >= 1 and slot <= Config.RadialSlots then requestUse(slot) end
end)

RegisterNUICallback('radial:close', function(_, cb)
    cb('ok')
    closeRadial()
end)

AddEventHandler('qs:client:onDeath', function()
    closeRadial()
    closeInventory()
end)

RegisterNUICallback('use', function(data, cb)
    requestUse(data.slot)
    cb('ok')
end)

RegisterNUICallback('drop', function(data, cb)
    TriggerServerEvent('qs-inv:server:drop', data.container or 'player', data.slot, tonumber(data.count) or 1)
    cb('ok')
end)

RegisterNUICallback('move', function(data, cb)
    TriggerServerEvent('qs-inv:server:move', data.fromContainer or 'player', data.from, data.toContainer or 'player', data.to)
    cb('ok')
end)

RegisterNUICallback('take', function(data, cb)
    TriggerServerEvent('qs-inv:server:take', data.slot, tonumber(data.count))
    cb('ok')
end)

RegisterNUICallback('split', function(data, cb)
    TriggerServerEvent('qs-inv:server:split', data.slot, tonumber(data.count), data.container)
    cb('ok')
end)

local function nearestPlayer()
    local me = PlayerPedId()
    local myCoords = GetEntityCoords(me)
    local target, best = nil, 3.5
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if ped ~= me and DoesEntityExist(ped) then
            local d = #(myCoords - GetEntityCoords(ped))
            if d < best then
                best = d
                target = GetPlayerServerId(pid)
            end
        end
    end
    return target
end

RegisterNUICallback('give', function(data, cb)
    local target = nearestPlayer()
    if target then
        TriggerServerEvent('qs-inv:server:give', target, data.slot, tonumber(data.count) or 1)
    else
        exports['qs-core']:Notify(T('no_player'), 'error')
    end
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    closeInventory()
    cb('ok')
end)

RegisterNetEvent('qs-inv:client:heal', function(amount)
    local ped = PlayerPedId()
    SetEntityHealth(ped, math.min(GetEntityHealth(ped) + amount, GetEntityMaxHealth(ped)))
end)

RegisterNetEvent('qs-inv:client:equip', function(weapon, ammo)
    local ped = PlayerPedId()
    local hash = joaat(weapon)
    if GetSelectedPedWeapon(ped) == hash then
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        return
    end
    if not HasPedGotWeapon(ped, hash, false) then
        GiveWeaponToPed(ped, hash, ammo or 0, false, false)
    end
    SetCurrentPedWeapon(ped, hash, true)
end)

exports('createQuest', function(...)
    return true
end)

AddEventHandler('qs:client:onPlayerLoaded', function()
    sendTheme()
    TriggerServerEvent('qs-inv:server:request')
end)

CreateThread(function()
    local paused = false
    while true do
        Wait(200)
        local active = IsPauseMenuActive()
        if active ~= paused then
            paused = active
            if active and isOpen then closeInventory() end
            if active and radialOpen then closeRadial() end
            send('paused', { on = active })
        end
    end
end)

CreateThread(function()
    Wait(500)
    sendTheme()
    TriggerServerEvent('qs-inv:server:request')
end)

CreateThread(function()
    while true do
        if IsControlPressed(0, 37) then
            BlockWeaponWheelThisFrame()
            Wait(0)
        else
            Wait(250)
        end
    end
end)
