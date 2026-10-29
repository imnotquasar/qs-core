local Active = false
local Camera = nil
local Entity = nil
local EntityPed = nil
local InVehicle = false
local Speed = 1.0
local ResourceName = GetCurrentResourceName()

local Settings = {
    minSpeed = 0.5,
    maxSpeed = 20.0,
    speedStep = 0.5,
    defaultSpeed = 1.0,
    pedFirstPerson = false,
    vehFirstPerson = false,
    allowMap = true,
    enableSounds = true,
    minPitch = -89.0,
    maxPitch = 89.0,
}

local Keys = {
    forward = 32,
    backward = 33,
    left = 34,
    right = 35,
    up = 44,
    down = 46,
    speedUp = 15,
    speedDown = 14,
    speedReset = 348,
    slow = 36,
    fast = 21,
    faster = 19,
}

local function PlaySound(name)
    if not Settings.enableSounds then return end
    PlaySoundFromEntity(-1, name, EntityPed, 'HUD_LIQUOR_STORE_SOUNDSET', false, 0)
end

local function IsPressed(inputGroup, control)
    return IsControlPressed(inputGroup, control) or IsDisabledControlPressed(inputGroup, control)
end

local function IsDriving(ped, veh)
    return ped == GetPedInVehicleSeat(veh, -1)
end

local function GetGroundZ(coords)
    local ray = StartShapeTestRay(coords.x, coords.y, coords.z + 1.0, coords.x, coords.y, -10000.0, 1, 0)
    local _, hit, hitCoords = GetShapeTestResult(ray)
    return hit == 1 and hitCoords or coords
end

local function SetupCamera()
    local rot = GetEntityRotation(Entity)
    local coords = GetEntityCoords(Entity)

    Camera = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', coords.x, coords.y, coords.z, 0.0, 0.0, rot.z, 75.0, false, 0)
    SetCamActive(Camera, true)
    RenderScriptCams(true, true, 800, false, false)

    local offsetY, offsetZ
    if InVehicle then
        offsetY = Settings.vehFirstPerson and 0.5 or -4.5
        offsetZ = Settings.vehFirstPerson and 1.0 or 2.0
    else
        offsetY = Settings.pedFirstPerson and 0.0 or -2.0
        offsetZ = Settings.pedFirstPerson and 0.8 or 0.5
    end

    AttachCamToEntity(Camera, Entity, 0.0, offsetY, offsetZ, true)
end

local function DestroyCamera()
    if not Camera then return end
    SetGameplayCamRelativeHeading(0)
    RenderScriptCams(false, true, 800, true, true)
    DetachEntity(Entity, true, true)
    SetCamActive(Camera, false)
    DestroyCam(Camera, true)
    Camera = nil
end

local function DisableControls()
    HudWeaponWheelIgnoreSelection()
    DisableAllControlActions(0)
    DisableAllControlActions(1)
    DisableAllControlActions(2)

    EnableControlAction(0, 178, true)
    EnableControlAction(0, 191, true)
    EnableControlAction(0, 201, true)
    EnableControlAction(0, 207, true)
    EnableControlAction(0, 220, true)
    EnableControlAction(0, 221, true)
    EnableControlAction(0, 245, true)

    if Settings.allowMap then
        EnableControlAction(0, 200, true)
    end
end

local function HandleRotation()
    local axisX = GetControlNormal(0, 220)
    local axisY = GetControlNormal(0, 221)
    local rot = GetCamRot(Camera, 2)

    local newX = rot.x + (axisY * -5.0)
    local newZ = rot.z + (axisX * -10.0)

    newX = math.max(Settings.minPitch, math.min(Settings.maxPitch, newX))

    SetCamRot(Camera, newX, rot.y, newZ, 2)
    SetEntityHeading(Entity, newZ % 360)
end

local function HandleSpeed()
    if IsPressed(2, Keys.speedUp) then
        Speed = math.min(Speed + Settings.speedStep, Settings.maxSpeed)
    elseif IsPressed(2, Keys.speedDown) then
        Speed = math.max(Speed - Settings.speedStep, Settings.minSpeed)
    elseif IsDisabledControlJustReleased(0, Keys.speedReset) then
        Speed = Settings.defaultSpeed
    end
end

local function GetSpeedMultiplier()
    if IsPressed(0, Keys.faster) then return 4.0 end
    if IsPressed(0, Keys.fast) then return 2.0 end
    if IsPressed(0, Keys.slow) then return 0.25 end
    return 1.0
end

local function HandleMovement()
    local multi = GetSpeedMultiplier()
    local finalSpeed = Speed * multi
    local pitch = GetCamRot(Camera, 0)
    local pitchFactor = pitch.x / 89.0

    if IsPressed(0, Keys.forward) then
        local verticalOffset = pitchFactor * (finalSpeed * 0.5)
        local newPos = GetOffsetFromEntityInWorldCoords(Entity, 0.0, 0.5 * finalSpeed, verticalOffset)
        SetEntityCoordsNoOffset(Entity, newPos.x, newPos.y, newPos.z, false, false, false)
    elseif IsPressed(0, Keys.backward) then
        local verticalOffset = -pitchFactor * (finalSpeed * 0.5)
        local newPos = GetOffsetFromEntityInWorldCoords(Entity, 0.0, -0.5 * finalSpeed, verticalOffset)
        SetEntityCoordsNoOffset(Entity, newPos.x, newPos.y, newPos.z, false, false, false)
    end

    if IsPressed(0, Keys.left) then
        local newPos = GetOffsetFromEntityInWorldCoords(Entity, -0.5 * finalSpeed, 0.0, 0.0)
        SetEntityCoordsNoOffset(Entity, newPos.x, newPos.y, newPos.z, false, false, false)
    elseif IsPressed(0, Keys.right) then
        local newPos = GetOffsetFromEntityInWorldCoords(Entity, 0.5 * finalSpeed, 0.0, 0.0)
        SetEntityCoordsNoOffset(Entity, newPos.x, newPos.y, newPos.z, false, false, false)
    end

    if IsPressed(0, Keys.up) then
        local newPos = GetOffsetFromEntityInWorldCoords(Entity, 0.0, 0.0, 0.5 * finalSpeed)
        SetEntityCoordsNoOffset(Entity, newPos.x, newPos.y, newPos.z, false, false, false)
    elseif IsPressed(0, Keys.down) then
        local newPos = GetOffsetFromEntityInWorldCoords(Entity, 0.0, 0.0, -0.5 * finalSpeed)
        SetEntityCoordsNoOffset(Entity, newPos.x, newPos.y, newPos.z, false, false, false)
    end
end

local function ApplyEntityState()
    local coords = GetEntityCoords(Entity)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    FreezeEntityPosition(Entity, true)
    SetEntityCollision(Entity, false, false)
    SetEntityVisible(Entity, false, false)
    SetEntityInvincible(Entity, true)
    SetEntityAlpha(Entity, 0, false)
    SetLocalPlayerVisibleLocally(false)

    if InVehicle then
        SetEntityVisible(EntityPed, false, false)
        SetEntityAlpha(EntityPed, 0, false)
    end

    SetEveryoneIgnorePlayer(EntityPed, true)
    SetPoliceIgnorePlayer(EntityPed, true)
end

local function DrawCenteredText(text, y, scale, r, g, b, a)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextOutline()
    SetTextDropShadow()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.5, y)
end

local ibScaleform = nil
local function DrawInstructional()
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

    local buttons = {
        { control = 32, label = 'Move' },
        { control = Keys.up, label = 'Up' },
        { control = Keys.down, label = 'Down' },
        { control = Keys.fast, label = 'Fast' },
        { control = Keys.slow, label = 'Slow' },
        { control = Keys.speedUp, label = 'Speed' },
    }
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

local function DrawUI()
    local multi = GetSpeedMultiplier()
    local modText = multi == 4.0 and '~r~[4x]' or multi == 2.0 and '~y~[2x]' or multi == 0.25 and '~c~[0.25x]' or ''
    DrawCenteredText(('~b~NOCLIP~s~  |  Speed: ~y~%.1f~s~ %s'):format(Speed, modText), 0.905, 0.38, 255, 255, 255, 220)
    DrawInstructional()
end

local function ResetEntityState()
    FreezeEntityPosition(Entity, false)
    SetEntityCollision(Entity, true, true)
    SetEntityVisible(Entity, true, false)
    SetLocalPlayerVisibleLocally(true)
    ResetEntityAlpha(Entity)
    ResetEntityAlpha(EntityPed)
    SetEveryoneIgnorePlayer(EntityPed, false)
    SetPoliceIgnorePlayer(EntityPed, false)
end

local function WaitForLanding()
    if GetVehiclePedIsIn(EntityPed, false) ~= 0 then
        while not IsVehicleOnAllWheels(Entity) and not Active do
            Wait(0)
        end
        while not Active do
            Wait(0)
            if IsVehicleOnAllWheels(Entity) then
                SetEntityInvincible(Entity, false)
                return
            end
        end
    else
        if IsPedFalling(Entity) and math.abs(1 - GetEntityHeightAboveGround(Entity)) > 1.0 then
            while (IsPedStopped(Entity) or not IsPedFalling(Entity)) and not Active do
                Wait(0)
            end
        end
        while not Active do
            Wait(0)
            if not IsPedFalling(Entity) and not IsPedRagdoll(Entity) then
                SetEntityInvincible(Entity, false)
                return
            end
        end
    end
end

local function StopNoclip()
    ResetEntityState()
    if ibScaleform then
        SetScaleformMovieAsNoLongerNeeded(ibScaleform)
        ibScaleform = nil
    end
    WaitForLanding()
end

local function StartNoclipLoop()
    CreateThread(function()
        while Active do
            Wait(0)
            DisableControls()
            HandleRotation()
            HandleSpeed()
            HandleMovement()
            ApplyEntityState()
            DrawUI()
        end
        StopNoclip()
    end)
end

local function ToggleNoclip(state)
    Active = state ~= nil and state or not Active
    EntityPed = PlayerPedId()

    local veh = GetVehiclePedIsIn(EntityPed, false)
    InVehicle = veh ~= 0 and IsDriving(EntityPed, veh)

    if InVehicle then
        Entity = veh
        SetVehicleEngineOn(Entity, not Active, true, Active)
    else
        Entity = EntityPed
    end

    if Active then
        FreezeEntityPosition(EntityPed, true)
        SetupCamera()
        PlaySound('SELECT')

        local waitTime = InVehicle and Settings.vehFirstPerson or Settings.pedFirstPerson
        if waitTime then
            Wait(800)
        end

        if not InVehicle then
            ClearPedTasksImmediately(EntityPed)
        end
    else
        local groundCoords = GetGroundZ(GetEntityCoords(Entity))
        SetEntityCoords(Entity, groundCoords.x, groundCoords.y, groundCoords.z + 1.0, false, false, false, false)
        Wait(50)
        DestroyCamera()
        PlaySound('CANCEL')
    end

    TriggerEvent('qs:client:notify',
        Active and 'Noclip enabled' or 'Noclip disabled',
        Active and 'success' or 'info')

    SetUserRadioControlEnabled(not Active)

    if Active then
        StartNoclipLoop()
    end
end

RegisterNetEvent('qs:client:noclip:toggle', function()
    ToggleNoclip()
end)

exports('IsNoclipActive', function()
    return Active
end)

exports('ToggleNoclip', function(state)
    ToggleNoclip(state)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= ResourceName then return end
    if not Active then return end

    Active = false

    if Entity then
        FreezeEntityPosition(Entity, false)
        SetEntityCollision(Entity, true, true)
        SetEntityVisible(Entity, true, false)
        ResetEntityAlpha(Entity)
        SetEntityInvincible(Entity, false)
    end

    if EntityPed then
        FreezeEntityPosition(EntityPed, false)
        ResetEntityAlpha(EntityPed)
        SetEveryoneIgnorePlayer(EntityPed, false)
        SetPoliceIgnorePlayer(EntityPed, false)
    end

    SetLocalPlayerVisibleLocally(true)
    DestroyCamera()
end)
