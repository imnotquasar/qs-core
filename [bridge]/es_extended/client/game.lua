-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from ESX Legacy (https://github.com/esx-framework/esx_core),
-- Copyright (C) 2022-2026 ESX Framework, and from QBCore
-- (https://github.com/qbcore-framework/qb-core), Copyright (C) QBCore Framework
-- and contributors. Modified for qscore in 2026: adapted to run on top of
-- qs-core. See NOTICE.

ESX.Game = ESX.Game or {}
ESX.Game.Utils = ESX.Game.Utils or {}
ESX.Streaming = ESX.Streaming or {}

function ESX.Streaming.RequestModel(model, cb)
    model = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(model) then return end
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    if cb then cb(model) end
    return model
end

function ESX.Streaming.RequestStreamedTextureDict(dict, cb)
    RequestStreamedTextureDict(dict, true)
    while not HasStreamedTextureDictLoaded(dict) do Wait(10) end
    if cb then cb(dict) end
    return dict
end

function ESX.Streaming.RequestNamedPtfxAsset(asset, cb)
    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do Wait(10) end
    if cb then cb(asset) end
    return asset
end

function ESX.Streaming.RequestAnimSet(animSet, cb)
    RequestAnimSet(animSet)
    while not HasAnimSetLoaded(animSet) do Wait(10) end
    if cb then cb(animSet) end
    return animSet
end

function ESX.Streaming.RequestAnimDict(dict, cb)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    if cb then cb(dict) end
    return dict
end

function ESX.Streaming.RequestWeaponAsset(weaponHash, cb)
    RequestWeaponAsset(weaponHash, 31, 0)
    while not HasWeaponAssetLoaded(weaponHash) do Wait(10) end
    if cb then cb(weaponHash) end
    return weaponHash
end

function ESX.Game.GetPedMugshot(ped, transparent)
    if not DoesEntityExist(ped) then return end
    local mugshot = transparent and RegisterPedheadshotTransparent(ped) or RegisterPedheadshot(ped)
    while not IsPedheadshotReady(mugshot) do Wait(10) end
    return mugshot, GetPedheadshotTxdString(mugshot)
end

function ESX.Game.Teleport(entity, coords, cb)
    local vector = type(coords) == 'vector4' and coords
        or type(coords) == 'vector3' and vector4(coords, 0.0)
        or vector4(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0, coords.heading or coords.w or 0.0)
    if DoesEntityExist(entity) then
        RequestCollisionAtCoord(vector.xyz)
        local deadline = GetGameTimer() + 3000
        while not HasCollisionLoadedAroundEntity(entity) and GetGameTimer() < deadline do
            Wait(0)
        end
        SetEntityCoords(entity, vector.xyz, false, false, false, false)
        SetEntityHeading(entity, vector.w)
    end
    if cb then cb() end
end

function ESX.Game.SpawnObject(object, coords, cb, networked)
    networked = networked == nil and true or networked
    local model = type(object) == 'string' and joaat(object) or object
    local vector = type(coords) == 'vector3' and coords or vector3(coords.x, coords.y, coords.z)
    CreateThread(function()
        ESX.Streaming.RequestModel(model)
        local obj = CreateObject(model, vector.xyz, networked, false, true)
        SetModelAsNoLongerNeeded(model)
        if cb then cb(obj) end
    end)
end

function ESX.Game.SpawnLocalObject(object, coords, cb)
    ESX.Game.SpawnObject(object, coords, cb, false)
end

function ESX.Game.DeleteVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

function ESX.Game.DeleteObject(object)
    SetEntityAsMissionEntity(object, false, true)
    DeleteObject(object)
end

function ESX.Game.SpawnVehicle(vehicle, coords, heading, cb, networked)
    networked = networked == nil and true or networked
    local model = type(vehicle) == 'string' and joaat(vehicle) or vehicle
    local vector = type(coords) == 'vector3' and coords or vector3(coords.x, coords.y, coords.z)
    if not IsModelInCdimage(model) then return end
    CreateThread(function()
        ESX.Streaming.RequestModel(model)
        local veh = CreateVehicle(model, vector.xyz, heading or 0.0, networked, false)
        NetworkFadeInEntity(veh, true)
        SetModelAsNoLongerNeeded(model)
        SetVehicleNeedsToBeHotwired(veh, false)
        SetVehRadioStation(veh, 'OFF')
        SetVehicleFuelLevel(veh, 100.0)
        local deadline = GetGameTimer() + 3000
        RequestCollisionAtCoord(vector.xyz)
        while not HasCollisionLoadedAroundEntity(veh) and GetGameTimer() < deadline do
            Wait(0)
        end
        if cb then cb(veh) end
    end)
end

function ESX.Game.SpawnLocalVehicle(vehicle, coords, heading, cb)
    ESX.Game.SpawnVehicle(vehicle, coords, heading, cb, false)
end

function ESX.Game.IsVehicleEmpty(vehicle)
    local passengers = GetVehicleNumberOfPassengers(vehicle)
    local driverSeatFree = IsVehicleSeatFree(vehicle, -1)
    return passengers == 0 and driverSeatFree
end

function ESX.Game.GetObjects()
    return GetGamePool('CObject')
end

function ESX.Game.GetPeds(onlyOtherPeds)
    local pool = GetGamePool('CPed')
    if not onlyOtherPeds then return pool end
    local myPed = PlayerPedId()
    local out = {}
    for _, ped in ipairs(pool) do
        if ped ~= myPed then out[#out + 1] = ped end
    end
    return out
end

function ESX.Game.GetVehicles()
    return GetGamePool('CVehicle')
end

function ESX.Game.GetPlayers(onlyOtherPlayers, returnKeyValue, returnPeds)
    local players, myPlayer = {}, PlayerId()
    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        if DoesEntityExist(ped) and ((onlyOtherPlayers and player ~= myPlayer) or not onlyOtherPlayers) then
            if returnKeyValue then
                players[player] = ped
            else
                players[#players + 1] = returnPeds and ped or player
            end
        end
    end
    return players
end

local function getClosestEntity(entities, isPlayerEntities, coords, modelFilter)
    local closestEntity, closestEntityDistance, filteredEntities = -1, -1, nil
    coords = coords and vector3(coords.x, coords.y, coords.z) or GetEntityCoords(PlayerPedId())

    if modelFilter then
        filteredEntities = {}
        for _, entity in ipairs(entities) do
            if modelFilter[GetEntityModel(entity)] then
                filteredEntities[#filteredEntities + 1] = entity
            end
        end
    end

    for k, entity in ipairs(filteredEntities or entities) do
        local distance = #(coords - GetEntityCoords(entity))
        if closestEntityDistance == -1 or distance < closestEntityDistance then
            closestEntity = isPlayerEntities and k or entity
            closestEntityDistance = distance
        end
    end

    return closestEntity, closestEntityDistance
end

function ESX.Game.GetClosestObject(coords, modelFilter)
    return getClosestEntity(GetGamePool('CObject'), false, coords, modelFilter)
end

function ESX.Game.GetClosestPed(coords, modelFilter)
    return getClosestEntity(ESX.Game.GetPeds(true), false, coords, modelFilter)
end

function ESX.Game.GetClosestPlayer(coords)
    local players = ESX.Game.GetPlayers(true, true)
    local closestPlayer, closestDistance = -1, -1
    coords = coords and vector3(coords.x, coords.y, coords.z) or GetEntityCoords(PlayerPedId())
    for player, ped in pairs(players) do
        local distance = #(coords - GetEntityCoords(ped))
        if closestDistance == -1 or distance < closestDistance then
            closestPlayer = player
            closestDistance = distance
        end
    end
    return closestPlayer, closestDistance
end

function ESX.Game.GetClosestVehicle(coords, modelFilter)
    return getClosestEntity(GetGamePool('CVehicle'), false, coords, modelFilter)
end

function ESX.Game.GetPlayersInArea(coords, maxDistance)
    local players = ESX.Game.GetPlayers(true, true)
    local out = {}
    coords = vector3(coords.x, coords.y, coords.z)
    for player, ped in pairs(players) do
        if #(coords - GetEntityCoords(ped)) <= maxDistance then
            out[#out + 1] = player
        end
    end
    return out
end

function ESX.Game.GetVehiclesInArea(coords, maxDistance)
    local out = {}
    coords = vector3(coords.x, coords.y, coords.z)
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if #(coords - GetEntityCoords(vehicle)) <= maxDistance then
            out[#out + 1] = vehicle
        end
    end
    return out
end

function ESX.Game.IsSpawnPointClear(coords, maxDistance)
    return #ESX.Game.GetVehiclesInArea(coords, maxDistance) == 0
end

function ESX.Game.GetVehicleInDirection()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local inDirection = GetOffsetFromEntityInWorldCoords(ped, 0.0, 5.0, 0.0)
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(coords, inDirection, 10, ped, 0)
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)
    if hit == 1 and GetEntityType(entityHit) == 2 then
        return entityHit
    end
    return nil
end

local function getVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then return end
    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    if GetIsVehiclePrimaryColourCustom(vehicle) then
        local r, g, b = GetVehicleCustomPrimaryColour(vehicle)
        colorPrimary = { r, g, b }
    end
    if GetIsVehicleSecondaryColourCustom(vehicle) then
        local r, g, b = GetVehicleCustomSecondaryColour(vehicle)
        colorSecondary = { r, g, b }
    end
    local extras = {}
    for extraId = 0, 12 do
        if DoesExtraExist(vehicle, extraId) then
            extras[tostring(extraId)] = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
        end
    end
    local mods = {}
    for i = 0, 48 do mods[i] = GetVehicleMod(vehicle, i) end

    return {
        model = GetEntityModel(vehicle),
        plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)),
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
        bodyHealth = ESX.Math.Round(GetVehicleBodyHealth(vehicle), 1),
        engineHealth = ESX.Math.Round(GetVehicleEngineHealth(vehicle), 1),
        tankHealth = ESX.Math.Round(GetVehiclePetrolTankHealth(vehicle), 1),
        fuelLevel = ESX.Math.Round(GetVehicleFuelLevel(vehicle), 1),
        dirtLevel = ESX.Math.Round(GetVehicleDirtLevel(vehicle), 1),
        color1 = colorPrimary,
        color2 = colorSecondary,
        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,
        wheels = GetVehicleWheelType(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),
        neonEnabled = {
            IsVehicleNeonLightEnabled(vehicle, 0),
            IsVehicleNeonLightEnabled(vehicle, 1),
            IsVehicleNeonLightEnabled(vehicle, 2),
            IsVehicleNeonLightEnabled(vehicle, 3),
        },
        neonColor = table.pack(GetVehicleNeonLightsColour(vehicle)),
        extras = extras,
        tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicle)),
        xenonColor = GetVehicleXenonLightsColour(vehicle),
        modSpoilers = mods[0], modFrontBumper = mods[1], modRearBumper = mods[2],
        modSideSkirt = mods[3], modExhaust = mods[4], modFrame = mods[5],
        modGrille = mods[6], modHood = mods[7], modFender = mods[8],
        modRightFender = mods[9], modRoof = mods[10], modEngine = mods[11],
        modBrakes = mods[12], modTransmission = mods[13], modHorns = mods[14],
        modSuspension = mods[15], modArmor = mods[16],
        modTurbo = IsToggleModOn(vehicle, 18),
        modSmokeEnabled = IsToggleModOn(vehicle, 20),
        modXenon = IsToggleModOn(vehicle, 22),
        modFrontWheels = mods[23], modBackWheels = mods[24],
        modPlateHolder = mods[25], modVanityPlate = mods[26], modTrimA = mods[27],
        modOrnaments = mods[28], modDashboard = mods[29], modDial = mods[30],
        modDoorSpeaker = mods[31], modSeats = mods[32], modSteeringWheel = mods[33],
        modShifterLeavers = mods[34], modAPlate = mods[35], modSpeakers = mods[36],
        modTrunk = mods[37], modHydrolic = mods[38], modEngineBlock = mods[39],
        modAirFilter = mods[40], modStruts = mods[41], modArchCover = mods[42],
        modAerials = mods[43], modTrimB = mods[44], modTank = mods[45],
        modWindows = mods[46], modLivery = GetVehicleLivery(vehicle),
    }
end

local function setVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) or not props then return end
    SetVehicleModKit(vehicle, 0)
    if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
    if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
    if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
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
    if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end
    if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end
    if props.neonEnabled then
        for i = 1, 4 do SetVehicleNeonLightEnabled(vehicle, i - 1, props.neonEnabled[i]) end
    end
    if props.neonColor then SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3]) end
    if props.extras then
        for extraId, enabled in pairs(props.extras) do
            SetVehicleExtra(vehicle, tonumber(extraId), enabled and 0 or 1)
        end
    end
    if props.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3]) end
    if props.xenonColor then SetVehicleXenonLightsColour(vehicle, props.xenonColor) end

    local simpleMods = {
        modSpoilers = 0, modFrontBumper = 1, modRearBumper = 2, modSideSkirt = 3,
        modExhaust = 4, modFrame = 5, modGrille = 6, modHood = 7, modFender = 8,
        modRightFender = 9, modRoof = 10, modEngine = 11, modBrakes = 12,
        modTransmission = 13, modHorns = 14, modSuspension = 15, modArmor = 16,
        modFrontWheels = 23, modBackWheels = 24, modPlateHolder = 25,
        modVanityPlate = 26, modTrimA = 27, modOrnaments = 28, modDashboard = 29,
        modDial = 30, modDoorSpeaker = 31, modSeats = 32, modSteeringWheel = 33,
        modShifterLeavers = 34, modAPlate = 35, modSpeakers = 36, modTrunk = 37,
        modHydrolic = 38, modEngineBlock = 39, modAirFilter = 40, modStruts = 41,
        modArchCover = 42, modAerials = 43, modTrimB = 44, modTank = 45, modWindows = 46,
    }
    for prop, modId in pairs(simpleMods) do
        if props[prop] ~= nil then SetVehicleMod(vehicle, modId, props[prop], false) end
    end
    if props.modTurbo ~= nil then ToggleVehicleMod(vehicle, 18, props.modTurbo) end
    if props.modSmokeEnabled ~= nil then ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled) end
    if props.modXenon ~= nil then ToggleVehicleMod(vehicle, 22, props.modXenon) end
    if props.modLivery then
        SetVehicleMod(vehicle, 48, props.modLivery, false)
        SetVehicleLivery(vehicle, props.modLivery)
    end
end

ESX.Game.GetVehicleProperties = getVehicleProperties
ESX.Game.SetVehicleProperties = setVehicleProperties

function ESX.Game.Utils.DrawText3D(coords, text, size, font)
    size = size or 1
    font = font or 0
    local vector = type(coords) == 'vector3' and coords or vector3(coords.x, coords.y, coords.z)
    local camCoords = GetFinalRenderedCamCoord()
    local distance = #(vector - camCoords)
    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    SetTextScale(0.0 * scale, 0.55 * scale)
    SetTextFont(font)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(vector.xyz, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end
