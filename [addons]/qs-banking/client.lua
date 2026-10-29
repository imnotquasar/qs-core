local core = exports['qs-core']

local uiOpen = false
local spawnedPeds = {}

local function send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local function sendTheme()
    local colors = core:GetColors()
    if colors then send('theme', colors) end
end

local function sendLocale()
    send('locale', Locales[GetConvar('qs:locale', 'en')] or Locales.en or {})
end

AddEventHandler('qs:client:colorsChanged', function() if uiOpen then sendTheme() end end)

local function helpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function openBank(mode)
    if uiOpen then return end
    core:TriggerCallback('qs-banking:data', function(data)
        if not data then return end
        uiOpen = true
        SetNuiFocus(true, true)
        TriggerEvent('qs-corehud:display', false)
        sendTheme()
        sendLocale()
        send('open', {
            mode = mode,
            cash = data.cash,
            bank = data.bank,
            account = data.account,
            history = data.history or {},
        })
    end)
end

local function closeBank()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    TriggerEvent('qs-corehud:display', true)
    send('close')
end

RegisterNetEvent('qs-banking:client:update', function(data)
    if uiOpen and data then send('update', data) end
end)

RegisterNUICallback('deposit', function(d, cb) cb('ok') TriggerServerEvent('qs-banking:server:deposit', tonumber(d and d.amount) or 0) end)
RegisterNUICallback('withdraw', function(d, cb) cb('ok') TriggerServerEvent('qs-banking:server:withdraw', tonumber(d and d.amount) or 0) end)
RegisterNUICallback('transfer', function(d, cb) cb('ok') TriggerServerEvent('qs-banking:server:transfer', d and d.account, tonumber(d and d.amount) or 0) end)
RegisterNUICallback('close', function(_, cb) cb('ok') closeBank() end)
RegisterNUICallback('accountCopied', function(d, cb)
    cb('ok')
    core:Notify(T('account_copied', d and d.account or ''), 'success', 2500)
end)

CreateThread(function()
    for _, b in ipairs(Config.Banks) do
        local blip = AddBlipForCoord(b.coords.x, b.coords.y, b.coords.z)
        SetBlipSprite(blip, Config.Blip.sprite or 108)
        SetBlipColour(blip, Config.Blip.color or 2)
        SetBlipScale(blip, Config.Blip.scale or 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Blip.label or 'Bank')
        EndTextCommandSetBlipName(blip)

        if b.ped then
            local hash = joaat(b.ped)
            RequestModel(hash)
            local dl = GetGameTimer() + 6000
            while not HasModelLoaded(hash) and GetGameTimer() < dl do Wait(10) end
            if HasModelLoaded(hash) then
                local ped = CreatePed(4, hash, b.coords.x, b.coords.y, b.coords.z - 1.0, b.coords.w or 0.0, false, true)
                FreezeEntityPosition(ped, true)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                TaskStartScenarioInPlace(ped, b.scenario or 'WORLD_HUMAN_STAND_MOBILE', 0, true)
                spawnedPeds[#spawnedPeds + 1] = ped
                SetModelAsNoLongerNeeded(hash)
            end
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 800
        if not uiOpen then
            local c = GetEntityCoords(PlayerPedId())
            for _, b in ipairs(Config.Banks) do
                if #(c - vector3(b.coords.x, b.coords.y, b.coords.z)) < Config.InteractDistance + 0.8 then
                    sleep = 0
                    helpText(T('help_bank'))
                    if IsControlJustPressed(0, Config.OpenKey) then openBank('bank') end
                    break
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 800
        if not uiOpen then
            local c = GetEntityCoords(PlayerPedId())
            local near = false
            for _, model in ipairs(Config.ATMModels) do
                local obj = GetClosestObjectOfType(c.x, c.y, c.z, Config.InteractDistance, model, false, false, false)
                if obj ~= 0 then near = true break end
            end
            if near then
                sleep = 0
                helpText(T('help_atm'))
                if IsControlJustPressed(0, Config.OpenKey) then openBank('atm') end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if uiOpen then closeBank() end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
