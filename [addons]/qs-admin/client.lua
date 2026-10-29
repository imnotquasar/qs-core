local core = exports['qs-core']

local menuOpen = false
local godmode = false
local invisible = false
local spectating = false
local timeFreeze = nil

local weatherNames = {}
for _, w in ipairs(Config.Weathers) do weatherNames[joaat(w)] = w end

local function send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local function currentStates()
    return { godmode = godmode, invisible = invisible, noclip = core:IsNoclipActive(), timeFrozen = timeFreeze ~= nil }
end

local function sendTheme()
    local colors = core:GetColors()
    if colors then send('theme', colors) end
end

local function sendLocale()
    send('locale', Locales[GetConvar('qs:locale', 'en')] or Locales.en or {})
end

AddEventHandler('qs:client:colorsChanged', function() if menuOpen then sendTheme() end end)

local function refreshPlayers()
    core:TriggerCallback('qs-admin:players', function(list)
        if menuOpen then send('players', { players = list or {} }) end
    end)
end

local function openMenu()
    if menuOpen then return end
    core:TriggerCallback('qs-admin:isAllowed', function(allowed)
        if not allowed then
            core:Notify(T('no_perm'), 'error')
            return
        end
        menuOpen = true
        SetNuiFocus(true, true)
        sendTheme()
        sendLocale()
        send('open', {
            weathers = Config.Weathers,
            groups = Config.Groups,
            vehicle = godmode,
            states = currentStates(),
        })
        refreshPlayers()
    end)
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    send('close')
end

RegisterNetEvent('qs-admin:client:open', openMenu)

RegisterNUICallback('close', function(_, cb) cb('ok') closeMenu() end)
RegisterNUICallback('refresh', function(_, cb) cb('ok') refreshPlayers() end)

RegisterNUICallback('action', function(data, cb)
    cb('ok')
    if not data or not data.action then return end
    TriggerServerEvent('qs-admin:action', data.action, data.target, data.data or {})
    if data.action == 'goto' or data.action == 'spectate' then closeMenu() end
end)

local function fixVehicle()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then core:Notify(T('no_vehicle'), 'error') return end
    SetVehicleFixed(veh)
    SetVehicleDeformationFixed(veh)
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehicleDirtLevel(veh, 0.0)
    core:Notify(T('veh_fixed'), 'success')
end

local function removeStuckVehicles(ped, spawnPos)
    local me = GetEntityCoords(ped)
    local current = GetVehiclePedIsIn(ped, false)
    for _, v in ipairs(GetGamePool('CVehicle')) do
        local pos = GetEntityCoords(v)
        if v == current or #(pos - me) < 3.0 or #(pos - spawnPos) < 3.0 then
            local occupied = false
            for seat = -1, GetVehicleMaxNumberOfPassengers(v) - 1 do
                local p = GetPedInVehicleSeat(v, seat)
                if p ~= 0 and p ~= ped and IsPedAPlayer(p) then occupied = true break end
            end
            if not occupied then
                NetworkRequestControlOfEntity(v)
                local dl = GetGameTimer() + 500
                while not NetworkHasControlOfEntity(v) and GetGameTimer() < dl do Wait(0) end
                SetEntityAsMissionEntity(v, true, true)
                DeleteVehicle(v)
            end
        end
    end
end

local function spawnVehicle(model)
    if not model or model == '' then return end
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        core:Notify(T('bad_model'), 'error')
        return
    end
    RequestModel(hash)
    local dl = GetGameTimer() + 6000
    while not HasModelLoaded(hash) and GetGameTimer() < dl do Wait(10) end
    if not HasModelLoaded(hash) then return end
    local ped = PlayerPedId()
    local c = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.0, 0.0)
    removeStuckVehicles(ped, c)
    local veh = CreateVehicle(hash, c.x, c.y, c.z, GetEntityHeading(ped), true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleFuelLevel(veh, 100.0)
    SetPedIntoVehicle(ped, veh, -1)
    SetModelAsNoLongerNeeded(hash)
    if GetResourceState('qs-corevehiclekeys') == 'started' then
        exports['qs-corevehiclekeys']:GiveKeys(GetVehicleNumberPlateText(veh))
    end
    core:Notify(T('veh_spawned'), 'success')
end

local function deleteVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local c = GetEntityCoords(ped)
        veh = GetClosestVehicle(c.x, c.y, c.z, 6.0, 0, 71)
    end
    if veh ~= 0 and DoesEntityExist(veh) then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
        core:Notify(T('veh_deleted'), 'success')
    end
end

local function clearArea()
    local c = GetEntityCoords(PlayerPedId())
    ClearAreaOfVehicles(c.x, c.y, c.z, 30.0, false, false, false, false, false)
    ClearAreaOfObjects(c.x, c.y, c.z, 30.0, 0)
    core:Notify(T('area_cleared'), 'success')
end

local function setGodmode(state)
    godmode = state
    local ped = PlayerPedId()
    SetEntityInvincible(ped, godmode)
    SetPlayerInvincible(PlayerId(), godmode)
    if godmode then
        CreateThread(function()
            while godmode do
                Wait(300)
                local p = PlayerPedId()
                SetEntityInvincible(p, true)
                SetPlayerInvincible(PlayerId(), true)
                ClearPedBloodDamage(p)
            end
        end)
    end
end

local function setInvisible(state)
    invisible = state
    SetEntityVisible(PlayerPedId(), not invisible, false)
end

RegisterNUICallback('self', function(data, cb)
    cb('ok')
    if not data or not data.what then return end
    local w = data.what
    if w == 'noclip' then
        closeMenu()
        core:ToggleNoclip()
        return
    elseif w == 'godmode' then setGodmode(not godmode)
    elseif w == 'invisible' then setInvisible(not invisible)
    elseif w == 'tpm' then closeMenu() TriggerEvent('qs:client:tpm')
    elseif w == 'fixveh' then fixVehicle()
    elseif w == 'spawnveh' then spawnVehicle(data.data and data.data.model)
    elseif w == 'delveh' then deleteVehicle()
    elseif w == 'cleararea' then clearArea()
    elseif w == 'freezetime' then
        TriggerServerEvent('qs-admin:action', 'freezetime', nil, {
            hour = GetClockHours(),
            minute = GetClockMinutes(),
            weather = weatherNames[GetPrevWeatherTypeHashName()],
        })
    end
    send('states', currentStates())
end)

RegisterNetEvent('qs-admin:client:teleport', function(c)
    if not c then return end
    local ped = PlayerPedId()
    DoScreenFadeOut(200)
    local t = GetGameTimer()
    while not IsScreenFadedOut() and GetGameTimer() - t < 800 do Wait(0) end
    SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
    if c.w then SetEntityHeading(ped, c.w) end
    local dl = GetGameTimer() + 2000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < dl do
        RequestCollisionAtCoord(c.x, c.y, c.z)
        Wait(0)
    end
    DoScreenFadeIn(300)
end)

RegisterNetEvent('qs-admin:client:heal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    core:Notify(T('healed'), 'success')
end)

RegisterNetEvent('qs-admin:client:freeze', function(state)
    FreezeEntityPosition(PlayerPedId(), state == true)
    core:Notify(state and T('you_frozen') or T('you_unfrozen'), 'info')
end)

RegisterNetEvent('qs-admin:client:giveweapon', function(weapon, ammo)
    GiveWeaponToPed(PlayerPedId(), joaat(weapon), ammo or 250, false, false)
    core:Notify(T('got_weapon'), 'success')
end)

RegisterNetEvent('qs-admin:client:announce', function(message)
    if not message or message == '' then return end
    send('announce', { message = message })
    if not menuOpen then
        CreateThread(function()
            SetNuiFocus(false, false)
        end)
    end
end)

RegisterNetEvent('qs-admin:client:weather', function(weather)
    SetOverrideWeather(weather)
    SetWeatherTypeOverTime(weather, 5.0)
    CreateThread(function()
        Wait(6000)
        ClearWeatherTypePersist()
        SetWeatherTypePersist(weather)
        SetWeatherTypeNow(weather)
    end)
end)

RegisterNetEvent('qs-admin:client:time', function(hour, minute)
    NetworkOverrideClockTime(hour, minute or 0, 0)
end)

local function holdTimeFreeze()
    CreateThread(function()
        PauseClock(true)
        while timeFreeze do
            NetworkOverrideClockTime(timeFreeze.hour, timeFreeze.minute, 0)
            if timeFreeze.weather then
                SetOverrideWeather(timeFreeze.weather)
                SetWeatherTypeNowPersist(timeFreeze.weather)
            end
            Wait(1000)
        end
        PauseClock(false)
        ClearOverrideWeather()
    end)
end

local function setTimeFreeze(value)
    local wasFrozen = timeFreeze ~= nil
    timeFreeze = value
    if value and not wasFrozen then holdTimeFreeze() end
    if menuOpen then send('states', currentStates()) end
end

AddStateBagChangeHandler('qsFreezeTime', 'global', function(_, _, value) setTimeFreeze(value) end)
CreateThread(function() if GlobalState.qsFreezeTime then setTimeFreeze(GlobalState.qsFreezeTime) end end)

local function stopSpectate()
    if not spectating then return end
    spectating = false
    NetworkSetInSpectatorMode(false, PlayerPedId())
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    if not godmode then SetEntityInvincible(ped, false) end
    core:Notify(T('spec_off'), 'info')
end

RegisterNetEvent('qs-admin:client:spectate', function(targetId, coords)
    if spectating then stopSpectate() return end
    local ped = PlayerPedId()
    if coords then
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    end
    local dl = GetGameTimer() + 3000
    local tped = 0
    while GetGameTimer() < dl do
        tped = GetPlayerPed(GetPlayerFromServerId(targetId))
        if tped ~= 0 and DoesEntityExist(tped) then break end
        Wait(50)
    end
    if tped == 0 or not DoesEntityExist(tped) then
        core:Notify(T('spec_fail'), 'error')
        return
    end
    spectating = true
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    NetworkSetInSpectatorMode(true, tped)
    core:Notify(T('spec_on'), 'primary', 5000)
    CreateThread(function()
        while spectating do
            Wait(0)
            if IsControlJustPressed(0, 194) or IsControlJustPressed(0, 202) then stopSpectate() break end
            local t = GetPlayerPed(GetPlayerFromServerId(targetId))
            if t == 0 or not DoesEntityExist(t) then stopSpectate() break end
        end
    end)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if spectating then stopSpectate() end
    if godmode then setGodmode(false) end
    if invisible then setInvisible(false) end
    if timeFreeze then
        timeFreeze = nil
        PauseClock(false)
        ClearOverrideWeather()
    end
end)
