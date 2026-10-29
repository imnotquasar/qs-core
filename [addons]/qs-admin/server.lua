local core = exports['qs-core']

local function isAdmin(src)
    return src == 0 or IsPlayerAceAllowed(src, Config.Permission)
end

local function adminName(src)
    local p = core:GetPlayer(src)
    local ci = p and p.PlayerData and p.PlayerData.charinfo
    if ci and ci.firstname then return (ci.firstname .. ' ' .. (ci.lastname or '')) end
    return GetPlayerName(src) or ('#' .. src)
end

local function coordsOf(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    return { x = c.x, y = c.y, z = c.z, w = GetEntityHeading(ped) }
end

local function logAction(src, action, target, extra)
    local line = ('[qs-admin] %s (%d) -> %s'):format(adminName(src), src, action)
    if target then line = line .. (' on %s (%d)'):format(GetPlayerName(target) or '?', target) end
    if extra then line = line .. ' ' .. extra end
    print(line)
    if Config.Webhook and Config.Webhook ~= '' then
        PerformHttpRequest(Config.Webhook, function() end, 'POST',
            json.encode({ content = line }), { ['Content-Type'] = 'application/json' })
    end
end

core:RegisterCallback('qs-admin:isAllowed', function(src)
    return isAdmin(src)
end)

core:RegisterCallback('qs-admin:players', function(src)
    if not isAdmin(src) then return {} end
    local list = {}
    for _, p in ipairs(core:GetPlayers()) do
        local pd = p.PlayerData or {}
        local ci = pd.charinfo or {}
        local job = pd.job or {}
        list[#list + 1] = {
            id = p.source,
            name = (ci.firstname and (ci.firstname .. ' ' .. (ci.lastname or ''))) or GetPlayerName(p.source) or ('#' .. p.source),
            job = job.label or job.name or 'unemployed',
            grade = job.grade_label or job.grade,
            ping = GetPlayerPing(p.source),
            cash = core:GetMoney(p.source, 'cash'),
            bank = core:GetMoney(p.source, 'bank'),
        }
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end)

local function ban(src, target, reason, minutes)
    local lic = GetPlayerIdentifierByType(target, 'license')
    if not lic then return end
    minutes = tonumber(minutes) or 0
    local expires = minutes > 0 and (os.date('%Y-%m-%d %H:%M:%S', os.time() + minutes * 60)) or nil
    MySQL.insert('INSERT INTO `bans` (license, name, reason, banned_by, expires) VALUES (?, ?, ?, ?, ?)', {
        lic, GetPlayerName(target), reason or 'No reason', adminName(src), expires,
    })
    DropPlayer(target, ('Banned: %s'):format(reason or 'No reason'))
end

RegisterNetEvent('qs-admin:action', function(action, target, data)
    local src = source
    if not isAdmin(src) then return end
    data = data or {}
    target = tonumber(target)

    if action == 'goto' then
        local c = target and coordsOf(target)
        if c then TriggerClientEvent('qs-admin:client:teleport', src, c) end
        return
    elseif action == 'bring' then
        local c = coordsOf(src)
        if c and target then TriggerClientEvent('qs-admin:client:teleport', target, c) end
    elseif action == 'spectate' then
        if target then TriggerClientEvent('qs-admin:client:spectate', src, target, coordsOf(target)) end
        return
    elseif action == 'kick' then
        if target then DropPlayer(target, data.reason and ('Kicked: ' .. data.reason) or 'Kicked by an admin') end
    elseif action == 'ban' then
        if target then ban(src, target, data.reason, data.minutes) end
    elseif action == 'heal' then
        if target then TriggerClientEvent('qs-admin:client:heal', target) end
    elseif action == 'revive' then
        if target then TriggerClientEvent('qs:client:revive', target) end
    elseif action == 'kill' then
        if target then TriggerClientEvent('qs:client:forceDown', target) end
    elseif action == 'freeze' then
        if target then TriggerClientEvent('qs-admin:client:freeze', target, data.state == true) end
    elseif action == 'setjob' then
        if target then core:SetJob(target, data.job, tonumber(data.grade) or 0) end
    elseif action == 'setgroup' then
        if target and data.group then ExecuteCommand(('setgroup %d %s'):format(target, data.group)) end
    elseif action == 'money' then
        if target then
            local amount = math.floor(tonumber(data.amount) or 0)
            local account = data.account or 'cash'
            if data.mode == 'remove' then core:RemoveMoney(target, account, amount, 'admin')
            elseif data.mode == 'set' then core:SetMoney(target, account, amount, 'admin')
            else core:AddMoney(target, account, amount, 'admin') end
        end
    elseif action == 'giveitem' then
        if target and data.item then
            local targetPlayer = core:GetPlayer(target)
            if targetPlayer then targetPlayer:addItem(data.item, math.floor(tonumber(data.count) or 1)) end
        end
    elseif action == 'giveweapon' then
        if target and data.weapon then
            TriggerClientEvent('qs-admin:client:giveweapon', target, data.weapon, math.floor(tonumber(data.ammo) or 250))
        end
    elseif action == 'announce' then
        TriggerClientEvent('qs-admin:client:announce', -1, tostring(data.message or ''))
    elseif action == 'weather' then
        TriggerClientEvent('qs-admin:client:weather', -1, tostring(data.weather or 'CLEAR'))
    elseif action == 'time' then
        TriggerClientEvent('qs-admin:client:time', -1, math.floor(tonumber(data.hour) or 12), math.floor(tonumber(data.minute) or 0))
    else
        return
    end

    logAction(src, action, target, data.reason or data.job or data.group or data.item or data.weather)
end)
