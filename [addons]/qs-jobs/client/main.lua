local myJob = 'unemployed'
local uiOpen = false
local spawnedPeds = {}
local spawnedProps = {}
local interactables = {}
local cooldowns = {}
local shift = nil

local function send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local function sendTheme()
    local colors = exports['qs-core']:GetColors()
    if colors then send('theme', colors) end
end

local function sendLocale()
    send('locale', Locales[GetConvar('qs:locale', 'en')] or Locales.en or {})
end

AddEventHandler('qs:client:colorsChanged', function() sendTheme() end)

local function loadModel(model)
    local hash = joaat(model)
    RequestModel(hash)
    local dl = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < dl do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

local function loadDict(dict)
    RequestAnimDict(dict)
    local dl = GetGameTimer() + 2000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < dl do Wait(10) end
end

local function addBlip(loc, b)
    if not b then return end
    local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipSprite(blip, b.sprite or 1)
    SetBlipColour(blip, b.color or 0)
    SetBlipScale(blip, b.scale or 0.7)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(b.label or 'Job')
    EndTextCommandSetBlipName(blip)
    return blip
end

local jobBlips = {}

local function clearJobBlips()
    for _, b in ipairs(jobBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    jobBlips = {}
end

local function refreshJobBlips()
    clearJobBlips()
    local function track(loc, b) if b and loc then jobBlips[#jobBlips + 1] = addBlip(loc, b) end end

    if myJob == 'delivery' then
        track(Config.Delivery.depot.coords, Config.Delivery.depot.blip)
    end
    local job = Config.Jobs[myJob]
    if job then
        if job.gather then
            for _, loc in ipairs(job.gather.locations or {}) do track(loc, job.gather.blip) end
        end
        if job.process then
            for _, loc in ipairs(job.process.locations or {}) do track(loc, job.process.blip) end
        end
        if job.sell then track(job.sell.coords, job.sell.blip) end
    end
end

local function spawnPed(model, loc, scenario)
    local hash = loadModel(model)
    if not hash then return nil end
    local ped = CreatePed(4, hash, loc.x, loc.y, loc.z - 1.0, loc.w or 0.0, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    if scenario then TaskStartScenarioInPlace(ped, scenario, 0, true) end
    SetModelAsNoLongerNeeded(hash)
    spawnedPeds[#spawnedPeds + 1] = ped
    return ped
end

local function spawnProp(model, x, y, z, heading)
    local hash = loadModel(model)
    if not hash then return nil end
    local obj = CreateObject(hash, x, y, z, false, false, false)
    SetEntityHeading(obj, heading or (math.random(0, 359) + 0.0))
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    SetModelAsNoLongerNeeded(hash)
    spawnedProps[#spawnedProps + 1] = obj
    return obj
end

CreateThread(function()
    addBlip(Config.Center.coords, Config.Center.blip)
    refreshJobBlips()
end)

CreateThread(function()
    spawnPed(Config.Center.ped, Config.Center.coords, Config.Center.scenario)
    interactables[#interactables + 1] = { kind = 'center', coords = vector3(Config.Center.coords.x, Config.Center.coords.y, Config.Center.coords.z) }

    local depot = Config.Delivery.depot
    spawnPed(depot.ped, depot.coords, depot.scenario)
    interactables[#interactables + 1] = { kind = 'depot', coords = vector3(depot.coords.x, depot.coords.y, depot.coords.z) }

    for key, job in pairs(Config.Jobs) do
        local g = job.gather
        if g then
            if g.prop then
                for _, loc in ipairs(g.locations or {}) do
                    for _ = 1, (g.perZone or 5) do
                        local ang = math.random() * math.pi * 2
                        local dist = math.random() * (g.spread or 4.0)
                        local x = loc.x + math.cos(ang) * dist
                        local y = loc.y + math.sin(ang) * dist
                        if spawnProp(g.prop, x, y, loc.z) then
                            interactables[#interactables + 1] = { kind = 'gather', key = key, cfg = g, coords = vector3(x, y, loc.z), face = vector3(x, y, loc.z) }
                        end
                    end
                end
            else
                for _, loc in ipairs(g.locations or {}) do
                    interactables[#interactables + 1] = { kind = 'gather', key = key, cfg = g, coords = vector3(loc.x, loc.y, loc.z), heading = loc.w }
                end
            end
        end
        local p = job.process
        if p then
            for _, loc in ipairs(p.locations or {}) do
                interactables[#interactables + 1] = { kind = 'process', key = key, cfg = p, coords = vector3(loc.x, loc.y, loc.z), heading = loc.w }
            end
        end
        local s = job.sell
        if s then
            spawnPed(s.ped, s.coords, s.scenario)
            interactables[#interactables + 1] = { kind = 'sell', key = key, cfg = s, coords = vector3(s.coords.x, s.coords.y, s.coords.z) }
        end
    end
end)

local function helpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function runTask(cfg, label, opts)
    local ped = PlayerPedId()
    opts = opts or {}

    if opts.heading then
        SetEntityHeading(ped, opts.heading + 0.0)
        Wait(150)
    elseif opts.face then
        TaskTurnPedToFaceCoord(ped, opts.face.x, opts.face.y, opts.face.z, 900)
        Wait(700)
    end

    local looping = false
    if cfg.scenario then
        TaskStartScenarioInPlace(ped, cfg.scenario, 0, true)
    elseif cfg.anim and cfg.anim.dict then
        loadDict(cfg.anim.dict)
        local flag = cfg.anim.flag or 49
        TaskPlayAnim(ped, cfg.anim.dict, cfg.anim.clip, 4.0, -4.0, cfg.time or 5000, flag, 0.0, false, false, false)
        if cfg.anim.loop then
            looping = true
            CreateThread(function()
                while looping do
                    Wait(cfg.anim.loop)
                    if not looping then break end
                    TaskPlayAnim(ped, cfg.anim.dict, cfg.anim.clip, 4.0, -4.0, cfg.time or 5000, flag, 0.0, false, false, false)
                end
            end)
        end
    end

    local ok = exports['qs-core']:Progress({
        duration = cfg.time or 5000,
        label = label,
        canCancel = true,
        disableMovement = true,
    })

    looping = false
    if cfg.scenario then
        ClearPedTasksImmediately(ped)
        CreateThread(function()
            local deadline = GetGameTimer() + 800
            while GetGameTimer() < deadline do
                local pc = GetEntityCoords(ped)
                local rod = GetClosestObjectOfType(pc.x, pc.y, pc.z, 3.0, joaat('prop_fishing_rod_01'), false, false, false)
                if rod ~= 0 then
                    SetEntityAsMissionEntity(rod, true, true)
                    DeleteEntity(rod)
                    break
                end
                Wait(50)
            end
        end)
    else
        ClearPedTasks(ped)
    end
    if cfg.anim and cfg.anim.dict then RemoveAnimDict(cfg.anim.dict) end
    return ok
end

local routeBlip = nil
local vanBlip = nil

local function setRoute(coords)
    if routeBlip and DoesBlipExist(routeBlip) then RemoveBlip(routeBlip) end
    routeBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(routeBlip, 1)
    SetBlipColour(routeBlip, 5)
    SetBlipScale(routeBlip, 0.8)
    SetBlipRoute(routeBlip, true)
    SetBlipRouteColour(routeBlip, 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(T('blip_delivery'))
    EndTextCommandSetBlipName(routeBlip)
end

local function clearRoute()
    if routeBlip and DoesBlipExist(routeBlip) then RemoveBlip(routeBlip) end
    routeBlip = nil
end

local function spawnVan()
    local d = Config.Delivery
    local spot = nil
    for _, s in ipairs(d.vanSpawns) do
        if not IsAnyVehicleNearPoint(s.x, s.y, s.z, 2.5) then spot = s break end
    end
    if not spot then return nil end

    local model = d.vanModels[math.random(#d.vanModels)]
    local hash = loadModel(model)
    if not hash then return nil end

    local veh = CreateVehicle(hash, spot.x, spot.y, spot.z, spot.w or 0.0, true, false)
    SetVehicleNumberPlateText(veh, ('QS%05d'):format(math.random(99999)))
    SetVehicleOnGroundProperly(veh)
    SetVehicleFuelLevel(veh, 100.0)
    SetModelAsNoLongerNeeded(hash)

    if vanBlip and DoesBlipExist(vanBlip) then RemoveBlip(vanBlip) end
    vanBlip = AddBlipForEntity(veh)
    SetBlipSprite(vanBlip, 477)
    SetBlipColour(vanBlip, 5)
    SetBlipScale(vanBlip, 0.8)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(T('blip_van'))
    EndTextCommandSetBlipName(vanBlip)
    return veh
end

local function cleanupShift()
    if shift and shift.van and DoesEntityExist(shift.van) then
        SetEntityAsMissionEntity(shift.van, true, true)
        DeleteVehicle(shift.van)
    end
    if vanBlip and DoesBlipExist(vanBlip) then RemoveBlip(vanBlip) end
    vanBlip = nil
    clearRoute()
    shift = nil
    send('shift', { on = false })
end

RegisterNetEvent('qs-jobs:client:shiftStarted', function(stops)
    if type(stops) ~= 'table' or #stops == 0 then return end
    local list = {}
    for i, s in ipairs(stops) do list[i] = vector3(s.x, s.y, s.z) end

    local van = spawnVan()
    if not van then
        exports['qs-core']:Notify(T('no_van_space'), 'error', 4000)
        TriggerServerEvent('qs-jobs:server:endShift')
        return
    end

    shift = { stops = list, next = 1, done = 0, total = #list, earned = 0, van = van }
    setRoute(list[1])
    send('shift', { on = true, done = 0, total = shift.total, earned = 0 })
end)

RegisterNetEvent('qs-jobs:client:delivered', function(data)
    if not shift or not data then return end
    shift.done = data.done or shift.done
    shift.earned = data.earned or shift.earned
    shift.next = shift.done + 1
    if shift.next <= shift.total then
        setRoute(shift.stops[shift.next])
    else
        local depot = Config.Delivery.depot.coords
        setRoute(vector3(depot.x, depot.y, depot.z))
    end
    send('shift', { on = true, done = shift.done, total = shift.total, earned = shift.earned })
end)

RegisterNetEvent('qs-jobs:client:shiftEnded', function()
    cleanupShift()
end)

local function trackJob(name)
    myJob = name or 'unemployed'
    if myJob ~= 'delivery' and shift then cleanupShift() end
    refreshJobBlips()
end

AddEventHandler('qs:client:onPlayerLoaded', function(data)
    trackJob(data and data.job and data.job.name)
    sendTheme()
    sendLocale()
end)

AddEventHandler('qs:client:onJobUpdate', function(job)
    trackJob(job and job.name)
end)

CreateThread(function()
    Wait(500)
    sendTheme()
    sendLocale()
    local data = exports['qs-core']:GetPlayerData()
    if data and data.job then trackJob(data.job.name) end
end)

local function currentStopTarget(coords)
    if not shift or shift.next > shift.total then return nil end
    local stop = shift.stops[shift.next]
    if #(coords - stop) < 3.0 then
        return { kind = 'stop', coords = stop }
    end
    return nil
end

local function anySellable(prices)
    for item in pairs(prices) do
        if exports['qs-core']:GetItemCount(item) > 0 then return true end
    end
    return false
end

CreateThread(function()
    while true do
        local sleep = 500
        local coords = GetEntityCoords(PlayerPedId())
        local target = nil
        local best = Config.InteractDistance

        for i, z in ipairs(interactables) do
            if not (z.kind == 'gather' and (cooldowns[i] or 0) > GetGameTimer()) then
                local dx, dy = coords.x - z.coords.x, coords.y - z.coords.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist < best then
                    best = dist
                    target = z
                    target.id = i
                end
            end
        end

        target = target or currentStopTarget(coords)

        if target and not uiOpen then
            sleep = 0
            local kind = target.kind

            if kind == 'center' then
                helpText(T('help_center'))
                if IsControlJustPressed(0, Config.Control) then
                    TriggerServerEvent('qs-jobs:server:openCenter')
                end
            elseif kind == 'depot' then
                if myJob ~= 'delivery' then
                    helpText(T('need_job'))
                elseif shift then
                    helpText(T('help_shift_end'))
                    if IsControlJustPressed(0, Config.Control) and not exports['qs-core']:IsBusy() then
                        TriggerServerEvent('qs-jobs:server:endShift')
                    end
                else
                    helpText(T('help_shift_start'))
                    if IsControlJustPressed(0, Config.Control) and not exports['qs-core']:IsBusy() then
                        TriggerServerEvent('qs-jobs:server:startShift')
                    end
                end
            elseif kind == 'stop' then
                helpText(T('help_deliver'))
                if IsControlJustPressed(0, Config.Control) and not exports['qs-core']:IsBusy() then
                    local d = Config.Delivery
                    if runTask({ time = d.deliverTime, anim = d.anim }, T('delivering'), { face = target.coords }) then
                        TriggerServerEvent('qs-jobs:server:deliver')
                    end
                end
            elseif myJob ~= target.key then
                helpText(T('need_job'))
            elseif kind == 'gather' then
                helpText(T('help_gather'))
                if IsControlJustPressed(0, Config.Control) and not exports['qs-core']:IsBusy() then
                    if runTask(target.cfg, T('working'), { face = target.face, heading = target.heading }) then
                        cooldowns[target.id] = GetGameTimer() + Config.GatherCooldown
                        TriggerServerEvent('qs-jobs:server:gather', target.key)
                    end
                end
            elseif kind == 'process' then
                helpText(T('help_process'))
                if IsControlJustPressed(0, Config.Control) and not exports['qs-core']:IsBusy() then
                    local p = target.cfg
                    if not exports['qs-core']:HasItem(p.input, p.inputAmount) then
                        exports['qs-core']:Notify(T('need_material_short'), 'error', 3000)
                    elseif runTask(p, T('processing'), { heading = target.heading }) then
                        TriggerServerEvent('qs-jobs:server:process', target.key)
                    end
                end
            elseif kind == 'sell' then
                helpText(T('help_sell'))
                if IsControlJustPressed(0, Config.Control) and not exports['qs-core']:IsBusy() then
                    if anySellable(target.cfg.prices) then
                        TriggerServerEvent('qs-jobs:server:sell', target.key)
                    else
                        exports['qs-core']:Notify(T('nothing_to_sell'), 'error', 3000)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('qs-jobs:client:openCenter', function(data)
    if uiOpen or not data then return end
    uiOpen = true
    SetNuiFocus(true, true)
    TriggerEvent('qs-corehud:display', false)
    sendTheme()
    sendLocale()
    send('open', data)
end)

local function closeCenter()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    TriggerEvent('qs-corehud:display', true)
    send('close')
end

RegisterNetEvent('qs-jobs:client:applied', function()
    closeCenter()
end)

RegisterNUICallback('apply', function(data, cb)
    cb('ok')
    if data and data.job then
        TriggerServerEvent('qs-jobs:server:apply', data.job)
    end
end)

RegisterNUICallback('close', function(_, cb)
    cb('ok')
    closeCenter()
end)

CreateThread(function()
    local paused = false
    while true do
        Wait(200)
        local active = IsPauseMenuActive()
        if active ~= paused then
            paused = active
            send('paused', { on = active })
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    for _, obj in ipairs(spawnedProps) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    cleanupShift()
end)
