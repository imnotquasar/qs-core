local maxSlots = GetConvarInt('sv_maxclients', 48)

local function push(target)
    TriggerClientEvent('qs-corehud:counts', target or -1, {
        online = #GetPlayers(),
        max = maxSlots,
    })
end

RegisterNetEvent('qs-corehud:request', function()
    push(source)
end)

AddEventHandler('playerDropped', function()
    SetTimeout(300, function() push(-1) end)
end)

AddEventHandler('qs:server:playerLoaded', function()
    push(-1)
end)

CreateThread(function()
    while true do
        Wait(60000)
        push(-1)
    end
end)
