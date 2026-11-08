local core = exports['qs-core']

function QBCore.Functions.SpawnVehicle(source, model, coords, warp)
    return core:SpawnVehicle(source, model, coords, warp)
end

exports('SpawnVehicle', function(source, model, coords, warp)
    return QBCore.Functions.SpawnVehicle(source, model, coords, warp)
end)
