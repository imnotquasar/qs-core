QBCore.Shared.Vehicles = QBCore.Shared.Vehicles or {}

QBCore.Shared.Vehicles = {

}

QBCore.Shared.VehicleHashes = {}
for _, v in pairs(QBCore.Shared.Vehicles) do
    if v.hash then QBCore.Shared.VehicleHashes[v.hash] = v end
end
