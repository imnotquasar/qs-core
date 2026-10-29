RegisterNetEvent('qb-vehiclekeys:server:AcquireVehicleKeys', function(plate)
    TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
end)

RegisterNetEvent('qb-vehiclekeys:server:GiveVehicleKeys', function(target, plate)
    TriggerClientEvent('vehiclekeys:client:SetOwner', tonumber(target) or source, plate)
end)

RegisterNetEvent('qb-vehiclekeys:server:setVehLockState', function(netId, state)
    TriggerClientEvent('qb-vehiclekeys:client:setVehLockState', -1, netId, state)
end)

exports('GiveKeys', function(src, plate)
    TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
end)
