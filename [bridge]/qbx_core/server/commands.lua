local ADMIN_ACE = 'command.qs'
local suggestions = {}

local function reply(src, text, notifyType)
    if src == 0 then
        print(text)
    else
        Notify(src, text, notifyType or 'inform')
    end
end

local function adminCommand(name, help, params, handler)
    RegisterCommand(name, function(source, args)
        if source > 0 and not IsPlayerAceAllowed(source, ADMIN_ACE) then
            reply(source, 'No permission', 'error')
            return
        end
        handler(source, args)
    end, false)
    suggestions[#suggestions + 1] = { name = '/' .. name, help = help, params = params }
end

local function targetCitizen(src, id)
    local target = tonumber(id)
    if not target then return nil end
    local player = exports.qbx_core:GetPlayer(target)
    if not player then
        reply(src, 'Player not online', 'error')
        return nil
    end
    return player
end

local function result(src, ok, err, success)
    if ok then
        reply(src, success, 'success')
    else
        reply(src, err and err.message or 'Failed', 'error')
    end
end

RegisterCommand('job', function(source)
    if source == 0 then return end
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    local job = player.PlayerData.job
    reply(source, locale('info.job_info', job.label, job.grade.name, job.onduty and locale('info.on_duty') or locale('info.off_duty')))
end, false)

RegisterCommand('gang', function(source)
    if source == 0 then return end
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    local gang = player.PlayerData.gang
    reply(source, locale('info.gang_info', gang.label, gang.grade.name))
end, false)

adminCommand('setgang', 'Set a player gang (admin)', { { name = 'id' }, { name = 'gang' }, { name = 'grade' } }, function(source, args)
    local player = targetCitizen(source, args[1])
    if not player then return end
    local ok, err = exports.qbx_core:SetGang(player.PlayerData.source, args[2] or 'none', tonumber(args[3]) or 0)
    result(source, ok, err, 'Gang set')
end)

adminCommand('addjob', 'Add a job to a player (admin)', { { name = 'id' }, { name = 'job' }, { name = 'grade' } }, function(source, args)
    local player = targetCitizen(source, args[1])
    if not player then return end
    local ok, err = exports.qbx_core:AddPlayerToJob(player.PlayerData.citizenid, args[2], tonumber(args[3]) or 0)
    result(source, ok, err, 'Job added')
end)

adminCommand('removejob', 'Remove a job from a player (admin)', { { name = 'id' }, { name = 'job' } }, function(source, args)
    local player = targetCitizen(source, args[1])
    if not player then return end
    local ok, err = exports.qbx_core:RemovePlayerFromJob(player.PlayerData.citizenid, args[2])
    result(source, ok, err, 'Job removed')
end)

adminCommand('changejob', 'Change the primary job of a player (admin)', { { name = 'id' }, { name = 'job' } }, function(source, args)
    local player = targetCitizen(source, args[1])
    if not player then return end
    local ok, err = exports.qbx_core:SetPlayerPrimaryJob(player.PlayerData.citizenid, args[2])
    result(source, ok, err, 'Primary job changed')
end)

adminCommand('setmoney', 'Set the money of a player (admin)', { { name = 'id' }, { name = 'type' }, { name = 'amount' } }, function(source, args)
    local player = targetCitizen(source, args[1])
    if not player then return end
    local ok = exports.qbx_core:SetMoney(player.PlayerData.source, args[2], tonumber(args[3]) or 0, 'admin command')
    result(source, ok, nil, 'Money set')
end)

adminCommand('togglepvp', 'Toggle PvP on the server (admin)', {}, function(source)
    GlobalState.PVPEnabled = not GlobalState.PVPEnabled
    reply(source, GlobalState.PVPEnabled and 'PvP enabled' or 'PvP disabled', 'success')
end)

AddEventHandler('qs:server:characterLoaded', function(src)
    if not IsPlayerAceAllowed(src, ADMIN_ACE) then return end
    for _, s in ipairs(suggestions) do
        TriggerClientEvent('chat:addSuggestion', src, s.name, s.help, s.params)
    end
end)
