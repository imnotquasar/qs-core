local core = exports['qs-core']

local function external()
    local state = GetResourceState('qs-vehiclekeys')
    return state == 'started' or state == 'starting'
end

local function vehicleNear(src, plate, reach)
    plate = tostring(plate or ''):match('^%s*(.-)%s*$')
    if plate == '' then return nil end
    local ped = GetPlayerPed(src)
    if ped == 0 then return nil end
    local pos = GetEntityCoords(ped)
    for _, veh in ipairs(GetAllVehicles()) do
        local vp = GetVehicleNumberPlateText(veh)
        if vp and vp:match('^%s*(.-)%s*$') == plate and #(pos - GetEntityCoords(veh)) <= reach then
            return plate
        end
    end
end

RegisterNetEvent('qb-vehiclekeys:server:AcquireVehicleKeys', function(plate)
    local src = tonumber(source)
    if not src or external() then return end
    if not core:RateLimit(('qbvk-acq:%d'):format(src), 5, 2000) then return end
    local near = vehicleNear(src, plate, 15.0)
    if near then TriggerClientEvent('vehiclekeys:client:SetOwner', src, near) end
end)

RegisterNetEvent('qb-vehiclekeys:server:GiveVehicleKeys', function(target, plate)
    local src = tonumber(source)
    if not src then
        if tonumber(target) then core:GiveVehicleKeys(tonumber(target), plate) end
        return
    end
    target = tonumber(target) or src
    if not core:RateLimit(('qbvk-give:%d'):format(src), 3, 2000) then return end
    local near = vehicleNear(src, plate, 15.0)
    if not near then return end
    local a, b = GetPlayerPed(src), GetPlayerPed(target)
    if a == 0 or b == 0 or #(GetEntityCoords(a) - GetEntityCoords(b)) > 10.0 then return end
    local row = core:GetVehicleByPlate(near)
    local player = core:GetPlayer(src)
    if row and not (player and row.citizenid == player.citizenid) then return end
    core:GiveVehicleKeys(target, near)
end)

RegisterNetEvent('qb-vehiclekeys:server:setVehLockState', function(netId, state)
    local src = tonumber(source)
    if not src or external() then return end
    state = tonumber(state)
    if type(netId) ~= 'number' or not state or state < 0 or state > 10 then return end
    if not core:RateLimit(('qbvk-lock:%d'):format(src), 10, 1000) then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    local ped = GetPlayerPed(src)
    if veh == 0 or ped == 0 or not DoesEntityExist(veh) or GetEntityType(veh) ~= 2 then return end
    if #(GetEntityCoords(ped) - GetEntityCoords(veh)) > 50.0 then return end
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
