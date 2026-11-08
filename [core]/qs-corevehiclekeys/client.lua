local core = exports['qs-core']

local keys = {}
local ownsChecked = {}
local hotwiring = false
local mySrc = -1

local function trim(s) return s and s:match('^%s*(.-)%s*$') or s end

AddEventHandler('qs:client:onPlayerLoaded', function() mySrc = GetPlayerServerId(PlayerId()) end)
CreateThread(function() Wait(500) mySrc = GetPlayerServerId(PlayerId()) end)

local function hasKeys(plate) return plate ~= nil and keys[trim(plate)] == true end
local function giveKeys(plate) if plate then keys[trim(plate)] = true end end
local function removeKeys(plate) if plate then keys[trim(plate)] = nil end end

exports('GiveKeys', function(plate) giveKeys(plate) end)
exports('RemoveKeys', function(plate) removeKeys(plate) end)
exports('HasKeys', function(plate) return hasKeys(plate) end)
exports('GetKeys', function() return keys end)

RegisterNetEvent('vehiclekeys:client:SetOwner', function(plate) giveKeys(plate) end)
RegisterNetEvent('qs-corevehiclekeys:client:give', function(plate) giveKeys(plate) end)
RegisterNetEvent('qs-corevehiclekeys:client:remove', function(plate) removeKeys(plate) end)

local function helpText(msg, duration)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, false, duration or -1)
end

local function currentVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then return veh end
    local c = GetEntityCoords(ped)
    veh = GetClosestVehicle(c.x, c.y, c.z, Config.LockDistance, 0, 71)
    return (veh ~= 0 and DoesEntityExist(veh)) and veh or nil
end

local function nearestPlayer(maxDist)
    local me = PlayerPedId()
    local mc = GetEntityCoords(me)
    local target, best = nil, maxDist or 5.0
    for _, pid in ipairs(GetActivePlayers()) do
        local p = GetPlayerPed(pid)
        if p ~= me and DoesEntityExist(p) then
            local d = #(mc - GetEntityCoords(p))
            if d < best then best = d target = GetPlayerServerId(pid) end
        end
    end
    return target
end

local function lockAnim()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end
    RequestAnimDict('anim@mp_player_intmenu@key_fob@')
    local dl = GetGameTimer() + 1000
    while not HasAnimDictLoaded('anim@mp_player_intmenu@key_fob@') and GetGameTimer() < dl do Wait(10) end
    TaskPlayAnim(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 4.0, -4.0, -1, 48, 0, false, false, false)
    CreateThread(function() Wait(900) StopAnimTask(ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 2.0) end)
end

local function toggleLock()
    local veh = currentVehicle()
    if not veh then return end
    local plate = trim(GetVehicleNumberPlateText(veh))
    if not hasKeys(plate) then
        core:Notify(T('no_keys'), 'error', 2500)
        return
    end
    local locked = GetVehicleDoorLockStatus(veh) == 2
    local state = locked and 1 or 2
    SetVehicleDoorsLocked(veh, state)
    lockAnim()
    SetVehicleLights(veh, 2)
    CreateThread(function() Wait(250) SetVehicleLights(veh, 0) end)
    TriggerServerEvent('qs-corevehiclekeys:server:lockState', VehToNet(veh), state)
    core:Notify(locked and T('unlocked') or T('locked'), 'primary', 1500)
end

RegisterCommand('vehlock', toggleLock, false)
RegisterKeyMapping('vehlock', 'Lock / unlock vehicle', 'keyboard', Config.LockKey)

RegisterNetEvent('qs-corevehiclekeys:client:lockState', function(netId, state, setter)
    if setter == mySrc then return end
    local veh = NetToVeh(netId)
    if veh and DoesEntityExist(veh) then SetVehicleDoorsLocked(veh, state) end
end)

RegisterCommand('givekeys', function(_, args)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then core:Notify(T('not_in_veh'), 'error') return end
    local plate = trim(GetVehicleNumberPlateText(veh))
    if not hasKeys(plate) then core:Notify(T('no_keys'), 'error') return end
    local target = tonumber(args[1]) or nearestPlayer(Config.GiveDistance)
    if not target then core:Notify(T('no_player'), 'error') return end
    TriggerServerEvent('qs-corevehiclekeys:server:giveTo', target, plate)
    core:Notify(T('keys_shared'), 'success')
end, false)

CreateThread(function()
    Wait(800)
    TriggerEvent('chat:addSuggestion', '/givekeys', T('sug_givekeys'), { { name = T('arg_id') } })
    TriggerEvent('chat:addSuggestion', '/adminkeys', T('sug_adminkeys'), { { name = T('arg_id') } })
end)

local function ensureOwnership(plate)
    if not Config.AutoKeysForOwned or ownsChecked[plate] then return end
    ownsChecked[plate] = true
    core:TriggerCallback('qs-corevehiclekeys:owns', function(owns)
        if owns then giveKeys(plate) end
    end, plate)
end

local function hasLockpick()
    return exports['qs-core']:GetItemCount(Config.HotwireItem) > 0
end

local function hotwire(veh, plate)
    if hotwiring then return end
    hotwiring = true
    local ok = core:Lockpick(Config.HotwireRounds or 3)
    hotwiring = false
    if ok then
        giveKeys(plate)
        SetVehicleEngineOn(veh, true, true, false)
        core:Notify(T('hotwire_ok'), 'success')
    else
        if Config.BreakLockpickOnFail then TriggerServerEvent('qs-corevehiclekeys:server:breakLockpick') end
        SetVehicleAlarm(veh, true)
        StartVehicleAlarm(veh)
        TriggerServerEvent('qs-corevehiclekeys:server:lockpickFail')
        core:Notify(T('hotwire_fail'), 'error')
    end
end

local blockedVeh = nil

RegisterCommand('hotwire', function()
    local veh = blockedVeh
    if not veh or hotwiring or GetVehiclePedIsIn(PlayerPedId(), false) ~= veh then return end
    if not hasLockpick() then return end
    CreateThread(function() hotwire(veh, trim(GetVehicleNumberPlateText(veh))) end)
end, false)
RegisterKeyMapping('hotwire', 'Hotwire vehicle', 'keyboard', Config.HotwireKey)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local keyless = nil
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local plate = trim(GetVehicleNumberPlateText(veh))
            if not hasKeys(plate) then
                ensureOwnership(plate)
                if not hasKeys(plate) and Config.RequireKeysToDrive then keyless = veh end
            end
        end

        if keyless then
            if blockedVeh ~= keyless or GetIsVehicleEngineRunning(keyless) then
                SetVehicleEngineOn(keyless, false, true, true)
            end
            if not hotwiring then
                helpText(hasLockpick() and T('hotwire_prompt') or T('no_keys_veh'), 1000)
            end
        elseif blockedVeh and blockedVeh == veh and DoesEntityExist(veh) then
            SetVehicleEngineOn(veh, GetIsVehicleEngineRunning(veh), true, false)
        end
        blockedVeh = keyless
        if keyless then
            DisableControlAction(0, 71, true)
            DisableControlAction(0, 72, true)
            Wait(0)
        else
            Wait(500)
        end
    end
end)
