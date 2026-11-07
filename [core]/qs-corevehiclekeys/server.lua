local core = exports['qs-core']

local function trim(s) return s and s:match('^%s*(.-)%s*$') or s end

core:RegisterCallback('qs-corevehiclekeys:owns', function(src, plate)
    if not Config.AutoKeysForOwned then return false end
    local player = core:GetPlayer(src)
    if not player then return false end
    local veh = core:GetVehicleByPlate(trim(tostring(plate or '')))
    return veh ~= nil and veh.citizenid == player.citizenid
end)

local function plateNear(ped, plate, reach)
    local pos = GetEntityCoords(ped)
    for _, veh in ipairs(GetAllVehicles()) do
        local vp = GetVehicleNumberPlateText(veh)
        if vp and trim(vp) == plate and #(pos - GetEntityCoords(veh)) <= reach then
            return true
        end
    end
    return false
end

RegisterNetEvent('qs-corevehiclekeys:server:giveTo', function(target, plate)
    local src = source
    target = tonumber(target)
    plate = trim(tostring(plate or ''))
    if not target or plate == '' then return end
    if not core:RateLimit(('vk-give:%d'):format(src), 3, 2000) then return end
    local a, b = GetPlayerPed(src), GetPlayerPed(target)
    if a == 0 or b == 0 then return end
    if #(GetEntityCoords(a) - GetEntityCoords(b)) > (Config.GiveDistance + 2.0) then return end
    if not plateNear(a, plate, 15.0) then return end
    local row = core:GetVehicleByPlate(plate)
    local player = core:GetPlayer(src)
    if row and not (player and row.citizenid == player.citizenid) then return end
    TriggerClientEvent('vehiclekeys:client:SetOwner', target, plate)
    TriggerClientEvent('qs:client:notify', target, T('got_keys'), 'success')
end)

RegisterCommand('adminkeys', function(src, args)
    if src == 0 then return end
    local veh = GetVehiclePedIsIn(GetPlayerPed(src), false)
    if veh == 0 then
        TriggerClientEvent('qs:client:notify', src, T('not_in_veh'), 'error')
        return
    end
    local target = tonumber(args[1]) or src
    if GetPlayerPed(target) == 0 then
        TriggerClientEvent('qs:client:notify', src, T('no_player'), 'error')
        return
    end
    core:GiveVehicleKeys(target, veh)
    TriggerClientEvent('qs:client:notify', target, T('got_keys'), 'success')
    if target ~= src then TriggerClientEvent('qs:client:notify', src, T('keys_shared'), 'success') end
end, true)

RegisterNetEvent('qs-corevehiclekeys:server:lockState', function(netId, state)
    local src = source
    if type(netId) ~= 'number' or (type(state) ~= 'number' and type(state) ~= 'boolean') then return end
    if not core:RateLimit(('vk-lock:%d'):format(src), 10, 1000) then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    local ped = GetPlayerPed(src)
    if veh == 0 or ped == 0 or not DoesEntityExist(veh) or GetEntityType(veh) ~= 2 then return end
    if #(GetEntityCoords(ped) - GetEntityCoords(veh)) > 50.0 then return end
    TriggerClientEvent('qs-corevehiclekeys:client:lockState', -1, netId, state, src)
end)

RegisterNetEvent('qs-corevehiclekeys:server:breakLockpick', function()
    local src = source
    local player = core:GetPlayer(src)
    if player then player:removeItem(Config.HotwireItem, 1) end
end)

RegisterNetEvent('qs-corevehiclekeys:server:lockpickFail', function()
    local src = source
    if not core:RateLimit(('vk-fail:%d'):format(src), 1, 8000) then return end
    if GetResourceState('qs-police') ~= 'started' then return end
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local c = GetEntityCoords(ped)
    exports['qs-police']:Alert({ x = c.x, y = c.y, z = c.z }, T('alert_carjack'))
end)
