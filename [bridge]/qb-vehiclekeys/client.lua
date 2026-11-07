local core = exports['qs-core']

local function external()
    local state = GetResourceState('qs-vehiclekeys')
    return state ~= 'missing' and state ~= 'stopped' and state ~= 'stopping'
end

local function giveKeys(plate)
    if plate then core:GiveVehicleKeys(plate) end
end

local function removeKeys(plate)
    if plate then core:RemoveVehicleKeys(plate) end
end

exports('GiveKeys', function(plate) giveKeys(plate) end)
exports('RemoveKeys', function(plate) removeKeys(plate) end)
exports('HasKeys', function(plate) return core:HasVehicleKeys(plate) end)
exports('GetKeys', function()
    if GetResourceState('qs-corevehiclekeys') == 'started' then return exports['qs-corevehiclekeys']:GetKeys() end
    return {}
end)

RegisterNetEvent('vehiclekeys:client:SetOwner', function(plate) if not external() then giveKeys(plate) end end)
RegisterNetEvent('qb-vehiclekeys:client:AddKeys', function(plate) if not external() then giveKeys(plate) end end)
RegisterNetEvent('qb-vehiclekeys:client:RemoveKeys', function(plate) if not external() then removeKeys(plate) end end)
RegisterNetEvent('qb-vehiclekeys:client:GiveKeys', function(plate) giveKeys(plate) end)

RegisterNetEvent('qb-vehiclekeys:client:setVehLockState', function(netId, state)
    local veh = NetToVeh(netId)
    if veh and DoesEntityExist(veh) then SetVehicleDoorsLocked(veh, state) end
end)
