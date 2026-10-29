local localKeys = {}
local function trim(s) return s and (s:gsub('%s+$', '')) or s end
local function qsk() return GetResourceState('qs-corevehiclekeys') == 'started' end

local function giveKeys(plate)
    if not plate then return end
    if qsk() then exports['qs-corevehiclekeys']:GiveKeys(plate) else localKeys[trim(plate)] = true end
end

local function removeKeys(plate)
    if not plate then return end
    if qsk() then exports['qs-corevehiclekeys']:RemoveKeys(plate) else localKeys[trim(plate)] = nil end
end

local function hasKeys(plate)
    if qsk() then return exports['qs-corevehiclekeys']:HasKeys(plate) end
    return plate ~= nil and localKeys[trim(plate)] == true
end

exports('GiveKeys', function(plate) giveKeys(plate) end)
exports('RemoveKeys', function(plate) removeKeys(plate) end)
exports('HasKeys', function(plate) return hasKeys(plate) end)
exports('GetKeys', function() if qsk() then return exports['qs-corevehiclekeys']:GetKeys() end return localKeys end)

RegisterNetEvent('vehiclekeys:client:SetOwner', function(plate) giveKeys(plate) end)
RegisterNetEvent('qb-vehiclekeys:client:AddKeys', function(plate) giveKeys(plate) end)
RegisterNetEvent('qb-vehiclekeys:client:RemoveKeys', function(plate) removeKeys(plate) end)
RegisterNetEvent('qb-vehiclekeys:client:GiveKeys', function(plate) giveKeys(plate) end)

RegisterNetEvent('qb-vehiclekeys:client:setVehLockState', function(netId, state)
    local veh = NetToVeh(netId)
    if veh and DoesEntityExist(veh) then SetVehicleDoorsLocked(veh, state) end
end)
