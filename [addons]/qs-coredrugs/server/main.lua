local core = exports['qs-core']

math.randomseed(os.time())

do
    local items = {}
    for _, drug in pairs(Config.Drugs) do
        local g, p = drug.gather, drug.process
        items[g.item] = { label = g.label or g.item, weight = g.weight or 50, useable = false, description = 'Raw drug material.' }
        items[p.output] = { label = p.label or p.output, weight = p.weight or 100, useable = false, description = 'A packaged narcotic. Sell it to a dealer.' }
    end
    core:RegisterItems(items)
end

local GATHER_DIST = (Config.HarvestSpread or 3.5) + Config.InteractDistance + 2.0

local function near(src, locations, dist)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    for _, loc in ipairs(locations or {}) do
        if #(coords - vector3(loc.x, loc.y, loc.z)) <= (dist or Config.InteractDistance + 1.5) then
            return true
        end
    end
    return false
end

RegisterNetEvent('qs-coredrugs:server:gather', function(key)
    local src = source
    local player = core:GetPlayer(src)
    if not player then return end
    local drug = Config.Drugs[key]
    if not drug then return end
    if not core:RateLimit(('drug-gather:%d'):format(src), 1, (drug.gather.time or 5000) - 500) then return end
    if not near(src, drug.gather.locations, GATHER_DIST) then return end

    local g = drug.gather
    local amount = math.random(g.min or 1, g.max or 1)
    if not player:canCarryItem(g.item, amount) then
        TriggerClientEvent('qs:client:notify', src, T('inventory_full'), 'error')
        return
    end
    if player:addItem(g.item, amount) then
        TriggerClientEvent('qs:client:notify', src, T('gathered', amount, g.label or g.item), 'success')
    end
end)

RegisterNetEvent('qs-coredrugs:server:process', function(key)
    local src = source
    local player = core:GetPlayer(src)
    if not player then return end
    local drug = Config.Drugs[key]
    if not drug then return end
    if not core:RateLimit(('drug-process:%d'):format(src), 1, (drug.process.time or 6000) - 500) then return end
    if not near(src, drug.process.locations) then return end

    local p = drug.process
    if not player:hasItem(p.input, p.inputAmount) then
        TriggerClientEvent('qs:client:notify', src, T('need_material', p.inputAmount, drug.gather.label or p.input), 'error')
        return
    end
    if not player:canCarryItem(p.output, p.outputAmount) then
        TriggerClientEvent('qs:client:notify', src, T('inventory_full'), 'error')
        return
    end
    if not player:removeItem(p.input, p.inputAmount) then return end
    player:addItem(p.output, p.outputAmount)
    TriggerClientEvent('qs:client:notify', src, T('processed', p.outputAmount, p.label or p.output), 'success')
end)

local offers = {}

local function buildDealerView(src)
    local player = core:GetPlayer(src)
    if not player then return {}, {} end
    local prices, view = {}, {}
    for key, drug in pairs(Config.Drugs) do
        local s = drug.sell
        local price = math.random(s.min, s.max)
        prices[s.item] = price
        view[#view + 1] = {
            key = key,
            name = s.item,
            label = drug.process.label or s.item,
            price = price,
            count = player:getItemCount(s.item),
        }
    end
    return prices, view
end

RegisterNetEvent('qs-coredrugs:server:openDealer', function()
    local src = source
    if not near(src, Config.Dealer.locations, Config.InteractDistance + 1.0) then return end

    local prices, view = buildDealerView(src)
    offers[src] = { prices = prices, sold = 0 }

    TriggerClientEvent('qs-coredrugs:client:openDealer', src, {
        items = view,
        black = core:GetMoney(src, Config.SellAccount),
        limit = Config.SellLimitPerVisit,
    })
end)

RegisterNetEvent('qs-coredrugs:server:closeDealer', function()
    offers[source] = nil
end)

RegisterNetEvent('qs-coredrugs:server:sell', function(itemName, count)
    local src = source
    local player = core:GetPlayer(src)
    if not player then return end
    local offer = offers[src]
    if not offer then return end
    if not near(src, Config.Dealer.locations, Config.InteractDistance + 1.0) then return end

    local price = offer.prices[itemName]
    if not price then return end

    count = math.floor(tonumber(count) or 0)
    if count < 1 then return end

    local remaining = math.max(0, (Config.SellLimitPerVisit or 999) - offer.sold)
    if remaining <= 0 then
        TriggerClientEvent('qs:client:notify', src, T('sell_limit'), 'error')
        return
    end
    count = math.min(count, remaining)

    local have = player:getItemCount(itemName)
    if have < count then count = have end
    if count < 1 then
        TriggerClientEvent('qs:client:notify', src, T('nothing_to_sell'), 'error')
        return
    end

    if not player:removeItem(itemName, count) then return end

    local payout = price * count
    core:AddMoney(src, Config.SellAccount, payout, 'drug-sale')
    offer.sold = offer.sold + count

    local _, view = buildDealerView(src)
    for _, row in ipairs(view) do row.price = offer.prices[row.name] or row.price end
    TriggerClientEvent('qs-coredrugs:client:updateDealer', src, {
        items = view,
        black = core:GetMoney(src, Config.SellAccount),
        sold = offer.sold,
    })
    TriggerClientEvent('qs:client:notify', src, T('sold', count, payout), 'success')
end)

AddEventHandler('playerDropped', function()
    offers[source] = nil
end)
