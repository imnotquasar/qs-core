RegisterNetEvent('qs:server:death', function()
    local player = QS.GetPlayer(source)
    if not player then return end
    if Config.Death.loseCashOnDeath then
        player:setMoney('cash', 0)
    end
end)

RegisterNetEvent('qs:server:setDead', function(state)
    local player = QS.GetPlayer(source)
    if not player then return end
    player:setDead(state == true)
    player:save(false)
end)

AddEventHandler('txAdmin:events:healedPlayer', function(data)
    local id = tonumber(data and data.id)
    if not id then return end
    if id == -1 then
        for _, src in ipairs(GetPlayers()) do
            local player = QS.GetPlayer(tonumber(src))
            if player then player:emit('qs:client:revive') end
        end
        return
    end
    local player = QS.GetPlayer(id)
    if player then player:emit('qs:client:revive') end
end)

exports('SetPlayerDead', function(source, state)
    local player = QS.GetPlayer(source)
    if not player then return false end
    player:setDead(state == true)
    if state then
        player:emit('qs:client:forceDown')
    else
        player:emit('qs:client:revive')
    end
    return true
end)
