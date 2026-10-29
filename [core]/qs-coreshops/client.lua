local shops = Config.Shops
local spawnedPeds = {}
local currentShop = nil
local uiOpen = false
local myJob = 'unemployed'

local function send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local function makeShopBlip(loc, shop)
    local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipSprite(blip, shop.blip.sprite or 52)
    SetBlipColour(blip, shop.blip.color or 2)
    SetBlipScale(blip, shop.blip.scale or 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(shop.label)
    EndTextCommandSetBlipName(blip)
    return blip
end

local jobShopBlips = {}

local function refreshJobShopBlips()
    for _, b in ipairs(jobShopBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    jobShopBlips = {}
    for _, shop in ipairs(shops) do
        if shop.blip and shop.job and shop.job == myJob then
            for _, loc in ipairs(shop.locations or {}) do
                jobShopBlips[#jobShopBlips + 1] = makeShopBlip(loc, shop)
            end
        end
    end
end

AddEventHandler('qs:client:onPlayerLoaded', function(data)
    myJob = (data and data.job and data.job.name) or 'unemployed'
    refreshJobShopBlips()
end)

AddEventHandler('qs:client:onJobUpdate', function(job)
    myJob = (job and job.name) or 'unemployed'
    refreshJobShopBlips()
end)

CreateThread(function()
    Wait(500)
    local data = exports['qs-core']:GetPlayerData()
    if data and data.job then myJob = data.job.name end
    refreshJobShopBlips()
end)

CreateThread(function()
    for _, shop in ipairs(shops) do
        if shop.blip and not shop.job then
            for _, loc in ipairs(shop.locations or {}) do
                makeShopBlip(loc, shop)
            end
        end
    end
end)

CreateThread(function()
    for _, shop in ipairs(shops) do
        if shop.ped then
            local model = joaat(shop.ped)
            RequestModel(model)
            local dl = GetGameTimer() + 8000
            while not HasModelLoaded(model) and GetGameTimer() < dl do Wait(10) end
            if HasModelLoaded(model) then
                for _, loc in ipairs(shop.locations or {}) do
                    local ped = CreatePed(4, model, loc.x, loc.y, loc.z - 1.0, loc.w or 0.0, false, true)
                    FreezeEntityPosition(ped, true)
                    SetEntityInvincible(ped, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    if shop.scenario then TaskStartScenarioInPlace(ped, shop.scenario, 0, true) end
                    spawnedPeds[#spawnedPeds + 1] = ped
                end
                SetModelAsNoLongerNeeded(model)
            end
        end
    end
end)

local function helpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

CreateThread(function()
    while true do
        local sleep = 900
        if not uiOpen then
            local coords = GetEntityCoords(PlayerPedId())
            local found = nil
            for _, shop in ipairs(shops) do
                if not shop.job or shop.job == myJob then
                    for _, loc in ipairs(shop.locations or {}) do
                        if #(coords - vector3(loc.x, loc.y, loc.z)) < Config.InteractDistance then
                            found = shop
                            break
                        end
                    end
                end
                if found then break end
            end
            if found then
                sleep = 0
                helpText(T('browse', found.label))
                if IsControlJustPressed(0, Config.OpenControl) then
                    TriggerServerEvent('qs-coreshops:server:open', found.name)
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('qs-coreshops:client:open', function(data)
    if uiOpen or not data then return end
    currentShop = data.name
    uiOpen = true
    SetNuiFocus(true, true)
    TriggerEvent('qs-corehud:display', false)
    local colors = exports['qs-core']:GetColors()
    if colors then send('theme', colors) end
    send('open', data)
    send('locale', Locales[GetConvar('qs:locale', 'en')] or Locales.en or {})
end)

AddEventHandler('qs:client:colorsChanged', function()
    if uiOpen then
        local colors = exports['qs-core']:GetColors()
        if colors then send('theme', colors) end
    end
end)

RegisterNetEvent('qs-coreshops:client:cash', function(cash)
    if uiOpen then send('cash', { cash = cash }) end
end)

local function closeShop()
    if not uiOpen then return end
    uiOpen = false
    currentShop = nil
    SetNuiFocus(false, false)
    TriggerEvent('qs-corehud:display', true)
    send('close')
end

RegisterNUICallback('buy', function(data, cb)
    cb('ok')
    if currentShop and data and data.name then
        TriggerServerEvent('qs-coreshops:server:buy', currentShop, data.name, tonumber(data.count) or 1)
    end
end)

RegisterNUICallback('close', function(_, cb)
    cb('ok')
    closeShop()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
