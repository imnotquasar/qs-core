Utils = {}

local IsDuplicityVersion = IsDuplicityVersion()

function Utils.Debug(...)
    if not Config.Debug then return end
    local side = IsDuplicityVersion and '^5[qs-core:server]^7' or '^4[qs-core:client]^7'
    print(side, ...)
end

function Utils.Info(...)
    print('^2[qs-core]^7', ...)
end

function Utils.Error(...)
    print('^1[qs-core:error]^7', ...)
end

function Utils.Warn(...)
    print('^3[qs-core:warn]^7', ...)
end

local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

function Utils.RandomCitizenId(length)
    length = length or 8
    local id = 'QS'
    for _ = 1, length - 2 do
        local i = math.random(1, #charset)
        id = id .. charset:sub(i, i)
    end
    return id
end

function Utils.Clone(t)
    if type(t) ~= 'table' then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = type(v) == 'table' and Utils.Clone(v) or v
    end
    return copy
end

function Utils.BuildJob(name, grade)
    local job = Jobs[name]
    if not job then return nil end

    local gradeData = job.grades[grade]
    if not gradeData then

        local lowest
        for level, data in pairs(job.grades) do
            if not lowest or level < lowest then
                lowest = level
                gradeData = data
            end
        end
        if not gradeData then return nil end
        grade = lowest
    end

    return {
        name = name,
        label = job.label,
        grade = grade,
        gradeName = gradeData.name,
        gradeLabel = gradeData.label,
        salary = gradeData.salary,
        isBoss = gradeData.isBoss or false,
        onduty = job.defaultDuty ~= false,
    }
end

local rateBuckets = {}
function Utils.RateLimit(key, max, windowMs)
    local now = GetGameTimer()
    local b = rateBuckets[key]
    if not b or now >= b.reset then
        rateBuckets[key] = { count = 1, reset = now + windowMs }
        return true
    end
    if b.count >= max then return false end
    b.count = b.count + 1
    return true
end

if IsDuplicityVersion then
    local colors = { money = 3066993, admin = 15158332, connections = 3447003 }

    function Utils.Log(channel, title, message)
        local url = Config.Webhooks and Config.Webhooks[channel]
        if not url or url == '' then return end
        PerformHttpRequest(url, function() end, 'POST', json.encode({
            username = 'qscore',
            embeds = { { title = title, description = message, color = colors[channel] or 3447003 } },
        }), { ['Content-Type'] = 'application/json' })
    end
else
    function Utils.Log() end
end
