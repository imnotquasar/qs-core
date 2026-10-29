local core = exports['qs-core']

local hidden = {}
for _, name in ipairs(Config.HiddenCommands or {}) do hidden[name] = true end

RegisterNetEvent('qs-corechat:server:commands', function()
    local src = source
    if not core:RateLimit(('chat-cmds:%d'):format(src), 1, 2000) then return end
    local list = {}
    for _, c in ipairs(GetRegisteredCommands()) do
        local name = c.name
        if c.resource and c.resource ~= '' and c.resource ~= 'internal' and not hidden[name]
            and not name:find('^[%+%-]') and IsPlayerAceAllowed(src, ('command.%s'):format(name)) then
            list[#list + 1] = { name = '/' .. name }
        end
    end
    TriggerClientEvent('qs-corechat:client:commands', src, list)
end)

RegisterNetEvent('qs-corechat:server:send', function(text)
    local src = source
    text = tostring(text or '')
    if #text == 0 then return end
    if #text > 256 then text = text:sub(1, 256) end

    local name
    local player = core:GetPlayer(src)
    if player and player.PlayerData and player.PlayerData.charinfo then
        local ci = player.PlayerData.charinfo
        name = (((ci.firstname or '') .. ' ' .. (ci.lastname or '')):gsub('^%s*(.-)%s*$', '%1'))
    end
    if not name or name == '' then name = GetPlayerName(src) end

    TriggerClientEvent('qs-corechat:client:message', -1, { author = name, text = text })
end)
