local core = exports['qs-core']

local DESCRIPTIONS = {
    melee = 'A melee weapon.',
    throwable = 'A throwable. Each one is spent when thrown.',
    misc = 'Equipment.',
}

local items = {}
for name, w in pairs(WeaponsConfig.Weapons) do
    local throwable = w.cat == 'throwable'
    items[name] = {
        label = w.label,
        weight = w.weight or 1000,
        useable = true,
        weapon = w.weapon,
        ammo = w.ammo or (throwable and 1) or WeaponsConfig.MagSize[w.cat] or 0,
        stack = throwable and WeaponsConfig.ThrowableStack or nil,
        description = DESCRIPTIONS[w.cat] or 'A firearm.',
    }
end
for name, a in pairs(WeaponsConfig.Ammo) do
    items[name] = {
        label = a.label,
        weight = a.weight or 200,
        useable = true,
        description = 'Ammunition.',
    }
end
core:RegisterItems(items)

AddEventHandler('qs:server:usedItem', function(src, item)
    local a = WeaponsConfig.Ammo[item]
    if not a then return end
    TriggerClientEvent('qs-coreweapons:client:useAmmo', src, item, a.cat, WeaponsConfig.MagSize[a.cat] or 30)
end)

RegisterNetEvent('qs-coreweapons:server:consumeAmmo', function(item)
    local src = source
    if not WeaponsConfig.Ammo[item] then return end
    local player = core:GetPlayer(src)
    if player then player:removeItem(item, 1) end
end)

RegisterNetEvent('qs-coreweapons:server:thrown', function(item, amount)
    local src = source
    local w = WeaponsConfig.Weapons[item]
    if not w or w.cat ~= 'throwable' then return end
    if not core:RateLimit(('qs-weapons-throw:%d'):format(src), 10, 2000) then return end
    amount = math.max(1, math.min(math.floor(tonumber(amount) or 1), WeaponsConfig.ThrowableStack))
    local player = core:GetPlayer(src)
    if player then player:removeItem(item, amount) end
end)
