QS.isLoaded = false

function QS.GetPlayerData()
    return QS.PlayerData
end

exports('GetPlayerData', QS.GetPlayerData)

local function applyClientColors(palette)
    if type(palette) ~= 'table' then return false end
    QS.ClientColors = palette
    SendNUIMessage({ action = 'theme', data = palette })
    TriggerEvent('qs:client:colorsChanged', palette)
    return true
end

exports('SetClientColors', applyClientColors)

CreateThread(function()
    TriggerServerEvent('qs:colors:request')
end)

RegisterNetEvent('qs:colors:load', function(palette)
    QS.HasSavedColors = type(palette) == 'table'
    if QS.HasSavedColors then applyClientColors(palette) end
    TriggerEvent('qs:client:colorsResolved', QS.HasSavedColors)
end)

exports('HasSavedColors', function() return QS.HasSavedColors == true end)

RegisterNetEvent('qs:client:playerLoaded', function(data)
    QS.PlayerData = data
    QS.isLoaded = true

    DoScreenFadeOut(250)
    Wait(250)

    if GetResourceState('qs-clothing') == 'started' then
        exports['qs-clothing']:ApplyAppearance(data.skin, data.charinfo and data.charinfo.sex)
    end

    local pos = data.position or Config.DefaultSpawn
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
    SetEntityHeading(ped, pos.w or 0.0)
    SetEntityVisible(ped, true, false)
    SetEntityAlpha(ped, 0, false)

    RenderScriptCams(false, false, 0, true, false)
    NewLoadSceneStartSphere(pos.x, pos.y, pos.z, 60.0, 0)
    local dl = GetGameTimer() + 8000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < dl do
        RequestCollisionAtCoord(pos.x, pos.y, pos.z)
        Wait(0)
    end
    if IsNewLoadSceneActive() then NewLoadSceneStop() end
    FreezeEntityPosition(ped, false)

    TriggerEvent('qs:client:onPlayerLoaded', data)

    ShutdownLoadingScreen()
    Wait(200)
    DoScreenFadeIn(500)

    CreateThread(function()
        local elapsed = 0.0
        while elapsed < 250.0 and DoesEntityExist(ped) do
            Wait(0)
            elapsed = elapsed + GetFrameTime() * 1000.0
            local t = elapsed / 250.0
            if t > 1.0 then t = 1.0 end
            SetEntityAlpha(ped, math.floor(255 * t), false)
        end
        if DoesEntityExist(ped) then ResetEntityAlpha(ped) end
    end)

    Utils.Info(('Character loaded: %s'):format(data.citizenid))
end)

RegisterNetEvent('qs:client:playerUnloaded', function()
    QS.isLoaded = false
    QS.PlayerData = nil
    TriggerEvent('qs:client:onPlayerUnloaded')
end)

RegisterNetEvent('qs:gang:set', function(gang)
    QS.PlayerData = QS.PlayerData or {}
    QS.PlayerData.gang = gang
    if QS.PlayerData.metadata then QS.PlayerData.metadata.gang = gang end
    TriggerEvent('qs:client:onGangUpdate', gang)
end)

RegisterNetEvent('qs:client:setDuty', function(onDuty)
    QS.PlayerData = QS.PlayerData or {}
    if QS.PlayerData.job then QS.PlayerData.job.onduty = onDuty and true or false end
    if QS.PlayerData.metadata then QS.PlayerData.metadata.onduty = onDuty and true or false end
    TriggerEvent('qs:client:onDutyUpdate', onDuty)
end)

RegisterNetEvent('qs:job:set', function(job)
    QS.PlayerData.job = job
    TriggerEvent('qs:client:onJobUpdate', job)
end)

RegisterNetEvent('qs:money:add', function(account, amount)
    QS.PlayerData.money = QS.PlayerData.money or {}
    QS.PlayerData.money[account] = (QS.PlayerData.money[account] or 0) + amount
end)

RegisterNetEvent('qs:money:remove', function(account, amount)
    QS.PlayerData.money = QS.PlayerData.money or {}
    QS.PlayerData.money[account] = (QS.PlayerData.money[account] or 0) - amount
end)

RegisterNetEvent('qs:money:set', function(account, amount)
    QS.PlayerData.money = QS.PlayerData.money or {}
    QS.PlayerData.money[account] = amount
end)

RegisterNetEvent('qs:metadata:set', function(key, value)
    QS.PlayerData.metadata = QS.PlayerData.metadata or {}
    QS.PlayerData.metadata[key] = value
end)

RegisterNetEvent('qs:client:notify', function(message, nType, duration, title)
    SendNUIMessage({
        action = 'notify',
        data = { message = message, type = nType or 'info', duration = duration or 4000, title = title },
    })
end)

exports('Notify', function(message, nType, duration, title)
    TriggerEvent('qs:client:notify', message, nType, duration, title)
end)

local progressActive = false
local progressCancelled = false

exports('Progress', function(data)
    if progressActive then return false end
    data = data or {}
    local duration = tonumber(data.duration) or 3000

    progressActive = true
    progressCancelled = false
    SendNUIMessage({ action = 'progress:start', data = { duration = duration, label = data.label or '' } })

    local endTime = GetGameTimer() + duration
    while GetGameTimer() < endTime and not progressCancelled do
        Wait(0)
        if data.disableMovement then
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 44, true)
        end
        if data.canCancel and IsControlJustReleased(0, 73) then
            progressCancelled = true
        end
    end

    local completed = not progressCancelled
    if not completed then
        SendNUIMessage({ action = 'progress:cancel' })
    end
    progressActive = false
    return completed
end)

exports('CancelProgress', function()
    progressCancelled = true
end)

exports('IsBusy', function()
    return progressActive
end)

local lockpickActive = false
local lockpickResult = nil

exports('Lockpick', function(rounds)
    if lockpickActive then return false end
    rounds = math.max(1, math.min(6, tonumber(rounds) or 3))
    lockpickActive = true
    lockpickResult = nil
    SendNUIMessage({ action = 'lockpick:start', data = { rounds = rounds } })

    local timeout = GetGameTimer() + 30000
    while lockpickResult == nil and GetGameTimer() < timeout do
        Wait(0)
        DisableControlAction(0, 22, true)
        if IsDisabledControlJustPressed(0, 22) then
            SendNUIMessage({ action = 'lockpick:lock' })
        elseif IsControlJustPressed(0, 177) or IsControlJustPressed(0, 194) or IsControlJustPressed(0, 200) then
            SendNUIMessage({ action = 'lockpick:cancel' })
            lockpickResult = false
        end
    end

    if lockpickResult == nil then
        SendNUIMessage({ action = 'lockpick:cancel' })
        lockpickResult = false
    end
    lockpickActive = false
    local r = lockpickResult == true
    lockpickResult = nil
    return r
end)

RegisterNUICallback('lockpick:done', function(data, cb)
    cb('ok')
    lockpickResult = (data and data.success) == true
end)

RegisterNUICallback('uiReady', function(_, cb)
    SendNUIMessage({ action = 'theme', data = QS.ClientColors or Config.Theme })
    SendNUIMessage({ action = 'locale', data = Locales[GetConvar('qs:locale', Config.Locale or 'en')] or Locales.en or {} })
    cb('ok')
end)

local recoloring = false
local function recolorWithFade(palette)
    if type(palette) ~= 'table' then return end
    if recoloring then applyClientColors(palette); return end
    recoloring = true
    CreateThread(function()
        DoScreenFadeOut(300)
        Wait(320)
        TriggerEvent('qs-corehud:display', false)
        TriggerEvent('qs:chat:display', false)
        applyClientColors(palette)
        Wait(260)
        TriggerEvent('qs-corehud:display', true)
        TriggerEvent('qs:chat:display', true)
        Wait(80)
        DoScreenFadeIn(400)
        recoloring = false
    end)
end

if Config.AllowColorChange then
    RegisterCommand(Config.ColorCommand or 'colors', function()
        SetNuiFocus(true, true)
        TriggerEvent('qs-corehud:display', false)
        SendNUIMessage({ action = 'colors:open', data = QS.ClientColors or Config.Theme })
    end, false)
end

RegisterNUICallback('colors:save', function(palette, cb)
    cb('ok')
    SetNuiFocus(false, false)
    TriggerEvent('qs-corehud:display', true)
    recolorWithFade(palette)
    TriggerServerEvent('qs:colors:save', palette)
end)

RegisterNUICallback('colors:close', function(_, cb)
    cb('ok')
    SetNuiFocus(false, false)
    TriggerEvent('qs-corehud:display', true)
end)
