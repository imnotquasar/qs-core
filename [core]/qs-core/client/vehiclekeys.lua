VehicleKeys = VehicleKeys or {}

local function trim(s) return s and (tostring(s):match('^%s*(.-)%s*$')) or s end

local function running(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

function VehicleKeys.Backend()
    if running('qs-vehiclekeys') then return 'qs-vehiclekeys' end
    if running('qs-corevehiclekeys') then return 'qs-corevehiclekeys' end
    return nil
end

local function vehicleByPlate(plate)
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(veh) and trim(GetVehicleNumberPlateText(veh)) == plate then
            return veh
        end
    end
end

local function modelName(model)
    if type(model) == 'number' then
        local name = GetDisplayNameFromVehicleModel(model)
        if name and name ~= '' and name ~= 'CARNOTFOUND' then return name end
        return nil
    end
    if type(model) == 'string' and model ~= '' then
        local hash = joaat(model)
        if IsModelInCdimage(hash) then
            local name = GetDisplayNameFromVehicleModel(hash)
            if name and name ~= '' and name ~= 'CARNOTFOUND' then return name end
        end
        return model
    end
    return nil
end

local function resolve(target, model)
    local plate, veh
    if type(target) == 'number' and DoesEntityExist(target) then
        veh = target
        plate = trim(GetVehicleNumberPlateText(veh))
    elseif target ~= nil then
        plate = trim(target)
        veh = vehicleByPlate(plate)
    end
    if not plate or plate == '' then return nil end
    local name = modelName(model)
    if not name and veh then name = modelName(GetEntityModel(veh)) end
    return plate, name, veh
end

function VehicleKeys.Give(target, model)
    local plate, name = resolve(target, model)
    if not plate then return false end
    local backend = VehicleKeys.Backend()
    if backend == 'qs-vehiclekeys' then
        if name then
            exports['qs-vehiclekeys']:GiveKeys(plate, name, false)
        else
            TriggerEvent('vehiclekeys:client:SetOwner', plate)
        end
        return true
    elseif backend == 'qs-corevehiclekeys' then
        exports['qs-corevehiclekeys']:GiveKeys(plate)
        return true
    end
    return false
end

function VehicleKeys.Remove(target, model)
    local plate, name = resolve(target, model)
    if not plate then return false end
    local backend = VehicleKeys.Backend()
    if backend == 'qs-vehiclekeys' then
        if name then
            exports['qs-vehiclekeys']:RemoveKeys(plate, name)
        else
            TriggerEvent('qb-vehiclekeys:client:RemoveKeys', plate)
        end
        return true
    elseif backend == 'qs-corevehiclekeys' then
        exports['qs-corevehiclekeys']:RemoveKeys(plate)
        return true
    end
    return false
end

function VehicleKeys.Has(target, model)
    local plate, name, veh = resolve(target, model)
    if not plate then return false end
    local backend = VehicleKeys.Backend()
    if backend == 'qs-vehiclekeys' then
        if name then return exports['qs-vehiclekeys']:GetKey(plate, name) == true end
        return exports['qs-vehiclekeys']:HasKeys(veh or plate) == true
    elseif backend == 'qs-corevehiclekeys' then
        return exports['qs-corevehiclekeys']:HasKeys(plate) == true
    end
    return true
end

exports('GetVehicleKeysBackend', VehicleKeys.Backend)
exports('GiveVehicleKeys', VehicleKeys.Give)
exports('RemoveVehicleKeys', VehicleKeys.Remove)
exports('HasVehicleKeys', VehicleKeys.Has)

RegisterNetEvent('qs:client:giveVehicleKeys', function(netId, plate, model)
    local veh = netId and NetworkDoesNetworkIdExist(netId) and NetToVeh(netId) or 0
    VehicleKeys.Give(veh ~= 0 and veh or plate, model)
end)

RegisterNetEvent('qs:client:removeVehicleKeys', function(netId, plate, model)
    local veh = netId and NetworkDoesNetworkIdExist(netId) and NetToVeh(netId) or 0
    VehicleKeys.Remove(veh ~= 0 and veh or plate, model)
end)
