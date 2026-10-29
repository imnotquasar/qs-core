local decided = false
local active = false
local introPed = nil
local cam = nil

local function send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local COMPONENTS = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 }
local PROPS = { 0, 1, 2, 6, 7 }

RegisterCommand('introoutfit', function()
    local ped = PlayerPedId()
    local model = IsPedMale(ped) and 'mp_m_freemode_01' or 'mp_f_freemode_01'

    local out = { '', '-- paste this into qs-intro/config.lua (Config.Ped)', "model  = '" .. model .. "'," }
    out[#out + 1] = 'components = {'
    for _, id in ipairs(COMPONENTS) do
        local d = GetPedDrawableVariation(ped, id)
        local t = GetPedTextureVariation(ped, id)
        out[#out + 1] = ('    { id = %d, drawable = %d, texture = %d },'):format(id, d, t)
    end
    out[#out + 1] = '},'
    out[#out + 1] = 'props = {'
    for _, id in ipairs(PROPS) do
        local d = GetPedPropIndex(ped, id)
        local t = GetPedPropTextureIndex(ped, id)
        out[#out + 1] = ('    { id = %d, drawable = %d, texture = %d },'):format(id, d, t)
    end
    out[#out + 1] = '},'

    print(table.concat(out, '\n'))
    exports['qs-core']:Notify(T('outfit_dumped'), 'success', 4000)
end, false)

RegisterCommand('introreset', function()
    TriggerServerEvent('qs:colors:clear')
    exports['qs-core']:Notify(T('colours_cleared'), 'success', 5000)
end, false)

if not Config.Enabled then
    AddEventHandler('playerSpawned', function()
        if not decided then decided = true; TriggerEvent('qs-intro:finished') end
    end)
    return
end

local function setupScene()
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        Config.Cam.pos.x, Config.Cam.pos.y, Config.Cam.pos.z, 0.0, 0.0, 0.0, Config.Cam.fov, false, 0)
    PointCamAtCoord(cam, Config.Cam.look.x, Config.Cam.look.y, Config.Cam.look.z)
    if Config.Dof then
        SetCamUseShallowDofMode(cam, true)
        SetCamNearDof(cam, 1.0)
        SetCamFarDof(cam, 6.0)
        SetCamDofStrength(cam, 1.0)
    end
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)

    local model = joaat(Config.Ped.model)
    RequestModel(model)
    local dl = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < dl do Wait(10) end

    local s = Config.Ped.start
    local sz = s.z
    local found, gz = GetGroundZFor_3dCoord(s.x, s.y, s.z + 3.0, false)
    if found then sz = gz end
    introPed = CreatePed(4, model, s.x, s.y, sz, s.w or 0.0, false, true)
    SetModelAsNoLongerNeeded(model)
    SetEntityInvincible(introPed, true)
    SetBlockingOfNonTemporaryEvents(introPed, true)

    for _, c in ipairs(Config.Ped.components or {}) do
        SetPedComponentVariation(introPed, c.id, c.drawable, c.texture or 0, 0)
    end
    for _, p in ipairs(Config.Ped.props or {}) do
        if (p.drawable or -1) >= 0 then
            SetPedPropIndex(introPed, p.id, p.drawable, p.texture or 0, true)
        else
            ClearPedProp(introPed, p.id)
        end
    end
end

local function walkAndTurn(done)
    local f = Config.Ped.finish
    TaskGoStraightToCoord(introPed, f.x, f.y, f.z, Config.Ped.speed or 1.0, -1, 0.0, 0.1)
    CreateThread(function()
        local dl = GetGameTimer() + 20000
        while active and GetGameTimer() < dl do
            Wait(120)
            if #(GetEntityCoords(introPed) - vector3(f.x, f.y, f.z)) < 0.7 then break end
        end
        if not active then return end
        ClearPedTasks(introPed)
        TaskTurnPedToFaceCoord(introPed, Config.Cam.pos.x, Config.Cam.pos.y, Config.Cam.pos.z, 1300)
        Wait(1400)
        if active and done then done() end
    end)
end

local function hideLoop()
    CreateThread(function()
        while active do
            Wait(0)
            HideHudAndRadarThisFrame()
            if Config.Dof then SetUseHiDof() end
            DisableAllControlActions(0)
        end
    end)
end

local function cleanup()
    active = false
    if cam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(cam, false)
        cam = nil
    end
    if introPed and DoesEntityExist(introPed) then DeleteEntity(introPed) end
    introPed = nil
    SetNuiFocus(false, false)
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
end

local function finish()
    send('close')
    DoScreenFadeOut(500)
    Wait(550)
    cleanup()
    TriggerEvent('qs-intro:finished')
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

local function begin()
    if active then return end
    active = true
    DoScreenFadeOut(0)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityCoordsNoOffset(ped, Config.Scene.hide.x, Config.Scene.hide.y, Config.Scene.hide.z, false, false, false)
    SetEntityVisible(ped, false, false)

    RequestCollisionAtCoord(Config.Scene.hide.x, Config.Scene.hide.y, Config.Scene.hide.z)
    local dl = GetGameTimer() + 6000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < dl do Wait(50) end

    setupScene()
    hideLoop()

    send('theme', exports['qs-core']:GetColors())
    send('locale', Locales[GetConvar('qs:locale', 'en')] or Locales.en or {})

    dismissLoadingScreen()
    Wait(200)
    DoScreenFadeIn(700)
    walkAndTurn(function()
        SetNuiFocus(true, true)
        send('open')
    end)
end

local function decide(palette)
    if decided then return end
    decided = true
    if type(palette) == 'table' then

        exports['qs-core']:SetClientColors(palette)
        TriggerEvent('qs-intro:finished')
    else
        begin()
    end
end

RegisterNetEvent('qs:colors:load', function(palette)
    decide(palette)
end)

RegisterNUICallback('confirm', function(data, cb)
    cb('ok')
    if type(data.palette) == 'table' then
        exports['qs-core']:SetClientColors(data.palette)
        TriggerServerEvent('qs:colors:save', data.palette)
    end
    finish()
end)

local function requestCheck()
    CreateThread(function()
        TriggerServerEvent('qs:colors:request')
        local dl = GetGameTimer() + 6000
        while not decided and GetGameTimer() < dl do Wait(150) end

        if not decided then decide(false) end
    end)
end

AddEventHandler('playerSpawned', function()
    if not decided then requestCheck() end
end)

CreateThread(function()
    Wait(1500)
    if not decided then requestCheck() end
end)
