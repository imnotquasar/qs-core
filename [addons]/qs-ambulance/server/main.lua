local core = exports['qs-core']

math.randomseed(os.time())

core:RegisterItems({
    icepack    = { label = 'Ice Pack',   weight = 350, useable = false, description = 'Use for beat wounds.' },
    burn_cream = { label = 'Burn Cream', weight = 300, useable = false, description = 'Use for burn wounds.' },
})

local injuries = {}
local downed = {}
local sessions = {}
local stretchers = {}
local stretcherSeq = 0

local REGION_OK = {}
for _, r in ipairs(Config.Regions) do REGION_OK[r] = true end

local TYPES = { 'bleeding', 'bruising', 'burning' }

local ITEM_TYPE = {}
for t, item in pairs(Config.TreatmentItems) do ITEM_TYPE[item] = t end

local function jobName(src)
    local player = core:GetPlayer(src)
    local job = player and player.PlayerData and player.PlayerData.job
    return (job and job.name) or 'unemployed'
end

local function isMedic(src) return jobName(src) == 'ambulance' end

local function charName(src)
    local player = core:GetPlayer(src)
    local ci = player and player.PlayerData and player.PlayerData.charinfo
    if ci and ci.firstname then
        return (('%s %s'):format(ci.firstname or '', ci.lastname or '')):gsub('^%s*(.-)%s*$', '%1')
    end
    return GetPlayerName(src) or 'Unknown'
end

local function distBetween(a, b)
    local pa, pb = GetPlayerPed(a), GetPlayerPed(b)
    if pa == 0 or pb == 0 then return math.huge end
    return #(GetEntityCoords(pa) - GetEntityCoords(pb))
end

local function clampLevel(v)
    v = math.floor(tonumber(v) or 0)
    if v < 0 then return 0 end
    if v > 4 then return 4 end
    return v
end

local function sanitize(raw)
    if type(raw) ~= 'table' then return {} end
    local out = {}
    for region, data in pairs(raw) do
        if REGION_OK[region] and type(data) == 'table' then
            out[region] = {
                bleeding = clampLevel(data.bleeding),
                bruising = clampLevel(data.bruising),
                burning = clampLevel(data.burning),
            }
        end
    end
    return out
end

local function worstOf(data)
    for _, t in ipairs(TYPES) do
        if (data[t] or 0) > 0 then return t, data[t] end
    end
    return 'none', 0
end

local function totalLevels(src)
    local total = 0
    for _, data in pairs(injuries[src] or {}) do
        for _, t in ipairs(TYPES) do total = total + (data[t] or 0) end
    end
    return total
end

local function reportData(target)
    local regions = {}
    for _, r in ipairs(Config.Regions) do
        local data = (injuries[target] or {})[r]
        local t, level = 'none', 0
        if data then t, level = worstOf(data) end
        regions[r] = { type = t, level = level, pct = 100 - level * 25 }
    end
    return regions
end

local function pushToVictim(target)
    TriggerClientEvent('qs-ambulance:client:setInjuries', target, injuries[target] or {})
end

local function pushToMedic(medic, target)
    TriggerClientEvent('qs-ambulance:client:updateReport', medic, reportData(target))
end

local function closeSessionsFor(target)
    for medic, t in pairs(sessions) do
        if t == target then
            sessions[medic] = nil
            TriggerClientEvent('qs-ambulance:client:closeReport', medic)
        end
    end
end

local function isDown(src)
    if downed[src] then return true end
    local ok, st = pcall(function() return Player(src).state.dead end)
    return ok and st == true
end

local function alertMedics(src, key)
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local coords = GetEntityCoords(ped)
    local name = charName(src)
    for _, p in ipairs(core:GetPlayers()) do
        local job = p.PlayerData and p.PlayerData.job
        if job and job.name == 'ambulance' and p.source ~= src then
            TriggerClientEvent('qs:client:notify', p.source, T(key, name), 'error', 7000)
            TriggerClientEvent('qs-ambulance:client:alert', p.source, { x = coords.x, y = coords.y, z = coords.z })
        end
    end
end

RegisterNetEvent('qs-ambulance:server:syncInjuries', function(raw)
    local src = source
    injuries[src] = sanitize(raw)
    for medic, t in pairs(sessions) do
        if t == src then pushToMedic(medic, src) end
    end
end)

RegisterNetEvent('qs-ambulance:server:down', function()
    local src = source
    if downed[src] then return end
    downed[src] = true
    alertMedics(src, 'alert_down')
end)

RegisterNetEvent('qs-ambulance:server:callEms', function()
    local src = source
    if not core:RateLimit(('amb-call:%d'):format(src), 1, 15000) then return end
    alertMedics(src, 'alert_call')
end)

RegisterNetEvent('qs-ambulance:server:up', function()
    local src = source
    downed[src] = nil
    closeSessionsFor(src)
end)

RegisterNetEvent('qs-ambulance:server:openReport', function(target)
    local src = source
    if not isMedic(src) then return end
    if not core:RateLimit(('amb-report:%d'):format(src), 2, 1500) then return end
    target = tonumber(target) or src
    if target ~= src then
        if GetPlayerPed(target) == 0 then return end
        if distBetween(src, target) > Config.TreatDistance then return end
    end

    local down = isDown(target)
    if down and totalLevels(target) == 0 then
        injuries[target] = injuries[target] or {}
        local r = Config.Regions[math.random(#Config.Regions)]
        injuries[target][r] = { bleeding = 2, bruising = 0, burning = 0 }
        pushToVictim(target)
    end

    sessions[src] = target
    TriggerClientEvent('qs-ambulance:client:openReport', src, {
        target = target,
        name = charName(target),
        downed = down,
        regions = reportData(target),
    })
end)

RegisterNetEvent('qs-ambulance:server:closeReport', function()
    sessions[source] = nil
end)

RegisterNetEvent('qs-ambulance:server:treat', function(item, region)
    local src = source
    local target = sessions[src]
    if not target or not isMedic(src) then return end
    if not core:RateLimit(('amb-treat:%d'):format(src), 1, Config.TreatmentTime - 800) then return end
    if target ~= src and distBetween(src, target) > Config.TreatDistance + 1.0 then return end

    local iType = ITEM_TYPE[item]
    if not iType or not REGION_OK[region] then return end

    local data = (injuries[target] or {})[region]
    if not data or (data[iType] or 0) <= 0 then
        TriggerClientEvent('qs:client:notify', src, T('wrong_treatment'), 'error')
        return
    end

    local medic = core:GetPlayer(src)
    if not medic then return end
    if not medic:hasItem(item, 1) then
        local def = core:GetItem(item)
        TriggerClientEvent('qs:client:notify', src, T('need_item', (def and def.label) or item), 'error')
        return
    end
    if not medic:removeItem(item, 1) then return end

    data[iType] = 0
    if data.bleeding == 0 and data.bruising == 0 and data.burning == 0 then
        injuries[target][region] = nil
    end

    TriggerClientEvent('qs:client:notify', src, T('zone_treated'), 'success')
    if target ~= src then
        TriggerClientEvent('qs:client:notify', target, T('being_treated_zone'), 'info')
    end

    if isDown(target) and totalLevels(target) == 0 then
        downed[target] = nil
        TriggerClientEvent('qs:client:revive', target)
        TriggerClientEvent('qs:client:notify', target, T('you_were_treated'), 'success', 6000)
        TriggerClientEvent('qs:client:notify', src, T('patient_stable'), 'success')
        if (Config.ReviveReward or 0) > 0 and target ~= src then
            core:AddMoney(src, 'cash', Config.ReviveReward, 'ems-revive')
            TriggerClientEvent('qs:client:notify', src, T('revive_reward', Config.ReviveReward), 'primary')
        end
    end

    pushToVictim(target)
    pushToMedic(src, target)
end)

RegisterNetEvent('qs-ambulance:server:checkin', function()
    local src = source
    if not core:RateLimit(('amb-checkin:%d'):format(src), 1, (Config.Hospital.time or 5000) - 500) then return end
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local h = Config.Hospital.coords
    if #(GetEntityCoords(ped) - vector3(h.x, h.y, h.z)) > Config.InteractDistance + 2.0 then return end

    if not core:RemoveMoney(src, 'cash', Config.Hospital.price, 'hospital') then
        TriggerClientEvent('qs:client:notify', src, T('no_money', Config.Hospital.price), 'error')
        return
    end
    injuries[src] = {}
    pushToVictim(src)
    TriggerClientEvent('qs-ambulance:client:healed', src)
    TriggerClientEvent('qs:client:notify', src, T('checked_in', Config.Hospital.price), 'success')
end)

core:RegisterUsableItem('bandage', function(src)
    local player = core:GetPlayer(src)
    if not player then return end
    if not player:removeItem('bandage', 1) then return end
    player:setBusy(Config.BandageTime)

    local worstRegion, worstLevel = nil, 0
    for region, data in pairs(injuries[src] or {}) do
        if (data.bleeding or 0) > worstLevel then
            worstLevel = data.bleeding
            worstRegion = region
        end
    end
    if worstRegion then
        local data = injuries[src][worstRegion]
        data.bleeding = data.bleeding - 1
        if data.bleeding == 0 and data.bruising == 0 and data.burning == 0 then
            injuries[src][worstRegion] = nil
        end
        pushToVictim(src)
    end
    TriggerClientEvent('qs-ambulance:client:bandage', src)
end)

RegisterNetEvent('qs-ambulance:server:supplies', function()
    local src = source
    if not isMedic(src) then return end
    if not core:RateLimit(('amb-supplies:%d'):format(src), 1, Config.Supplies.cooldown) then
        TriggerClientEvent('qs:client:notify', src, T('supplies_cooldown'), 'error')
        return
    end
    local s = Config.Supplies.coords
    local ped = GetPlayerPed(src)
    if ped == 0 or #(GetEntityCoords(ped) - vector3(s.x, s.y, s.z)) > Config.InteractDistance + 2.0 then return end

    local player = core:GetPlayer(src)
    if not player then return end
    for _, e in ipairs(Config.Supplies.items) do
        if player:canCarryItem(e.name, e.count) then
            player:addItem(e.name, e.count)
        end
    end
    TriggerClientEvent('qs:client:notify', src, T('supplies_taken'), 'success')
end)

RegisterNetEvent('qs-ambulance:server:createStretcher', function(netId, coords)
    local src = source
    if not isMedic(src) then return end
    if not core:RateLimit(('amb-str:%d'):format(src), 1, 1500) then return end
    if type(coords) ~= 'table' then return end
    for _, s in pairs(stretchers) do
        if s.owner == src then return end
    end
    stretcherSeq = stretcherSeq + 1
    local id = stretcherSeq
    stretchers[id] = {
        id = id, netId = netId, owner = src, patient = nil,
        coords = { x = coords.x, y = coords.y, z = coords.z, w = coords.w or 0.0 },
    }
    TriggerClientEvent('qs-ambulance:client:stretcherAdd', -1, stretchers[id])
    TriggerClientEvent('qs-ambulance:client:stretcherId', src, id)
end)

RegisterNetEvent('qs-ambulance:server:updateStretcher', function(id, data)
    local s = stretchers[tonumber(id) or -1]
    if not s or s.owner ~= source or type(data) ~= 'table' then return end
    if data.netId then s.netId = data.netId end
    if data.coords then s.coords = data.coords end
    TriggerClientEvent('qs-ambulance:client:stretcherUpdate', -1, s.id, {
        netId = s.netId, coords = s.coords,
    })
end)

RegisterNetEvent('qs-ambulance:server:setPatient', function(id, target)
    local src = source
    local s = stretchers[tonumber(id) or -1]
    if not s or not isMedic(src) then return end
    target = tonumber(target)

    if not target or target == 0 then
        if s.patient then
            s.patient = nil
            TriggerClientEvent('qs-ambulance:client:stretcherPatient', -1, s.id, 0)
        end
        return
    end

    if s.patient or not isDown(target) then return end
    if distBetween(src, target) > Config.TreatDistance + 2.5 then return end
    s.patient = target
    TriggerClientEvent('qs-ambulance:client:stretcherPatient', -1, s.id, target)
end)

RegisterNetEvent('qs-ambulance:server:leaveStretcher', function(id)
    local src = source
    local s = stretchers[tonumber(id) or -1]
    if not s or s.patient ~= src then return end
    s.patient = nil
    TriggerClientEvent('qs-ambulance:client:stretcherPatient', -1, s.id, 0)
end)

RegisterNetEvent('qs-ambulance:server:removeStretcher', function(id)
    local src = source
    local s = stretchers[tonumber(id) or -1]
    if not s or s.owner ~= src then return end
    if s.patient then
        TriggerClientEvent('qs-ambulance:client:stretcherPatient', -1, s.id, 0)
    end
    stretchers[s.id] = nil
    TriggerClientEvent('qs-ambulance:client:stretcherRemove', -1, s.id)
end)

RegisterNetEvent('qs-ambulance:server:requestStretchers', function()
    local src = source
    for _, s in pairs(stretchers) do
        TriggerClientEvent('qs-ambulance:client:stretcherAdd', src, s)
        if s.patient then
            TriggerClientEvent('qs-ambulance:client:stretcherPatient', src, s.id, s.patient)
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    injuries[src] = nil
    downed[src] = nil
    sessions[src] = nil
    closeSessionsFor(src)
    for id, s in pairs(stretchers) do
        if s.owner == src then
            if s.patient then
                TriggerClientEvent('qs-ambulance:client:stretcherPatient', -1, s.id, 0)
            end
            stretchers[id] = nil
            TriggerClientEvent('qs-ambulance:client:stretcherRemove', -1, s.id)
        elseif s.patient == src then
            s.patient = nil
            TriggerClientEvent('qs-ambulance:client:stretcherPatient', -1, s.id, 0)
        end
    end
end)

AddEventHandler('qs:server:jobChange', function(src, job)
    if job and job.name ~= 'ambulance' and sessions[src] then
        sessions[src] = nil
        TriggerClientEvent('qs-ambulance:client:closeReport', src)
    end
end)
