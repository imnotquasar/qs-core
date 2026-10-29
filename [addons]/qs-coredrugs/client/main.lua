local spawnedPeds = {}
local spawnedProps = {}
local interactables = {}
local dealerZones = {}
local uiOpen = false

local function send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

for _, loc in ipairs(Config.Dealer.locations or {}) do
    dealerZones[#dealerZones + 1] = vector3(loc.x, loc.y, loc.z)
end

local function addBlip(loc, b)
    if not b then return end
    local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipSprite(blip, b.sprite or 51)
    SetBlipColour(blip, b.color or 2)
    SetBlipScale(blip, b.scale or 0.7)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(b.label or 'Drugs')
    EndTextCommandSetBlipName(blip)
end

CreateThread(function()
    for _, drug in pairs(Config.Drugs) do
        for _, loc in ipairs(drug.gather.locations or {}) do addBlip(loc, drug.gather.blip) end
        for _, loc in ipairs(drug.process.locations or {}) do addBlip(loc, drug.process.blip) end
    end
    for _, loc in ipairs(Config.Dealer.locations or {}) do addBlip(loc, Config.Dealer.blip) end
end)

local function loadModel(model)
    local hash = joaat(model)
    RequestModel(hash)
    local dl = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < dl do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

local function spawnProp(model, x, y, z, heading, snap)
    local hash = loadModel(model)
    if not hash then return nil end
    local obj = CreateObject(hash, x, y, z, false, false, false)
    SetEntityHeading(obj, heading or (math.random(0, 359) + 0.0))
    if snap == false then
        SetEntityCoordsNoOffset(obj, x, y, z, false, false, false)
    else
        PlaceObjectOnGroundProperly(obj)
    end
    FreezeEntityPosition(obj, true)
    SetEntityInvincible(obj, true)
    SetModelAsNoLongerNeeded(hash)
    return obj
end

CreateThread(function()
    for key, drug in pairs(Config.Drugs) do
        for _, loc in ipairs(drug.gather.locations or {}) do
            for _ = 1, Config.HarvestPerZone do
                local ang = math.random() * math.pi * 2
                local dist = math.random() * Config.HarvestSpread
                local x = loc.x + math.cos(ang) * dist
                local y = loc.y + math.sin(ang) * dist
                local obj = spawnProp(drug.gather.prop, x, y, loc.z)
                if obj then
                    spawnedProps[#spawnedProps + 1] = obj
                    interactables[#interactables + 1] = { kind = 'gather', key = key, cfg = drug.gather, coords = vector3(x, y, loc.z), label = drug.label }
                end
            end
        end
        for _, loc in ipairs(drug.process.locations or {}) do
            local obj = spawnProp(drug.process.prop, loc.x, loc.y, loc.z, loc.w, false)
            if obj then spawnedProps[#spawnedProps + 1] = obj end
            interactables[#interactables + 1] = { kind = 'process', key = key, cfg = drug.process, coords = vector3(loc.x, loc.y, loc.z), label = drug.label, rawLabel = drug.gather.label }
        end
    end
end)

CreateThread(function()
    local d = Config.Dealer
    if not d.ped then return end
    local hash = loadModel(d.ped)
    if not hash then return end
    for _, loc in ipairs(d.locations or {}) do
        local ped = CreatePed(4, hash, loc.x, loc.y, loc.z - 1.0, loc.w or 0.0, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        if d.scenario then TaskStartScenarioInPlace(ped, d.scenario, 0, true) end
        spawnedPeds[#spawnedPeds + 1] = ped
    end
    SetModelAsNoLongerNeeded(hash)
end)

local function helpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function loadDict(dict)
    if not dict then return end
    RequestAnimDict(dict)
    local dl = GetGameTimer() + 2000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < dl do Wait(10) end
end

local function runTask(cfg, label, face, flag)
    local ped = PlayerPedId()

    if face then
        TaskTurnPedToFaceCoord(ped, face.x, face.y, face.z, 900)
        Wait(700)
    end

    if cfg.anim and cfg.anim.dict then
        loadDict(cfg.anim.dict)
        TaskPlayAnim(ped, cfg.anim.dict, cfg.anim.clip, 4.0, -4.0, cfg.time or 5000, flag or 49, 0.0, false, false, false)
    end

    local ok = exports['qs-core']:Progress({
        duration = cfg.time or 5000,
        label = label,
        canCancel = true,
        disableMovement = true,
    })

    ClearPedTasks(ped)
    if cfg.anim and cfg.anim.dict then RemoveAnimDict(cfg.anim.dict) end
    return ok
end

local function attachProp(ped, p)
    if not p or not p.model then return nil end
    local hash = loadModel(p.model)
    if not hash then return nil end
    local c = GetEntityCoords(ped)
    local obj = CreateObject(hash, c.x, c.y, c.z + 0.2, false, false, false)
    local pos = p.pos or vector3(0.0, 0.0, 0.0)
    local rot = p.rot or vector3(0.0, 0.0, 0.0)
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, p.bone or 18905),
        pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(hash)
    return obj
end

local function startPtfx(ped, f)
    if not f or not f.asset or not f.name then return nil end
    RequestNamedPtfxAsset(f.asset)
    local dl = GetGameTimer() + 1500
    while not HasNamedPtfxAssetLoaded(f.asset) and GetGameTimer() < dl do Wait(0) end
    if not HasNamedPtfxAssetLoaded(f.asset) then return nil end
    UseParticleFxAssetNextCall(f.asset)
    local o = f.offset or vector3(0.0, 0.0, 0.0)
    return StartParticleFxLoopedOnPedBone(f.name, ped, o.x, o.y, o.z, 0.0, 0.0, 0.0,
        GetPedBoneIndex(ped, f.bone or 57005), f.scale or 1.0, false, false, false)
end

local function runProcessStages(cfg, face)
    local ped = PlayerPedId()
    if face then
        TaskTurnPedToFaceCoord(ped, face.x, face.y, face.z, 800)
        Wait(500)
    end

    for _, st in ipairs(cfg.stages) do
        local prop = attachProp(ped, st.prop)
        if st.anim and st.anim.dict then
            loadDict(st.anim.dict)
            TaskPlayAnim(ped, st.anim.dict, st.anim.clip, 4.0, -4.0, st.time or 4000, st.flag or 49, 0.0, false, false, false)
        end
        local fx = startPtfx(ped, st.ptfx)

        local ok = exports['qs-core']:Progress({
            duration = st.time or 4000,
            label = st.label and T(st.label) or '',
            canCancel = true,
            disableMovement = true,
        })

        if fx then StopParticleFxLooped(fx, false) end
        if prop and DoesEntityExist(prop) then DeleteEntity(prop) end
        ClearPedTasks(ped)
        if st.anim and st.anim.dict then RemoveAnimDict(st.anim.dict) end
        if not ok then return false end
    end
    return true
end

CreateThread(function()
    while true do
        local sleep = 500
        local coords = GetEntityCoords(PlayerPedId())
        local target = nil
        local best = Config.InteractDistance

        for _, z in ipairs(interactables) do
            local dist = #(coords - z.coords)
            if dist < best then
                best = dist
                target = z
            end
        end

        if not target then
            for _, dz in ipairs(dealerZones) do
                if #(coords - dz) < Config.InteractDistance + 1.0 then
                    target = { kind = 'dealer' }
                    break
                end
            end
        end

        if target and not uiOpen then
            sleep = 0
            if target.kind == 'gather' then
                helpText(T('help_gather', target.label))
            elseif target.kind == 'process' then
                helpText(T('help_process', target.label))
            else
                helpText(T('help_dealer'))
            end

            if IsControlJustPressed(0, Config.Control) and not exports['qs-core']:IsBusy() then
                if target.kind == 'gather' then
                    if runTask(target.cfg, T('gathering', target.label), target.coords) then
                        TriggerServerEvent('qs-coredrugs:server:gather', target.key)
                    end
                elseif target.kind == 'process' then
                    local p = target.cfg
                    if not exports['qs-core']:HasItem(p.input, p.inputAmount) then
                        exports['qs-core']:Notify(T('need_material', p.inputAmount, target.rawLabel or p.input), 'error', 3000)
                    else
                        local ok
                        if p.stages then
                            ok = runProcessStages(p, target.coords)
                        else
                            ok = runTask(p, T('processing', target.label), target.coords)
                        end
                        if ok then TriggerServerEvent('qs-coredrugs:server:process', target.key) end
                    end
                else
                    TriggerServerEvent('qs-coredrugs:server:openDealer')
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('qs-coredrugs:client:openDealer', function(data)
    if uiOpen or not data then return end
    uiOpen = true
    SetNuiFocus(true, true)
    TriggerEvent('qs-corehud:display', false)
    local colors = exports['qs-core']:GetColors()
    if colors then send('theme', colors) end
    send('open', data)
    send('locale', Locales[GetConvar('qs:locale', 'en')] or Locales.en or {})
end)

RegisterNetEvent('qs-coredrugs:client:updateDealer', function(data)
    if uiOpen and data then send('update', data) end
end)

AddEventHandler('qs:client:colorsChanged', function()
    if uiOpen then
        local colors = exports['qs-core']:GetColors()
        if colors then send('theme', colors) end
    end
end)

local function closeDealer()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    TriggerEvent('qs-corehud:display', true)
    TriggerServerEvent('qs-coredrugs:server:closeDealer')
    send('close')
end

RegisterNUICallback('sell', function(data, cb)
    cb('ok')
    if data and data.name then
        TriggerServerEvent('qs-coredrugs:server:sell', data.name, tonumber(data.count) or 1)
    end
end)

RegisterNUICallback('close', function(_, cb)
    cb('ok')
    closeDealer()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    for _, obj in ipairs(spawnedProps) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
end)
