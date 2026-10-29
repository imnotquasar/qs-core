local Config = {
    tick = 1000,
    idleUse = 0.02,
    driveUse = 0.18,
}

local function GetFuel(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return 0.0 end
    local sb = Entity(vehicle).state.fuel
    if sb ~= nil then return sb + 0.0 end
    return GetVehicleFuelLevel(vehicle) + 0.0
end

local function SetFuel(vehicle, fuel)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    fuel = math.max(0.0, math.min(100.0, (tonumber(fuel) or 0.0) + 0.0))
    if NetworkGetEntityIsNetworked(vehicle) then
        Entity(vehicle).state:set('fuel', fuel, true)
    end
    SetVehicleFuelLevel(vehicle, fuel)
    DecorSetFloat(vehicle, '_FUEL_LEVEL', fuel)
end

exports('GetFuel', GetFuel)
exports('SetFuel', SetFuel)

CreateThread(function()
    DecorRegister('_FUEL_LEVEL', 1)
end)

local function ensureFuel(veh)
    if Entity(veh).state.fuel == nil then
        local base = GetVehicleFuelLevel(veh)
        if not base or base <= 0.0 then base = math.random(45, 85) + 0.0 end
        SetFuel(veh, base)
    end
end

CreateThread(function()
    while true do
        Wait(Config.tick)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            ensureFuel(veh)
            if GetIsVehicleEngineRunning(veh) then
                local rpm = GetVehicleCurrentRpm(veh)
                local used = Config.idleUse + Config.driveUse * (rpm * rpm)
                local cur = GetFuel(veh)
                if cur > 0.0 then
                    SetFuel(veh, cur - used)
                end
                if GetFuel(veh) <= 0.0 then
                    SetVehicleEngineOn(veh, false, true, true)
                end
            end
        end
    end
end)
