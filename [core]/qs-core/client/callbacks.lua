local requests = {}
local requestId = 0
local qbCallbacks = {}

function QS.TriggerCallback(name, cb, ...)
    requestId = requestId + 1
    requests[requestId] = cb
    TriggerServerEvent('qs:server:triggerCallback', name, requestId, ...)
end

function QS.TriggerQBCallback(name, cb, ...)
    qbCallbacks[name] = cb
    TriggerServerEvent('QBCore:Server:TriggerCallback', name, ...)
end

exports('TriggerCallback', QS.TriggerCallback)
exports('TriggerQBCallback', QS.TriggerQBCallback)

RegisterNetEvent('qs:client:callbackResponse', function(id, ...)
    local cb = requests[id]
    if not cb then return end
    requests[id] = nil
    cb(...)
end)

RegisterNetEvent('QBCore:Client:TriggerCallback', function(name, ...)
    local cb = qbCallbacks[name]
    if not cb then return end
    qbCallbacks[name] = nil
    cb(...)
end)
