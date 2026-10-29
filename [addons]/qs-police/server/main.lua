local core = exports['qs-core']

math.randomseed(os.time())

core:RegisterItems({
    handcuffs    = { label = 'Handcuffs',    weight = 450, useable = false, description = 'Standard issue restraints.' },
    evidence_bag = { label = 'Evidence Bag', weight = 30,  useable = false, description = 'For collecting evidence at a scene.' },
    evidence     = { label = 'Evidence',     weight = 120, useable = false, description = 'Sealed evidence. Analyze it at the lab.' },
    armor        = { label = 'Body Armor',   weight = 2000, useable = true, description = 'Kevlar vest.' },
})

CreateThread(function()
    Wait(1000)
    core:RegisterStash('police_evidence', 'Evidence Locker', 50, 200000, 5)
end)

local cuffed = {}
local escorts = {}
local searchSessions = {}
local evidence = {}
local evidenceSeq = 0

local function jobName(src)
    local player = core:GetPlayer(src)
    local job = player and player.PlayerData and player.PlayerData.job
    return (job and job.name) or 'unemployed'
end

local function isCop(src) return jobName(src) == 'police' end

local function charName(src)
    local player = core:GetPlayer(src)
    local ci = player and player.PlayerData and player.PlayerData.charinfo
    if ci and ci.firstname then
        return (('%s %s'):format(ci.firstname or '', ci.lastname or '')):gsub('^%s*(.-)%s*$', '%1')
    end
    return GetPlayerName(src) or 'Unknown'
end

local function citizenId(src)
    local player = core:GetPlayer(src)
    return player and player.citizenid or nil
end

local function distBetween(a, b)
    local pa, pb = GetPlayerPed(a), GetPlayerPed(b)
    if pa == 0 or pb == 0 then return math.huge end
    return #(GetEntityCoords(pa) - GetEntityCoords(pb))
end

local function nearPoint(src, loc, dist)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(loc.x, loc.y, loc.z)) <= dist
end

local function copBroadcast(event, ...)
    for _, p in ipairs(core:GetPlayers()) do
        local job = p.PlayerData and p.PlayerData.job
        if job and job.name == 'police' then
            TriggerClientEvent(event, p.source, ...)
        end
    end
end

exports('Alert', function(coords, label)
    if type(coords) ~= 'table' then return end
    copBroadcast('qs-police:client:alert', { x = coords.x, y = coords.y, z = coords.z }, label)
end)

RegisterNetEvent('qs-police:server:cuff', function(target)
    local src = source
    target = tonumber(target)
    if not target or target == src or not isCop(src) then return end
    if not core:RateLimit(('pd-cuff:%d'):format(src), 1, 2000) then return end
    if distBetween(src, target) > Config.TargetDistance then return end

    if cuffed[target] then
        cuffed[target] = nil
        if escorts[target] then
            escorts[target] = nil
            TriggerClientEvent('qs-police:client:escorted', target, 0)
        end
        Player(target).state:set('cuffed', false, true)
        TriggerClientEvent('qs-police:client:cuffed', target, false)
        TriggerClientEvent('qs:client:notify', target, T('you_uncuffed'), 'info')
        TriggerClientEvent('qs:client:notify', src, T('target_uncuffed'), 'success')
    else
        local cop = core:GetPlayer(src)
        if not cop or not cop:hasItem('handcuffs', 1) then
            TriggerClientEvent('qs:client:notify', src, T('need_handcuffs'), 'error')
            return
        end
        cuffed[target] = true
        Player(target).state:set('cuffed', true, true)
        TriggerClientEvent('qs-police:client:cuffed', target, true)
        TriggerClientEvent('qs:client:notify', target, T('you_cuffed'), 'error')
        TriggerClientEvent('qs:client:notify', src, T('target_cuffed'), 'success')
    end
end)

RegisterNetEvent('qs-police:server:escort', function(target)
    local src = source
    target = tonumber(target)
    if not target or target == src or not isCop(src) then return end
    if not core:RateLimit(('pd-escort:%d'):format(src), 1, 1500) then return end
    if not cuffed[target] then
        TriggerClientEvent('qs:client:notify', src, T('not_cuffed'), 'error')
        return
    end

    if escorts[target] == src then
        escorts[target] = nil
        TriggerClientEvent('qs-police:client:escorted', target, 0)
    else
        if distBetween(src, target) > Config.TargetDistance then return end
        escorts[target] = src
        TriggerClientEvent('qs-police:client:escorted', target, src)
    end
end)

RegisterNetEvent('qs-police:server:putInCar', function(target)
    local src = source
    target = tonumber(target)
    if not target or not isCop(src) or not cuffed[target] then return end
    if distBetween(src, target) > Config.TargetDistance + 3.0 then return end
    if escorts[target] then
        escorts[target] = nil
        TriggerClientEvent('qs-police:client:escorted', target, 0)
    end
    TriggerClientEvent('qs-police:client:putInCar', target)
end)

RegisterNetEvent('qs-police:server:outCar', function(target)
    local src = source
    target = tonumber(target)
    if not target or not isCop(src) or not cuffed[target] then return end
    if distBetween(src, target) > Config.TargetDistance + 3.0 then return end
    TriggerClientEvent('qs-police:client:outCar', target)
end)

local function searchView(target)
    local targetPlayer = core:GetPlayer(target)
    if not targetPlayer then return {} end
    local items = core:GetItems() or {}
    local view = {}
    for _, it in ipairs(targetPlayer:getSlotView() or {}) do
        if type(it) == 'table' and it.name then
            local def = items[it.name]
            view[#view + 1] = {
                slot = it.slot,
                name = it.name,
                label = (def and def.label) or it.name,
                count = it.count or 1,
                info = it.info,
            }
        end
    end
    return view
end

RegisterNetEvent('qs-police:server:search', function(target)
    local src = source
    target = tonumber(target)
    if not target or target == src or not isCop(src) then return end
    if not core:RateLimit(('pd-search:%d'):format(src), 1, 2000) then return end
    if distBetween(src, target) > Config.TargetDistance then return end

    searchSessions[src] = target
    TriggerClientEvent('qs-police:client:openUI', src, {
        mode = 'search',
        name = charName(target),
        items = searchView(target),
    })
    TriggerClientEvent('qs:client:notify', target, T('being_searched'), 'info')
end)

RegisterNetEvent('qs-police:server:confiscate', function(slot)
    local src = source
    local target = searchSessions[src]
    if not target or not isCop(src) then return end
    if not core:RateLimit(('pd-conf:%d'):format(src), 1, 800) then return end
    if not cuffed[target] then
        TriggerClientEvent('qs:client:notify', src, T('not_cuffed'), 'error')
        return
    end
    if distBetween(src, target) > Config.TargetDistance + 1.5 then return end

    local cop = core:GetPlayer(src)
    local targetPlayer = core:GetPlayer(target)
    if not cop or not targetPlayer then return end

    local it = targetPlayer:getItemBySlot(tonumber(slot))
    if not it then return end
    if not cop:canCarryItem(it.name, it.count) then
        TriggerClientEvent('qs:client:notify', src, T('cant_carry'), 'error')
        return
    end
    if not targetPlayer:removeItem(it.name, it.count, it.slot) then return end
    cop:addItem(it.name, it.count, nil, it.info)

    TriggerClientEvent('qs:client:notify', src, T('confiscated', it.count, it.name), 'success')
    TriggerClientEvent('qs:client:notify', target, T('item_confiscated'), 'error')
    TriggerClientEvent('qs-police:client:updateUI', src, { mode = 'search', items = searchView(target) })
end)

RegisterNetEvent('qs-police:server:closeUI', function()
    searchSessions[source] = nil
end)

RegisterNetEvent('qs-police:server:fine', function(target, amount, reason)
    local src = source
    target = tonumber(target)
    amount = math.floor(tonumber(amount) or 0)
    if not target or target == src or not isCop(src) then return end
    if amount < Config.Fine.min or amount > Config.Fine.max then return end
    if not core:RateLimit(('pd-fine:%d'):format(src), 1, 3000) then return end
    if distBetween(src, target) > 6.0 then return end

    reason = tostring(reason or ''):sub(1, 80)
    if core:RemoveMoney(target, 'bank', amount, 'police-fine') then
        TriggerClientEvent('qs:client:notify', target, T('you_fined', amount, reason ~= '' and reason or '-'), 'error', 6000)
        TriggerClientEvent('qs:client:notify', src, T('fine_ok', amount), 'success')
    else
        TriggerClientEvent('qs:client:notify', src, T('fine_no_funds'), 'error')
    end
end)

local function addEvidence(data)
    local count = 0
    for _ in pairs(evidence) do count = count + 1 end
    if count >= Config.Evidence.maxPoints then return end

    evidenceSeq = evidenceSeq + 1
    data.id = evidenceSeq
    data.expires = GetGameTimer() + Config.Evidence.lifetime
    evidence[evidenceSeq] = data
end

RegisterNetEvent('qs-police:server:casing', function(coords, weaponLabel)
    local src = source
    if type(coords) ~= 'table' then return end
    if not core:RateLimit(('pd-casing:%d'):format(src), 1, math.max(150, Config.Evidence.casingCooldown - 150)) then return end
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local real = GetEntityCoords(ped)
    local c = vector3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
    if #(real - c) > (Config.Evidence.maxCasingDist or 150.0) then return end

    addEvidence({
        type = 'casing',
        coords = { x = c.x, y = c.y, z = c.z },
        weapon = tostring(weaponLabel or 'Unknown'):sub(1, 40),
        time = os.date('%H:%M'),
    })

    if math.random() < Config.Evidence.alertChance
        and core:RateLimit(('pd-shotalert:%d'):format(src), 1, Config.Evidence.alertCooldown or 15000) then
        copBroadcast('qs-police:client:alert', { x = real.x, y = real.y, z = real.z }, T('alert_shots'))
    end
end)

RegisterNetEvent('qs-police:server:blood', function()
    local src = source
    if not core:RateLimit(('pd-blood:%d'):format(src), 1, 10000) then return end
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local c = GetEntityCoords(ped)
    local cid = citizenId(src)
    if not cid then return end

    addEvidence({
        type = 'blood',
        coords = { x = c.x, y = c.y, z = c.z },
        dna = cid,
        time = os.date('%H:%M'),
    })
end)

RegisterNetEvent('qs-police:server:requestEvidence', function()
    local src = source
    if not isCop(src) then return end
    if not core:RateLimit(('pd-evreq:%d'):format(src), 1, 5000) then return end
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local coords = GetEntityCoords(ped)

    local now = GetGameTimer()
    local nearby = {}
    for id, e in pairs(evidence) do
        if e.expires < now then
            evidence[id] = nil
        elseif #(coords - vector3(e.coords.x, e.coords.y, e.coords.z)) < 80.0 then
            nearby[#nearby + 1] = { id = id, type = e.type, coords = e.coords }
        end
    end
    TriggerClientEvent('qs-police:client:evidence', src, nearby)
end)

RegisterNetEvent('qs-police:server:collect', function(id)
    local src = source
    if not isCop(src) then return end
    if not core:RateLimit(('pd-collect:%d'):format(src), 1, 1500) then return end
    local e = evidence[tonumber(id) or -1]
    if not e then return end
    if not nearPoint(src, e.coords, Config.Evidence.collectDistance + 1.5) then return end

    local player = core:GetPlayer(src)
    if not player then return end

    if not player:hasItem('evidence_bag', 1) then
        TriggerClientEvent('qs:client:notify', src, T('need_bag'), 'error')
        return
    end
    local info = {
        etype = e.type,
        weapon = e.weapon,
        dna = e.dna,
        time = e.time,
        location = ('%.0f, %.0f'):format(e.coords.x, e.coords.y),
    }
    if not player:canCarryItem('evidence', 1) then
        TriggerClientEvent('qs:client:notify', src, T('cant_carry'), 'error')
        return
    end
    if not player:removeItem('evidence_bag', 1) then return end
    player:addItem('evidence', 1, nil, info)
    evidence[e.id] = nil
    TriggerClientEvent('qs:client:notify', src, T('collected'), 'success')
    TriggerClientEvent('qs-police:client:evidenceRemoved', -1, e.id)
end)

local function labView(src)
    local player = core:GetPlayer(src)
    if not player then return {} end
    local view = {}
    for _, it in ipairs(player:getSlotView() or {}) do
        if type(it) == 'table' and it.name == 'evidence' then
            view[#view + 1] = { slot = it.slot, info = it.info or {} }
        end
    end
    return view
end

RegisterNetEvent('qs-police:server:openLab', function()
    local src = source
    if not isCop(src) then return end
    if not nearPoint(src, Config.Station.lab, Config.InteractDistance + 1.5) then return end
    TriggerClientEvent('qs-police:client:openUI', src, { mode = 'lab', items = labView(src) })
end)

RegisterNetEvent('qs-police:server:analyze', function(slot)
    local src = source
    if not isCop(src) then return end
    if not core:RateLimit(('pd-analyze:%d'):format(src), 1, 3000) then return end
    if not nearPoint(src, Config.Station.lab, Config.InteractDistance + 2.0) then return end

    local player = core:GetPlayer(src)
    if not player then return end

    local it = player:getItemBySlot(tonumber(slot))
    if not it or it.name ~= 'evidence' then return end
    local info = it.info or {}
    if info.analyzed or not info.dna then return end

    local name = nil
    local owner = core:GetPlayerByCitizenId(info.dna)
    if owner and owner.PlayerData and owner.PlayerData.charinfo then
        local ci = owner.PlayerData.charinfo
        name = (('%s %s'):format(ci.firstname or '', ci.lastname or '')):gsub('^%s*(.-)%s*$', '%1')
    else
        local raw = MySQL.scalar.await('SELECT charinfo FROM players WHERE citizenid = ?', { info.dna })
        if raw then
            local ok, ci = pcall(json.decode, raw)
            if ok and ci then name = (('%s %s'):format(ci.firstname or '', ci.lastname or '')):gsub('^%s*(.-)%s*$', '%1') end
        end
    end

    info.analyzed = name or 'No match'
    player:setItemInfo(it.slot, info)
    TriggerClientEvent('qs:client:notify', src, T('analyzed', info.analyzed), 'success')
    TriggerClientEvent('qs-police:client:updateUI', src, { mode = 'lab', items = labView(src) })
end)

local armoryAllowed = {}
for _, e in ipairs(Config.Armory) do armoryAllowed[e.name] = e.count end

RegisterNetEvent('qs-police:server:armoryTake', function(name)
    local src = source
    if not isCop(src) then return end
    if not core:RateLimit(('pd-armory:%d'):format(src), 1, 1500) then return end
    if not nearPoint(src, Config.Station.armory, Config.InteractDistance + 1.5) then return end

    local player = core:GetPlayer(src)
    if not player then return end

    local count = armoryAllowed[name]
    if not count then return end
    if not player:canCarryItem(name, count) then
        TriggerClientEvent('qs:client:notify', src, T('cant_carry'), 'error')
        return
    end
    if player:addItem(name, count) then
        local def = core:GetItem(name)
        TriggerClientEvent('qs:client:notify', src, T('armory_taken', count, (def and def.label) or name), 'success')
    end
end)

core:RegisterUsableItem('armor', function(src)
    local player = core:GetPlayer(src)
    if not player then return end
    if not player:removeItem('armor', 1) then return end
    player:setBusy(3000)
    TriggerClientEvent('qs-police:client:useArmor', src)
end)

AddEventHandler('qs:server:jobChange', function(src, job)
    if job and job.name ~= 'police' then
        searchSessions[src] = nil
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    cuffed[src] = nil
    searchSessions[src] = nil
    for target, officer in pairs(escorts) do
        if officer == src or target == src then
            escorts[target] = nil
            if target ~= src then TriggerClientEvent('qs-police:client:escorted', target, 0) end
        end
    end
end)
