local isSelecting = false
local hasLoaded = false
local cam = nil
local characters = {}
local introPending = GetResourceState('qs-intro') == 'started'
math.randomseed(GetGameTimer())

local function frontOf(coords, heading, dist)
    local rad = math.rad(heading)
    return vector3(coords.x - math.sin(rad) * dist, coords.y + math.cos(rad) * dist, coords.z)
end

local function dismissLoadingScreen()
    if GetResourceState('loadingscreen') == 'started' then
        local gone = false
        local h = AddEventHandler('loadingscreen:done', function() gone = true end)
        TriggerEvent('loadingscreen:finish')
        local dl = GetGameTimer() + 6000
        while not gone and GetGameTimer() < dl do Wait(50) end
        RemoveEventHandler(h)
    end
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end

local function applyDof(c)
    if not Config.Preview.dof then return end
    SetCamUseShallowDofMode(c, true)
    SetCamNearDof(c, Config.Preview.dofNear or 0.6)
    SetCamFarDof(c, Config.Preview.dofFar or 2.4)
    SetCamDofStrength(c, Config.Preview.dofStrength or 1.0)
end

local function setupCam()
    local c = Config.Preview.coords
    local rad = math.rad(c.w)

    local side = Config.Preview.camSide or 0.0
    local sx, sy = math.cos(rad) * side, math.sin(rad) * side
    local base = frontOf(c, c.w, Config.Preview.camDist)

    if cam then DestroyCam(cam, false) end
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        base.x + sx, base.y + sy, c.z + Config.Preview.camHeight,
        0.0, 0.0, 0.0, Config.Preview.fov, false, 0)
    PointCamAtCoord(cam, c.x + sx, c.y + sy, c.z + (Config.Preview.targetHeight or 0.5))
    applyDof(cam)

    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)
end

local function focusCam(sectionKey, interpMs)
    local c = Config.Preview.coords
    local s = (Config.Preview.creatorSections or {})[sectionKey]
        or (Config.Preview.creatorSections or {}).upper
        or { dist = 1.5, height = 0.5, target = 0.45, fov = 25.0 }
    local rad = math.rad(c.w)
    local side = -(Config.Preview.creatorSide or 0.35)
    local sx, sy = math.cos(rad) * side, math.sin(rad) * side
    local base = frontOf(c, c.w, s.dist)

    local newCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        base.x + sx, base.y + sy, c.z + s.height, 0.0, 0.0, 0.0, s.fov, false, 0)
    PointCamAtCoord(newCam, c.x + sx, c.y + sy, c.z + s.target)
    applyDof(newCam)

    local interp = interpMs or 700
    if cam and DoesCamExist(cam) then
        SetCamActiveWithInterp(newCam, cam, interp, 1, 1)
        local old = cam
        cam = newCam
        CreateThread(function()
            Wait(interp + 120)
            if DoesCamExist(old) then DestroyCam(old, false) end
        end)
    else
        cam = newCam
        SetCamActive(cam, true)
    end
    RenderScriptCams(true, false, 0, true, false)
end

AddEventHandler('qs:clothing:section', function(sectionKey)
    if isSelecting then focusCam(sectionKey, 700) end
end)

local FADE_MS = 250

local function fadePed(ped, from, to)
    if not (ped and DoesEntityExist(ped)) then return end
    SetEntityAlpha(ped, from, false)
    local elapsed = 0.0
    while elapsed < FADE_MS and DoesEntityExist(ped) do
        Wait(0)
        elapsed = elapsed + GetFrameTime() * 1000.0
        local t = elapsed / FADE_MS
        if t > 1.0 then t = 1.0 end
        SetEntityAlpha(ped, math.floor(from + (to - from) * t), false)
    end
    if ped and DoesEntityExist(ped) then
        if to >= 255 then ResetEntityAlpha(ped) else SetEntityAlpha(ped, to, false) end
    end
end

local function fadeInPed(ped)
    CreateThread(function() fadePed(ped, 0, 255) end)
end

local function applyPose(ped)
    if #Config.Poses == 0 then return end

    local pose = Config.Poses[math.random(#Config.Poses)]
    if not pose then return end
    RequestAnimDict(pose.dict)
    local t = GetGameTimer()
    while not HasAnimDictLoaded(pose.dict) and GetGameTimer() - t < 2000 do Wait(10) end
    if HasAnimDictLoaded(pose.dict) then
        TaskPlayAnim(ped, pose.dict, pose.clip, 2.0, 2.0, -1, 1, 0, false, false, false)
    end
end

local wantChar, wantSet, stageRunning = nil, false, false

local function stagePed(char)
    wantChar, wantSet = char, true
    if stageRunning then return end
    stageRunning = true
    CreateThread(function()
        while wantSet do
            local ch = wantChar
            wantSet = false

            local cur = PlayerPedId()
            if DoesEntityExist(cur) then fadePed(cur, GetEntityAlpha(cur), 0) end

            if not wantSet then
                if ch and GetResourceState('qs-clothing') == 'started' then
                    exports['qs-clothing']:ApplyAppearance(ch.skin, ch.charinfo and ch.charinfo.sex)
                end

                local c = Config.Preview.coords
                local ped = PlayerPedId()
                SetEntityAlpha(ped, 0, false)
                SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
                SetEntityHeading(ped, c.w)
                FreezeEntityPosition(ped, true)
                SetEntityVisible(ped, true, false)
                SetEntityInvincible(ped, true)
                applyPose(ped)
                setupCam()
                if ch then fadePed(ped, 0, 255) end
            end
        end
        stageRunning = false
    end)
end

local function openListUI()
    SetNuiFocus(true, true)

    local colors = exports['qs-core']:GetColors()
    if colors then SendNUIMessage({ action = 'theme', data = colors }) end
    SendNUIMessage({ action = 'open', data = {
        brand = Config.Brand,
        t = Locales[GetConvar('qs:locale', Config.Locale or 'en')] or Locales.en,
    } })

    TriggerServerEvent('qs-coremultichar:server:getCharacters')
end

local function enterSelection()
    isSelecting = true
    DoScreenFadeOut(0)

    TriggerEvent('qs-corehud:display', false)
    TriggerEvent('qs:chat:display', false)
    CreateThread(function()
        while isSelecting do
            Wait(0)
            if Config.Preview.dof then SetUseHiDof() end
            HideHudAndRadarThisFrame()

            local me = PlayerPedId()
            for _, pid in ipairs(GetActivePlayers()) do
                local other = GetPlayerPed(pid)
                if other ~= me and DoesEntityExist(other) then
                    SetEntityLocallyInvisible(other)
                end
            end

            DisableControlAction(0, 245, true)
            DisableControlAction(0, 246, true)
            DisableControlAction(0, 247, true)
            DisableControlAction(0, 248, true)
        end
    end)

    local c = Config.Preview.coords
    RequestCollisionAtCoord(c.x, c.y, c.z)
    stagePed(nil)

    dismissLoadingScreen()

    openListUI()
    Wait(300)
    DoScreenFadeIn(500)
end

local function leaveSelection()
    isSelecting = false
    TriggerEvent('qs-corehud:display', true)
    TriggerEvent('qs:chat:display', true)
    if cam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(cam, false)
        cam = nil
    end
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close', data = {} })
end

AddEventHandler('playerSpawned', function()
    if isSelecting or hasLoaded or introPending then return end
    enterSelection()
end)

AddEventHandler('qs-intro:finished', function()
    introPending = false
    if not isSelecting and not hasLoaded then enterSelection() end
end)

CreateThread(function()
    local data = exports['qs-core']:GetPlayerData()
    if data and data.citizenid then hasLoaded = true end
end)

CreateThread(function()
    Wait(2000)
    if introPending and LocalPlayer.state.qsIntroDone then introPending = false end
    if not isSelecting and not hasLoaded and not introPending then enterSelection() end
end)

RegisterNetEvent('qs-coremultichar:client:setCharacters', function(chars, maxSlots)
    characters = chars or {}
    SendNUIMessage({ action = 'setCharacters', data = { characters = characters, maxSlots = maxSlots } })
    stagePed(characters[1])
end)

RegisterNetEvent('qs-coremultichar:client:error', function(err)
    if isSelecting and not hasLoaded then
        openListUI()
    end
    SendNUIMessage({ action = 'error', data = { code = err } })
end)

AddEventHandler('qs:client:onPlayerLoaded', function()
    hasLoaded = true
    if isSelecting then leaveSelection() end
end)

AddEventHandler('qs:client:onPlayerUnloaded', function()
    hasLoaded = false
    if not isSelecting then enterSelection() end
end)

if Config.EnableLogout then
    RegisterCommand(Config.LogoutCommand or 'logout', function()
        if isSelecting or not hasLoaded then return end
        DoScreenFadeOut(300)
        Wait(350)
        TriggerServerEvent('qs-coremultichar:server:logout')
    end, false)

    CreateThread(function()
        Wait(800)
        local t = Locales[GetConvar('qs:locale', Config.Locale or 'en')] or Locales.en
        TriggerEvent('chat:addSuggestion', '/' .. (Config.LogoutCommand or 'logout'), t.sug_logout or '')
    end)
end

RegisterNUICallback('highlight', function(data, cb)
    for _, c in ipairs(characters) do
        if c.citizenid == data.citizenid then
            stagePed(c)
            break
        end
    end
    cb('ok')
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    TriggerServerEvent('qs-coremultichar:server:selectCharacter', data.citizenid)
    cb('ok')
end)

local function enterCreator(data)
    focusCam('face', Config.Preview.creatorInterp or 1200)
    SendNUIMessage({ action = 'close', data = {} })

    exports['qs-clothing']:OpenCreator(data.sex, function(skin)
        TriggerServerEvent('qs-coremultichar:server:createCharacter', data, skin)
    end)

    local c = Config.Preview.coords
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
    SetEntityHeading(ped, c.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    applyPose(ped)
    fadeInPed(ped)
end

RegisterNUICallback('createCharacter', function(data, cb)
    cb('ok')
    if GetResourceState('qs-clothing') == 'started' then
        enterCreator(data)
    else
        TriggerServerEvent('qs-coremultichar:server:createCharacter', data)
    end
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    TriggerServerEvent('qs-coremultichar:server:deleteCharacter', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('quit', function(_, cb)
    cb('ok')
    TriggerServerEvent('qs-coremultichar:server:quit')
end)
