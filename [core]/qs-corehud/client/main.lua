local shown = false
local themeSent = false
local money = { cash = 0, bank = 0 }
local hunger, thirst = 100, 100
local voiceMode = 2
local counts = { online = 1, max = 48 }
local lastStatus = {}
local zoneBurstUntil = 0
local lastZone

local function send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local cashHideUntil = 0
local cashBurstRunning = false
local function hideCashBurst()
    cashHideUntil = GetGameTimer() + 4000
    if cashBurstRunning then return end
    cashBurstRunning = true
    CreateThread(function()
        while GetGameTimer() < cashHideUntil do
            HideHudComponentThisFrame(3)
            HideHudComponentThisFrame(4)
            Wait(0)
        end
        cashBurstRunning = false
    end)
end

local function sendTheme()
    local colors = exports['qs-core']:GetColors()
    if colors then
        send('theme', colors)
        themeSent = true
    end
end

AddEventHandler('qs:client:colorsChanged', function() sendTheme() end)

local function jobText(job)
    if not job then return T('ui_civilian') end
    return job.label or job.name or T('ui_civilian')
end

local function pushMoney()
    send('money', { cash = money.cash, bank = money.bank })
    hideCashBurst()
end

local function show(data)
    if not themeSent then sendTheme() end
    shown = true
    lastStatus = {}
    local meta = data.metadata or {}
    money.cash = (data.money and data.money.cash) or 0
    money.bank = (data.money and data.money.bank) or 0
    hunger = meta.hunger or 100
    thirst = meta.thirst or 100
    send('show', {
        serverId = GetPlayerServerId(PlayerId()),
        job = jobText(data.job),
        cash = money.cash,
        bank = money.bank,
        online = counts.online,
        max = counts.max,
    })
    TriggerServerEvent('qs-corehud:request')
    hideCashBurst()
end

local function radarWanted()
    return not Config.MinimapOnlyInVehicle or IsPedInAnyVehicle(PlayerPedId(), false)
end

local function normalizeMinimap()
    CreateThread(function()
        for _, delay in ipairs({ 0, 250, 1000, 3000 }) do
            Wait(delay)
            DisplayRadar(not shown or radarWanted())
            SetRadarBigmapEnabled(true, false)
            Wait(0)
            SetRadarBigmapEnabled(false, false)
        end
    end)
end

normalizeMinimap()

AddEventHandler('qs-corehud:normalizeMinimap', function() normalizeMinimap() end)

local function isDeadNow()
    return LocalPlayer.state and LocalPlayer.state.dead == true
end

AddEventHandler('qs-corehud:display', function(state)
    if state then
        if isDeadNow() then return end
        DisplayRadar(radarWanted())
        local data = exports['qs-core']:GetPlayerData()
        if data and data.citizenid then show(data) end
    else
        shown = false
        DisplayRadar(false)
        send('hide')
    end
end)

AddEventHandler('qs:client:onDeath', function()
    shown = false
    send('hide')
end)

AddEventHandler('qs:client:onRevive', function()
    local data = exports['qs-core']:GetPlayerData()
    if data and data.citizenid then show(data) end
    normalizeMinimap()
end)

AddEventHandler('qs:client:onPlayerLoaded', function(data)
    if data and not isDeadNow() then show(data) end
    normalizeMinimap()
end)

AddEventHandler('qs:client:onJobUpdate', function(job)
    send('job', { job = jobText(job) })
end)

RegisterNetEvent('qs-corehud:counts', function(data)
    counts.online = data.online or counts.online
    counts.max = data.max or counts.max
    if shown then send('counts', { online = counts.online, max = counts.max }) end
end)

RegisterNetEvent('qs:metadata:set', function(key, value)
    if key == 'hunger' then
        hunger = tonumber(value) or hunger
    elseif key == 'thirst' then
        thirst = tonumber(value) or thirst
    end
end)

RegisterNetEvent('qs:money:add', function(account, amount)
    if money[account] ~= nil then money[account] = money[account] + amount; pushMoney() end
end)
RegisterNetEvent('qs:money:remove', function(account, amount)
    if money[account] ~= nil then money[account] = money[account] - amount; pushMoney() end
end)
RegisterNetEvent('qs:money:set', function(account, amount)
    if money[account] ~= nil then money[account] = amount; pushMoney() end
end)

AddEventHandler('pma-voice:setTalkingMode', function(mode)
    voiceMode = tonumber(mode) or voiceMode
end)

CreateThread(function()
    Wait(500)
    sendTheme()
    if shown then return end
    local data = exports['qs-core']:GetPlayerData()
    if data and data.citizenid then show(data) end
end)

CreateThread(function()
    local pausedHidden = false
    while true do
        Wait(Config.UpdateInterval)

        if IsPauseMenuActive() then
            if shown and not pausedHidden then
                pausedHidden = true
                shown = false
                send('hide')
            end
        else
            if pausedHidden then
                pausedHidden = false
                local data = exports['qs-core']:GetPlayerData()
                if data and data.citizenid then show(data) end
            end

            if shown then
                local ped = PlayerPedId()
                local pid = PlayerId()

                local hp = GetEntityHealth(ped)
                local maxhp = math.max(GetEntityMaxHealth(ped), 101)
                local health = math.floor(((hp - 100) / (maxhp - 100)) * 100)
                if IsEntityDead(ped) or health < 0 then health = 0 elseif health > 100 then health = 100 end

                local armor = math.min(GetPedArmour(ped), 100)

                local stamina = 100
                if Config.Show.stamina then
                    if IsEntityInWater(ped) then
                        stamina = math.floor(GetPlayerUnderwaterTimeRemaining(pid) * 10)
                    else
                        stamina = math.floor(100 - GetPlayerSprintStaminaRemaining(pid))
                    end
                    if stamina < 0 then stamina = 0 elseif stamina > 100 then stamina = 100 end
                end

                local talking = Config.Show.voice and NetworkIsPlayerTalking(pid) or false
                local hu, th = math.floor(hunger), math.floor(thirst)

                if health ~= lastStatus.health or armor ~= lastStatus.armor or hu ~= lastStatus.hunger
                    or th ~= lastStatus.thirst or stamina ~= lastStatus.stamina
                    or talking ~= lastStatus.talking or voiceMode ~= lastStatus.voicemode then
                    lastStatus.health, lastStatus.armor = health, armor
                    lastStatus.hunger, lastStatus.thirst = hu, th
                    lastStatus.stamina, lastStatus.talking, lastStatus.voicemode = stamina, talking, voiceMode
                    send('status', {
                        health = health,
                        armor = armor,
                        hunger = hu,
                        thirst = th,
                        stamina = stamina,
                        talking = talking,
                        voicemode = voiceMode,
                    })
                end

                if Config.HideGameText then
                    local c = GetEntityCoords(ped)
                    local z = GetNameOfZone(c.x, c.y, c.z)
                    if z ~= lastZone then
                        lastZone = z
                        zoneBurstUntil = GetGameTimer() + 6000
                    end
                end
            end
        end
    end
end)

local seatbelt = false

if Config.Vehicle.seatbelt then
    RegisterCommand('+qsbelt', function()
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return end

        seatbelt = not seatbelt
        if seatbelt then
            exports['qs-core']:Notify(T('belt_on'), 'success', 2500)
        else
            exports['qs-core']:Notify(T('belt_off'), 'error', 2500)
        end
    end, false)
    RegisterKeyMapping('+qsbelt', 'Toggle seatbelt', 'keyboard', Config.Vehicle.beltKey)
end

local function streetName(ped)
    local pos = GetEntityCoords(ped)
    local s1 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
    local name = GetStreetNameFromHashKey(s1)
    return name ~= '' and name or 'Los Santos'
end

local fuelResource = Config.Vehicle.fuelResource
local fuelExport = Config.Vehicle.fuelExport

local function getFuel(veh)
    if fuelResource and fuelResource ~= '' and GetResourceState(fuelResource) == 'started' then
        local ok, level = pcall(function()
            return exports[fuelResource][fuelExport](exports[fuelResource], veh)
        end)
        if ok and type(level) == 'number' then return level end
    end
    return GetVehicleFuelLevel(veh)
end

local radarOn = nil

local function syncRadar()
    if not shown then return end
    local want = radarWanted()
    if want == IsRadarHidden() then DisplayRadar(want) end
    if want ~= radarOn then
        radarOn = want
        send('minimap', { visible = want })
    end
end

CreateThread(function()
    local mult = Config.Vehicle.unit == 'mph' and 2.236936 or 3.6
    local inVeh = false

    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        syncRadar()

        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            inVeh = true
            send('vehicle', {
                speed = math.floor(GetEntitySpeed(veh) * mult + 0.5),
                rpm = GetVehicleCurrentRpm(veh),
                gear = GetVehicleCurrentGear(veh),
                fuel = math.floor(getFuel(veh)),
                engine = math.floor(GetVehicleEngineHealth(veh) / 10),
                belt = seatbelt,
                street = streetName(ped),
                unit = Config.Vehicle.unit,
            })
            Wait(Config.Vehicle.interval)
        else
            if inVeh then
                inVeh = false
                seatbelt = false
                send('vehicle:hide')
            end
            Wait(350)
        end
    end
end)

CreateThread(function()
    local minimap = RequestScaleformMovie('minimap')
    local deadline = GetGameTimer() + 5000
    while not HasScaleformMovieLoaded(minimap) and GetGameTimer() < deadline do
        Wait(50)
    end

    while true do
        if shown and HasScaleformMovieLoaded(minimap) then
            BeginScaleformMovieMethod(minimap, 'SETUP_HEALTH_ARMOUR')
            ScaleformMovieMethodAddParamInt(3)
            EndScaleformMovieMethod()
            Wait(250)
        else
            Wait(700)
        end
    end
end)

if Config.HideGameText then
    CreateThread(function()
        while true do
            if shown and (IsPedInAnyVehicle(PlayerPedId(), false) or GetGameTimer() < zoneBurstUntil) then
                HideHudComponentThisFrame(6)
                HideHudComponentThisFrame(7)
                HideHudComponentThisFrame(8)
                HideHudComponentThisFrame(9)
                Wait(0)
            else
                Wait(300)
            end
        end
    end)
end
