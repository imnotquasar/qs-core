CreateThread(function()
    if Config.EnablePvP == false then return end
    NetworkSetFriendlyFireOption(true)
    while true do
        local ped = PlayerPedId()
        NetworkSetFriendlyFireOption(true)
        SetCanAttackFriendly(ped, true, false)
        SetPedCanBeTargetted(ped, true)
        Wait(2000)
    end
end)

CreateThread(function()
    if not Config.DisablePeds and not Config.DisableTraffic then return end
    if Config.DisableTraffic then
        SetGarbageTrucks(false)
        SetRandomBoats(false)
        SetRandomTrains(false)
    end
    while true do
        Wait(0)
        if Config.DisablePeds then
            SetPedDensityMultiplierThisFrame(0.0)
            SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
        end
        if Config.DisableTraffic then
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
        end
    end
end)

CreateThread(function()
    if not Config.DisableVehicleFires then return end
    while true do
        for _, veh in ipairs(GetGamePool('CVehicle')) do
            SetDisableVehicleEngineFires(veh, true)
            SetDisableVehiclePetrolTankFires(veh, true)
            SetDisableVehiclePetrolTankDamage(veh, true)
            if NetworkHasControlOfEntity(veh) then
                if IsEntityOnFire(veh) then StopEntityFire(veh) end
                if GetVehicleEngineHealth(veh) < 0.0 then SetVehicleEngineHealth(veh, 0.0) end
            end
        end
        Wait(1000)
    end
end)

CreateThread(function()
    if not Config.RemoveAnimals or #Config.RemoveAnimals == 0 then return end
    local blocked = {}
    for _, model in ipairs(Config.RemoveAnimals) do
        local hash = joaat(model)
        blocked[hash] = true
        SetPedModelIsSuppressed(hash, true)
    end
    while true do
        for _, ped in ipairs(GetGamePool('CPed')) do
            if blocked[GetEntityModel(ped)] and not IsPedAPlayer(ped) and NetworkHasControlOfEntity(ped) then
                SetEntityAsMissionEntity(ped, true, true)
                DeletePed(ped)
            end
        end
        Wait(2000)
    end
end)

CreateThread(function()
    if not Config.DisableWeaponScroll then return end
    local scroll = { 14, 15, 16, 17, 99, 100, 115, 116, 261, 262 }
    while true do
        for i = 1, #scroll do DisableControlAction(0, scroll[i], true) end
        Wait(0)
    end
end)

CreateThread(function()
    if not Config.DisableRain then return end
    local rainy = { [`RAIN`] = true, [`THUNDER`] = true, [`CLEARING`] = true }
    while true do
        Wait(1500)
        if rainy[GetNextWeatherTypeHashName()] and not GlobalState.qsFreezeTime then
            SetWeatherTypeOvertimePersist('CLOUDS', 8.0)
        end
    end
end)

CreateThread(function()
    if not Config.DisableWanted and not Config.DisableDispatch then return end

    if Config.DisableWanted then SetMaxWantedLevel(0) end

    while true do
        Wait(250)

        if Config.DisableWanted then
            local pid = PlayerId()
            if GetPlayerWantedLevel(pid) ~= 0 then
                SetPlayerWantedLevel(pid, 0, false)
                SetPlayerWantedLevelNow(pid, false)
            end
        end

        if Config.DisableDispatch then
            for service = 1, 15 do
                EnableDispatchService(service, false)
            end
        end
    end
end)
