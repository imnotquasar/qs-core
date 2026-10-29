local savedSkin = nil
local editSkin = nil
local editing = false
local stripped = false

local function stripPed(sex)
    local ped = PlayerPedId()
    SetPedComponentVariation(ped, 3, 15, 0, 2)
    SetPedComponentVariation(ped, 11, 15, 0, 2)
    if sex == 'female' then
        SetPedComponentVariation(ped, 8, 14, 0, 2)
        SetPedComponentVariation(ped, 4, 15, 0, 2)
        SetPedComponentVariation(ped, 6, 35, 0, 2)
    else
        SetPedComponentVariation(ped, 8, 15, 0, 2)
        SetPedComponentVariation(ped, 4, 21, 0, 2)
        SetPedComponentVariation(ped, 6, 34, 0, 2)
    end
    ClearPedProp(ped, 0)
    stripped = true
end
local cam = nil
local creatorCb = nil
local editorActive = false

local function reapplyTattoos(skin)
    if type(skin) ~= 'table' then return end
    local ped = PlayerPedId()
    ClearPedDecorations(ped)
    for _, cat in ipairs(Clothing.Categories) do
        if cat.kind == 'tattoo' then
            local e = skin[cat.key]
            local idx = (e and e.drawable) or 0
            local lib = Clothing.Tattoos[cat.key]
            if idx > 0 and lib and lib.names[idx] then
                AddPedDecorationFromHashes(ped, joaat(lib.collection), joaat(lib.names[idx]))
            end
        end
    end
end

local function applyCategory(cat, drawable, texture)
    local ped = PlayerPedId()
    if cat.kind == 'tattoo' then
        return
    elseif cat.kind == 'component' then
        SetPedComponentVariation(ped, cat.id, drawable, texture, 0)
    elseif cat.kind == 'overlay' then
        if drawable and drawable >= 0 then
            SetPedHeadOverlay(ped, cat.id, drawable, 1.0)
            SetPedHeadOverlayColor(ped, cat.id, 1, texture or 0, 0)
        else
            SetPedHeadOverlay(ped, cat.id, 255, 0.0)
        end
    else
        if drawable and drawable >= 0 then
            SetPedPropIndex(ped, cat.id, drawable, texture, true)
        else
            ClearPedProp(ped, cat.id)
        end
    end
end

function ApplyAppearance(skin, sex)
    if type(skin) ~= 'table' or next(skin) == nil then
        skin = Clothing.DefaultSkin(sex)
    end
    skin.sex = skin.sex or sex or 'male'

    local model = Clothing.Models[skin.sex] or Clothing.Models.male
    local hash = joaat(model)
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 100 do
        Wait(50)
        tries = tries + 1
    end
    if HasModelLoaded(hash) then
        SetPlayerModel(PlayerId(), hash)
        SetModelAsNoLongerNeeded(hash)
    end

    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)

    for _, cat in ipairs(Clothing.Categories) do
        local entry = skin[cat.key]
        if entry then
            applyCategory(cat, entry.drawable or 0, entry.texture or 0)
        end
    end
    reapplyTattoos(skin)

    savedSkin = skin
    return true
end

exports('ApplyAppearance', ApplyAppearance)

RegisterNetEvent('qs:clothing:apply', function(skin)
    ApplyAppearance(skin)
end)

local function focusCam(sectionKey, interpMs)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local rad = math.rad(GetEntityHeading(ped))
    local s = (Config.Cam.sections or {})[sectionKey]
        or (Config.Cam.sections or {}).upper
        or { dist = 1.6, height = 0.5, target = 0.45, fov = 25.0 }

    local fx, fy = -math.sin(rad), math.cos(rad)
    local rx, ry = math.cos(rad), math.sin(rad)
    local side = Config.Cam.side or -0.35

    local newCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        coords.x + fx * s.dist + rx * side,
        coords.y + fy * s.dist + ry * side,
        coords.z + s.height, 0.0, 0.0, 0.0, s.fov, false, 0)
    PointCamAtCoord(newCam, coords.x + rx * side, coords.y + ry * side, coords.z + s.target)

    SetCamUseShallowDofMode(newCam, true)
    SetCamNearDof(newCam, s.dist * 0.55)
    SetCamFarDof(newCam, s.dist + 1.4)
    SetCamDofStrength(newCam, 1.0)

    local interp = interpMs or 700
    if cam and DoesCamExist(cam) then
        SetCamActiveWithInterp(newCam, cam, interp, 1, 1)
        local old = cam
        cam = newCam
        CreateThread(function()
            Wait(interp + 120)
            if DoesCamExist(old) then DestroyCam(old, false) end
        end)
    else
        cam = newCam
        SetCamActive(cam, true)
    end
    RenderScriptCams(true, false, 0, true, false)
end

local function destroyCam()
    if not cam then return end
    RenderScriptCams(false, false, 0, true, false)
    if DoesCamExist(cam) then DestroyCam(cam, false) end
    cam = nil
end

local function sendTheme()
    local colors = exports['qs-core']:GetColors()
    if colors then SendNUIMessage({ action = 'theme', data = colors }) end
end

AddEventHandler('qs:client:colorsChanged', function() sendTheme() end)

local function startEditorLoop()
    if editorActive then return end
    editorActive = true
    CreateThread(function()
        while editorActive do
            Wait(0)
            SetUseHiDof()
            HideHudAndRadarThisFrame()
        end
    end)
end

local function firstEnabledSection(disabled)
    if not disabled then return 'face' end
    local off = {}
    for _, k in ipairs(disabled) do off[k] = true end
    for _, s in ipairs(Clothing.Sections) do
        if not off[s.key] then return s.key end
    end
    return 'face'
end

local function openEditor(opts)
    if editing or not savedSkin then return end
    repeat Wait(0) until IsScreenFadedIn() and not IsPlayerTeleportActive() and not IsPlayerSwitchInProgress()
    opts = opts or {}
    editing = true
    startEditorLoop()
    TriggerEvent('qs-corehud:display', false)
    SetPedHeadBlendData(PlayerPedId(), 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)

    local working = {}
    for k, v in pairs(savedSkin) do
        working[k] = (type(v) == 'table') and { drawable = v.drawable, texture = v.texture } or v
    end

    editSkin = working
    local disabled = opts.disabled or { 'tattoos' }
    local defaultSection = opts.defaultSection or firstEnabledSection(disabled)
    focusCam(defaultSection)
    SetNuiFocus(true, true)
    sendTheme()
    SendNUIMessage({ action = 'locale', data = Locales[GetConvar('qs:locale', 'en')] or Locales.en or {} })
    SendNUIMessage({
        action = 'open',
        data = {
            categories = Clothing.Categories,
            sections = Clothing.Sections,
            skin = working,
            creator = false,
            disabled = disabled,
            defaultSection = defaultSection,
        },
    })
    if opts.strip then stripPed(working.sex) end
end

RegisterNetEvent('qs-clothing:client:open', function(opts)
    openEditor(opts)
end)

local function finishCreator(skin, saved)
    local done = creatorCb
    creatorCb = nil
    editing = false
    if done then done(skin) end
    TriggerEvent('qs-clothing:creatorClosed', skin, saved == true)
end

function OpenCreator(sex, cb)
    ApplyAppearance(nil, sex)
    creatorCb = cb
    editing = true

    local working = {}
    for k, v in pairs(savedSkin) do
        working[k] = (type(v) == 'table') and { drawable = v.drawable, texture = v.texture } or v
    end

    editSkin = working
    SetNuiFocus(true, true)
    sendTheme()
    SendNUIMessage({ action = 'locale', data = Locales[GetConvar('qs:locale', 'en')] or Locales.en or {} })
    SendNUIMessage({
        action = 'open',
        data = {
            categories = Clothing.Categories,
            sections = Clothing.Sections,
            skin = working,
            creator = true,
            disabled = { 'tattoos' },
            defaultSection = 'face',
        },
    })
end

exports('OpenCreator', OpenCreator)

exports('IsCreatorOpen', function()
    return editing == true and creatorCb ~= nil
end)

RegisterNUICallback('change', function(data, cb)
    cb('ok')
    for _, cat in ipairs(Clothing.Categories) do
        if cat.key == data.key then
            local d, t = tonumber(data.drawable), tonumber(data.texture)
            if editSkin then editSkin[cat.key] = { drawable = d, texture = t } end
            if cat.kind == 'tattoo' then
                reapplyTattoos(editSkin or savedSkin)
            else
                applyCategory(cat, d, t)
            end
            break
        end
    end
end)

RegisterNUICallback('section', function(data, cb)
    if creatorCb then
        TriggerEvent('qs:clothing:section', data.key)
    else
        focusCam(data.key, 700)
    end
    cb('ok')
end)

RegisterNUICallback('rotate', function(data, cb)
    local ped = PlayerPedId()
    SetEntityHeading(ped, GetEntityHeading(ped) + (tonumber(data.dir) or 1) * 20.0)
    cb('ok')
end)

RegisterNUICallback('save', function(data, cb)
    SetNuiFocus(false, false)
    savedSkin = data.skin
    savedSkin.sex = savedSkin.sex or 'male'
    if creatorCb then
        finishCreator(savedSkin, true)
    else
        editing = false
        editorActive = false
        destroyCam()
        TriggerEvent('qs-corehud:display', true)
        if stripped then
            ApplyAppearance(savedSkin)
            stripped = false
        end
        TriggerServerEvent('qs-clothing:server:save', savedSkin)
    end
    cb('ok')
end)

RegisterNUICallback('cancel', function(_, cb)
    SetNuiFocus(false, false)
    if creatorCb then
        finishCreator(savedSkin, false)
    else
        editing = false
        editorActive = false
        destroyCam()
        TriggerEvent('qs-corehud:display', true)
        if savedSkin then ApplyAppearance(savedSkin) end
        stripped = false
    end
    cb('ok')
end)

AddEventHandler('qs:client:onPlayerLoaded', function(data)
    if GetResourceState('qs-coremulticharacter') == 'started' then return end
    if not (Config.EditOnNewCharacter and data and data.isNew) then return end

    local skin = data.skin
    if type(skin) == 'table' and next(skin) ~= nil then return end
    CreateThread(function()
        Wait(1200)
        openEditor()
    end)
end)

CreateThread(function()
    Wait(500)
    if savedSkin then return end
    local data = exports['qs-core']:GetPlayerData()
    if not (data and data.citizenid) then return end
    local skin = data.skin
    if type(skin) ~= 'table' or next(skin) == nil then
        skin = Clothing.DefaultSkin(data.charinfo and data.charinfo.sex)
    end
    savedSkin = skin
end)

local function storeDisabled(typeCfg)
    local en = {}
    for _, k in ipairs(typeCfg.enabled) do en[k] = true end
    local off = {}
    for _, s in ipairs(Clothing.Sections) do
        if not en[s.key] then off[#off + 1] = s.key end
    end
    return off
end

local function helpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

CreateThread(function()
    for _, store in ipairs(Config.Stores or {}) do
        local t = Config.StoreTypes[store.type]
        if t then
            local blip = AddBlipForCoord(store.coords.x, store.coords.y, store.coords.z)
            SetBlipSprite(blip, t.blip.sprite or 73)
            SetBlipColour(blip, t.blip.color or 0)
            SetBlipScale(blip, t.blip.size or 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(t.blip.label or 'Store')
            EndTextCommandSetBlipName(blip)
        end
    end

    while true do
        local sleep = 800
        if not editing then
            local coords = GetEntityCoords(PlayerPedId())
            for _, store in ipairs(Config.Stores or {}) do
                local dx, dy = coords.x - store.coords.x, coords.y - store.coords.y
                if math.sqrt(dx * dx + dy * dy) < Config.StoreDistance then
                    sleep = 0
                    local t = Config.StoreTypes[store.type]
                    helpText(T('store_' .. store.type) or T('store_open'))
                    if IsControlJustPressed(0, Config.StoreKey) and t then
                        openEditor({ disabled = storeDisabled(t), defaultSection = t.enabled[1], strip = (store.type == 'tattoo') })
                    end
                    break
                end
            end
        end
        Wait(sleep)
    end
end)
