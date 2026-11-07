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

local function isVehicle(value)
    return type(value) == 'number' and value > 0 and DoesEntityExist(value) and GetEntityType(value) == 2
end

function VehicleKeys.Give(src, target, model)
    src = tonumber(src)
    if not src or GetPlayerPed(src) == 0 then return false end
    local backend = VehicleKeys.Backend()
    local veh = isVehicle(target) and target or nil
    local plate = veh and trim(GetVehicleNumberPlateText(veh)) or (target and trim(target))
    if not plate or plate == '' then return false end

    if backend == 'qs-vehiclekeys' then
        if type(model) == 'string' and model ~= '' and not veh then
            return exports['qs-vehiclekeys']:GiveServerKeys(src, plate, model:upper(), false) == true
        end
        return exports['qs-vehiclekeys']:GiveKeys(src, veh or plate, true) == true
    elseif backend == 'qs-corevehiclekeys' then
        TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
        return true
    end
    return false
end

function VehicleKeys.Remove(src, target, model)
    src = tonumber(src)
    if not src or GetPlayerPed(src) == 0 then return false end
    local backend = VehicleKeys.Backend()
    local veh = isVehicle(target) and target or nil
    local plate = veh and trim(GetVehicleNumberPlateText(veh)) or (target and trim(target))
    if not plate or plate == '' then return false end

    if backend == 'qs-vehiclekeys' then
        if type(model) == 'string' and model ~= '' and not veh then
            return exports['qs-vehiclekeys']:RemoveServerKeys(src, plate, model:upper()) == true
        end
        return exports['qs-vehiclekeys']:RemoveKeys(src, veh or plate, true) == true
    elseif backend == 'qs-corevehiclekeys' then
        TriggerClientEvent('qs-corevehiclekeys:client:remove', src, plate)
        return true
    end
    return false
end

function VehicleKeys.Has(src, target)
    src = tonumber(src)
    if not src then return false end
    local backend = VehicleKeys.Backend()
    if backend == 'qs-vehiclekeys' then
        return exports['qs-vehiclekeys']:HasKeys(src, target) == true
    end
    return true
end

exports('GetVehicleKeysBackend', VehicleKeys.Backend)
exports('GiveVehicleKeys', VehicleKeys.Give)
exports('RemoveVehicleKeys', VehicleKeys.Remove)
exports('HasVehicleKeys', VehicleKeys.Has)
