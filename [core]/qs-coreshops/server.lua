local core = exports['qs-core']

local shopsByName = {}
for _, s in ipairs(Config.Shops) do shopsByName[s.name] = s end

local function shopView(shop)
    local items = core:GetItems() or {}
    local out = {}
    for _, entry in ipairs(shop.items or {}) do
        local def = items[entry.name]
        if def then
            out[#out + 1] = {
                name = entry.name,
                label = def.label or entry.name,
                price = math.max(0, math.floor(tonumber(entry.price) or 0)),
                weight = def.weight or 0,
                image = def.image,
            }
        end
    end
    return out
end

local function jobOk(src, shop)
    if not shop.job then return true end
    local player = core:GetPlayer(src)
    local job = player and player.PlayerData and player.PlayerData.job
    return job and job.name == shop.job
end

local function nearAny(src, shop, dist)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    for _, loc in ipairs(shop.locations or {}) do
        if #(coords - vector3(loc.x, loc.y, loc.z)) < dist then return true end
    end
    return false
end

RegisterNetEvent('qs-coreshops:server:open', function(name)
    local src = source
    local shop = shopsByName[name]
    if not shop then return end
    if not jobOk(src, shop) then
        TriggerClientEvent('qs:client:notify', src, T('not_allowed'), 'error')
        return
    end
    if not nearAny(src, shop, Config.BuyDistance) then return end

    TriggerClientEvent('qs-coreshops:client:open', src, {
        name = shop.name,
        label = shop.label,
        items = shopView(shop),
        cash = core:GetMoney(src, Config.PayAccount),
    })
end)

RegisterNetEvent('qs-coreshops:server:buy', function(name, itemName, count)
    local src = source
    local player = core:GetPlayer(src)
    if not player then return end
    local shop = shopsByName[name]
    if not shop then return end
    count = math.floor(tonumber(count) or 1)
    if count < 1 or count > 100 then return end
    if not jobOk(src, shop) then return end
    if not nearAny(src, shop, Config.BuyDistance) then return end

    local entry
    for _, e in ipairs(shop.items or {}) do
        if e.name == itemName then entry = e break end
    end
    if not entry then return end

    local price = math.floor((tonumber(entry.price) or 0) * count)

    if not player:canCarryItem(itemName, count) then
        TriggerClientEvent('qs:client:notify', src, T('cant_carry'), 'error')
        return
    end
    if core:GetMoney(src, Config.PayAccount) < price then
        TriggerClientEvent('qs:client:notify', src, T('no_money'), 'error')
        return
    end
    if not core:RemoveMoney(src, Config.PayAccount, price, 'shop:' .. shop.name) then return end

    if not player:addItem(itemName, count) then
        core:AddMoney(src, Config.PayAccount, price, 'shop-refund:' .. shop.name)
        return
    end

    TriggerClientEvent('qs-coreshops:client:cash', src, core:GetMoney(src, Config.PayAccount))
end)
