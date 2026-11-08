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

local messageHooks = {}

local function chatExport(name, fn)
    AddEventHandler(('__cfx_export_chat_%s'):format(name), function(setCB) setCB(fn) end)
end

chatExport('registerMessageHook', function(hook)
    messageHooks[#messageHooks + 1] = hook
end)

chatExport('addMessage', function(target, message)
    TriggerClientEvent('chat:addMessage', target, message)
end)

local function runMessageHooks(src, message)
    local cancelled, routing = false, -1
    for _, hook in ipairs(messageHooks) do
        pcall(hook, src, message, {
            updateMessage = function(changes)
                for key, value in pairs(changes or {}) do message[key] = value end
            end,
            cancel = function() cancelled = true end,
            setRouting = function(target) routing = target end,
        })
    end
    return not cancelled, routing
end

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

    TriggerEvent('chatMessage', src, name, text)
    if WasEventCanceled() then return end

    local message = { author = name, text = text, args = { name, text } }
    local allowed, routing = runMessageHooks(src, message)
    if not allowed then return end

    if type(routing) == 'table' then
        for _, target in ipairs(routing) do
            TriggerClientEvent('qs-corechat:client:message', target, message)
        end
    else
        TriggerClientEvent('qs-corechat:client:message', routing, message)
    end
end)
