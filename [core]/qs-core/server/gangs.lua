function Gangs.SetPlayer(source, name, grade)
    local player = QS.GetPlayer(source)
    if not player then return false end
    return player:setGang(name, grade)
end

function Gangs.GetPlayer(source)
    local player = QS.GetPlayer(source)
    if not player then return QS.BuildGang('none', 0) end
    return player:getGang()
end

function QS.GetPlayersOnDuty(jobName)
    local sources, count = {}, 0
    for src, player in pairs(QS.Players) do
        local j = player.PlayerData.job
        if j and j.name == jobName and j.onduty ~= false then
            sources[#sources + 1] = src
            count = count + 1
        end
    end
    return sources, count
end

exports('SetGang', Gangs.SetPlayer)
exports('GetGangForPlayer', Gangs.GetPlayer)
exports('SetJobDuty', function(source, onDuty)
    local player = QS.GetPlayer(source)
    return player and player:setJobDuty(onDuty) or false
end)
exports('GetPlayersOnDuty', QS.GetPlayersOnDuty)
