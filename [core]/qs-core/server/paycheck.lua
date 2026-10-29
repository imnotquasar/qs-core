CreateThread(function()
    if not Config.Paycheck.enabled then return end

    while true do
        Wait(Config.Paycheck.interval)
        for _, player in pairs(QS.Players) do
            local job = player.PlayerData.job
            local salary = job and job.salary or 0
            if salary > 0 then
                player:addMoney('bank', salary, 'paycheck')
                player:emit('qs:client:notify', T('paycheck', salary), 'success')
            end
        end
    end
end)
