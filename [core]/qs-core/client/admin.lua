RegisterNetEvent('qs:client:adminKill', function()
    SetEntityHealth(PlayerPedId(), 0)
end)

local frozen = false
RegisterNetEvent('qs:client:freeze', function()
    frozen = not frozen
    FreezeEntityPosition(PlayerPedId(), frozen)
    TriggerEvent('qs:client:notify', frozen and T('frozen') or T('unfrozen'), 'info')
end)

local god = false
RegisterNetEvent('qs:client:god', function()
    god = not god
    SetEntityInvincible(PlayerPedId(), god)
    SetPlayerInvincible(PlayerId(), god)
    TriggerEvent('qs:client:notify', god and T('god_on') or T('god_off'), god and 'success' or 'info')
end)

RegisterNetEvent('qs:client:setCoords', function(x, y, z)
    x, y, z = x + 0.0, y + 0.0, z + 0.0
    local ped = PlayerPedId()
    RequestCollisionAtCoord(x, y, z)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
end)

RegisterNetEvent('qs:client:spawnCar', function(model)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        TriggerEvent('qs:client:notify', 'Invalid vehicle model.', 'error')
        return
    end
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(0) end
    if not HasModelLoaded(hash) then return end

    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local veh = CreateVehicle(hash, pos.x, pos.y, pos.z, GetEntityHeading(ped), true, false)
    SetPedIntoVehicle(ped, veh, -1)
    local plate = 'QS' .. math.random(1000, 9999)
    SetVehicleNumberPlateText(veh, plate)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetModelAsNoLongerNeeded(hash)
    if GetResourceState('qs-corevehiclekeys') == 'started' then
        exports['qs-corevehiclekeys']:GiveKeys(plate)
    end
end)

RegisterNetEvent('qs:client:deleteVehicle', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local c = GetEntityCoords(ped)
        veh = GetClosestVehicle(c.x, c.y, c.z, 5.0, 0, 71)
    end
    if veh ~= 0 then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    end
end)

RegisterNetEvent('qs:client:coords', function()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local s = ('vec4(%.2f, %.2f, %.2f, %.2f)'):format(c.x, c.y, c.z, GetEntityHeading(ped))
    print('[qs-core] ' .. s)
    TriggerEvent('qs:client:notify', s, 'primary', 8000)
end)
