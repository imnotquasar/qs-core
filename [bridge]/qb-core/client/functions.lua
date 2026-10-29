-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from QBCore (https://github.com/qbcore-framework/qb-core)
-- Copyright (C) QBCore Framework and contributors
-- Modified for qscore in 2026: adapted to run on top of qs-core. See NOTICE.

QBCore = QBCore or {}
QBCore.Functions = QBCore.Functions or {}
QBCore.ClientCallbacks = QBCore.ClientCallbacks or {}
QBCore.ServerCallbacks = QBCore.ServerCallbacks or {}

local NOTIFY_MAP = { primary = 'primary', success = 'success', error = 'error', police = 'info', ambulance = 'info', inform = 'info' }

function QBCore.Functions.Notify(text, texttype, length)
    local msg = text
    if type(text) == 'table' then
        msg = text.text or 'Placeholder'
        texttype = texttype or text.type
        length = length or text.length
    end
    exports['qs-core']:Notify(msg, NOTIFY_MAP[texttype or 'primary'] or 'info', length or 5000)
end

function QBCore.Functions.TriggerCallback(name, cb, ...)
    exports['qs-core']:TriggerQBCallback(name, cb, ...)
end

function QBCore.Functions.CreateClientCallback(name, cb)
    QBCore.ClientCallbacks[name] = cb
end

RegisterNetEvent('QBCore:Client:TriggerClientCallback', function(name, ...)
    if QBCore.ClientCallbacks[name] then
        QBCore.ClientCallbacks[name](function(...)
            TriggerServerEvent('QBCore:Server:TriggerClientCallback', name, ...)
        end, ...)
    end
end)

function QBCore.Functions.Progressbar(_name, label, duration, _useWhileDead, canCancel, disableControls, animation, prop, _propTwo, onFinish, onCancel)
    CreateThread(function()
        local ped = PlayerPedId()
        local propObj

        if animation then
            if animation.animDict and animation.anim then
                RequestAnimDict(animation.animDict)
                local deadline = GetGameTimer() + 2000
                while not HasAnimDictLoaded(animation.animDict) and GetGameTimer() < deadline do Wait(10) end
                TaskPlayAnim(ped, animation.animDict, animation.anim, 3.0, 3.0, -1, animation.flags or 49, 0, false, false, false)
            elseif animation.task then
                TaskStartScenarioInPlace(ped, animation.task, 0, true)
            end
        end

        if prop and prop.model then
            local model = type(prop.model) == 'string' and joaat(prop.model) or prop.model
            RequestModel(model)
            local deadline = GetGameTimer() + 2000
            while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(10) end
            if HasModelLoaded(model) then
                propObj = CreateObject(model, GetEntityCoords(ped), true, true, false)
                local c = prop.coords or {}
                local r = prop.rotation or {}
                AttachEntityToEntity(propObj, ped, GetPedBoneIndex(ped, prop.bone or 60309),
                    c.x or 0.0, c.y or 0.0, c.z or 0.0, r.x or 0.0, r.y or 0.0, r.z or 0.0,
                    true, true, false, true, 1, true)
                SetModelAsNoLongerNeeded(model)
            end
        end

        local disableMove = false
        if disableControls then
            disableMove = disableControls.move or disableControls.car or false
        end

        local ok = exports['qs-core']:Progress({
            duration = duration or 3000,
            label = label or '',
            canCancel = canCancel,
            disableMovement = disableMove,
        })

        ClearPedTasks(ped)
        if propObj and DoesEntityExist(propObj) then DeleteEntity(propObj) end

        if ok then
            if onFinish then onFinish() end
        else
            if onCancel then onCancel() end
        end
    end)
end

function QBCore.Functions.GetPlayerData(cb)
    if cb then
        cb(QBCore.PlayerData)
        return
    end
    return QBCore.PlayerData
end

function QBCore.Functions.GetCoords(entity)
    local coords = GetEntityCoords(entity)
    return vector4(coords.x, coords.y, coords.z, GetEntityHeading(entity))
end

function QBCore.Functions.HasItem(items, amount)
    amount = amount or 1
    if type(items) == 'table' then
        if items[1] ~= nil then
            for _, name in ipairs(items) do
                if not exports['qs-core']:HasItem(name, amount) then return false end
            end
            return true
        end
        for name, amt in pairs(items) do
            if not exports['qs-core']:HasItem(name, amt) then return false end
        end
        return true
    end
    return exports['qs-core']:HasItem(items, amount)
end

function QBCore.Functions.GetPlayers()
    return GetActivePlayers()
end

function QBCore.Functions.GetClosestPlayer(coords)
    local ped = PlayerPedId()
    coords = coords or GetEntityCoords(ped)
    local closest, dist = -1, -1
    for _, player in ipairs(GetActivePlayers()) do
        local target = GetPlayerPed(player)
        if target ~= ped then
            local d = #(coords - GetEntityCoords(target))
            if dist == -1 or d < dist then
                closest, dist = player, d
            end
        end
    end
    return closest, dist
end

function QBCore.Functions.GetPlayersFromCoords(coords, radius)
    coords = coords or GetEntityCoords(PlayerPedId())
    radius = radius or 5.0
    local out = {}
    for _, player in ipairs(GetActivePlayers()) do
        if #(coords - GetEntityCoords(GetPlayerPed(player))) <= radius then
            out[#out + 1] = player
        end
    end
    return out
end

local function closestFromPool(pool, coords)
    coords = coords or GetEntityCoords(PlayerPedId())
    local closest, dist = -1, -1
    for _, entity in ipairs(GetGamePool(pool)) do
        local d = #(coords - GetEntityCoords(entity))
        if dist == -1 or d < dist then
            closest, dist = entity, d
        end
    end
    return closest, dist
end

function QBCore.Functions.GetClosestVehicle(coords)
    return closestFromPool('CVehicle', coords)
end

function QBCore.Functions.GetClosestObject(coords)
    return closestFromPool('CObject', coords)
end

function QBCore.Functions.GetClosestPed(coords, ignoreList)
    coords = coords or GetEntityCoords(PlayerPedId())
    local ignore = {}
    for _, p in ipairs(ignoreList or {}) do ignore[p] = true end
    local closest, dist = -1, -1
    for _, ped in ipairs(GetGamePool('CPed')) do
        if not IsPedAPlayer(ped) and not ignore[ped] then
            local d = #(coords - GetEntityCoords(ped))
            if dist == -1 or d < dist then
                closest, dist = ped, d
            end
        end
    end
    return closest, dist
end

function QBCore.Functions.LoadModel(model)
    model = type(model) == 'string' and joaat(model) or model
    if HasModelLoaded(model) then return end
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
end

function QBCore.Functions.LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

function QBCore.Functions.RequestAnimDict(dict)
    QBCore.Functions.LoadAnimDict(dict)
end

function QBCore.Functions.LoadParticleDictionary(dict)
    if HasNamedPtfxAssetLoaded(dict) then return end
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do Wait(10) end
end

function QBCore.Functions.GetPlate(vehicle)
    if not vehicle or vehicle == 0 then return end
    return QBCore.Shared.Trim(GetVehicleNumberPlateText(vehicle))
end

function QBCore.Functions.GetVehicleLabel(vehicle)
    if not vehicle or vehicle == 0 then return end
    return GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
end

function QBCore.Functions.SpawnVehicle(model, cb, coords, isnetworked, teleportInto)
    local ped = PlayerPedId()
    model = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(model) then return end
    if coords then
        coords = type(coords) == 'table' and vector4(coords.x, coords.y, coords.z, coords.w or 0.0) or coords
    else
        coords = QBCore.Functions.GetCoords(ped)
    end
    if isnetworked == nil then isnetworked = true end
    QBCore.Functions.LoadModel(model)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, isnetworked, false)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')
    SetVehicleFuelLevel(veh, 100.0)
    SetModelAsNoLongerNeeded(model)
    if teleportInto then TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) end
    if cb then cb(veh) end
end

function QBCore.Functions.DeleteVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

function QBCore.Functions.GetVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then return end
    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    local hasCustomPrimaryColor = GetIsVehiclePrimaryColourCustom(vehicle)
    if hasCustomPrimaryColor then
        local r, g, b = GetVehicleCustomPrimaryColour(vehicle)
        colorPrimary = { r, g, b }
    end
    local hasCustomSecondaryColor = GetIsVehicleSecondaryColourCustom(vehicle)
    if hasCustomSecondaryColor then
        local r, g, b = GetVehicleCustomSecondaryColour(vehicle)
        colorSecondary = { r, g, b }
    end

    local extras = {}
    for extraId = 0, 12 do
        if DoesExtraExist(vehicle, extraId) then
            extras[tostring(extraId)] = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
        end
    end

    local modLivery = GetVehicleMod(vehicle, 48)
    if GetVehicleMod(vehicle, 48) == -1 and GetVehicleLivery(vehicle) ~= 0 then
        modLivery = GetVehicleLivery(vehicle)
    end

    local tireHealth = {}
    for i = 0, 3 do
        tireHealth[i] = GetVehicleWheelHealth(vehicle, i)
    end

    local windowStatus = {}
    for i = 0, 7 do
        windowStatus[i] = IsVehicleWindowIntact(vehicle, i) == 1
    end

    local doorStatus = {}
    for i = 0, 5 do
        doorStatus[i] = IsVehicleDoorDamaged(vehicle, i) == 1
    end

    return {
        model = GetEntityModel(vehicle),
        plate = QBCore.Functions.GetPlate(vehicle),
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
        bodyHealth = QBCore.Shared.Round(GetVehicleBodyHealth(vehicle), 0.1),
        engineHealth = QBCore.Shared.Round(GetVehicleEngineHealth(vehicle), 0.1),
        tankHealth = QBCore.Shared.Round(GetVehiclePetrolTankHealth(vehicle), 0.1),
        fuelLevel = QBCore.Shared.Round(GetVehicleFuelLevel(vehicle), 0.1),
        dirtLevel = QBCore.Shared.Round(GetVehicleDirtLevel(vehicle), 0.1),
        oilLevel = QBCore.Shared.Round(GetVehicleOilLevel(vehicle), 0.1),
        color1 = colorPrimary,
        color2 = colorSecondary,
        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,
        wheels = GetVehicleWheelType(vehicle),
        wheelSize = GetVehicleWheelSize(vehicle),
        wheelWidth = GetVehicleWheelWidth(vehicle),
        tireHealth = tireHealth,
        windowTint = GetVehicleWindowTint(vehicle),
        windowStatus = windowStatus,
        doorStatus = doorStatus,
        neonEnabled = {
            IsVehicleNeonLightEnabled(vehicle, 0),
            IsVehicleNeonLightEnabled(vehicle, 1),
            IsVehicleNeonLightEnabled(vehicle, 2),
            IsVehicleNeonLightEnabled(vehicle, 3),
        },
        neonColor = table.pack(GetVehicleNeonLightsColour(vehicle)),
        headlightColor = GetVehicleHeadlightsColour(vehicle),
        interiorColor = GetVehicleInteriorColour(vehicle),
        extras = extras,
        tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicle)),
        modSpoilers = GetVehicleMod(vehicle, 0),
        modFrontBumper = GetVehicleMod(vehicle, 1),
        modRearBumper = GetVehicleMod(vehicle, 2),
        modSideSkirt = GetVehicleMod(vehicle, 3),
        modExhaust = GetVehicleMod(vehicle, 4),
        modFrame = GetVehicleMod(vehicle, 5),
        modGrille = GetVehicleMod(vehicle, 6),
        modHood = GetVehicleMod(vehicle, 7),
        modFender = GetVehicleMod(vehicle, 8),
        modRightFender = GetVehicleMod(vehicle, 9),
        modRoof = GetVehicleMod(vehicle, 10),
        modEngine = GetVehicleMod(vehicle, 11),
        modBrakes = GetVehicleMod(vehicle, 12),
        modTransmission = GetVehicleMod(vehicle, 13),
        modHorns = GetVehicleMod(vehicle, 14),
        modSuspension = GetVehicleMod(vehicle, 15),
        modArmor = GetVehicleMod(vehicle, 16),
        modTurbo = IsToggleModOn(vehicle, 18),
        modSmokeEnabled = IsToggleModOn(vehicle, 20),
        modXenon = IsToggleModOn(vehicle, 22),
        xenonColor = GetVehicleXenonLightsColour(vehicle),
        modFrontWheels = GetVehicleMod(vehicle, 23),
        modBackWheels = GetVehicleMod(vehicle, 24),
        modCustomTiresF = GetVehicleModVariation(vehicle, 23),
        modCustomTiresR = GetVehicleModVariation(vehicle, 24),
        modPlateHolder = GetVehicleMod(vehicle, 25),
        modVanityPlate = GetVehicleMod(vehicle, 26),
        modTrimA = GetVehicleMod(vehicle, 27),
        modOrnaments = GetVehicleMod(vehicle, 28),
        modDashboard = GetVehicleMod(vehicle, 29),
        modDial = GetVehicleMod(vehicle, 30),
        modDoorSpeaker = GetVehicleMod(vehicle, 31),
        modSeats = GetVehicleMod(vehicle, 32),
        modSteeringWheel = GetVehicleMod(vehicle, 33),
        modShifterLeavers = GetVehicleMod(vehicle, 34),
        modAPlate = GetVehicleMod(vehicle, 35),
        modSpeakers = GetVehicleMod(vehicle, 36),
        modTrunk = GetVehicleMod(vehicle, 37),
        modHydrolic = GetVehicleMod(vehicle, 38),
        modEngineBlock = GetVehicleMod(vehicle, 39),
        modAirFilter = GetVehicleMod(vehicle, 40),
        modStruts = GetVehicleMod(vehicle, 41),
        modArchCover = GetVehicleMod(vehicle, 42),
        modAerials = GetVehicleMod(vehicle, 43),
        modTrimB = GetVehicleMod(vehicle, 44),
        modTank = GetVehicleMod(vehicle, 45),
        modWindows = GetVehicleMod(vehicle, 46),
        modLivery = modLivery,
        liveryRoof = GetVehicleRoofLivery(vehicle),
    }
end

function QBCore.Functions.SetVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) or not props then return end
    if props.modKit == nil then SetVehicleModKit(vehicle, 0) else SetVehicleModKit(vehicle, props.modKit) end

    if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
    if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
    if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
    if props.oilLevel then SetVehicleOilLevel(vehicle, props.oilLevel + 0.0) end

    if props.color1 then
        if type(props.color1) == 'table' then
            SetVehicleCustomPrimaryColour(vehicle, props.color1[1], props.color1[2], props.color1[3])
        else
            local _, colorSecondary = GetVehicleColours(vehicle)
            SetVehicleColours(vehicle, props.color1, colorSecondary)
        end
    end
    if props.color2 then
        if type(props.color2) == 'table' then
            SetVehicleCustomSecondaryColour(vehicle, props.color2[1], props.color2[2], props.color2[3])
        else
            local colorPrimary = GetVehicleColours(vehicle)
            SetVehicleColours(vehicle, colorPrimary, props.color2)
        end
    end
    if props.pearlescentColor or props.wheelColor then
        local pearlescent, wheel = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescent, props.wheelColor or wheel)
    end
    if props.interiorColor then SetVehicleInteriorColour(vehicle, props.interiorColor) end
    if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end
    if props.wheelSize then SetVehicleWheelSize(vehicle, props.wheelSize) end
    if props.wheelWidth then SetVehicleWheelWidth(vehicle, props.wheelWidth) end
    if props.tireHealth then
        for i, health in pairs(props.tireHealth) do
            SetVehicleWheelHealth(vehicle, tonumber(i), health)
        end
    end
    if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end

    if props.neonEnabled then
        for i = 1, 4 do
            SetVehicleNeonLightEnabled(vehicle, i - 1, props.neonEnabled[i])
        end
    end
    if props.neonColor then SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3]) end
    if props.headlightColor then SetVehicleHeadlightsColour(vehicle, props.headlightColor) end
    if props.extras then
        for extraId, enabled in pairs(props.extras) do
            SetVehicleExtra(vehicle, tonumber(extraId), enabled and 0 or 1)
        end
    end
    if props.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3]) end

    local simpleMods = {
        modSpoilers = 0, modFrontBumper = 1, modRearBumper = 2, modSideSkirt = 3,
        modExhaust = 4, modFrame = 5, modGrille = 6, modHood = 7, modFender = 8,
        modRightFender = 9, modRoof = 10, modEngine = 11, modBrakes = 12,
        modTransmission = 13, modHorns = 14, modSuspension = 15, modArmor = 16,
        modPlateHolder = 25, modVanityPlate = 26, modTrimA = 27, modOrnaments = 28,
        modDashboard = 29, modDial = 30, modDoorSpeaker = 31, modSeats = 32,
        modSteeringWheel = 33, modShifterLeavers = 34, modAPlate = 35, modSpeakers = 36,
        modTrunk = 37, modHydrolic = 38, modEngineBlock = 39, modAirFilter = 40,
        modStruts = 41, modArchCover = 42, modAerials = 43, modTrimB = 44,
        modTank = 45, modWindows = 46,
    }
    for prop, modId in pairs(simpleMods) do
        if props[prop] ~= nil then SetVehicleMod(vehicle, modId, props[prop], false) end
    end

    if props.modTurbo ~= nil then ToggleVehicleMod(vehicle, 18, props.modTurbo) end
    if props.modSmokeEnabled ~= nil then ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled) end
    if props.modXenon ~= nil then ToggleVehicleMod(vehicle, 22, props.modXenon) end
    if props.xenonColor then SetVehicleXenonLightsColour(vehicle, props.xenonColor) end
    if props.modFrontWheels then SetVehicleMod(vehicle, 23, props.modFrontWheels, props.modCustomTiresF) end
    if props.modBackWheels then SetVehicleMod(vehicle, 24, props.modBackWheels, props.modCustomTiresR) end
    if props.modLivery then
        SetVehicleMod(vehicle, 48, props.modLivery, false)
        SetVehicleLivery(vehicle, props.modLivery)
    end
    if props.liveryRoof then SetVehicleRoofLivery(vehicle, props.liveryRoof) end
end

function QBCore.Functions.DrawText(x, y, width, height, scale, r, g, b, a, text)
    SetTextFont(4)
    SetTextProportional(false)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x - width / 2, y - height / 2 + 0.005)
end

function QBCore.Functions.DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function QBCore.Functions.IsWearingGloves()
    local ped = PlayerPedId()
    local armIndex = GetPedDrawableVariation(ped, 3)
    return armIndex ~= 15
end
