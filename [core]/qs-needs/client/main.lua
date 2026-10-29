local hunger = 100
local thirst = 100

RegisterNetEvent('qs:metadata:set', function(key, value)
    if key == 'hunger' then
        hunger = tonumber(value) or hunger
    elseif key == 'thirst' then
        thirst = tonumber(value) or thirst
    end
end)

AddEventHandler('qs:client:onPlayerLoaded', function(data)
    local meta = data and data.metadata
    if meta then
        hunger = meta.hunger or hunger
        thirst = meta.thirst or thirst
    end
end)

local consuming = false

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + 2000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do Wait(10) end
end

local function makeProp(ped, a)
    if not a.prop then return nil end
    local model = GetHashKey(a.prop)
    RequestModel(model)
    local deadline = GetGameTimer() + 2000
    while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(10) end
    if not HasModelLoaded(model) then return nil end

    local prop = CreateObject(model, GetEntityCoords(ped), true, true, false)
    AttachEntityToEntity(
        prop, ped, GetPedBoneIndex(ped, a.bone or 18905),
        a.pos.x, a.pos.y, a.pos.z, a.rot.x, a.rot.y, a.rot.z,
        true, true, false, true, 1, true
    )
    SetModelAsNoLongerNeeded(model)
    return prop
end

RegisterNetEvent('qs-needs:consume', function(verb)
    if consuming then return end
    local a = NeedsConfig.Anim[verb] or NeedsConfig.Anim.eat
    if not a then return end

    consuming = true
    local ped = PlayerPedId()
    local prop = makeProp(ped, a)

    loadAnimDict(a.dict)

    TaskPlayAnim(ped, a.dict, a.anim, 4.0, -4.0, a.duration, 49, 0.0, false, false, false)

    local label = verb == 'drink' and 'Drinking' or 'Eating'
    exports['qs-core']:Progress({ duration = a.duration, label = label })

    StopAnimTask(ped, a.dict, a.anim, 3.0)
    RemoveAnimDict(a.dict)
    if prop then DeleteEntity(prop) end
    consuming = false
end)

if NeedsConfig.StarveDamage > 0 then
    CreateThread(function()
        while true do
            Wait(NeedsConfig.StarveInterval)
            if hunger <= 0 or thirst <= 0 then
                local ped = PlayerPedId()
                if not IsEntityDead(ped) then
                    SetEntityHealth(ped, math.max(GetEntityHealth(ped) - NeedsConfig.StarveDamage, 0))
                end
            end
        end
    end)
end
