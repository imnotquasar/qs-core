local busy = false

local function playAnimation(ped, data)
    local anim = data.animation
    if not anim then return end
    if anim.animDict and anim.anim then
        RequestAnimDict(anim.animDict)
        local deadline = GetGameTimer() + 2000
        while not HasAnimDictLoaded(anim.animDict) and GetGameTimer() < deadline do Wait(10) end
        TaskPlayAnim(ped, anim.animDict, anim.anim, 3.0, 3.0, -1, anim.flags or 49, 0, false, false, false)
    elseif anim.task then
        TaskStartScenarioInPlace(ped, anim.task, 0, true)
    end
end

local function spawnProp(ped, prop)
    if not prop or not prop.model then return nil end
    local model = type(prop.model) == 'string' and joaat(prop.model) or prop.model
    RequestModel(model)
    local deadline = GetGameTimer() + 2000
    while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(10) end
    if not HasModelLoaded(model) then return nil end
    local obj = CreateObject(model, GetEntityCoords(ped), true, true, false)
    local c = prop.coords or {}
    local r = prop.rotation or {}
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, prop.bone or 60309),
        c.x or 0.0, c.y or 0.0, c.z or 0.0, r.x or 0.0, r.y or 0.0, r.z or 0.0,
        true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
    return obj
end

local function run(data, handler)
    if busy then
        if handler then handler(true) end
        return
    end
    busy = true
    CreateThread(function()
        local ped = PlayerPedId()
        playAnimation(ped, data)
        local prop1 = spawnProp(ped, data.prop)
        local prop2 = spawnProp(ped, data.propTwo)

        local disableMove = false
        local dc = data.controlDisables or data.disableControls
        if dc then disableMove = dc.disableMovement or dc.move or dc.car or false end

        local ok = exports['qs-core']:Progress({
            duration = data.duration or 3000,
            label = data.label or '',
            canCancel = data.canCancel,
            disableMovement = disableMove,
        })

        ClearPedTasks(ped)
        if prop1 and DoesEntityExist(prop1) then DeleteEntity(prop1) end
        if prop2 and DoesEntityExist(prop2) then DeleteEntity(prop2) end
        busy = false

        if handler then handler(not ok) end
    end)
end

exports('Progress', run)

exports('ProgressWithStartEvent', function(data, startCb, handler)
    if startCb then startCb() end
    run(data, handler)
end)

exports('ProgressWithTickEvent', function(data, _tickCb, handler)
    run(data, handler)
end)

exports('ProgressWithStartAndTick', function(data, startCb, _tickCb, handler)
    if startCb then startCb() end
    run(data, handler)
end)

exports('isDoingSomething', function()
    return busy
end)

RegisterNetEvent('progressbar:client:cancel', function()
    exports['qs-core']:CancelProgress()
end)
