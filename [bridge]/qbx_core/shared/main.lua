local qbShared = {}
qbShared.ForceJobDefaultDutyAtLogin = true
qbShared.Locations = require 'shared.locations'
qbShared.Vehicles = require 'shared.vehicles'
qbShared.Weapons = require 'shared.weapons'

qbShared.VehicleHashes = {}

for _, v in pairs(qbShared.Vehicles) do
    qbShared.VehicleHashes[v.hash] = v
end

return qbShared
