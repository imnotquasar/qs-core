local core = exports['qs-core']

local function trim(s)
    return (tostring(s or ''):gsub('^%s*(.-)%s*$', '%1'))
end

local function clamp(s)
    s = trim(s)
    if #s > Config.MaxLength then s = s:sub(1, Config.MaxLength) end
    return s
end

local function playerName(src)
    local player = core:GetPlayer(src)
    if player and player.PlayerData and player.PlayerData.charinfo then
        local ci = player.PlayerData.charinfo
        local n = trim(((ci.firstname or '') .. ' ' .. (ci.lastname or '')))
        if n ~= '' then return n end
    end
    return GetPlayerName(src) or 'Unknown'
end

local function nearby(src, dist)
    local out = {}
    local sped = GetPlayerPed(src)
    if not sped or sped == 0 then return { src } end
    local sc = GetEntityCoords(sped)
    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        local ped = GetPlayerPed(pid)
        if ped and ped ~= 0 and DoesEntityExist(ped) then
            if #(sc - GetEntityCoords(ped)) <= dist then
                out[#out + 1] = pid
            end
        end
    end
    return out
end

local function toChat(targets, msg)
    for _, id in ipairs(targets) do
        TriggerClientEvent('qs-corechat:client:message', id, msg)
    end
end

local function notify(src, text, kind)
    TriggerClientEvent('qs:client:notify', src, text, kind or 'error', 3000)
end

RegisterNetEvent('qs-rp:me', function(text)
    local src = source
    text = clamp(text)
    if text == '' then notify(src, T('empty')) return end
    toChat(nearby(src, Config.Proximity), {
        type = 'me',
        text = T('me_format', playerName(src), text),
    })
end)

RegisterNetEvent('qs-rp:do', function(text)
    local src = source
    text = clamp(text)
    if text == '' then notify(src, T('empty')) return end
    toChat(nearby(src, Config.Proximity), {
        type = 'do',
        text = T('do_format', text, playerName(src)),
    })
end)

RegisterNetEvent('qs-rp:b', function(text)
    local src = source
    text = clamp(text)
    if text == '' then notify(src, T('empty')) return end
    toChat(nearby(src, Config.Proximity), {
        type = 'b',
        text = T('b_format', playerName(src), text),
    })
end)

RegisterNetEvent('qs-rp:ooc', function(text)
    local src = source
    text = clamp(text)
    if text == '' then notify(src, T('empty')) return end
    TriggerClientEvent('qs-corechat:client:message', -1, {
        type = 'ooc',
        text = T('ooc_prefix', playerName(src), text),
    })
end)

RegisterNetEvent('qs-rp:try', function(text)
    local src = source
    text = clamp(text)
    if text == '' then notify(src, T('empty')) return end
    local ok = math.random(1, 2) == 1
    toChat(nearby(src, Config.Proximity), {
        type = 'me',
        text = T('try_format', playerName(src), text, ok and T('try_success') or T('try_fail')),
    })
end)

RegisterNetEvent('qs-rp:pm', function(targetId, text)
    local src = source
    targetId = tonumber(targetId)
    text = clamp(text)
    if not targetId or text == '' then notify(src, T('empty')) return end
    if targetId == src then notify(src, T('pm_self')) return end
    if GetPlayerPed(targetId) == 0 then notify(src, T('pm_no_target')) return end

    TriggerClientEvent('qs-corechat:client:message', targetId, {
        type = 'pm',
        text = T('pm_from', playerName(src), text),
    })
    TriggerClientEvent('qs-corechat:client:message', src, {
        type = 'pm',
        text = T('pm_to', playerName(targetId), text),
    })
end)

RegisterNetEvent('qs-rp:ame', function(text)
    local src = source
    text = clamp(text)
    if text == '' then notify(src, T('empty')) return end
    for _, pid in ipairs(nearby(src, Config.AmeDistance)) do
        TriggerClientEvent('qs-rp:client:ame', pid, src, text)
    end
end)
