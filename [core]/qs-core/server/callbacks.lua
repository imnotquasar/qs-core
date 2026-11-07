local serverCallbacks = {}
local qbCallbacks = {}

function QS.RegisterCallback(name, handler)
    serverCallbacks[name] = handler
end

function QS.RegisterQBCallback(name, handler)
    qbCallbacks[name] = handler
end

exports('RegisterCallback', QS.RegisterCallback)
exports('RegisterQBCallback', QS.RegisterQBCallback)

RegisterNetEvent('qs:server:triggerCallback', function(name, requestId, ...)
    local source = source
    if type(name) ~= 'string' or #name > 128 then return end
    if not Utils.RateLimit(('cb:%d'):format(source), 100, 1000) then return end
    local handler = serverCallbacks[name]
    if not handler then
        Utils.Error(('Unknown server callback requested: "%s" by %s'):format(name, source))
        return
    end

    local results = { handler(source, ...) }
    TriggerClientEvent('qs:client:callbackResponse', source, requestId, table.unpack(results))
end)

RegisterNetEvent('QBCore:Server:TriggerCallback', function(name, ...)
    local src = source
    if type(name) ~= 'string' or #name > 128 then return end
    if not Utils.RateLimit(('qbcb:%d'):format(src), 100, 1000) then return end
    local handler = qbCallbacks[name]
    if not handler then
        Utils.Warn(('Unknown QB callback: %s'):format(name))
        return
    end
    handler(src, function(...)
        TriggerClientEvent('QBCore:Client:TriggerCallback', src, name, ...)
    end, ...)
end)
