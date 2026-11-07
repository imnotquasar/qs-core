local core = exports['qs-core']

local function external()
    local state = GetResourceState('qs-vehiclekeys')
    return state == 'started' or state == 'starting'
end

RegisterNetEvent('qb-vehiclekeys:server:AcquireVehicleKeys', function(plate)
    if external() then return end
    TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
end)

RegisterNetEvent('qb-vehiclekeys:server:GiveVehicleKeys', function(target, plate)
    core:GiveVehicleKeys(tonumber(target) or source, plate)
end)

RegisterNetEvent('qb-vehiclekeys:server:setVehLockState', function(netId, state)
    if external() then return end
    TriggerClientEvent('qb-vehiclekeys:client:setVehLockState', -1, netId, state)
end)

exports('GiveKeys', function(src, target)
    return core:GiveVehicleKeys(src, target)
end)

exports('RemoveKeys', function(src, target)
    return core:RemoveVehicleKeys(src, target)
end)

exports('HasKeys', function(src, target)
    return core:HasVehicleKeys(src, target)
end)
