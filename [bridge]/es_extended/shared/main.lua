ESX = ESX or {}
ESX.PlayerData = {}
ESX.PlayerLoaded = false

Config.OxInventory = Config.CustomInventory == 'ox'
Config.QsInventory = Config.CustomInventory == 'qs'

function ESX.GetConfig(key)
    if key then return Config[key] end
    return Config
end
ESX.UI = ESX.UI or {}
ESX.Game = ESX.Game or {}
ESX.Scaleform = ESX.Scaleform or {}
ESX.Streaming = ESX.Streaming or {}
ESX.Math = {}
ESX.Table = {}

function ESX.Math.Round(value, numDecimalPlaces)
    if numDecimalPlaces then
        local power = 10 ^ numDecimalPlaces
        return math.floor((value * power) + 0.5) / power
    end
    return math.floor(value + 0.5)
end

function ESX.Math.GroupDigits(value)
    local left, num, right = string.match(value, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

function ESX.Math.Trim(value)
    if not value then return nil end
    return (string.gsub(value, '^%s*(.-)%s*$', '%1'))
end

function ESX.Table.SizeOf(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function ESX.Table.Set(t)
    local set = {}
    for _, v in ipairs(t) do set[v] = true end
    return set
end

function ESX.Table.IndexOf(t, value)
    for i = 1, #t do
        if t[i] == value then return i end
    end
    return -1
end

function ESX.Table.LastIndexOf(t, value)
    for i = #t, 1, -1 do
        if t[i] == value then return i end
    end
    return -1
end

function ESX.Table.Find(t, cb)
    for i = 1, #t do
        if cb(t[i]) then return t[i] end
    end
    return nil
end

function ESX.Table.FindIndex(t, cb)
    for i = 1, #t do
        if cb(t[i]) then return i end
    end
    return -1
end

function ESX.Table.Filter(t, cb)
    local out = {}
    for i = 1, #t do
        if cb(t[i]) then out[#out + 1] = t[i] end
    end
    return out
end

function ESX.Table.Map(t, cb)
    local out = {}
    for i = 1, #t do
        out[i] = cb(t[i], i)
    end
    return out
end

function ESX.Table.Reverse(t)
    local out = {}
    for i = #t, 1, -1 do
        out[#out + 1] = t[i]
    end
    return out
end

function ESX.Table.Clone(t)
    if type(t) ~= 'table' then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = type(v) == 'table' and ESX.Table.Clone(v) or v
    end
    return out
end

function ESX.Table.Concat(t1, t2)
    local out = ESX.Table.Clone(t1)
    for i = 1, #t2 do
        out[#out + 1] = t2[i]
    end
    return out
end

function ESX.Table.Join(t, sep)
    sep = sep or ','
    local out = ''
    for i = 1, #t do
        out = out .. (i > 1 and sep or '') .. tostring(t[i])
    end
    return out
end

function ESX.Table.Contains(t, value)
    for _, v in pairs(t) do
        if v == value then return true end
    end
    return false
end

function ESX.DumpTable(t, indent)
    indent = indent or 0
    for k, v in pairs(t or {}) do
        local pad = string.rep('  ', indent)
        if type(v) == 'table' then
            print(pad .. tostring(k) .. ':')
            ESX.DumpTable(v, indent + 1)
        else
            print(pad .. tostring(k) .. ' = ' .. tostring(v))
        end
    end
end

local timeoutCount = 0
local cancelledTimeouts = {}

function ESX.SetTimeout(msec, cb)
    timeoutCount = timeoutCount + 1
    local id = timeoutCount
    SetTimeout(msec, function()
        if cancelledTimeouts[id] then
            cancelledTimeouts[id] = nil
            return
        end
        cb()
    end)
    return id
end

function ESX.ClearTimeout(id)
    if id then cancelledTimeouts[id] = true end
end

exports('getSharedObject', function()
    return ESX
end)

AddEventHandler('esx:getSharedObject', function(cb)
    if type(cb) == 'function' then cb(ESX) end
end)
