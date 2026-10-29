local core = exports['qs-core']

math.randomseed(os.time())

core:RegisterItems({
    stone       = { label = 'Stone',       weight = 900,  useable = false, description = 'A chunk of raw ore.' },
    metal_ingot = { label = 'Metal Ingot', weight = 1200, useable = false, description = 'Smelted metal, ready to sell.' },
    gold_nugget = { label = 'Gold Nugget', weight = 200,  useable = false, description = 'A rare find from the quarry.' },
    wood_log    = { label = 'Wood Log',    weight = 1500, useable = false, description = 'A freshly cut log.' },
    wood_plank  = { label = 'Wood Plank',  weight = 800,  useable = false, description = 'Sawmill-cut plank, ready to sell.' },
    mackerel    = { label = 'Mackerel',    weight = 400,  useable = false, description = 'A common catch.' },
    bass        = { label = 'Bass',        weight = 700,  useable = false, description = 'A decent catch.' },
    tuna        = { label = 'Tuna',        weight = 2500, useable = false, description = 'A prized catch.' },
})

local function jobName(src)
    local player = core:GetPlayer(src)
    local job = player and player.PlayerData and player.PlayerData.job
    return (job and job.name) or 'unemployed'
end

local function coordsOf(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function nearList(src, locations, dist)
    local coords = coordsOf(src)
    if not coords then return false end
    for _, loc in ipairs(locations or {}) do
        if #(coords - vector3(loc.x, loc.y, loc.z)) <= dist then return true end
    end
    return false
end

local function nearPoint(src, loc, dist)
    local coords = coordsOf(src)
    if not coords then return false end
    return #(coords - vector3(loc.x, loc.y, loc.z)) <= dist
end

local function pickCatch(catches)
    local total = 0
    for _, c in ipairs(catches) do total = total + (c.weight or 1) end
    local r = math.random(total)
    for _, c in ipairs(catches) do
        r = r - (c.weight or 1)
        if r <= 0 then return c.item end
    end
    return catches[1].item
end

RegisterNetEvent('qs-jobs:server:openCenter', function()
    local src = source
    if not core:RateLimit(('jobs-center:%d'):format(src), 2, 2000) then return end
    if not nearPoint(src, Config.Center.coords, Config.InteractDistance + 1.5) then return end

    local defs = core:GetJobs() or {}
    local list = {}
    for _, key in ipairs(Config.Center.jobs) do
        local def = defs[key]
        if def then
            local grade = def.grades and (def.grades[0] or def.grades[1] or def.grades['0'])
            list[#list + 1] = {
                key = key,
                label = def.label or key,
                salary = (grade and grade.salary) or 0,
            }
        end
    end

    TriggerClientEvent('qs-jobs:client:openCenter', src, { jobs = list, current = jobName(src) })
end)

RegisterNetEvent('qs-jobs:server:apply', function(key)
    local src = source
    if type(key) ~= 'string' then return end
    if not core:RateLimit(('jobs-apply:%d'):format(src), 2, 2000) then return end
    if not nearPoint(src, Config.Center.coords, Config.InteractDistance + 1.5) then return end

    local allowed = key == 'unemployed'
    for _, k in ipairs(Config.Center.jobs) do
        if k == key then allowed = true break end
    end
    if not allowed then return end
    if jobName(src) == key then return end

    core:SetJob(src, key, 0)
    local defs = core:GetJobs() or {}
    local label = (defs[key] and defs[key].label) or key
    if key == 'unemployed' then
        TriggerClientEvent('qs:client:notify', src, T('job_quit'), 'info')
    else
        TriggerClientEvent('qs:client:notify', src, T('job_applied', label), 'success')
    end
    TriggerClientEvent('qs-jobs:client:applied', src, key)
end)

RegisterNetEvent('qs-jobs:server:gather', function(key)
    local src = source
    local player = core:GetPlayer(src)
    if not player then return end
    local job = Config.Jobs[key]
    if not job or not job.gather then return end
    if jobName(src) ~= key then return end
    local g = job.gather
    if not core:RateLimit(('jobs-gather:%d'):format(src), 1, (g.time or 5000) - 500) then return end
    if not nearList(src, g.locations, (g.spread or 0) + Config.InteractDistance + 2.5) then return end

    local item, amount
    if g.catches then
        item, amount = pickCatch(g.catches), 1
    else
        item, amount = g.item, math.random(g.min or 1, g.max or 1)
    end

    if not player:canCarryItem(item, amount) then
        TriggerClientEvent('qs:client:notify', src, T('inventory_full'), 'error')
        return
    end
    if not player:addItem(item, amount) then return end

    local def = core:GetItem(item)
    TriggerClientEvent('qs:client:notify', src, T('gathered', amount, (def and def.label) or item), 'success')

    local b = g.bonus
    if b and math.random() < (b.chance or 0) and player:canCarryItem(b.item, b.count or 1) then
        if player:addItem(b.item, b.count or 1) then
            local bdef = core:GetItem(b.item)
            TriggerClientEvent('qs:client:notify', src, T('bonus_found', (bdef and bdef.label) or b.item), 'primary')
        end
    end
end)

RegisterNetEvent('qs-jobs:server:process', function(key)
    local src = source
    local player = core:GetPlayer(src)
    if not player then return end
    local job = Config.Jobs[key]
    if not job or not job.process then return end
    if jobName(src) ~= key then return end
    local p = job.process
    if not core:RateLimit(('jobs-process:%d'):format(src), 1, (p.time or 5000) - 500) then return end
    if not nearList(src, p.locations, Config.InteractDistance + 2.0) then return end

    if not player:hasItem(p.input, p.inputAmount) then
        local def = core:GetItem(p.input)
        TriggerClientEvent('qs:client:notify', src, T('need_material', p.inputAmount, (def and def.label) or p.input), 'error')
        return
    end
    if not player:canCarryItem(p.output, p.outputAmount) then
        TriggerClientEvent('qs:client:notify', src, T('inventory_full'), 'error')
        return
    end
    if not player:removeItem(p.input, p.inputAmount) then return end
    player:addItem(p.output, p.outputAmount)
    local def = core:GetItem(p.output)
    TriggerClientEvent('qs:client:notify', src, T('processed', p.outputAmount, (def and def.label) or p.output), 'success')
end)

RegisterNetEvent('qs-jobs:server:sell', function(key)
    local src = source
    local player = core:GetPlayer(src)
    if not player then return end
    local job = Config.Jobs[key]
    if not job or not job.sell then return end
    if jobName(src) ~= key then return end
    if not core:RateLimit(('jobs-sell:%d'):format(src), 1, 2000) then return end
    if not nearPoint(src, job.sell.coords, Config.InteractDistance + 1.5) then return end

    local total, soldAny = 0, false
    for item, price in pairs(job.sell.prices) do
        local count = player:getItemCount(item)
        if count > 0 and player:removeItem(item, count) then
            total = total + math.random(price.min, price.max) * count
            soldAny = true
        end
    end

    if not soldAny then
        TriggerClientEvent('qs:client:notify', src, T('nothing_to_sell'), 'error')
        return
    end

    core:AddMoney(src, Config.PayAccount, total, 'job:' .. key)
    TriggerClientEvent('qs:client:notify', src, T('sold_goods', total), 'success')
end)

local shifts = {}

local function endShift(src, atDepot)
    local shift = shifts[src]
    if not shift then return end
    shifts[src] = nil

    local d = Config.Delivery
    local bonus = 0
    if atDepot and shift.done >= shift.total then
        bonus = d.finishBonus or 0
        if bonus > 0 then core:AddMoney(src, Config.PayAccount, bonus, 'job:delivery-bonus') end
    end
    if (d.deposit or 0) > 0 then
        core:AddMoney(src, Config.PayAccount, d.deposit, 'job:delivery-deposit')
    end

    TriggerClientEvent('qs-jobs:client:shiftEnded', src, { earned = shift.earned, bonus = bonus })
    if bonus > 0 then
        TriggerClientEvent('qs:client:notify', src, T('shift_done_bonus', shift.earned + bonus, bonus), 'success')
    else
        TriggerClientEvent('qs:client:notify', src, T('shift_done', shift.earned), 'info')
    end
end

RegisterNetEvent('qs-jobs:server:startShift', function()
    local src = source
    if jobName(src) ~= 'delivery' then return end
    if shifts[src] then return end
    if not core:RateLimit(('jobs-shift:%d'):format(src), 2, 3000) then return end
    local d = Config.Delivery
    if not nearPoint(src, d.depot.coords, Config.InteractDistance + 2.0) then return end

    if (d.deposit or 0) > 0 then
        if not core:RemoveMoney(src, Config.PayAccount, d.deposit, 'job:delivery-deposit') then
            TriggerClientEvent('qs:client:notify', src, T('no_deposit', d.deposit), 'error')
            return
        end
    end

    local pool = d.stops
    local picked, used = {}, {}
    local want = math.min(d.stopsPerShift or 5, #pool)
    while #picked < want do
        local i = math.random(#pool)
        if not used[i] then
            used[i] = true
            picked[#picked + 1] = i
        end
    end

    shifts[src] = { order = picked, next = 1, total = want, done = 0, earned = 0 }

    local stops = {}
    for n, i in ipairs(picked) do
        local s = pool[i]
        stops[n] = { x = s.x, y = s.y, z = s.z }
    end
    TriggerClientEvent('qs-jobs:client:shiftStarted', src, stops)
    TriggerClientEvent('qs:client:notify', src, T('shift_started', want), 'success')
end)

RegisterNetEvent('qs-jobs:server:deliver', function()
    local src = source
    local shift = shifts[src]
    if not shift or shift.next > shift.total then return end
    if not core:RateLimit(('jobs-deliver:%d'):format(src), 1, 3000) then return end

    local stop = Config.Delivery.stops[shift.order[shift.next]]
    if not nearPoint(src, stop, 35.0) then return end

    local pay = math.random(Config.Delivery.payPerStop.min, Config.Delivery.payPerStop.max)
    core:AddMoney(src, Config.PayAccount, pay, 'job:delivery')
    shift.earned = shift.earned + pay
    shift.done = shift.done + 1
    shift.next = shift.next + 1

    TriggerClientEvent('qs-jobs:client:delivered', src, { done = shift.done, total = shift.total, earned = shift.earned })
    if shift.done >= shift.total then
        TriggerClientEvent('qs:client:notify', src, T('all_delivered', pay), 'success')
    else
        TriggerClientEvent('qs:client:notify', src, T('delivered', pay), 'success')
    end
end)

RegisterNetEvent('qs-jobs:server:endShift', function()
    local src = source
    if not shifts[src] then return end
    if not nearPoint(src, Config.Delivery.depot.coords, 20.0) then return end
    endShift(src, true)
end)

AddEventHandler('qs:server:jobChange', function(src, job)
    if shifts[src] and job and job.name ~= 'delivery' then
        endShift(src, false)
    end
end)

AddEventHandler('playerDropped', function()
    shifts[source] = nil
end)
