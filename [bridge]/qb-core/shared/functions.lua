-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from QBCore (https://github.com/qbcore-framework/qb-core)
-- Copyright (C) QBCore Framework and contributors
-- Modified for qscore in 2026: adapted to run on top of qs-core. See NOTICE.

local StringCharset = {}
local NumberCharset = {}

for i = 48, 57 do NumberCharset[#NumberCharset + 1] = string.char(i) end
for i = 65, 90 do StringCharset[#StringCharset + 1] = string.char(i) end
for i = 97, 122 do StringCharset[#StringCharset + 1] = string.char(i) end

function QBCore.Shared.RandomStr(length)
    if length <= 0 then return '' end
    return QBCore.Shared.RandomStr(length - 1) .. StringCharset[math.random(1, #StringCharset)]
end

function QBCore.Shared.RandomInt(length)
    if length <= 0 then return '' end
    return QBCore.Shared.RandomInt(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
end

function QBCore.Shared.SplitStr(str, delimiter)
    local result = {}
    local from = 1
    local delimFrom, delimTo = string.find(str, delimiter, from)
    while delimFrom do
        result[#result + 1] = string.sub(str, from, delimFrom - 1)
        from = delimTo + 1
        delimFrom, delimTo = string.find(str, delimiter, from)
    end
    result[#result + 1] = string.sub(str, from)
    return result
end

function QBCore.Shared.Trim(value)
    if not value then return nil end
    return (string.gsub(value, '^%s*(.-)%s*$', '%1'))
end

function QBCore.Shared.FirstToUpper(value)
    if not value then return nil end
    return (value:gsub('^%l', string.upper))
end

function QBCore.Shared.Round(value, numDecimalPlaces)
    if not numDecimalPlaces then return math.floor(value + 0.5) end
    local power = 10 ^ numDecimalPlaces
    return math.floor((value * power) + 0.5) / power
end

function QBCore.Shared.CommaValue(amount)
    local formatted = tostring(amount)
    local k
    while true do
        formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

function QBCore.Shared.ChangeVehicleExtra(vehicle, extra, enable)
    if DoesExtraExist(vehicle, extra) then
        SetVehicleExtra(vehicle, extra, enable and 0 or 1)
    end
end

function QBCore.Shared.SetDefaultVehicleExtras(vehicle, config)
    for id = 1, 20 do
        if DoesExtraExist(vehicle, id) then
            SetVehicleExtra(vehicle, id, 1)
        end
    end
    for id, enabled in pairs(config or {}) do
        QBCore.Shared.ChangeVehicleExtra(vehicle, tonumber(id), enabled and true or false)
    end
end
