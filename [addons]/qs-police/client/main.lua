local myJob = 'unemployed'
local uiOpen = false
local uiMode = nil
local isCuffed = false
local escortedBy = 0
local wasDead = false
local evidenceList = {}
local lastCasing = 0

local WEAPON_HASH_LABEL = {}
for name, label in pairs(Config.WeaponLabels) do
    WEAPON_HASH_LABEL[joaat(name)] = label
end

local function send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local function sendTheme()
    local colors = exports['qs-core']:GetColors()
    if colors then send('theme', colors) end
end

local function sendLocale()
    send('locale', Locales[GetConvar('qs:locale', 'en')] or Locales.en or {})
end

AddEventHandler('qs:client:colorsChanged', function() sendTheme() end)

local policeGarageBlip = nil
local function refreshPoliceBlips()
    if myJob == 'police' then
        if not (policeGarageBlip and DoesBlipExist(policeGarageBlip)) then
            local s = Config.Station
            policeGarageBlip = AddBlipForCoord(s.garage.x, s.garage.y, s.garage.z)
            SetBlipSprite(policeGarageBlip, 357)
            SetBlipColour(policeGarageBlip, 29)
            SetBlipScale(policeGarageBlip, 0.7)
            SetBlipAsShortRange(policeGarageBlip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName('Police Garage')
            EndTextCommandSetBlipName(policeGarageBlip)
        end
    elseif policeGarageBlip and DoesBlipExist(policeGarageBlip) then
        RemoveBlip(policeGarageBlip)
        policeGarageBlip = nil
    end
end

CreateThread(function()
    local s = Config.Station
    local blip = AddBlipForCoord(s.coords.x, s.coords.y, s.coords.z)
    SetBlipSprite(blip, s.blip.sprite or 60)
    SetBlipColour(blip, s.blip.color or 29)
    SetBlipScale(blip, s.blip.scale or 0.9)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(s.blip.label or 'Police')
    EndTextCommandSetBlipName(blip)
end)

local function trackJob(name)
    myJob = name or 'unemployed'
    refreshPoliceBlips()
    if myJob == 'police' then
        exports['qs-core']:RegisterStashZone('police_evidence', Config.Station.locker, { radius = 1.8 })
    else
        exports['qs-core']:RemoveStashZone('police_evidence')
    end
end

AddEventHandler('qs:client:onPlayerLoaded', function(data)
    trackJob(data and data.job and data.job.name)
    sendTheme()
    sendLocale()
end)

AddEventHandler('qs:client:onJobUpdate', function(job)
    trackJob(job and job.name)
end)

CreateThread(function()
    Wait(500)
    sendTheme()
    sendLocale()
    local data = exports['qs-core']:GetPlayerData()
    if data and data.job then trackJob(data.job.name) end
end)

local function helpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function nearestPlayer(maxDist)
    local me = PlayerPedId()
    local myCoords = GetEntityCoords(me)
    local target, best = nil, maxDist or Config.TargetDistance
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

local copActions = {}
local menuOpen = false
local MENU_MOVE = { 30, 31, 32, 33, 34, 35, 21, 22, 59, 60, 71, 72, 76 }

local function menuTarget()
    local id = nearestPlayer(Config.TargetDistance + 2.0)
    if not id then return nil end
    return { id = id, name = GetPlayerName(GetPlayerFromServerId(id)) }
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    send('menu:close')
end

local function openMenu()
    if menuOpen or uiOpen or myJob ~= 'police' then return end
    if IsPauseMenuActive() or IsNuiFocused() or exports['qs-core']:IsDead() then return end
    menuOpen = true
    sendTheme()
    sendLocale()
    local target = menuTarget()
    send('menu:open', { target = target })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    CreateThread(function()
        local lastId = target and target.id
        local nextCheck = 0
        while menuOpen do
            DisableAllControlActions(0)
            for i = 1, #MENU_MOVE do EnableControlAction(0, MENU_MOVE[i], true) end
            if IsDisabledControlJustReleased(0, 322) then closeMenu() break end
            if GetGameTimer() >= nextCheck then
                nextCheck = GetGameTimer() + 300
                if myJob ~= 'police' or exports['qs-core']:IsDead() then closeMenu() break end
                local t = menuTarget()
                local id = t and t.id
                if id ~= lastId then
                    lastId = id
                    send('menu:target', { target = t })
                end
            end
            Wait(0)
        end
    end)
end

RegisterCommand('policemenu', function()
    if menuOpen then closeMenu() else openMenu() end
end, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then closeMenu() end
end)
RegisterKeyMapping('policemenu', 'Police menu', 'keyboard', Config.MenuKey or 'F6')

RegisterNUICallback('menu:close', function(_, cb)
    cb('ok')
    closeMenu()
end)

RegisterNUICallback('menu:typing', function(data, cb)
    cb('ok')
    if menuOpen then SetNuiFocusKeepInput(not (data and data.on)) end
end)

RegisterNUICallback('menu:action', function(data, cb)
    cb('ok')
    if not menuOpen or not data or myJob ~= 'police' then return end
    local action = copActions[data.action]
    if not action then return end
    if data.action == 'search' then closeMenu() end
    action(type(data.args) == 'table' and data.args or {})
end)

local function openUI(data)
    if uiOpen or not data then return end
    if menuOpen then closeMenu() end
    uiOpen = true
    uiMode = data.mode
    SetNuiFocus(true, true)
    TriggerEvent('qs-corehud:display', false)
    sendTheme()
    sendLocale()
    send('open', data)
end

local function closeUI()
    if not uiOpen then return end
    uiOpen = false
    uiMode = nil
    SetNuiFocus(false, false)
    TriggerEvent('qs-corehud:display', true)
    send('close')
    TriggerServerEvent('qs-police:server:closeUI')
end

RegisterNetEvent('qs-police:client:openUI', function(data)
    openUI(data)
end)

RegisterNetEvent('qs-police:client:updateUI', function(data)
    if uiOpen and data and data.mode == uiMode then send('update', data) end
end)

RegisterNUICallback('take', function(data, cb)
    cb('ok')
    if data and data.name then TriggerServerEvent('qs-police:server:armoryTake', data.name) end
end)

RegisterNUICallback('confiscate', function(data, cb)
    cb('ok')
    if data and data.slot then TriggerServerEvent('qs-police:server:confiscate', data.slot) end
end)

RegisterNUICallback('analyze', function(data, cb)
    cb('ok')
    if not (data and data.slot) or uiMode ~= 'lab' then return end
    SetNuiFocus(false, false)
    CreateThread(function()
        local ok = exports['qs-core']:Progress({
            duration = 4000,
            label = T('analyzing'),
            canCancel = true,
            disableMovement = true,
        })
        if uiOpen then SetNuiFocus(true, true) end
        if ok then TriggerServerEvent('qs-police:server:analyze', data.slot) end
    end)
end)

local function spawnPoliceVehicle(model)
    local ok = false
    for _, v in ipairs(Config.Garage) do
        if v.model == model then ok = true break end
    end
    if not ok or myJob ~= 'police' then return end

    local s = Config.Station.garageSpawn
    if IsAnyVehicleNearPoint(s.x, s.y, s.z, 3.0) then
        exports['qs-core']:Notify(T('garage_blocked'), 'error')
        return
    end
    local hash = joaat(model)
    RequestModel(hash)
    local dl = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < dl do Wait(10) end
    if not HasModelLoaded(hash) then return end
    local veh = CreateVehicle(hash, s.x, s.y, s.z, s.w or 0.0, true, false)
    SetVehicleOnGroundProperly(veh)
    SetVehicleFuelLevel(veh, 100.0)
    if GetResourceState('qs-corevehiclekeys') == 'started' then
        exports['qs-corevehiclekeys']:GiveKeys(GetVehicleNumberPlateText(veh))
    end
    SetModelAsNoLongerNeeded(hash)
end

local function storePoliceVehicle(veh)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= PlayerPedId() then
        exports['qs-core']:Notify(T('garage_not_driver'), 'error')
        return
    end
    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
    exports['qs-core']:Notify(T('vehicle_stored'), 'success')
end

RegisterNUICallback('spawn', function(data, cb)
    cb('ok')
    closeUI()
    if data and data.model then spawnPoliceVehicle(data.model) end
end)

RegisterNUICallback('close', function(_, cb)
    cb('ok')
    closeUI()
end)

CreateThread(function()
    local s = Config.Station
    local points = {
        { kind = 'armory', coords = vector3(s.armory.x, s.armory.y, s.armory.z), help = 'help_armory' },
        { kind = 'lab',    coords = vector3(s.lab.x, s.lab.y, s.lab.z),          help = 'help_lab' },
        { kind = 'garage', coords = vector3(s.garage.x, s.garage.y, s.garage.z), help = 'help_garage' },
    }
    while true do
        local sleep = 1000
        if not uiOpen then
            local coords = GetEntityCoords(PlayerPedId())
            local nearest = 9999.0
            for _, p in ipairs(points) do
                local d = #(coords - p.coords)
                if d < nearest then nearest = d end
                if d < Config.InteractDistance then
                    sleep = 0
                    if myJob ~= 'police' then
                        helpText(T('need_job'))
                    elseif p.kind == 'garage' and GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then
                        helpText(T('help_store'))
                        if IsControlJustPressed(0, Config.Control) then
                            storePoliceVehicle(GetVehiclePedIsIn(PlayerPedId(), false))
                        end
                    else
                        helpText(T(p.help))
                        if IsControlJustPressed(0, Config.Control) then
                            if p.kind == 'armory' then
                                local list = {}
                                for _, e in ipairs(Config.Armory) do
                                    local def = exports['qs-core']:GetItem(e.name)
                                    list[#list + 1] = { name = e.name, label = (def and def.label) or e.name, count = e.count }
                                end
                                openUI({ mode = 'armory', items = list })
                            elseif p.kind == 'lab' then
                                TriggerServerEvent('qs-police:server:openLab')
                            elseif p.kind == 'garage' then
                                openUI({ mode = 'garage', vehicles = Config.Garage })
                            end
                        end
                    end
                    break
                end
            end
            if sleep ~= 0 then sleep = nearest > 40.0 and 1500 or 300 end
        end
        Wait(sleep)
    end
end)

local function copCommand(name, handler, suggestion, params)
    copActions[name] = handler
    RegisterCommand(name, function(_, args)
        if myJob ~= 'police' then
            exports['qs-core']:Notify(T('need_job'), 'error')
            return
        end
        handler(args)
    end, false)
    TriggerEvent('chat:addSuggestion', '/' .. name, suggestion, params or {})
end

CreateThread(function()
    Wait(1000)

    copCommand('cuff', function()
        local target = nearestPlayer()
        if target then TriggerServerEvent('qs-police:server:cuff', target)
        else exports['qs-core']:Notify(T('no_player'), 'error') end
    end, T('sug_cuff'))

    copCommand('escort', function()
        local target = nearestPlayer()
        if target then TriggerServerEvent('qs-police:server:escort', target)
        else exports['qs-core']:Notify(T('no_player'), 'error') end
    end, T('sug_escort'))

    copCommand('putincar', function()
        local target = nearestPlayer(Config.TargetDistance + 2.0)
        if target then TriggerServerEvent('qs-police:server:putInCar', target)
        else exports['qs-core']:Notify(T('no_player'), 'error') end
    end, T('sug_putincar'))

    copCommand('outcar', function()
        local target = nearestPlayer(Config.TargetDistance + 2.0)
        if target then TriggerServerEvent('qs-police:server:outCar', target)
        else exports['qs-core']:Notify(T('no_player'), 'error') end
    end, T('sug_outcar'))

    copCommand('search', function()
        local target = nearestPlayer()
        if target then TriggerServerEvent('qs-police:server:search', target)
        else exports['qs-core']:Notify(T('no_player'), 'error') end
    end, T('sug_search'))

    copCommand('fine', function(args)
        local amount = tonumber(args[1])
        if not amount then
            exports['qs-core']:Notify(T('fine_usage'), 'error')
            return
        end
        local reason = table.concat(args, ' ', 2)
        local target = nearestPlayer(5.0)
        if target then TriggerServerEvent('qs-police:server:fine', target, amount, reason)
        else exports['qs-core']:Notify(T('no_player'), 'error') end
    end, T('sug_fine'), { { name = 'amount', help = '$' }, { name = 'reason', help = '...' } })

    copCommand('impound', function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
        if veh ~= 0 and DoesEntityExist(veh) then
            SetEntityAsMissionEntity(veh, true, true)
            DeleteVehicle(veh)
            exports['qs-core']:Notify(T('impounded'), 'success')
        else
            exports['qs-core']:Notify(T('no_vehicle'), 'error')
        end
    end, T('sug_impound'))
end)

RegisterNetEvent('qs-police:client:cuffed', function(state)
    isCuffed = state
    local ped = PlayerPedId()
    if state then
        RequestAnimDict('mp_arresting')
        local dl = GetGameTimer() + 2000
        while not HasAnimDictLoaded('mp_arresting') and GetGameTimer() < dl do Wait(10) end
        SetEnableHandcuffs(ped, true)
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        CreateThread(function()
            while isCuffed do
                Wait(0)
                local p = PlayerPedId()
                if not IsEntityPlayingAnim(p, 'mp_arresting', 'idle', 3) and not IsEntityDead(p) then
                    TaskPlayAnim(p, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0.0, false, false, false)
                end
                DisableControlAction(0, 21, true)
                DisableControlAction(0, 22, true)
                DisableControlAction(0, 23, true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 37, true)
                DisableControlAction(0, 44, true)
                DisableControlAction(0, 45, true)
                DisableControlAction(0, 58, true)
                DisableControlAction(0, 75, true)
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
                DisableControlAction(0, 143, true)
                DisableControlAction(0, 257, true)
                DisableControlAction(0, 263, true)
                DisableControlAction(0, 264, true)
            end
        end)
    else
        SetEnableHandcuffs(ped, false)
        ClearPedTasks(ped)
        StopAnimTask(ped, 'mp_arresting', 'idle', 3.0)
    end
end)

RegisterNetEvent('qs-police:client:escorted', function(officer)
    escortedBy = officer or 0
    local ped = PlayerPedId()
    if escortedBy > 0 then
        local oped = GetPlayerPed(GetPlayerFromServerId(escortedBy))
        if oped ~= 0 and DoesEntityExist(oped) then
            AttachEntityToEntity(ped, oped, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
            CreateThread(function()
                while escortedBy > 0 do
                    Wait(500)
                    local o = GetPlayerPed(GetPlayerFromServerId(escortedBy))
                    if o == 0 or not DoesEntityExist(o) then
                        escortedBy = 0
                        DetachEntity(PlayerPedId(), true, false)
                    end
                end
            end)
        end
    else
        DetachEntity(ped, true, false)
    end
end)

RegisterNetEvent('qs-police:client:putInCar', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 8.0, 0, 71)
    if veh == 0 or not DoesEntityExist(veh) then return end
    if escortedBy > 0 then
        escortedBy = 0
        DetachEntity(ped, true, false)
    end
    for _, seat in ipairs({ 1, 2, 0 }) do
        if IsVehicleSeatFree(veh, seat) then
            TaskWarpPedIntoVehicle(ped, veh, seat)
            return
        end
    end
end)

RegisterNetEvent('qs-police:client:outCar', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then TaskLeaveVehicle(ped, veh, 16) end
end)

RegisterNetEvent('qs-police:client:useArmor', function()
    local ok = exports['qs-core']:Progress({
        duration = 3000,
        label = T('equipping_armor'),
        disableMovement = true,
    })
    if ok ~= false then
        SetPedArmour(PlayerPedId(), 100)
        exports['qs-core']:Notify(T('armor_on'), 'success')
    end
end)

CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        if IsPedArmed(ped, 6) then
            wait = 0
            if IsPedShooting(ped) and GetGameTimer() - lastCasing > Config.Evidence.casingCooldown then
                lastCasing = GetGameTimer()
                local hit, impact = GetPedLastWeaponImpactCoord(ped)
                local c = (hit and impact) or GetEntityCoords(ped)
                local label = WEAPON_HASH_LABEL[GetSelectedPedWeapon(ped)] or 'Unknown firearm'
                TriggerServerEvent('qs-police:server:casing', { x = c.x, y = c.y, z = c.z }, label)
            end
        end
        Wait(wait)
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        local dead = IsEntityDead(PlayerPedId())
        if dead and not wasDead then
            wasDead = true
            TriggerServerEvent('qs-police:server:blood')
        elseif not dead and wasDead then
            wasDead = false
        end
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        if myJob == 'police' then
            TriggerServerEvent('qs-police:server:requestEvidence')
        elseif next(evidenceList) then
            evidenceList = {}
        end
    end
end)

RegisterNetEvent('qs-police:client:evidence', function(list)
    evidenceList = list or {}
end)

RegisterNetEvent('qs-police:client:evidenceRemoved', function(id)
    for i, e in ipairs(evidenceList) do
        if e.id == id then
            table.remove(evidenceList, i)
            break
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 800
        if myJob == 'police' and #evidenceList > 0 and not uiOpen then
            local coords = GetEntityCoords(PlayerPedId())
            local nearest, bestDist = nil, Config.Evidence.collectDistance
            for _, e in ipairs(evidenceList) do
                local c = vector3(e.coords.x, e.coords.y, e.coords.z)
                local d = #(coords - c)
                if d < Config.Evidence.viewDistance then
                    sleep = 0
                    local r, g = 240, 200
                    if e.type == 'blood' then r, g = 220, 60 end
                    if not e.groundZ then
                        local found, gz = GetGroundZFor_3dCoord(c.x, c.y, c.z + 1.0, false)
                        if found then e.groundZ = gz end
                    end
                    DrawMarker(25, c.x, c.y, (e.groundZ or c.z) + 0.02, 0, 0, 0, 0, 0, 0, 0.35, 0.35, 0.35, r, g, 60, 160, false, true, 2, false, nil, nil, false)
                end
                if d < bestDist then
                    bestDist = d
                    nearest = e
                end
            end
            if nearest then
                helpText(nearest.type == 'blood' and T('help_blood') or T('help_casing'))
                if IsControlJustPressed(0, Config.Control) and not exports['qs-core']:IsBusy() then
                    if exports['qs-core']:GetItemCount('evidence_bag') < 1 then
                        exports['qs-core']:Notify(T('need_bag'), 'error')
                    else
                        local ped = PlayerPedId()
                        local dict = 'amb@medic@standing@kneel@base'
                        RequestAnimDict(dict)
                        local adl = GetGameTimer() + 1000
                        while not HasAnimDictLoaded(dict) and GetGameTimer() < adl do Wait(10) end
                        TaskPlayAnim(ped, dict, 'base', 4.0, -4.0, -1, 1, 0, false, false, false)
                        local ok = exports['qs-core']:Progress({
                            duration = 3000,
                            label = T('collecting'),
                            canCancel = true,
                            disableMovement = true,
                        })
                        StopAnimTask(ped, dict, 'base', 1.0)
                        ClearPedTasks(ped)
                        RemoveAnimDict(dict)
                        if ok then TriggerServerEvent('qs-police:server:collect', nearest.id) end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('qs-police:client:alert', function(coords, label)
    exports['qs-core']:Notify(label or T('alert_shots'), 'error', 6000)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.2)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label or T('alert_shots'))
    EndTextCommandSetBlipName(blip)
    SetTimeout(Config.Evidence.alertDuration, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)

CreateThread(function()
    local paused = false
    while true do
        Wait(500)
        local active = IsPauseMenuActive()
        if active ~= paused then
            paused = active
            send('paused', { on = active })
        end
    end
end)
