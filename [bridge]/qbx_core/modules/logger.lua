local isServer = IsDuplicityVersion()
if not isServer then
    lib.print.error('cannot use the logger on the client')
    return
end

local logQueue, isProcessingQueue, logCount = {}, false, 0
local lastRequestTime, requestDelay = 0, 0

local Colors = {
    default = 14423100,
    blue = 255,
    red = 16711680,
    green = 65280,
    white = 16777215,
    black = 0,
    orange = 16744192,
    yellow = 16776960,
    pink = 16761035,
    lightgreen = 65309,
}

local function applyRequestDelay()
    local currentTime = GetGameTimer()
    local timeDiff = currentTime - lastRequestTime

    if timeDiff < requestDelay then
        local remainingDelay = requestDelay - timeDiff

        Wait(remainingDelay)
    end

    lastRequestTime = GetGameTimer()
end

local allowedErr = {
    [200] = true,
    [201] = true,
    [204] = true,
    [304] = true
}

local function logPayload(payload)
    local tags
    local username = 'QBX Logs'
    local avatarUrl = 'https://qbox-project.github.io/qbox-duck.png'

    if payload.tags then
        for i = 1, #payload.tags do
            if not tags then tags = '' end
            tags = tags .. payload.tags[i]
        end
    end

    PerformHttpRequest(payload.webhook, function(err, _, headers)
        if err and not allowedErr[err] then
            lib.print.error('can\'t send log to discord', err)
            return
        end

        local remainingRequests = tonumber(headers['X-RateLimit-Remaining'])
        local resetTime = tonumber(headers['X-RateLimit-Reset'])

        if remainingRequests and resetTime and remainingRequests == 0 then
            local currentTime = os.time()
            local resetDelay = resetTime - currentTime

            if resetDelay > 0 then
                requestDelay = resetDelay * 1000 / 10
            end
        end
    end, 'POST', json.encode({username = username, avatar_url = avatarUrl, content = tags, embeds = payload.embed}), { ['Content-Type'] = 'application/json' })
end

local function processLogQueue()
    if #logQueue > 0 then
        local payload = table.remove(logQueue, 1)

        logPayload(payload)

        logCount += 1

        if logCount % 5 == 0 then
            Wait(60000)
        else
            applyRequestDelay()
        end

        processLogQueue()
    else
        isProcessingQueue = false
    end
end

local function discordLog(log)
    local embedData = {
        {
            title = log.event,
            color = Colors[log.color] or Colors.default,
            footer = {
                text = os.date('%H:%M:%S %m-%d-%Y'),
            },
            description = log.message,
            author = {
                name = log.source,
            },
        }
    }

    logQueue[#logQueue + 1] = {
        webhook = log.webhook,
        tags = log.tags,
        embed = embedData
    }

    if not isProcessingQueue then
        isProcessingQueue = true
        CreateThread(processLogQueue)
    end
end

local function createLog(log)
    if log.webhook then
        discordLog(log)
    end
    lib.logger(log.source, log.event, log.message, log.oxLibTags)
end

return {
    log = createLog
}
