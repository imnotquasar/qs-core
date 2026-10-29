local downed = false
local respawnAt = 0
local emsCooldownUntil = 0
local animPaused = false

QS.IsDead = function() return downed end
exports('IsDead', function() return downed end)

exports('SetDownAnimPaused', function(state)
    animPaused = state == true
end)

local ANIM = Config.Death.anim or { dict = 'mini@cpr@char_b@cpr_def', clip = 'cpr_pumpchest_idle' }
local ANIM_FLAGS = 1 | 2 | 4 | 8 | 2048 | 8388608

local function nearestHospital()
    local pos = GetEntityCoords(PlayerPedId())
    local best, bestDist = Config.Death.hospitals[1], math.huge
    for _, h in ipairs(Config.Death.hospitals) do
        local d = #(pos - vector3(h.x, h.y, h.z))
        if d < bestDist then best, bestDist = h, d end
    end
    return best
end

local function sendDeath(visible, remain, canRespawn)
    SendNUIMessage({
        action = 'death',
        data = { visible = visible, seconds = remain or 0, canRespawn = canRespawn or false },
    })
end

local function loadDict(dict)
    RequestAnimDict(dict)
    local dl = GetGameTimer() + 2000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < dl do Wait(10) end
end

local function playDownedAnim()
    local ped = PlayerPedId()
    ClearPedSecondaryTask(ped)
    loadDict(ANIM.dict)
    local c = GetEntityCoords(ped)
    local r = GetEntityRotation(ped, 2)
    TaskPlayAnimAdvanced(ped, ANIM.dict, ANIM.clip, c.x, c.y, c.z, r.x, r.y, r.z,
        8.0, 8.0, -1, ANIM_FLAGS, 0.0, 0, 0)
end

local function clearDowned()
    if not downed then return end
    downed = false
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    if IsEntityDead(ped) then
        local c = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(ped), true, false)
    end
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPlayerInvincible(PlayerId(), false)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityVisible(ped, true, false)
    SetEntityAlpha(ped, 255, false)
    ResetEntityAlpha(ped)
    ClearPedBloodDamage(ped)
    DisplayRadar(true)
    TriggerServerEvent('qs:server:setDead', false)
    sendDeath(false)
    TriggerEvent('qs-corehud:display', true)
    TriggerEvent('qs:client:onRevive')

    CreateThread(function()
        for _ = 1, 6 do
            local p = PlayerPedId()
            if IsEntityPlayingAnim(p, ANIM.dict, ANIM.clip, 3) then
                ClearPedTasksImmediately(p)
            end
            SetEntityVisible(p, true, false)
            SetEntityCollision(p, true, true)
            FreezeEntityPosition(p, false)
            ResetEntityAlpha(p)
            Wait(50)
        end
    end)
end

local function respawn()
    if not downed then return end
    local h = nearestHospital()
    DoScreenFadeOut(500)
    local t = GetGameTimer()
    while not IsScreenFadedOut() and GetGameTimer() - t < 1500 do Wait(0) end

    if Config.Death.loseCashOnDeath then TriggerServerEvent('qs:server:death') end

    clearDowned()
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, h.x, h.y, h.z, false, false, false)
    SetEntityHeading(ped, h.w or 0.0)

    Wait(500)
    DoScreenFadeIn(600)
end

local function callEms()
    if GetGameTimer() < emsCooldownUntil then return end
    emsCooldownUntil = GetGameTimer() + (Config.Death.emsCooldown or 30000)
    TriggerEvent('qs:client:emsCall')
    TriggerEvent('qs:client:notify', T('ems_called'), 'info', 4000)
end

local function downedLoop()
    CreateThread(function()
        while downed do
            Wait(0)
            if not downed then break end
            local ped = PlayerPedId()
            if not animPaused and not IsEntityPlayingAnim(ped, ANIM.dict, ANIM.clip, 3) then
                playDownedAnim()
            end
            HideHudComponentThisFrame(19)
            DisplayRadar(false)
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 245, true)

            local canRespawn = GetGameTimer() >= respawnAt
            if canRespawn and IsDisabledControlJustPressed(0, 38) then
                respawn()
            elseif IsDisabledControlJustPressed(0, 47) then
                callEms()
            end
        end
    end)
    CreateThread(function()
        while downed do
            local remain = math.max(0, math.ceil((respawnAt - GetGameTimer()) / 1000))
            sendDeath(true, remain, remain <= 0)
            Wait(500)
        end
    end)
end

local function fadePedAlpha(ped, from, to, ms)
    if not (ped and DoesEntityExist(ped)) then return end
    SetEntityAlpha(ped, from, false)
    local elapsed = 0.0
    while elapsed < ms and DoesEntityExist(ped) do
        Wait(0)
        elapsed = elapsed + GetFrameTime() * 1000.0
        local t = elapsed / ms
        if t > 1.0 then t = 1.0 end
        SetEntityAlpha(ped, math.floor(from + (to - from) * t), false)
    end
    if ped and DoesEntityExist(ped) then
        if to >= 255 then ResetEntityAlpha(ped) else SetEntityAlpha(ped, to, false) end
    end
end

local function fadeOutPed(ped)
    fadePedAlpha(ped, GetEntityAlpha(ped), 0, 250)
end

local function fadeInPed(ped)
    fadePedAlpha(ped, 0, 255, 250)
end

local function enterDowned(persist)
    downed = true
    respawnAt = GetGameTimer() + (Config.Death.respawnTime or 20) * 1000
    if persist ~= false then TriggerServerEvent('qs:server:setDead', true) end
    TriggerEvent('qs-corehud:display', false)
    sendDeath(true, Config.Death.respawnTime or 20, false)
    TriggerEvent('qs:client:onDeath')

    local ped = PlayerPedId()
    local t = GetGameTimer()
    while IsPedRagdoll(ped) and GetGameTimer() - t < 2500 do Wait(0) end

    ped = PlayerPedId()
    fadeOutPed(ped)
    if not downed then ResetEntityAlpha(PlayerPedId()) return end

    ped = PlayerPedId()
    if IsEntityDead(ped) then
        local c = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(ped), false, false)
    end
    SetEntityHealth(ped, 200)
    SetEntityInvincible(ped, true)
    playDownedAnim()
    Wait(120)
    if not downed then
        ped = PlayerPedId()
        ClearPedTasksImmediately(ped)
        SetEntityInvincible(ped, false)
        ResetEntityAlpha(ped)
        return
    end

    fadeInPed(PlayerPedId())

    downedLoop()
end

CreateThread(function()
    while true do
        Wait(300)
        if QS.isLoaded and not downed and IsEntityDead(PlayerPedId()) then
            enterDowned()
        end
    end
end)

RegisterNetEvent('qs:client:revive', function()
    if downed then
        clearDowned()
    else
        local ped = PlayerPedId()
        if IsEntityDead(ped) then
            local c = GetEntityCoords(ped)
            NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(ped), true, false)
        end
        ClearPedTasksImmediately(ped)
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        SetEntityInvincible(ped, false)
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, true)
        SetEntityVisible(ped, true, false)
        ClearPedBloodDamage(ped)
        ResetEntityAlpha(ped)
    end
    TriggerEvent('qs:client:notify', T('revived'), 'success')
end)

RegisterNetEvent('qs:client:forceDown', function()
    if not downed then enterDowned() end
end)

AddEventHandler('qs:client:onPlayerLoaded', function(data)
    if data and data.is_dead and not downed then
        TriggerEvent('qs-corehud:display', false)
        sendDeath(true, 0, true)
        CreateThread(function()
            Wait(1200)
            if not downed then enterDowned(false) end
        end)
    end
end)
