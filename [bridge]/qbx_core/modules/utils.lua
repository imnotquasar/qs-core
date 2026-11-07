lib.print.warn('This resource is still using the deprecated qbx_core utils!')
lib.print.warn(
    'If you are the author, please update to use the new lib module. If you are not, please tell them to update!')

local isServer = IsDuplicityVersion()

local oldqbx = qbx
require 'modules.lib'
local qbx = qbx
_ENV.qbx = oldqbx

function GetCoordsFromEntity(entity)
    local coords = GetEntityCoords(entity)
    return vec4(coords.x, coords.y, coords.z, GetEntityHeading(entity))
end

function GetPlate(vehicle)
    if not vehicle or vehicle == 0 then return end
    return qbx.getVehiclePlate(vehicle)
end

function CommaValue(num)
    return lib.math.groupdigits(num)
end

function string.split(str, delimiter)
    local result = table.pack(string.strsplit(delimiter, str))
    result.n = nil
    return result
end

function string.trim(str)
    if not str then return end
    return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

function string.firstToUpper(str)
    if not str or str == '' then return end
    return str:gsub('^%l', string.upper)
end

function math.round(value, numDecimalPlaces)
    return qbx.math.round(value, numDecimalPlaces)
end

function RandomLetter(length)
    if length <= 0 then return '' end
    local pattern = math.random(2) == 1 and 'a' or 'A'
    return RandomLetter(length - 1) .. lib.string.random(pattern)
end

function RandomNumber(length)
    if length <= 0 then return '' end
    return RandomNumber(length - 1) .. lib.string.random('1')
end

function RandomNumberOrLetter(length)
    if length <= 0 then return '' end
    local func = math.random(2) == 1 and RandomLetter or RandomNumber
    return RandomNumberOrLetter(length - 1) .. func(1)
end

function GenerateRandomPlate(pattern)
    return qbx.generateRandomPlate(pattern:upper())
end

function MapTableBySubfield(subfield, table)
    return qbx.table.mapBySubfield(table, subfield)
end

if isServer then
    function SpawnVehicle(source, model, coords, warp, props)
        model = type(model) == 'string' and joaat(model) or (model )
        local ped = GetPlayerPed(source)

        local netId, _ = qbx.spawnVehicle({
            model = model,
            spawnSource = coords or ped,
            warp = warp and ped or nil,
            props = props,
        })

        return netId
    end

    local discordLink = GetConvar('qbx:discordlink', 'discord.gg/qbox')
    function KickWithReason(source, reason, setKickReason, deferrals)
        reason = ('\n %s \n 🔸 Check our Discord for further information: %s'):format(reason, discordLink)
        if setKickReason then
            setKickReason(reason)
        end
        CreateThread(function()
            if deferrals then
                deferrals.update(reason)
                Wait(2500)
            end
            if source then
                DropPlayer(source , reason)
            end
            for _ = 0, 4 do
                while true do
                    if source then
                        if GetPlayerPing(source ) >= 0 then
                            break
                        end
                        Wait(100)
                        CreateThread(function()
                            DropPlayer(source , reason)
                        end)
                    end
                end
                Wait(5000)
            end
        end)
    end

    function IsLicenseInUse(license)
        local players = GetPlayers()

        for _, player in pairs(players) do
            local plyLicense2 = GetPlayerIdentifierByType(player , 'license2')
            local plyLicense = GetPlayerIdentifierByType(player , 'license')
            if plyLicense2 == license or plyLicense == license then
                return true
            end
        end

        return false
    end

    function HasItem(source, items, amount)
        return exports.qbx_core:HasItem(source, items, amount)
    end
else
    function DrawText2D(text, coords, width, height, scale, font, r, g, b, a)
        qbx.drawText2d({
            text = text,
            coords = coords,
            width = width,
            height = height,
            scale = scale,
            font = font,
            color = vec4(r or 255, g or 255, b or 255, a or 215),
        })
    end

    function DrawText3D(text, coords, scale, font, r, g, b, a)
        qbx.drawText3d({
            text = text,
            coords = coords,
            scale = scale,
            font = font,
            color = vec4(r or 255, g or 255, b or 255, a or 215),
        })
    end

    function GetEntityAndNetIdFromBagName(bagName)
        return qbx.getEntityAndNetIdFromBagName(bagName)
    end

    function EntityStateHandler(keyFilter, cb)
        return qbx.entityStateHandler(keyFilter, cb)
    end

    function HasItem(items, amount)
        return exports.qbx_core:HasItem(items, amount)
    end

    function PlayAnim(animDict, animName, upperbodyOnly, duration)
        local flags = upperbodyOnly and 16 or 0
        local runTime = duration or -1
        lib.playAnim(cache.ped, animDict, animName, 8.0, 3.0, runTime, flags, 0.0, false, false, true)
    end

    function GetEntities(pool, ignoreList)
        ignoreList = ignoreList or {}
        local ents = GetGamePool(pool)
        local entities = {}
        local ignoreMap = {}
        for i = 1, #ignoreList do
            ignoreMap[ignoreList[i]] = true
        end

        for i = 1, #ents do
            local entity = ents[i]
            if not ignoreMap[entity] then
                entities[#entities + 1] = entity
            end
        end
        return entities
    end

    function GetVehicles(ignoreList)
        return GetEntities('CVehicle', ignoreList)
    end

    function GetObjects(ignoreList)
        return GetEntities('CObject', ignoreList)
    end

    function GetPeds(ignoreList)
        return GetEntities('CPed', ignoreList)
    end

    function GetPickups(ignoreList)
        return GetEntities('CPickups', ignoreList)
    end

    function GetPlayersInScope(ignoreList)
        ignoreList = ignoreList or {}
        local plys = GetActivePlayers()
        local players = {}
        local ignoreMap = {}
        for i = 1, #ignoreList do
            ignoreMap[ignoreList[i]] = true
        end

        for i = 1, #plys do
            local player = plys[i]
            if not ignoreMap[player] then
                players[#players + 1] = player
            end
        end
        return players
    end

    function GetClosestEntity(entities, coords)
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)
        local closestDistance = -1
        local closestEntity = -1
        for i = 1, #entities do
            local entity = entities[i]
            local entityCoords = GetEntityCoords(entity)
            local distance = #(entityCoords - coords)
            if closestDistance == -1 or closestDistance > distance then
                closestEntity = entity
                closestDistance = distance
            end
        end
        return closestEntity, closestDistance
    end

    function GetClosestPed(coords, ignoreList)
        return GetClosestEntity(GetPeds(ignoreList), coords)
    end

    function GetClosestVehicle(coords, ignoreList)
        return GetClosestEntity(GetVehicles(ignoreList), coords)
    end

    function GetClosestObject(coords, ignoreList)
        return GetClosestEntity(GetObjects(ignoreList), coords)
    end

    local _deleteVehicle = DeleteVehicle

    function DeleteVehicle(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)
        _deleteVehicle(vehicle)
        return DoesEntityExist(vehicle)
    end

    function GetClosestPlayer(coords, maxDistance)
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)
        local playerId, _, playerCoords = lib.getClosestPlayer(coords, maxDistance or 50, false)
        local closestDistance = playerCoords and #(playerCoords - coords) or nil
        return playerId, closestDistance
    end

    function GetPlayersFromCoords(coords, distance)
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)
        local players = lib.getNearbyPlayers(coords, distance or 5, true)

        for i = 1, #players do
            players[i] = players[i].id
        end

        return players
    end

    function GetClosestBone(entity, list)
        local playerCoords = GetEntityCoords(cache.ped)

        local bone, coords, distance
        for _, element in pairs(list) do
            local boneCoords = GetWorldPositionOfEntityBone(entity, element.id or element)
            local boneDistance = #(playerCoords - boneCoords)
            if not coords or distance > boneDistance then
                bone = element
                coords = boneCoords
                distance = boneDistance
            end
        end
        if not bone then
            bone = { id = GetEntityBoneIndexByName(entity, 'bodyshell'), type = 'remains', name = 'bodyshell' }
            coords = GetWorldPositionOfEntityBone(entity, bone.id)
            distance = #(coords - playerCoords)
        end
        return bone, coords, distance
    end

    function GetBoneDistance(entity, boneType, bone)
        local boneIndex = boneType == 1 and GetPedBoneIndex(entity, bone ) or
            GetEntityBoneIndexByName(entity, bone )
        local boneCoords = GetWorldPositionOfEntityBone(entity, boneIndex)
        local playerCoords = GetEntityCoords(cache.ped)
        return #(playerCoords - boneCoords)
    end

    function AttachProp(ped, model, boneId, x, y, z, xR, yR, zR, vertex)
        local modelHash = type(model) == 'string' and joaat(model) or model
        local bone = GetPedBoneIndex(ped, boneId)
        lib.requestModel(modelHash)
        local prop = CreateObject(modelHash, 1.0, 1.0, 1.0, true, true, false)
        AttachEntityToEntity(prop, ped, bone, x, y, z, xR, yR, zR, true, true, false, true, not vertex and 2 or 0, true)
        SetModelAsNoLongerNeeded(modelHash)
        return prop
    end

    function GetVehicleDisplayName(vehicle)
        return qbx.getVehicleDisplayName(vehicle)
    end

    function GetVehicleMakeName(vehicle)
        return qbx.getVehicleMakeName(vehicle)
    end

    function IsVehicleSpawnClear(coords, radius)
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)
        radius = radius or 5
        local vehicles = GetGamePool('CVehicle')
        local closeVeh = {}
        for i = 1, #vehicles do
            local vehicleCoords = GetEntityCoords(vehicles[i])
            local distance = #(vehicleCoords - coords)
            if distance <= radius then
                closeVeh[#closeVeh + 1] = vehicles[i]
            end
        end
        return #closeVeh == 0
    end

    function StartParticleAtCoord(dict, ptName, looped, coords, rot, scale, alpha, color, duration)
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)

        lib.requestNamedPtfxAsset(dict)
        UseParticleFxAssetNextCall(dict)
        SetPtfxAssetNextCall(dict)
        local particleHandle
        if looped then
            particleHandle = StartParticleFxLoopedAtCoord(ptName, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z,
                scale or 1.0, false, false, false, false)
            if color then
                SetParticleFxLoopedColour(particleHandle, color.r, color.g, color.b, false)
            end
            SetParticleFxLoopedAlpha(particleHandle, alpha or 10.0)
            if duration then
                Wait(duration)
                StopParticleFxLooped(particleHandle, false)
            end
        else
            SetParticleFxNonLoopedAlpha(alpha or 1.0)
            if color then
                SetParticleFxNonLoopedColour(color.r, color.g, color.b)
            end
            StartParticleFxNonLoopedAtCoord(ptName, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, scale or 1.0,
                false, false, false)
        end
        return particleHandle
    end

    function StartParticleOnEntity(dict, ptName, looped, entity, bone, offset, rot, scale, alpha, color, evolution,
                                   duration)
        lib.requestNamedPtfxAsset(dict)
        UseParticleFxAssetNextCall(dict)
        local particleHandle = nil
        local pedBoneIndex = bone and GetPedBoneIndex(entity, bone) or 0
        local nameBoneIndex = bone and GetEntityBoneIndexByName(entity, bone) or 0
        local entityType = GetEntityType(entity)
        local boneID = entityType == 1 and (pedBoneIndex ~= 0 and pedBoneIndex) or
            (looped and nameBoneIndex ~= 0 and nameBoneIndex)
        if looped then
            if boneID then
                particleHandle = StartParticleFxLoopedOnEntityBone(ptName, entity, offset.x, offset.y, offset.z, rot.x,
                    rot.y, rot.z, boneID, scale or 1.0, false, false, false)
            else
                particleHandle = StartParticleFxLoopedOnEntity(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot
                    .y, rot.z, scale or 1.0, false, false, false)
            end
            if evolution then
                SetParticleFxLoopedEvolution(particleHandle, evolution.name, evolution.amount, false)
            end
            if color then
                SetParticleFxLoopedColour(particleHandle, color.r, color.g, color.b, false)
            end
            SetParticleFxLoopedAlpha(particleHandle, alpha or 1.0)
            if duration then
                Wait(duration)
                StopParticleFxLooped(particleHandle, false)
            end
        else
            SetParticleFxNonLoopedAlpha(alpha or 1.0)
            if color then
                SetParticleFxNonLoopedColour(color.r, color.g, color.b)
            end
            if boneID then
                StartParticleFxNonLoopedOnPedBone(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z,
                    boneID, scale or 1.0, false, false, false)
            else
                StartParticleFxNonLoopedOnEntity(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z,
                    scale or 1.0, false, false, false)
            end
        end
        return particleHandle
    end

    function GetStreetNameAtCoords(coords)
        return qbx.getStreetName(coords)
    end

    function GetZoneAtCoords(coords)
        return qbx.getZoneName(coords)
    end

    function GetCardinalDirection(entity)
        entity = entity or cache.ped
        if not entity or not DoesEntityExist(entity) then
            return 'Entity does not exist'
        end

        return qbx.getCardinalDirection(entity)
    end

    function GetCurrentTime()
        local obj = {}
        obj.min = GetClockMinutes()
        obj.hour = GetClockHours()

        if obj.hour == 0 then
            obj.ampm = 'AM'
            obj.formattedHour = 12
        elseif obj.hour < 12 then
            obj.ampm = 'AM'
            obj.formattedHour = obj.hour
        elseif obj.hour == 12 then
            obj.ampm = 'PM'
            obj.formattedHour = 12
        else
            obj.ampm = 'PM'
            obj.formattedHour = obj.hour - 12
        end

        if obj.min <= 9 then
            obj.formattedMin = ('0%s'):format(obj.min)
        end

        return obj
    end

    function GetGroundZCoord(coords)
        if not coords then return end

        local retval, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
        if retval then
            return vec3(coords.x, coords.y, groundZ)
        end

        lib.print.verbose('Couldn\'t find Ground Z Coordinates given 3D Coordinates:', coords)
        return coords
    end

    function ChangeVehicleExtra(vehicle, extra, enable)
        qbx.setVehicleExtra(vehicle, extra, enable)
    end

    function SetVehicleExtras(vehicle, extras)
        qbx.setVehicleExtras(vehicle, extras)
    end

    MaleNoGloves = {
        [0] = true,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
        [6] = true,
        [7] = true,
        [8] = true,
        [9] = true,
        [10] = true,
        [11] = true,
        [12] = true,
        [13] = true,
        [14] = true,
        [15] = true,
        [18] = true,
        [26] = true,
        [52] = true,
        [53] = true,
        [54] = true,
        [55] = true,
        [56] = true,
        [57] = true,
        [58] = true,
        [59] = true,
        [60] = true,
        [61] = true,
        [62] = true,
        [112] = true,
        [113] = true,
        [114] = true,
        [118] = true,
        [125] = true,
        [132] = true
    }

    FemaleNoGloves = {
        [0] = true,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
        [6] = true,
        [7] = true,
        [8] = true,
        [9] = true,
        [10] = true,
        [11] = true,
        [12] = true,
        [13] = true,
        [14] = true,
        [15] = true,
        [19] = true,
        [59] = true,
        [60] = true,
        [61] = true,
        [62] = true,
        [63] = true,
        [64] = true,
        [65] = true,
        [66] = true,
        [67] = true,
        [68] = true,
        [69] = true,
        [70] = true,
        [71] = true,
        [129] = true,
        [130] = true,
        [131] = true,
        [135] = true,
        [142] = true,
        [149] = true,
        [153] = true,
        [157] = true,
        [161] = true,
        [165] = true
    }

    function IsWearingGloves()
        local armIndex = GetPedDrawableVariation(cache.ped, 3)
        local model = GetEntityModel(cache.ped)
        local tbl = model == `mp_m_freemode_01` and MaleNoGloves or FemaleNoGloves
        return not tbl[armIndex]
    end

    function LoadAudioBank(audioBank, timeout)
        return qbx.loadAudioBank(audioBank, timeout)
    end

    function PlayAudio(audioName, audioRef, returnSoundId, entity, coords, range)
        return qbx.playAudio({
            audioName = audioName,
            audioRef = audioRef,
            returnSoundId = returnSoundId,
            audioSource = coords or entity,
            range = range,
        })
    end
end