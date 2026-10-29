local core = exports['qs-core']

local isOpen = false
local locIndex = nil
local previewVeh = 0
local cam = nil
local currentModel = nil
local spawnedPeds = {}

local function send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local function sendTheme()
    local colors = core:GetColors()
    if colors then send('theme', colors) end
end

local function sendLocale()
    send('locale', Locales[GetConvar('qs:locale', 'en')] or Locales.en or {})
end

AddEventHandler('qs:client:colorsChanged', function() if isOpen then sendTheme() end end)

local function loadModel(model)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then return nil end
    RequestModel(hash)
    local dl = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < dl do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

local function frontOf(x, y, heading, dist)
    local rad = math.rad(heading)
    return x - math.sin(rad) * dist, y + math.cos(rad) * dist
end

local function deletePreview()
    if previewVeh ~= 0 and DoesEntityExist(previewVeh) then
        SetEntityAsMissionEntity(previewVeh, true, true)
        DeleteVehicle(previewVeh)
    end
    previewVeh = 0
end

local FADE_MS = 250
local wantModel, wantSet = nil, false
local swapRunning = false

local function fadeEntity(ent, from, to)
    if not (ent and DoesEntityExist(ent)) then return end
    local steps = 12
    local dt = math.floor(FADE_MS / steps)
    for i = 1, steps do
        if not DoesEntityExist(ent) then return end
        SetEntityAlpha(ent, math.floor(from + (to - from) * (i / steps)), false)
        Wait(dt)
    end
end

local function buildPreview(model)
    local loc = Config.Locations[locIndex]
    if not loc then return nil end
    local hash = loadModel(model)
    if not hash then return nil end
    local p = loc.preview
    local v = CreateVehicle(hash, p.x, p.y, p.z, p.w or 0.0, false, false)
    SetVehicleOnGroundProperly(v)
    SetEntityHeading(v, p.w or 0.0)
    FreezeEntityPosition(v, true)
    SetEntityInvincible(v, true)
    SetEntityCollision(v, false, false)
    SetVehicleDoorsLocked(v, 2)
    SetVehicleNumberPlateText(v, 'SHOWROOM')
    SetVehicleDirtLevel(v, 0.0)
    SetEntityAlpha(v, 0, false)
    SetModelAsNoLongerNeeded(hash)
    return v
end

local function spawnPreview(model)
    wantModel, wantSet = model, true
    if swapRunning then return end
    swapRunning = true
    CreateThread(function()
        while wantSet and isOpen do
            local m = wantModel
            wantSet = false

            if previewVeh ~= 0 and DoesEntityExist(previewVeh) then
                fadeEntity(previewVeh, GetEntityAlpha(previewVeh), 0)
                deletePreview()
            end

            if not wantSet and isOpen then
                local v = buildPreview(m)
                if v and isOpen then
                    previewVeh = v
                    currentModel = m
                    fadeEntity(v, 0, 255)
                    if DoesEntityExist(v) then ResetEntityAlpha(v) end
                elseif v and DoesEntityExist(v) then
                    SetEntityAsMissionEntity(v, true, true)
                    DeleteVehicle(v)
                end
            end
        end
        swapRunning = false
    end)
end

local function setupCam()
    local loc = Config.Locations[locIndex]
    local p = loc.preview
    local c = Config.Camera
    local bx, by = frontOf(p.x, p.y, p.w or 0.0, c.dist)
    local rad = math.rad(p.w or 0.0)
    local sx, sy = math.cos(rad) * c.side, math.sin(rad) * c.side

    if cam then DestroyCam(cam, false) end
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        bx + sx, by + sy, p.z + c.height, 0.0, 0.0, 0.0, c.fov, false, 0)
    PointCamAtCoord(cam, p.x, p.y, p.z + (c.target or 0.5))
    SetCamUseShallowDofMode(cam, true)
    SetCamNearDof(cam, 1.0)
    SetCamFarDof(cam, 12.0)
    SetCamDofStrength(cam, 1.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 600, true, false)
end

local function turntableLoop()
    CreateThread(function()
        local speed = Config.Camera.turntable or 12.0
        while isOpen do
            Wait(0)
            if previewVeh ~= 0 and DoesEntityExist(previewVeh) then
                local h = (GetEntityHeading(previewVeh) + speed * GetFrameTime()) % 360.0
                SetEntityHeading(previewVeh, h)
            end
            SetUseHiDof()
        end
    end)
end

local function openShop(index)
    if isOpen then return end
    isOpen = true
    locIndex = index

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    TriggerEvent('qs-corehud:display', false)

    local firstCat = Config.Categories[1]
    local firstList = Config.Vehicles[firstCat.id] or {}
    spawnPreview((firstList[1] or {}).model or 'blista')
    setupCam()
    turntableLoop()

    local data = core:GetPlayerData() or {}
    local money = data.money or {}
    SetNuiFocus(true, true)
    sendTheme()
    sendLocale()
    send('open', {
        categories = Config.Categories,
        vehicles = Config.Vehicles,
        cash = money.cash or 0,
        bank = money.bank or 0,
    })
end

local function closeShop()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    send('close')

    RenderScriptCams(false, true, 600, true, false)
    if cam then DestroyCam(cam, false) cam = nil end
    deletePreview()

    FreezeEntityPosition(PlayerPedId(), false)
    TriggerEvent('qs-corehud:display', true)
    locIndex = nil
    currentModel = nil
end

local function deliverVehicle(loc, model, plate)
    if not loc then return end
    local hash = loadModel(model)
    if not hash then return end
    local s = loc.spawn
    local v = CreateVehicle(hash, s.x, s.y, s.z, s.w or 0.0, true, true)
    SetVehicleOnGroundProperly(v)
    SetVehicleNumberPlateText(v, plate)
    if GetResourceState('qs-corevehiclekeys') == 'started' then exports['qs-corevehiclekeys']:GiveKeys(plate) end
    SetVehicleFuelLevel(v, 100.0)
    SetVehicleDirtLevel(v, 0.0)
    SetEntityAsMissionEntity(v, true, true)
    SetVehicleDoorsLocked(v, 1)
    SetVehicleHasBeenOwnedByPlayer(v, true)
    SetModelAsNoLongerNeeded(hash)
    local netId = NetworkGetNetworkIdFromEntity(v)
    SetNetworkIdCanMigrate(netId, true)
    TaskWarpPedIntoVehicle(PlayerPedId(), v, -1)
end

RegisterNUICallback('preview', function(data, cb)
    cb('ok')
    if isOpen and data and data.model and data.model ~= currentModel then
        spawnPreview(data.model)
    end
end)

RegisterNUICallback('buy', function(data, cb)
    cb('ok')
    if not isOpen or not data or not data.model then return end
    local model = data.model
    local loc = Config.Locations[locIndex]
    core:TriggerCallback('qs-vehicleshop:buy', function(res)
        if res and res.ok then
            core:Notify(T('bought', res.plate), 'success', 6000)
            closeShop()
            deliverVehicle(loc, model, res.plate)
        elseif res and res.msg == 'money' then
            core:Notify(T('no_money'), 'error')
        elseif res and res.msg == 'far' then
            core:Notify(T('too_far'), 'error')
        else
            core:Notify(T('buy_failed'), 'error')
        end
    end, model)
end)

RegisterNUICallback('close', function(_, cb)
    cb('ok')
    closeShop()
end)

local function helpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

CreateThread(function()
    for _, loc in ipairs(Config.Locations) do
        if loc.blip then
            local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
            SetBlipSprite(blip, loc.blip.sprite or 326)
            SetBlipColour(blip, loc.blip.color or 3)
            SetBlipScale(blip, loc.blip.scale or 0.85)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(loc.blip.label or 'Dealership')
            EndTextCommandSetBlipName(blip)
        end
        if loc.ped then
            local phash = joaat(loc.ped)
            RequestModel(phash)
            local dl = GetGameTimer() + 6000
            while not HasModelLoaded(phash) and GetGameTimer() < dl do Wait(10) end
            if HasModelLoaded(phash) then
                local ped = CreatePed(4, phash, loc.coords.x, loc.coords.y, loc.coords.z - 1.0, loc.coords.w or 0.0, false, true)
                FreezeEntityPosition(ped, true)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
                spawnedPeds[#spawnedPeds + 1] = ped
                SetModelAsNoLongerNeeded(phash)
            end
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if not isOpen then
            local coords = GetEntityCoords(PlayerPedId())
            local nearest = 9999.0
            for i, loc in ipairs(Config.Locations) do
                local d = #(coords - vector3(loc.coords.x, loc.coords.y, loc.coords.z))
                if d < nearest then nearest = d end
                if d < Config.InteractDistance then
                    sleep = 0
                    helpText(T('help_open'))
                    if IsControlJustPressed(0, Config.OpenKey) then
                        openShop(i)
                    end
                    break
                end
            end
            if sleep ~= 0 then sleep = nearest > 40.0 and 1500 or 400 end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isOpen then closeShop() end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
