local core = exports['qs-core']

local function trim(s) return s and s:match('^%s*(.-)%s*$') or s end

core:RegisterCallback('qs-corevehiclekeys:owns', function(src, plate)
    if not Config.AutoKeysForOwned then return false end
    local player = core:GetPlayer(src)
    if not player then return false end
    local veh = core:GetVehicleByPlate(trim(tostring(plate or '')))
    return veh ~= nil and veh.citizenid == player.citizenid
end)

RegisterNetEvent('qs-corevehiclekeys:server:giveTo', function(target, plate)
    local src = source
    target = tonumber(target)
    if not target or not plate then return end
    local a, b = GetPlayerPed(src), GetPlayerPed(target)
    if a == 0 or b == 0 then return end
    if #(GetEntityCoords(a) - GetEntityCoords(b)) > (Config.GiveDistance + 2.0) then return end
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
    local plate = trim(GetVehicleNumberPlateText(veh))
    TriggerClientEvent('vehiclekeys:client:SetOwner', target, plate)
    TriggerClientEvent('qs:client:notify', target, T('got_keys'), 'success')
    if target ~= src then TriggerClientEvent('qs:client:notify', src, T('keys_shared'), 'success') end
end, true)

RegisterNetEvent('qs-corevehiclekeys:server:lockState', function(netId, state)
    TriggerClientEvent('qs-corevehiclekeys:client:lockState', -1, netId, state, source)
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
