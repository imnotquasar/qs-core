local myJob = 'unemployed'
local spawnedPeds = {}

local myInjuries = {}
local injuriesDirty = false

local reportOpen = false
local reportTarget = nil
local reportCam = nil
local treating = false

local stretchers = {}
local myStretcherId = nil
local carryingId = nil
local lyingId = nil
local mySrc = -1

local BONE_REGION = {}
for region, data in pairs(Config.BodyRegions) do
    for _, bone in ipairs(data.bones) do BONE_REGION[bone] = region end
end

local DAMAGE_TYPE = {}
for category, list in pairs(Config.DamageCategories) do
    for _, name in ipairs(list) do DAMAGE_TYPE[joaat(name)] = category end
end
local HASH_FALL = joaat('WEAPON_FALL')
local HASH_FIRE = joaat('WEAPON_FIRE')

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

local emsGarageBlip = nil
local function refreshEmsBlips()
    if myJob == 'ambulance' then
        if not (emsGarageBlip and DoesBlipExist(emsGarageBlip)) then
            local g = Config.Garage
            emsGarageBlip = AddBlipForCoord(g.coords.x, g.coords.y, g.coords.z)
            SetBlipSprite(emsGarageBlip, g.blip.sprite or 357)
            SetBlipColour(emsGarageBlip, g.blip.color or 2)
            SetBlipScale(emsGarageBlip, g.blip.scale or 0.7)
            SetBlipAsShortRange(emsGarageBlip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(g.blip.label or 'EMS Garage')
            EndTextCommandSetBlipName(emsGarageBlip)
        end
    elseif emsGarageBlip and DoesBlipExist(emsGarageBlip) then
        RemoveBlip(emsGarageBlip)
        emsGarageBlip = nil
    end
end

local function trackJob(name)
    myJob = name or 'unemployed'
    refreshEmsBlips()
end

AddEventHandler('qs:client:onPlayerLoaded', function(data)
    trackJob(data and data.job and data.job.name)
    sendTheme()
    sendLocale()
    mySrc = GetPlayerServerId(PlayerId())
    TriggerServerEvent('qs-ambulance:server:requestStretchers')
end)

AddEventHandler('qs:client:onJobUpdate', function(job)
    trackJob(job and job.name)
end)

CreateThread(function()
    Wait(500)
    sendTheme()
    sendLocale()
    mySrc = GetPlayerServerId(PlayerId())
    local data = exports['qs-core']:GetPlayerData()
    if data and data.job then trackJob(data.job.name) end
    TriggerServerEvent('qs-ambulance:server:requestStretchers')
end)

local function addInjury(region, category)
    if not myInjuries[region] then
        myInjuries[region] = { bleeding = 0, bruising = 0, burning = 0 }
    end
    local data = myInjuries[region]
    data[category] = math.min((data[category] or 0) + 1, 4)
    injuriesDirty = true
end

AddEventHandler('gameEventTriggered', function(event, args)
    if event ~= 'CEventNetworkEntityDamage' then return end
    local ped = PlayerPedId()
    if args[1] ~= ped then return end

    local attacker = args[2]
    local _, bone = GetPedLastDamageBone(ped)
    local region = BONE_REGION[bone] or 'body'

    local category = nil
    if HasPedBeenDamagedByWeapon(ped, HASH_FALL, 0) then
        category = 'bruising'
        ClearPedLastWeaponDamage(ped)
    elseif IsEntityOnFire(ped) or HasPedBeenDamagedByWeapon(ped, HASH_FIRE, 0) then
        category = 'burning'
    elseif attacker and attacker > 0 and attacker ~= ped and IsEntityAPed(attacker) then
        category = DAMAGE_TYPE[GetSelectedPedWeapon(attacker)] or 'bleeding'
    elseif attacker and attacker > 0 and IsEntityAVehicle(attacker) then
        category = 'bruising'
    else
        category = 'bleeding'
    end

    addInjury(region, category)
    ClearPedLastDamageBone(ped)
end)

CreateThread(function()
    while true do
        Wait(1000)
        if injuriesDirty then
            injuriesDirty = false
            TriggerServerEvent('qs-ambulance:server:syncInjuries', myInjuries)
        end
    end
end)

RegisterNetEvent('qs-ambulance:client:setInjuries', function(data)
    myInjuries = type(data) == 'table' and data or {}
end)

local limpApplied = false
local blurApplied = false

CreateThread(function()
    while true do
        Wait(Config.Effects.interval)
        local ped = PlayerPedId()
        if not IsEntityDead(ped) and not exports['qs-core']:IsDead() then
            local bleed, legs, burn = 0, 0, 0
            for region, data in pairs(myInjuries) do
                bleed = math.max(bleed, data.bleeding or 0)
                if region == 'left_leg' or region == 'right_leg' then
                    legs = math.max(legs, data.bruising or 0)
                end
                if region == 'head' or region == 'body' then
                    burn = math.max(burn, data.burning or 0)
                end
            end

            if Config.Effects.bleedDamage and bleed > 0 then
                local hp = GetEntityHealth(ped)
                if hp > 100 + bleed then SetEntityHealth(ped, hp - bleed) end
            end

            if Config.Effects.legLimp then
                if legs > 0 then
                    SetPedMoveRateOverride(ped, 1.0 - legs * 0.1)
                    if legs >= 3 and not limpApplied then
                        limpApplied = true
                        RequestAnimSet('move_m@injured')
                        local dl = GetGameTimer() + 2000
                        while not HasAnimSetLoaded('move_m@injured') and GetGameTimer() < dl do Wait(10) end
                        SetPedMovementClipset(ped, 'move_m@injured', 0.3)
                    end
                elseif limpApplied then
                    limpApplied = false
                    ResetPedMovementClipset(ped, 0.3)
                    SetPedMoveRateOverride(ped, 1.0)
                end
            end

            if Config.Effects.burnBlur then
                if burn >= 2 and not blurApplied then
                    blurApplied = true
                    SetTimecycleModifier('hud_def_blur')
                elseif burn < 2 and blurApplied then
                    blurApplied = false
                    ClearTimecycleModifier()
                end
            end
        end
    end
end)

AddEventHandler('qs:client:onDeath', function()
    TriggerServerEvent('qs-ambulance:server:down')
end)

AddEventHandler('qs:client:onRevive', function()
    TriggerServerEvent('qs-ambulance:server:up')
end)

AddEventHandler('qs:client:emsCall', function()
    TriggerServerEvent('qs-ambulance:server:callEms')
end)

local function itemCounts()
    local items = {}
    for iType, item in pairs(Config.TreatmentItems) do
        items[#items + 1] = {
            name = item,
            injury = iType,
            count = exports['qs-core']:GetItemCount(item),
        }
    end
    table.sort(items, function(a, b) return a.name < b.name end)
    return items
end

local function closeReport(notifyServer)
    if not reportOpen then return end
    reportOpen = false
    reportTarget = nil
    treating = false
    SetNuiFocus(false, false)
    send('close')
    TriggerEvent('qs-corehud:display', true)
    if reportCam then
        RenderScriptCams(false, true, 800, true, false)
        DestroyCam(reportCam, false)
        reportCam = nil
    end
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    SetEntityVisible(ped, true, false)
    ResetEntityAlpha(ped)
    DisplayRadar(true)
    TriggerEvent('qs-corehud:normalizeMinimap')
    if notifyServer then TriggerServerEvent('qs-ambulance:server:closeReport') end
end

local function reportPositionLoop()
    CreateThread(function()
        while reportOpen do
            Wait(0)
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            DisplayRadar(false)
            local tped = reportTarget == GetPlayerServerId(PlayerId()) and PlayerPedId()
                or GetPlayerPed(GetPlayerFromServerId(reportTarget or -1))
            if tped == 0 or not DoesEntityExist(tped) then
                closeReport(true)
                break
            end
            local positions = {}
            for region, data in pairs(Config.BodyRegions) do
                local c = GetPedBoneCoords(tped, data.marker, 0.0, 0.0, 0.0)
                local on, x, y = GetScreenCoordFromWorldCoord(c.x, c.y, c.z)
                positions[region] = { x = x * 100, y = y * 100, on = on }
            end
            send('positions', positions)
        end
    end)
end

local function reportAbortLoop()
    CreateThread(function()
        while reportOpen do
            Wait(600)
            if reportTarget and reportTarget ~= GetPlayerServerId(PlayerId()) then
                local tped = GetPlayerPed(GetPlayerFromServerId(reportTarget))
                if tped == 0 or not DoesEntityExist(tped)
                    or #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(tped)) > Config.TreatDistance + 1.5 then
                    closeReport(true)
                end
            end
        end
    end)
end

RegisterNetEvent('qs-ambulance:client:openReport', function(data)
    if reportOpen or not data then return end
    local isSelf = data.target == GetPlayerServerId(PlayerId())
    local tped = isSelf and PlayerPedId() or GetPlayerPed(GetPlayerFromServerId(data.target))
    if tped == 0 or not DoesEntityExist(tped) then return end

    reportOpen = true
    reportTarget = data.target

    local offset = data.downed and vec3(0.0, 1.5, 7.4) or vec3(0.0, 3.8, 1.5)
    local camPos = GetOffsetFromEntityInWorldCoords(tped, offset.x, offset.y, offset.z)
    reportCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(reportCam, camPos.x, camPos.y, camPos.z)
    PointCamAtEntity(reportCam, tped, 0.0, 0.0, data.downed and 0.0 or 0.2, true)
    SetCamFov(reportCam, data.downed and 10.5 or 22.0)
    SetCamActive(reportCam, true)
    RenderScriptCams(true, true, 800, true, false)

    if not isSelf then
        local scen = data.downed and 'CODE_HUMAN_MEDIC_TEND_TO_DEAD' or 'WORLD_HUMAN_CLIPBOARD'
        CreateThread(function()
            local ped = PlayerPedId()
            local c = GetEntityCoords(tped)
            TaskTurnPedToFaceCoord(ped, c.x, c.y, c.z, 500)
            Wait(450)
            while reportOpen do
                ped = PlayerPedId()
                if not IsPedUsingAnyScenario(ped) then
                    TaskStartScenarioInPlace(ped, scen, 0, true)
                end
                Wait(500)
            end
        end)
    end

    TriggerEvent('qs-corehud:display', false)
    SetNuiFocus(true, true)
    sendTheme()
    sendLocale()
    send('open', {
        name = data.name,
        downed = data.downed,
        regions = data.regions,
        items = itemCounts(),
    })

    reportPositionLoop()
    reportAbortLoop()
end)

RegisterNetEvent('qs-ambulance:client:updateReport', function(regions)
    if not reportOpen then return end
    send('update', { regions = regions, items = itemCounts() })
end)

RegisterNetEvent('qs-ambulance:client:closeReport', function()
    closeReport(false)
end)

RegisterNUICallback('treat', function(data, cb)
    cb('ok')
    if not reportOpen or treating or not data or not data.item or not data.region then return end

    treating = true
    SetNuiFocus(false, false)
    CreateThread(function()
        local ok = exports['qs-core']:Progress({
            duration = Config.TreatmentTime,
            label = T('treating'),
            canCancel = true,
        })

        treating = false

        if reportOpen then
            SetNuiFocus(true, true)
            if ok then
                TriggerServerEvent('qs-ambulance:server:treat', data.item, data.region)
            end
        end
    end)
end)

RegisterNUICallback('close', function(_, cb)
    cb('ok')
    if not treating then closeReport(true) end
end)

local function nearestPlayer(maxDist)
    local me = PlayerPedId()
    local myCoords = GetEntityCoords(me)
    local target, best = nil, maxDist or (Config.TreatDistance - 0.5)
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if ped ~= me and DoesEntityExist(ped) then
            local d = #(myCoords - GetEntityCoords(ped))
            if d < best then
                best = d
                target = GetPlayerServerId(pid)
            end
        end
    end
    return target
end

local function nearestDowned()
    local me = PlayerPedId()
    local myCoords = GetEntityCoords(me)
    local target, best = nil, Config.TreatDistance - 0.5
    for _, pid in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(pid)
        if ped ~= me and DoesEntityExist(ped) then
            local sid = GetPlayerServerId(pid)
            local isDown = (Player(sid).state and Player(sid).state.dead) or IsEntityDead(ped)
            if isDown then
                local d = #(myCoords - GetEntityCoords(ped))
                if d < best then
                    best = d
                    target = sid
                end
            end
        end
    end
    return target
end

RegisterCommand('diagnose', function()
    if myJob ~= 'ambulance' then
        exports['qs-core']:Notify(T('need_job'), 'error')
        return
    end
    if reportOpen or exports['qs-core']:IsDead() then return end
    local target = nearestPlayer() or GetPlayerServerId(PlayerId())
    TriggerServerEvent('qs-ambulance:server:openReport', target)
end, false)

RegisterNetEvent('qs-ambulance:client:bandage', function()
    local ok = exports['qs-core']:Progress({
        duration = Config.BandageTime,
        label = T('applying_bandage'),
        disableMovement = true,
    })
    if ok then
        local ped = PlayerPedId()
        SetEntityHealth(ped, math.min(GetEntityHealth(ped) + Config.BandageHeal, GetEntityMaxHealth(ped)))
        exports['qs-core']:Notify(T('bandaged'), 'success')
    end
end)

RegisterNetEvent('qs-ambulance:client:healed', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    myInjuries = {}
end)

RegisterNetEvent('qs-ambulance:client:alert', function(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 153)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.0)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(T('blip_down'))
    EndTextCommandSetBlipName(blip)
    SetTimeout(Config.AlertDuration, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)

local ibScaleform = nil
local function drawInstructional(buttons)
    if not ibScaleform then
        ibScaleform = RequestScaleformMovie('instructional_buttons')
        local dl = GetGameTimer() + 2000
        while not HasScaleformMovieLoaded(ibScaleform) and GetGameTimer() < dl do Wait(0) end
    end
    local sf = ibScaleform
    PushScaleformMovieFunction(sf, 'CLEAR_ALL')
    PopScaleformMovieFunctionVoid()
    PushScaleformMovieFunction(sf, 'SET_CLEAR_SPACE')
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()
    for i = 1, #buttons do
        PushScaleformMovieFunction(sf, 'SET_DATA_SLOT')
        PushScaleformMovieFunctionParameterInt(i - 1)
        PushScaleformMovieMethodParameterButtonName(GetControlInstructionalButton(2, buttons[i].control, true))
        BeginTextCommandScaleformString('STRING')
        AddTextComponentSubstringPlayerName(buttons[i].label)
        EndTextCommandScaleformString()
        PopScaleformMovieFunctionVoid()
    end
    PushScaleformMovieFunction(sf, 'DRAW_INSTRUCTIONAL_BUTTONS')
    PushScaleformMovieFunctionParameterInt(-1)
    PopScaleformMovieFunctionVoid()
    PushScaleformMovieFunction(sf, 'SET_BACKGROUND_COLOUR')
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()
    DrawScaleformMovieFullscreen(sf, 255, 255, 255, 255, 0)
end

local function netToObj(netId)
    if not netId or netId == 0 or not NetworkDoesNetworkIdExist(netId) then return 0 end
    local obj = NetToObj(netId)
    return (obj ~= 0 and DoesEntityExist(obj)) and obj or 0
end

local function requestControl(entity)
    if entity == 0 then return false end
    if not NetworkGetEntityIsNetworked(entity) then return true end
    NetworkRequestControlOfEntity(entity)
    local dl = GetGameTimer() + 1500
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < dl do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end
    return NetworkHasControlOfEntity(entity)
end

local KEYS = Config.Stretcher.keys
local DISABLED = Config.Stretcher.disabledControls

local function loadDict(dict)
    RequestAnimDict(dict)
    local dl = GetGameTimer() + 2000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < dl do Wait(10) end
end

local function nearAnyStretcher(coords)
    for _, s in pairs(stretchers) do
        local o = netToObj(s.netId)
        if o ~= 0 and #(coords - GetEntityCoords(o)) < 2.5 then return true end
    end
    return false
end

local move, drop, placePatient, putInVehicle, handlePatient

function move(id)
    local s = stretchers[id]
    if not s or carryingId then return end
    local obj = netToObj(s.netId)
    if obj == 0 or not requestControl(obj) then return end
    carryingId = id
    DetachEntity(obj, false, false)
    SetEntityCollision(obj, false, false)
    local a = Config.Stretcher.carryAnim
    loadDict(a.dict)
    CreateThread(function()
        while carryingId == id do
            Wait(0)
            local ped = PlayerPedId()
            local o = netToObj(s.netId)
            if o == 0 then break end
            if NetworkGetEntityOwner(o) ~= PlayerId() then requestControl(o) end
            DisablePlayerFiring(PlayerId(), true)
            for _, c in ipairs(DISABLED) do DisableControlAction(0, c, true) end
            if not IsEntityPlayingAnim(ped, a.dict, a.clip, 3) then
                TaskPlayAnim(ped, a.dict, a.clip, 8.0, 8.0, -1, 50, 0, false, false, false)
            end
            if not IsEntityAttachedToEntity(o, ped) then
                local off = Config.Stretcher.carryOffset
                AttachEntityToEntity(o, ped, 0, off.x, off.y, off.z, 180.0, 180.0, 180.0, 0.0, false, false, false, 2, true)
            end
            drawInstructional({ { control = KEYS.action, label = T('ib_drop') } })
            if IsControlJustPressed(0, KEYS.action) or IsDisabledControlJustPressed(0, KEYS.action) then
                drop(id)
            end
        end
        RemoveAnimDict(a.dict)
    end)
end

function drop(id)
    if carryingId ~= id then return end
    carryingId = nil
    local s = stretchers[id]
    ClearPedTasks(PlayerPedId())
    local obj = netToObj(s and s.netId or 0)
    if obj ~= 0 then
        DetachEntity(obj, true, true)
        SetEntityCollision(obj, true, true)
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        local c = GetEntityCoords(obj)
        TriggerServerEvent('qs-ambulance:server:updateStretcher', id, { coords = { x = c.x, y = c.y, z = c.z, w = GetEntityHeading(obj) } })
    end
end

function placePatient(id)
    local target = nearestDowned()
    if not target then
        exports['qs-core']:Notify(T('no_downed_near'), 'error')
        return
    end
    TriggerServerEvent('qs-ambulance:server:setPatient', id, target)
end

function putInVehicle(id, veh)
    local s = stretchers[id]
    if not s then return end
    local off = Config.Stretcher.vehicleOffsets[GetEntityModel(veh)]
    if not off then
        exports['qs-core']:Notify(T('not_ambulance'), 'error')
        return
    end
    local obj = netToObj(s.netId)
    if obj == 0 or not requestControl(obj) then return end
    if carryingId == id then carryingId = nil ClearPedTasks(PlayerPedId()) end
    SetVehicleDoorOpen(veh, 2, false, false)
    SetVehicleDoorOpen(veh, 3, false, false)
    Wait(400)
    SetEntityCollision(obj, false, false)
    FreezeEntityPosition(obj, false)
    AttachEntityToEntity(obj, veh, 0, off.coords.x, off.coords.y, off.coords.z, off.rotation.x, off.rotation.y, off.rotation.z, false, false, false, false, 1, true)
    SetTimeout(600, function()
        if DoesEntityExist(veh) then
            SetVehicleDoorShut(veh, 2, false)
            SetVehicleDoorShut(veh, 3, false)
        end
    end)
end

function handlePatient(id)
    CreateThread(function()
        local a = Config.Stretcher.patientAnim
        loadDict(a.dict)
        exports['qs-core']:SetDownAnimPaused(true)
        local ped = PlayerPedId()
        SetEntityVisible(ped, true, false)
        ResetEntityAlpha(ped)
        while lyingId == id do
            Wait(0)
            local s = stretchers[id]
            local obj = s and netToObj(s.netId) or 0
            if obj == 0 then lyingId = nil break end
            ped = PlayerPedId()
            for _, c in ipairs(DISABLED) do DisableControlAction(0, c, true) end
            DisablePlayerFiring(PlayerId(), true)
            if not IsEntityAttachedToEntity(ped, obj) then
                local off = Config.Stretcher.patientOffset
                AttachEntityToEntity(ped, obj, 0, off.x, off.y, off.z, 0.0, 0.0, 180.0, false, false, false, true, 1, true)
            end
            if not IsEntityPlayingAnim(ped, a.dict, a.clip, 3) then
                TaskPlayAnim(ped, a.dict, a.clip, 8.0, 8.0, -1, 1, 0, false, false, false)
            end
            if not exports['qs-core']:IsDead() then
                drawInstructional({ { control = KEYS.action, label = T('ib_get_off') } })
                if IsControlJustPressed(0, KEYS.action) or IsDisabledControlJustPressed(0, KEYS.action) then
                    TriggerServerEvent('qs-ambulance:server:leaveStretcher', id)
                end
            end
        end
        ped = PlayerPedId()
        local s = stretchers[id]
        local obj = s and netToObj(s.netId) or 0
        local dropX, dropY, dropZ
        if obj ~= 0 then
            local bc = GetEntityCoords(obj)
            local side = GetOffsetFromEntityInWorldCoords(obj, 0.9, 0.0, 0.0)
            local gFound, groundZ = GetGroundZFor_3dCoord(bc.x, bc.y, bc.z + 1.0, false)
            dropX, dropY, dropZ = side.x, side.y, (gFound and groundZ or bc.z)
        else
            local c = GetEntityCoords(ped)
            dropX, dropY, dropZ = c.x, c.y, c.z
        end
        DetachEntity(ped, true, true)
        ClearPedTasksImmediately(ped)
        SetEntityCoordsNoOffset(ped, dropX, dropY, dropZ + 0.02, false, false, false)
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        SetEntityVisible(ped, true, false)
        ResetEntityAlpha(ped)
        exports['qs-core']:SetDownAnimPaused(false)
        RemoveAnimDict(a.dict)
    end)
end

AddEventHandler('qs:client:onRevive', function()
    if lyingId then
        local id = lyingId
        lyingId = nil
        DetachEntity(PlayerPedId(), true, false)
        ClearPedTasksImmediately(PlayerPedId())
        TriggerServerEvent('qs-ambulance:server:leaveStretcher', id)
    end
end)

RegisterCommand('stretcher', function()
    if myJob ~= 'ambulance' then
        exports['qs-core']:Notify(T('need_job'), 'error')
        return
    end
    if myStretcherId then
        TriggerServerEvent('qs-ambulance:server:removeStretcher', myStretcherId)
        return
    end

    local model = Config.Stretcher.model
    if type(model) == 'string' then model = joaat(model) end
    RequestModel(model)
    local dl = GetGameTimer() + 8000
    while not HasModelLoaded(model) and GetGameTimer() < dl do Wait(10) end
    if not HasModelLoaded(model) then return end

    local ped = PlayerPedId()
    local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, 0.0)
    local obj = CreateObject(model, pos.x, pos.y, pos.z, true, true, false)
    SetModelAsNoLongerNeeded(model)
    while not DoesEntityExist(obj) do Wait(0) end
    SetEntityHeading(obj, GetEntityHeading(ped))
    PlaceObjectOnGroundProperly(obj)
    if not NetworkGetEntityIsNetworked(obj) then NetworkRegisterEntityAsNetworked(obj) end
    if not NetworkGetEntityIsNetworked(obj) then
        DeleteEntity(obj)
        exports['qs-core']:Notify(T('stretcher_fail'), 'error')
        return
    end
    SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(obj), true)
    local c = GetEntityCoords(obj)
    TriggerServerEvent('qs-ambulance:server:createStretcher', NetworkGetNetworkIdFromEntity(obj), { x = c.x, y = c.y, z = c.z, w = GetEntityHeading(obj) })
end, false)

RegisterNetEvent('qs-ambulance:client:stretcherAdd', function(s)
    if not s or not s.id then return end
    stretchers[s.id] = s
end)

RegisterNetEvent('qs-ambulance:client:stretcherUpdate', function(id, data)
    local s = stretchers[id]
    if not s or not data then return end
    if data.netId then s.netId = data.netId end
    if data.coords then s.coords = data.coords end
end)

RegisterNetEvent('qs-ambulance:client:stretcherId', function(id)
    myStretcherId = id
    move(id)
end)

RegisterNetEvent('qs-ambulance:client:stretcherPatient', function(id, target)
    local s = stretchers[id]
    if not s then return end
    s.patient = (target and target ~= 0) and target or nil
    if target == mySrc then
        lyingId = id
        handlePatient(id)
    elseif lyingId == id then
        lyingId = nil
    end
end)

RegisterNetEvent('qs-ambulance:client:stretcherRemove', function(id)
    local s = stretchers[id]
    if not s then return end
    if carryingId == id then carryingId = nil ClearPedTasks(PlayerPedId()) end
    if lyingId == id then lyingId = nil end
    if myStretcherId == id then myStretcherId = nil end
    if s.owner == mySrc then
        local obj = netToObj(s.netId)
        if obj ~= 0 then
            SetEntityAsMissionEntity(obj, true, true)
            DeleteEntity(obj)
        end
    end
    stretchers[id] = nil
end)

CreateThread(function()
    while true do
        local sleep = 500
        if myJob == 'ambulance' and not carryingId and not lyingId and not reportOpen then
            local coords = GetEntityCoords(PlayerPedId())
            local nearId
            for id, s in pairs(stretchers) do
                local o = netToObj(s.netId)
                if o ~= 0 and #(coords - GetEntityCoords(o)) < 2.2 then nearId = id break end
            end
            if nearId then
                sleep = 0
                local s = stretchers[nearId]
                local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
                if veh == 0 or not Config.Stretcher.vehicleOffsets[GetEntityModel(veh)] then veh = nil end

                local buttons = {
                    { control = KEYS.action, label = T('ib_move') },
                    { control = KEYS.patient, label = s.patient and T('ib_unload') or T('ib_load') },
                    { control = KEYS.store, label = veh and T('ib_into_vehicle') or T('ib_store') },
                }
                drawInstructional(buttons)

                if IsControlJustPressed(0, KEYS.action) then
                    move(nearId)
                elseif IsControlJustPressed(0, KEYS.patient) then
                    if s.patient then TriggerServerEvent('qs-ambulance:server:setPatient', nearId, 0)
                    else placePatient(nearId) end
                elseif IsControlJustPressed(0, KEYS.store) then
                    if veh then putInVehicle(nearId, veh)
                    else TriggerServerEvent('qs-ambulance:server:removeStretcher', nearId) end
                end
            end
        end
        Wait(sleep)
    end
end)

local function helpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

CreateThread(function()
    local h = Config.Hospital
    local addBlip = function(loc, b)
        if not b then return end
        local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
        SetBlipSprite(blip, b.sprite or 61)
        SetBlipColour(blip, b.color or 2)
        SetBlipScale(blip, b.scale or 0.75)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(b.label or 'Hospital')
        EndTextCommandSetBlipName(blip)
    end
    addBlip(h.coords, h.blip)

    local hash = joaat(h.ped)
    RequestModel(hash)
    local dl = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < dl do Wait(10) end
    if HasModelLoaded(hash) then
        local ped = CreatePed(4, hash, h.coords.x, h.coords.y, h.coords.z - 1.0, h.coords.w or 0.0, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        if h.scenario then TaskStartScenarioInPlace(ped, h.scenario, 0, true) end
        spawnedPeds[#spawnedPeds + 1] = ped
        SetModelAsNoLongerNeeded(hash)
    end
end)

local function spawnAmbulance()
    local g = Config.Garage
    if IsAnyVehicleNearPoint(g.spawn.x, g.spawn.y, g.spawn.z, 3.0) then
        exports['qs-core']:Notify(T('garage_blocked'), 'error')
        return
    end
    local hash = joaat(g.model)
    RequestModel(hash)
    local dl = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < dl do Wait(10) end
    if not HasModelLoaded(hash) then return end
    local veh = CreateVehicle(hash, g.spawn.x, g.spawn.y, g.spawn.z, g.spawn.w or 0.0, true, false)
    SetVehicleOnGroundProperly(veh)
    SetVehicleFuelLevel(veh, 100.0)
    SetModelAsNoLongerNeeded(hash)
end

local function storeAmbulance(veh)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= PlayerPedId() then
        exports['qs-core']:Notify(T('garage_not_driver'), 'error')
        return
    end
    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
    exports['qs-core']:Notify(T('vehicle_stored'), 'success')
end

CreateThread(function()
    local h = Config.Hospital.coords
    local sup = Config.Supplies.coords
    local gar = Config.Garage.coords
    while true do
        local sleep = 600
        if not reportOpen and not lyingId then
            local coords = GetEntityCoords(PlayerPedId())

            if #(coords - vector3(h.x, h.y, h.z)) < Config.InteractDistance then
                sleep = 0
                helpText(T('help_checkin', Config.Hospital.price))
                if IsControlJustPressed(0, Config.Control) and not exports['qs-core']:IsBusy() then
                    local ok = exports['qs-core']:Progress({
                        duration = Config.Hospital.time,
                        label = T('being_treated'),
                        disableMovement = true,
                    })
                    if ok then TriggerServerEvent('qs-ambulance:server:checkin') end
                end
            elseif myJob == 'ambulance' and #(coords - vector3(sup.x, sup.y, sup.z)) < Config.InteractDistance then
                sleep = 0
                helpText(T('help_supplies'))
                if IsControlJustPressed(0, Config.Control) then
                    TriggerServerEvent('qs-ambulance:server:supplies')
                end
            elseif myJob == 'ambulance' and #(coords - vector3(gar.x, gar.y, gar.z)) < Config.InteractDistance then
                sleep = 0
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if veh ~= 0 then
                    helpText(T('help_ems_store'))
                    if IsControlJustPressed(0, Config.Control) then
                        storeAmbulance(veh)
                    end
                else
                    helpText(T('help_ems_garage'))
                    if IsControlJustPressed(0, Config.Control) then
                        spawnAmbulance()
                    end
                end
            elseif myJob == 'ambulance' then
                local target = nearestDowned()
                if target and not nearAnyStretcher(coords) then
                    sleep = 0
                    helpText(T('help_treat'))
                    if IsControlJustPressed(0, Config.Control) and not exports['qs-core']:IsBusy() then
                        TriggerServerEvent('qs-ambulance:server:openReport', target)
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    Wait(1000)
    TriggerEvent('chat:addSuggestion', '/diagnose', T('sug_diagnose'))
    TriggerEvent('chat:addSuggestion', '/stretcher', T('sug_stretcher'))
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    closeReport(false)
    if myStretcherId then TriggerServerEvent('qs-ambulance:server:removeStretcher', myStretcherId) end
    for _, s in pairs(stretchers) do
        if s.owner == mySrc then
            local obj = netToObj(s.netId)
            if obj ~= 0 then SetEntityAsMissionEntity(obj, true, true) DeleteEntity(obj) end
        end
    end
    carryingId = nil
    if lyingId then
        lyingId = nil
        DetachEntity(PlayerPedId(), true, false)
    end
    if limpApplied then ResetPedMovementClipset(PlayerPedId(), 0.0) end
    if blurApplied then ClearTimecycleModifier() end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
