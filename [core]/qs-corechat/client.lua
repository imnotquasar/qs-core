local chatOpen = false
local chatVisible = true
local hiddenByPause = false

local function send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local suggestions = {}
local serverCommands = {}
local clientCommands = {}

local hidden = {}
for _, name in ipairs(Config.HiddenCommands or {}) do hidden[name] = true end

local function suggestionList()
    local out = {}
    for _, s in pairs(suggestions) do out[#out + 1] = s end
    for _, auto in ipairs({ serverCommands, clientCommands }) do
        for name, s in pairs(auto) do
            if not suggestions[name] then out[#out + 1] = s end
        end
    end
    return out
end

local function toSuggestions(list)
    local out = {}
    for _, s in ipairs(list or {}) do
        if s.name then out[s.name] = { name = s.name, help = '', params = {} } end
    end
    return out
end

local function readClientCommands()
    local list = {}
    for _, c in ipairs(GetRegisteredCommands()) do
        local name = c.name
        if c.resource and c.resource ~= '' and c.resource ~= 'internal' and not hidden[name]
            and not name:find('^[%+%-]') and IsAceAllowed(('command.%s'):format(name)) then
            list[#list + 1] = { name = '/' .. name }
        end
    end
    return toSuggestions(list)
end

RegisterNetEvent('qs-corechat:client:commands', function(list)
    serverCommands = toSuggestions(list)
    if chatOpen then send('suggestions', suggestionList()) end
end)

RegisterNetEvent('chat:addSuggestion', function(name, help, params)
    if not name then return end
    suggestions[name] = { name = name, help = help or '', params = params or {} }
    if chatOpen then send('suggestions', suggestionList()) end
end)

RegisterNetEvent('chat:addSuggestions', function(list)
    for _, s in ipairs(list or {}) do
        if s.name then suggestions[s.name] = { name = s.name, help = s.help or '', params = s.params or {} } end
    end
    if chatOpen then send('suggestions', suggestionList()) end
end)

RegisterNetEvent('chat:removeSuggestion', function(name)
    if name then suggestions[name] = nil end
    if chatOpen then send('suggestions', suggestionList()) end
end)

RegisterCommand('chatopen', function()
    if chatOpen or hiddenByPause or not chatVisible or IsPauseMenuActive() then return end
    chatOpen = true
    SetNuiFocus(true, true)
    clientCommands = readClientCommands()
    TriggerServerEvent('qs-corechat:server:commands')
    send('suggestions', suggestionList())
    send('open')
end, false)

RegisterKeyMapping('chatopen', 'Open chat', 'keyboard', 'T')

RegisterNUICallback('send', function(data, cb)
    chatOpen = false
    SetNuiFocus(false, false)
    local msg = tostring(data.message or ''):gsub('^%s*(.-)%s*$', '%1')
    if msg ~= '' then
        if msg:sub(1, 1) == '/' then
            ExecuteCommand(msg:sub(2))
        else
            TriggerServerEvent('qs-corechat:server:send', msg)
        end
    end
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    chatOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNetEvent('qs-corechat:client:message', function(msg)
    send('message', msg)
end)

RegisterNetEvent('chat:addMessage', function(msg)
    local author, text
    if type(msg) == 'table' then
        if msg.args then
            if #msg.args >= 2 then author, text = msg.args[1], msg.args[2] else text = msg.args[1] end
        else
            text = msg.text or ''
        end
    else
        text = tostring(msg)
    end
    send('message', { author = author, text = text })
end)

local function sendTheme()
    local colors = exports['qs-core']:GetColors()
    if colors then send('theme', colors) end
end
AddEventHandler('qs:client:colorsChanged', function() sendTheme() end)
CreateThread(function()
    Wait(500)
    sendTheme()
    send('locale', Locales[GetConvar('qs:locale', 'en')] or Locales.en or {})
end)

AddEventHandler('qs:chat:display', function(state)
    chatVisible = state and true or false
    if not state and chatOpen then
        chatOpen = false
        SetNuiFocus(false, false)
    end
    if not hiddenByPause then
        send(state and 'show' or 'hide')
    end
end)

CreateThread(function()
    while true do
        Wait(250)
        if IsPauseMenuActive() then
            if not hiddenByPause then
                hiddenByPause = true
                if chatOpen then
                    chatOpen = false
                    SetNuiFocus(false, false)
                end
                send('hide')
            end
        elseif hiddenByPause then
            hiddenByPause = false
            if chatVisible then send('show') end
        end
    end
end)
