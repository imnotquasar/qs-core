local chatSuggestions = {}
local frameworkCommands = {}

function QS.RegisterFrameworkCommand(name, help, arguments, argsrequired, callback, permission)
    name = tostring(name):lower()
    permission = tostring(permission or 'user'):lower()
    frameworkCommands[name] = {
        name = name,
        help = help or '',
        arguments = arguments or {},
        argsrequired = argsrequired or false,
        callback = callback,
        permission = permission,
    }

    RegisterCommand(name, function(source, args, raw)
        if source > 0 and not Permissions.Has(source, permission) then
            local player = QS.GetPlayer(source)
            if player then player:emit('qs:client:notify', T('no_permission'), 'error') end
            return
        end
        if argsrequired and #args < #(arguments or {}) then
            local player = QS.GetPlayer(source)
            if player then player:emit('qs:client:notify', 'All arguments must be filled out', 'error') end
            return
        end
        callback(source, args, raw)
    end, false)

    chatSuggestions[#chatSuggestions + 1] = { name = '/' .. name, help = help or '', arguments = arguments or {} }
    TriggerClientEvent('chat:addSuggestion', -1, '/' .. name, help or '', arguments or {})
end

function QS.RefreshCommands(source)
    for _, c in pairs(frameworkCommands) do
        TriggerClientEvent('chat:addSuggestion', source, '/' .. c.name, c.help, c.arguments)
    end
    for _, s in ipairs(chatSuggestions) do
        TriggerClientEvent('chat:addSuggestion', source, s.name, s.help, s.arguments)
    end
end

exports('RegisterFrameworkCommand', QS.RegisterFrameworkCommand)
exports('RefreshCommands', QS.RefreshCommands)

local function registerCommand(name, ace, handler, help)
    RegisterCommand(name, function(source, args)
        if ace and source > 0 and not IsPlayerAceAllowed(source, ace) then
            local player = QS.GetPlayer(source)
            if player then player:emit('qs:client:notify', T('no_permission'), 'error') end
            return
        end
        handler(source, args, QS.GetPlayer(source))
    end, false)
    if help then
        chatSuggestions[#chatSuggestions + 1] = { name = '/' .. name, help = help }
    end
end

AddEventHandler('qs:server:characterLoaded', function(src)
    QS.RefreshCommands(src)
end)

local function nearestPlayer(source, maxDist)
    local src = QS.GetPlayer(source)
    if not src then return nil end
    local pos = src:getCoords()
    local best, bestDist = nil, maxDist or 3.0
    for _, p in pairs(QS.Players) do
        if p.source ~= source then
            local c = p:getCoords()
            local d = #(vector3(pos.x, pos.y, pos.z) - vector3(c.x, c.y, c.z))
            if d < bestDist then best, bestDist = p, d end
        end
    end
    return best
end

local function firstName(player)
    return player.PlayerData.charinfo and player.PlayerData.charinfo.firstname or 'Someone'
end

registerCommand('cash', false, function(_, _, player)
    if not player then return end
    player:emit('qs:client:notify', T('balance', player:getMoney('cash'), player:getMoney('bank')), 'primary')
end, 'Check your balance')

registerCommand('id', false, function(source)
    if source > 0 then TriggerClientEvent('qs:client:notify', source, T('your_id', source), 'primary') end
end, 'Show your server ID')

registerCommand('givemoney', false, function(source, args, player)
    if not player then return end
    local amount = math.floor(tonumber(args[1]) or 0)
    if amount <= 0 then return player:emit('qs:client:notify', T('invalid_amount'), 'error') end

    local target = nearestPlayer(source)
    if not target then return player:emit('qs:client:notify', T('nobody_nearby'), 'error') end
    if not player:removeMoney('cash', amount, 'give') then
        return player:emit('qs:client:notify', T('no_cash'), 'error')
    end

    target:addMoney('cash', amount, 'give')
    player:emit('qs:client:notify', T('gave_money', amount, firstName(target)), 'success')
    target:emit('qs:client:notify', T('received_money', amount, firstName(player)), 'success')
    Utils.Log('money', 'Give money', ('%s -> %s : $%d'):format(player.citizenid, target.citizenid, amount))
end, 'Give cash to the nearest player')

registerCommand('setjob', 'command.qs', function(source, args)
    local target = tonumber(args[1])
    local job, grade = args[2], tonumber(args[3]) or 0
    if not target or not job then return end
    local player = QS.GetPlayer(target)
    if player and player:setJob(job, grade) then
        Utils.Log('admin', 'Set job', ('%s set %s -> %s[%d]'):format(source, target, job, grade))
    end
end, 'Set a player\'s job')

registerCommand('addmoney', 'command.qs', function(source, args)
    local target, account, amount = tonumber(args[1]), args[2], tonumber(args[3])
    if not target or not account or not amount then return end
    local player = QS.GetPlayer(target)
    if player and player:addMoney(account, amount, 'admin') then
        Utils.Log('admin', 'Add money', ('%s +$%d %s to %s'):format(source, amount, account, target))
    end
end, 'Give money to a player')

registerCommand('removemoney', 'command.qs', function(source, args)
    local target, account, amount = tonumber(args[1]), args[2], tonumber(args[3])
    if not target or not account or not amount then return end
    local player = QS.GetPlayer(target)
    if player and player:removeMoney(account, amount, 'admin') then
        Utils.Log('admin', 'Remove money', ('%s -$%d %s from %s'):format(source, amount, account, target))
    end
end, 'Take money from a player')

registerCommand('giveitem', 'command.qs', function(_, args)
    local target, item, count = tonumber(args[1]), args[2], tonumber(args[3]) or 1
    if not target or not item then return end
    local player = QS.GetPlayer(target)
    if player then player:addItem(item, count) end
end, 'Give an item to a player')

registerCommand('revive', 'command.qs', function(source, args, player)
    local target = tonumber(args[1]) or source
    if not QS.GetPlayer(target) then
        if player then player:emit('qs:client:notify', T('player_not_found', target), 'error') end
        return
    end
    TriggerClientEvent('qs:client:revive', target)
    if player and target ~= source then
        player:emit('qs:client:notify', T('player_revived', target), 'success')
    end
end, 'Revive a player (default: yourself)')

registerCommand('kill', 'command.qs', function(source, args, player)
    local target = tonumber(args[1]) or source
    if not QS.GetPlayer(target) then
        if player then player:emit('qs:client:notify', T('player_not_found', target), 'error') end
        return
    end
    TriggerClientEvent('qs:client:adminKill', target)
end, 'Kill a player (default: yourself)')

registerCommand('freeze', 'command.qs', function(_, args)
    local target = tonumber(args[1])
    if target then TriggerClientEvent('qs:client:freeze', target) end
end, 'Toggle freeze on a player')

registerCommand('god', 'command.qs', function(source)
    TriggerClientEvent('qs:client:god', source)
end, 'Toggle god mode')

registerCommand('announce', 'command.qs', function(_, args)
    local msg = table.concat(args, ' ')
    if msg ~= '' then TriggerClientEvent('qs:client:notify', -1, msg, 'primary', 8000) end
end, 'Announce a message to everyone')

registerCommand('car', 'command.qs', function(source, args)
    if args[1] then TriggerClientEvent('qs:client:spawnCar', source, args[1]) end
end, 'Spawn a vehicle')

registerCommand('dv', 'command.qs', function(source)
    TriggerClientEvent('qs:client:deleteVehicle', source)
end, 'Delete the vehicle you are in/near')

registerCommand('coords', 'command.qs', function(source)
    TriggerClientEvent('qs:client:coords', source)
end, 'Print your current coordinates')

registerCommand('tp', 'command.qs', function(source, args)
    local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
    if x and y and z then TriggerClientEvent('qs:client:setCoords', source, x, y, z) end
end, 'Teleport to coordinates')

registerCommand('goto', 'command.qs', function(source, args)
    local target = QS.GetPlayer(tonumber(args[1]))
    if not target then return end
    local c = target:getCoords()
    TriggerClientEvent('qs:client:setCoords', source, c.x, c.y, c.z)
end, 'Teleport to a player')

registerCommand('bring', 'command.qs', function(source, args)
    local caller = QS.GetPlayer(source)
    local target = tonumber(args[1])
    if not caller or not target then return end
    local c = caller:getCoords()
    TriggerClientEvent('qs:client:setCoords', target, c.x, c.y, c.z)
end, 'Bring a player to you')

registerCommand('kick', 'command.qs', function(source, args)
    local target = tonumber(args[1])
    if not target then return end
    local reason = table.concat(args, ' ', 2)
    Utils.Log('admin', 'Player kicked', ('%s kicked %s: %s'):format(source, target, reason))
    DropPlayer(target, reason ~= '' and reason or 'Kicked by an admin.')
end, 'Kick a player')

registerCommand('ban', 'command.qs', function(source, args)
    local target, minutes = tonumber(args[1]), tonumber(args[2]) or 0
    local reason = table.concat(args, ' ', 3)
    if not target or not Bans then return end
    Bans.Add(target, minutes, reason ~= '' and reason or 'No reason', tostring(source))
end, 'Ban a player: /ban <id> <minutes|0=perma> <reason>')

registerCommand('unban', 'command.qs', function(_, args)
    if args[1] and Bans then Bans.Remove(args[1]) end
end, 'Unban a license: /unban <license:...>')

registerCommand('noclip', 'command.qs', function(source)
    TriggerClientEvent('qs:client:noclip:toggle', source)
end, 'Toggle noclip (admin)')

registerCommand('tpm', 'command.qs', function(source)
    TriggerClientEvent('qs:client:tpm', source)
end, 'Teleport to waypoint (admin)')

chatSuggestions[#chatSuggestions + 1] = { name = '/' .. (Config.ColorCommand or 'colors'), help = 'Open your interface colour picker' }
chatSuggestions[#chatSuggestions + 1] = { name = '/setgroup', help = 'Set a player group (admin)', arguments = { { name = 'id' }, { name = 'group' } } }
chatSuggestions[#chatSuggestions + 1] = { name = '/removegroup', help = 'Remove a player group (admin)', arguments = { { name = 'id' } } }
