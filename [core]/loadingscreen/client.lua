local outroStarted = false
local dismissed = false

local savedPalette = nil
local dbAnswered = false

local function toLoader(msg)
    SendLoadingScreenMessage(json.encode(msg))
end

RegisterNetEvent('qs:colors:load', function(palette)
    dbAnswered = true
    if type(palette) == 'table' then savedPalette = palette end
end)

CreateThread(function()
    for _ = 1, 24 do
        if dismissed then return end
        if not dbAnswered then TriggerServerEvent('qs:colors:request') end

        if savedPalette then toLoader({ action = 'theme', data = savedPalette }) end
        Wait(200)
    end
end)

AddEventHandler('qs:client:colorsChanged', function(palette)
    if dismissed then return end
    if type(palette) == 'table' then
        savedPalette = palette
        toLoader({ action = 'theme', data = palette })
    end
end)

local function dismiss()
    if dismissed then
        TriggerEvent('loadingscreen:done')
        return
    end
    dismissed = true

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    TriggerEvent('loadingscreen:done')
end

RegisterNUICallback('done', function(_, cb)
    cb('ok')
    dismiss()
end)

local function finish()

    if dismissed then TriggerEvent('loadingscreen:done'); return end
    if outroStarted then return end
    outroStarted = true

    toLoader({ action = 'outro' })

    CreateThread(function()
        Wait(2500)
        dismiss()
    end)
end

AddEventHandler('loadingscreen:finish', finish)

AddEventHandler('playerSpawned', function()
    CreateThread(function()
        Wait(12000)
        finish()
    end)
end)
