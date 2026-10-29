local core = exports['qs-core']

local isOpen = false
local garageIndex = nil
local previewVeh = 0
local cam = nil
local currentPlate = nil

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

local function trim(s) return s and (s:gsub('%s+$', '')) or s end

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

local function getProps(veh)
    local props = { mods = {}, extras = {} }
    props.plate = trim(GetVehicleNumberPlateText(veh))
    props.color1, props.color2 = GetVehicleColours(veh)
    props.pearlescent, props.wheelColor = GetVehicleExtraColours(veh)
    props.wheelType = GetVehicleWheelType(veh)
    props.windowTint = GetVehicleWindowTint(veh)
    props.plateIndex = GetVehicleNumberPlateTextIndex(veh)
    props.livery = GetVehicleLivery(veh)
    for m = 0, 49 do props.mods[tostring(m)] = GetVehicleMod(veh, m) end
    for e = 0, 20 do
        if DoesExtraExist(veh, e) then
            props.extras[tostring(e)] = IsVehicleExtraTurnedOn(veh, e) == 1
        end
    end
    return props
end

local function setProps(veh, props)
    if type(props) ~= 'table' then return end
    SetVehicleModKit(veh, 0)
    if props.color1 and props.color2 then SetVehicleColours(veh, props.color1, props.color2) end
    if props.pearlescent then SetVehicleExtraColours(veh, props.pearlescent, props.wheelColor or 0) end
    if props.wheelType then SetVehicleWheelType(veh, props.wheelType) end
    if props.windowTint then SetVehicleWindowTint(veh, props.windowTint) end
    if props.plateIndex then SetVehicleNumberPlateTextIndex(veh, props.plateIndex) end
    if props.livery then SetVehicleLivery(veh, props.livery) end
    if type(props.mods) == 'table' then
        for m, v in pairs(props.mods) do SetVehicleMod(veh, tonumber(m), v, false) end
    end
    if type(props.extras) == 'table' then
        for e, on in pairs(props.extras) do SetVehicleExtra(veh, tonumber(e), on and 0 or 1) end
    end
end

local function plateInWorld(plate)
    plate = trim(plate)
    for _, v in ipairs(GetGamePool('CVehicle')) do
        if trim(GetVehicleNumberPlateText(v)) == plate then return true end
    end
    return false
end

local function deletePreview()
    if previewVeh ~= 0 and DoesEntityExist(previewVeh) then
        SetEntityAsMissionEntity(previewVeh, true, true)
        DeleteVehicle(previewVeh)
    end
    previewVeh = 0
end

local FADE_MS = 250
local wantModel, wantProps, wantSet = nil, nil, false
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

local function buildPreview(model, props)
    local g = Config.Garages[garageIndex]
    if not g then return nil end
    local hash = loadModel(model)
    if not hash then return nil end
    local p = g.preview
    local v = CreateVehicle(hash, p.x, p.y, p.z, p.w or 0.0, false, false)
    SetVehicleOnGroundProperly(v)
    SetEntityHeading(v, p.w or 0.0)
    setProps(v, props)
    FreezeEntityPosition(v, true)
    SetEntityInvincible(v, true)
    SetEntityCollision(v, false, false)
    SetVehicleDoorsLocked(v, 2)
    SetVehicleDirtLevel(v, 0.0)
    SetEntityAlpha(v, 0, false)
    SetModelAsNoLongerNeeded(hash)
    return v
end

local function spawnPreview(model, props)
    wantModel, wantProps, wantSet = model, props, true
    if swapRunning then return end
    swapRunning = true
    CreateThread(function()
        while wantSet and isOpen do
            local m, pr = wantModel, wantProps
            wantSet = false

            if previewVeh ~= 0 and DoesEntityExist(previewVeh) then
                fadeEntity(previewVeh, GetEntityAlpha(previewVeh), 0)
                deletePreview()
            end

            if not wantSet and isOpen then
                local v = buildPreview(m, pr)
                if v and isOpen then
                    previewVeh = v
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
    local g = Config.Garages[garageIndex]
    local p = g.preview
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

local vehCache = {}

local function closeGarage()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    send('close')
    RenderScriptCams(false, true, 600, true, false)
    if cam then DestroyCam(cam, false) cam = nil end
    deletePreview()
    FreezeEntityPosition(PlayerPedId(), false)
    TriggerEvent('qs-corehud:display', true)
    garageIndex = nil
    currentPlate = nil
    vehCache = {}
end

local function openGarage(index)
    if isOpen then return end
    local g = Config.Garages[index]
    if not g then return end
    isOpen = true
    garageIndex = index
    FreezeEntityPosition(PlayerPedId(), true)
    TriggerEvent('qs-corehud:display', false)

    core:TriggerCallback('qs-garage:list', function(vehs)
        if not isOpen then return end
        vehs = vehs or {}
        vehCache = {}
        for _, v in ipairs(vehs) do vehCache[trim(v.plate)] = v end

        setupCam()
        local first = vehs[1]
        if first then
            currentPlate = trim(first.plate)
            spawnPreview(first.model, first.props)
        end
        turntableLoop()

        SetNuiFocus(true, true)
        sendTheme()
        sendLocale()
        send('open', { label = g.label, vehicles = vehs })
    end, g.id)
end

local function takeOut(plate)
    plate = trim(plate)
    if plateInWorld(plate) then
        core:Notify(T('already_out'), 'error')
        return
    end
    local g = Config.Garages[garageIndex or 1]
    core:TriggerCallback('qs-garage:takeout', function(res)
        if not (res and res.ok) then
            core:Notify(T(res and res.msg or 'not_yours'), 'error')
            return
        end
        closeGarage()
        local hash = loadModel(res.model)
        if not hash then return end
        local s = g.spawn
        local v = CreateVehicle(hash, s.x, s.y, s.z, s.w or 0.0, true, true)
        SetVehicleOnGroundProperly(v)
        SetVehicleNumberPlateText(v, res.plate)
        if GetResourceState('qs-corevehiclekeys') == 'started' then exports['qs-corevehiclekeys']:GiveKeys(res.plate) end
        setProps(v, res.props)
        SetVehicleEngineHealth(v, res.engine or 1000.0)
        SetVehicleBodyHealth(v, res.body or 1000.0)
        SetVehicleFuelLevel(v, (res.fuel or 100) + 0.0)
        SetVehicleDirtLevel(v, 0.0)
        SetEntityAsMissionEntity(v, true, true)
        SetVehicleDoorsLocked(v, 1)
        SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(v), true)
        SetModelAsNoLongerNeeded(hash)
        TaskWarpPedIntoVehicle(PlayerPedId(), v, -1)
        core:Notify(T('took_out'), 'success')
    end, g.id, plate)
end

local function storeVehicle(g, veh)
    if GetPedInVehicleSeat(veh, -1) ~= PlayerPedId() then
        core:Notify(T('need_driver'), 'error')
        return
    end
    local plate = trim(GetVehicleNumberPlateText(veh))
    local props = getProps(veh)
    local fuel = math.floor(GetVehicleFuelLevel(veh))
    local engine = GetVehicleEngineHealth(veh)
    local body = GetVehicleBodyHealth(veh)
    core:TriggerCallback('qs-garage:store', function(res)
        if res and res.ok then
            SetEntityAsMissionEntity(veh, true, true)
            DeleteVehicle(veh)
            core:Notify(T('stored'), 'success')
        else
            core:Notify(T('not_yours'), 'error')
        end
    end, g.id, plate, fuel, engine, body, props)
end

RegisterNUICallback('select', function(data, cb)
    cb('ok')
    if not isOpen or not data or not data.plate then return end
    local plate = trim(data.plate)
    if plate == currentPlate then return end
    local v = vehCache[plate]
    if v then
        currentPlate = plate
        spawnPreview(v.model, v.props)
    end
end)

RegisterNUICallback('takeout', function(data, cb)
    cb('ok')
    if isOpen and data and data.plate then takeOut(data.plate) end
end)

RegisterNUICallback('close', function(_, cb)
    cb('ok')
    closeGarage()
end)

local function helpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

CreateThread(function()
    for _, g in ipairs(Config.Garages) do
        if g.blip then
            local blip = AddBlipForCoord(g.coords.x, g.coords.y, g.coords.z)
            SetBlipSprite(blip, g.blip.sprite or 357)
            SetBlipColour(blip, g.blip.color or 3)
            SetBlipScale(blip, g.blip.scale or 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(g.blip.label or 'Garage')
            EndTextCommandSetBlipName(blip)
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if not isOpen then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local nearest = 9999.0
            for i, g in ipairs(Config.Garages) do
                local d = #(coords - vector3(g.coords.x, g.coords.y, g.coords.z))
                if d < nearest then nearest = d end
                if d < Config.InteractDistance then
                    sleep = 0
                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh ~= 0 then
                        helpText(T('help_store'))
                        if IsControlJustPressed(0, Config.OpenKey) then storeVehicle(g, veh) end
                    else
                        helpText(T('help_open'))
                        if IsControlJustPressed(0, Config.OpenKey) then openGarage(i) end
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
    if isOpen then closeGarage() end
end)
