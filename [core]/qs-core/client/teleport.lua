RegisterNetEvent('qs:client:tpm', function()
    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then
        TriggerEvent('qs:client:notify', 'No waypoint set.', 'error')
        return
    end

    local target = GetBlipInfoIdCoord(blip)
    local x, y = target.x, target.y
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local entity = (veh ~= 0) and veh or ped

    DoScreenFadeOut(250)
    local fadeStart = GetGameTimer()
    while not IsScreenFadedOut() and GetGameTimer() - fadeStart < 1000 do Wait(0) end

    FreezeEntityPosition(entity, true)
    SetEntityInvincible(ped, true)
    if veh ~= 0 then SetEntityInvincible(veh, true) end

    local groundZ, found = nil, false
    for _, probe in ipairs({ 60.0, 30.0, 100.0, 150.0, 10.0, 250.0, 400.0, 600.0, 800.0, 1000.0 }) do
        SetPedCoordsKeepVehicle(ped, x, y, probe)
        local dl = GetGameTimer() + 700
        while not HasCollisionLoadedAroundEntity(entity) and GetGameTimer() < dl do
            RequestCollisionAtCoord(x, y, probe)
            Wait(0)
        end
        local ok, z = GetGroundZFor_3dCoord(x, y, probe, false)
        if ok then
            groundZ, found = z, true
            break
        end
    end

    local finalZ = (found and groundZ + 1.0) or 100.0
    SetPedCoordsKeepVehicle(ped, x, y, finalZ)

    local dl = GetGameTimer() + 3000
    while not HasCollisionLoadedAroundEntity(entity) and GetGameTimer() < dl do
        RequestCollisionAtCoord(x, y, finalZ)
        Wait(0)
    end
    if IsNewLoadSceneActive() then NewLoadSceneStop() end

    if veh ~= 0 then
        SetVehicleOnGroundProperly(veh)
        SetEntityInvincible(veh, false)
    end
    FreezeEntityPosition(entity, false)
    SetEntityInvincible(ped, false)

    Wait(150)
    DoScreenFadeIn(400)
    TriggerEvent('qs:client:notify',
        found and 'Teleported to waypoint.' or 'Teleported (no ground found).',
        found and 'success' or 'info')
end)
