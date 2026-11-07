local isServer = IsDuplicityVersion()

local qbx = {}
qbx.string = {}
qbx.math = {}
qbx.table = {}
qbx.array = {}

qbx.armsWithoutGloves = lib.table.freeze({
    male = lib.table.freeze({
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
    }),

    female = lib.table.freeze({
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
    }),
})

qbx.duffelbagIndexes = lib.table.freeze({
    male = lib.table.freeze({
        [40] = true,
        [41] = true,
        [44] = true,
        [45] = true,
        [81] = true,
        [82] = true,
        [85] = true,
        [86] = true,
        [130] = true,
        [131] = true,
        [132] = true
    }),
    female = lib.table.freeze({
        [40] = true,
        [41] = true,
        [44] = true,
        [45] = true,
        [81] = true,
        [82] = true,
        [85] = true,
        [86] = true,
        [131] = true,
        [132] = true,
        [133] = true
    })
})

function qbx.string.trim(str)
    local trimmed = str:gsub('^%s*(.-)%s*$', '%1')
    return trimmed
end

function qbx.string.capitalize(str)
    local capitalized = str:gsub('^%l', string.upper)
    return capitalized
end

function qbx.math.round(num, decimalPlaces)
    if not decimalPlaces then return math.floor(num + 0.5) end
    local power = 10 ^ decimalPlaces
    return math.floor((num * power) + 0.5) / power
end

function qbx.math.isFinite(value)
    return type(value) == 'number' and value == value and value ~= math.huge and value ~= -math.huge
end

function qbx.table.size(tbl)
    local size = 0
    for _ in pairs(tbl) do
        size += 1
    end
    return size
end

function qbx.table.mapBySubfield(tble, subfield)
    local map = {}

    for _, subTable in pairs(tble) do
        local subfieldValue = subTable[subfield]

        if subfieldValue then
            if not map[subfieldValue] then
                map[subfieldValue] = {}
            end

            map[subfieldValue][#map[subfieldValue] + 1] = subTable
        end
    end

    return map
end

function qbx.array.contains(arr, val)
    for i = 1, #arr do
        if arr[i] == val then
            return true
        end
    end

    return false
end

function qbx.getVehiclePlate(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then return end
    return qbx.string.trim(plate)
end

function qbx.generateRandomPlate(pattern)
    pattern = pattern or '........'
    return lib.string.random(pattern):upper()
end

function qbx.getCardinalDirection(entity)
    local heading = GetEntityHeading(entity) % 360

    if heading < 45 or heading >= 315 then
        return 'North'
    end

    if heading >= 45 and heading < 135 then
        return 'West'
    end

    if heading >= 135 and heading < 225 then
        return 'South'
    end

    return 'East'
end

if isServer then

    function qbx.spawnVehicle(params)
        local model = params.model
        local source = params.spawnSource
        local sourceType = type(source)
        local warp = params.warp
        local ped = type(warp) == 'number' and warp or (sourceType == 'number' and warp and source or nil)
        local props = params.props
        local bucket = params.bucket or ped and GetEntityRoutingBucket(ped) or nil

        local coords
        if sourceType == 'vector3' then
            coords = vec4(source.x, source.y, source.z, 0)
        elseif sourceType == 'vector4' then
            coords = source
        else
            local pedCoords = GetEntityCoords(source)
            coords = vec4(pedCoords.x, pedCoords.y, pedCoords.z, GetEntityHeading(source))
        end

        local vehicleType = exports.qbx_core:GetVehiclesByHash(joaat(model)).type
        if not vehicleType then
            warn(('No vehicle type found for model: %s temp vehicle was created and taken in type'):format(
                model))

            local tempVehicle = CreateVehicle(model, 0, 0, -200, 0, true, true)
            while not DoesEntityExist(tempVehicle) do Wait(0) end

            vehicleType = GetVehicleType(tempVehicle)
            DeleteEntity(tempVehicle)
        end

        local attempts = 0

        local veh, netId
        while attempts < 3 do
            veh = CreateVehicleServerSetter(model, vehicleType, coords.x, coords.y, coords.z, coords.w)

            if bucket and bucket > 0 then
                exports.qbx_core:SetEntityBucket(veh, bucket)
            end

            while not DoesEntityExist(veh) do Wait(0) end
            while GetVehicleNumberPlateText(veh) == '' do Wait(0) end

            if ped then
                SetPedIntoVehicle(ped, veh, -1)
            end

            if not pcall(function()
                lib.waitFor(function()
                    local owner = NetworkGetEntityOwner(veh)
                    if ped then
                        if owner == NetworkGetEntityOwner(ped) then return true end
                    else
                        if owner ~= -1 then return true end
                    end
                end, 'client never set as owner', 5000)
            end) then
                DeleteEntity(veh)
                error('Deleting vehicle which timed out finding an owner')
            end

            local state = Entity(veh).state
            local owner = NetworkGetEntityOwner(veh)
            state:set('initVehicle', true, true)
            netId = NetworkGetNetworkIdFromEntity(veh)
            if props and type(props) == 'table' and props.plate then
                TriggerClientEvent('qbx_core:client:setVehicleProperties', owner, netId, props)
                local success = pcall(function()
                    local plateMatched = false
                    lib.waitFor(function()
                        if qbx.string.trim(GetVehicleNumberPlateText(veh)) == qbx.string.trim(props.plate) then
                            local currentOwner = NetworkGetEntityOwner(veh)
                            assert(currentOwner == owner, ('Owner changed during vehicle init. expected=%s, actual=%s'):format(owner, currentOwner))
                            if plateMatched then
                                return true
                            end
                            plateMatched = true
                            Wait(100)
                        end
                    end, 'Failed to set vehicle properties within 1 second', 1000)
                end)
                if success then
                    break
                else
                    DeleteEntity(veh)
                    attempts += 1
                end
            else
                break
            end
        end

        if attempts == 3 then
            error('unable to successfully spawn vehicle after 3 attempts')
        end

        SetEntityOrphanMode(veh, 2)
        exports.qbx_core:EnablePersistence(veh)
        return netId, veh
    end
else

    function qbx.drawText2d(params)
        local text = params.text
        local coords = params.coords
        local scale = params.scale or 0.35
        local font = params.font or 4
        local color = params.color or vec4(255, 255, 255, 255)
        local width = params.width or 1.0
        local height = params.height or 1.0
        local enableDropShadow = params.enableDropShadow or false
        local enableOutline = params.enableOutline or false

        SetTextScale(scale, scale)
        SetTextFont(font)
        SetTextColour(math.floor(color.r), math.floor(color.g), math.floor(color.b), math.floor(color.a))
        if enableDropShadow then
            SetTextDropShadow()
        end
        if enableOutline then
            SetTextOutline()
        end

        SetTextCentre(true)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(coords.x - width / 2, coords.y - height / 2 + 0.005)
    end

    function qbx.drawText3d(params)
        local isScaleparamANumber = type(params.scale) == "number"
        local text = params.text
        local coords = params.coords
        local scale = (isScaleparamANumber and vec2(params.scale, params.scale))
        or params.scale
        or vec2(0.35, 0.35)
        local font = params.font or 4
        local color = params.color or vec4(255, 255, 255, 255)
        local enableDropShadow = params.enableDropShadow or false
        local enableOutline = params.enableOutline or false

        SetTextScale(scale.x, scale.y)
        SetTextFont(font)
        SetTextColour(math.floor(color.r), math.floor(color.g), math.floor(color.b), math.floor(color.a))
        if enableDropShadow then
            SetTextDropShadow()
        end
        if enableOutline then
            SetTextOutline()
        end
        SetTextCentre(true)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(text)
        SetDrawOrigin(coords.x, coords.y, coords.z, 0)
        EndTextCommandDisplayText(0.0, 0.0)

        if not params.disableDrawRect then
            local factor = #text / 370
            DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
        end
        ClearDrawOrigin()
    end

    function qbx.getEntityAndNetIdFromBagName(bagName)
        local netId = tonumber(bagName:gsub('entity:', ''), 10)

        local entity = lib.waitFor(function()
            if NetworkDoesEntityExistWithNetworkId(netId) then
                return NetworkGetEntityFromNetworkId(netId)
            end
        end, ('statebag timed out while awaiting entity creation! (%s)'):format(bagName), 10000)

        if not entity then
            lib.print.error(('statebag received invalid entity! (%s)'):format(bagName))
            return 0, 0
        end

        return entity, netId
    end

    function qbx.entityStateHandler(keyFilter, cb)
        return AddStateBagChangeHandler(keyFilter, '', function(bagName, _, value)
            local entity, netId = qbx.getEntityAndNetIdFromBagName(bagName)
            if entity then
                cb(entity, netId, value, bagName)
            end
        end)
    end

    function qbx.deleteVehicle(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        return not DoesEntityExist(vehicle)
    end

    function qbx.getVehicleDisplayName(vehicle)
        return GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    end

    function qbx.getVehicleMakeName(vehicle)
        return GetLabelText(GetMakeNameFromVehicleModel(GetEntityModel(vehicle)))
    end

    function qbx.getVehicleModName(vehicle, modType, modIndex)
        return GetLabelText(GetModTextLabel(vehicle, modType, modIndex))
    end

    function qbx.getVehicleLiveryName(vehicle, liveryIndex)
        return GetLabelText(GetLiveryName(vehicle, liveryIndex))
    end

    function qbx.getStreetName(coords)
        local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        return { main = GetStreetNameFromHashKey(street1), cross = GetStreetNameFromHashKey(street2) }
    end

    function qbx.getZoneName(coords)
        return GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
    end

    function qbx.setVehicleExtra(vehicle, extra, enable)
        if not DoesExtraExist(vehicle, extra) then return end
        SetVehicleExtra(vehicle, extra, not enable)
    end

    function qbx.resetVehicleExtras(vehicle)
        for i = 1, 20 do
            qbx.setVehicleExtra(vehicle, i, true)
        end
    end

    function qbx.setVehicleExtras(vehicle, extras)
        qbx.resetVehicleExtras(vehicle)

        for id, enable in pairs(extras) do
            qbx.setVehicleExtra(vehicle, id, enable)
        end
    end

    function qbx.isWearingGloves()
        local armIndex = GetPedDrawableVariation(cache.ped, 3)
        local model = GetEntityModel(cache.ped)
        local tble = qbx.armsWithoutGloves[model == `mp_m_freemode_01` and 'male' or 'female']
        return not tble[armIndex]
    end

    function qbx.isWearingDuffelbag()
        local torsoIndex = GetPedDrawableVariation(cache.ped, 5)
        local model = GetEntityModel(cache.ped)
        local tble = qbx.duffelbagIndexes[model == `mp_m_freemode_01` and 'male' or 'female']
        return tble[torsoIndex] == true
    end

    function qbx.loadAudioBank(audioBank, timeout)
        return lib.waitFor(function()
            if RequestScriptAudioBank(audioBank, false) then
                return true
            end
        end, ('timed out while requesting audio bank! (%s)'):format(audioBank), timeout or 500) or false
    end

    function qbx.playAudio(params)
        local audioName = params.audioName
        local audioRef = params.audioRef
        local returnSoundId = params.returnSoundId or false
        local source = params.audioSource
        local range = params.range or 5.0

        local soundId = GetSoundId()

        local sourceType = type(source)
        if sourceType == 'vector3' then
            local coords = source
            PlaySoundFromCoord(soundId, audioName, coords.x, coords.y, coords.z, audioRef, false, range, false)
        elseif sourceType == 'number' then
            PlaySoundFromEntity(soundId, audioName, source, audioRef, false, false)
        else
            PlaySoundFrontend(soundId, audioName, audioRef, true)
        end

        if returnSoundId then
            return soundId
        end

        ReleaseSoundId(soundId)
    end
end

_ENV.qbx = qbx
