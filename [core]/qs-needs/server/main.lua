local core = exports['qs-core']

local function clamp(v)
    if v < 0 then return 0 end
    if v > 100 then return 100 end
    return v
end

local function addNeed(src, key, amount)
    if not amount then return end
    core:SetMetadata(src, key, clamp((core:GetMetadata(src, key) or 0) + amount))
end

core:RegisterItems({
    burger       = { label = 'Burger',       weight = 400, useable = true, description = 'A juicy burger. Fills you up.' },
    sandwich     = { label = 'Sandwich',     weight = 250, useable = true, description = 'A quick bite.' },
    cola         = { label = 'Cola',         weight = 350, useable = true, description = 'A fizzy soft drink.' },
    coffee       = { label = 'Coffee',       weight = 300, useable = true, description = 'Hot and refreshing.' },
    energy_drink = { label = 'Energy Drink', weight = 350, useable = true, description = 'Quenches thirst fast.' },
})

AddEventHandler('qs:server:usedItem', function(src, item, itemData)
    local def = NeedsConfig.Consumables[item]
    if not def then return end

    local player = core:GetPlayer(src)
    if not player then return end

    local slot = type(itemData) == 'table' and itemData.slot or nil
    if not player:removeItem(item, 1, slot) then return end

    local anim = NeedsConfig.Anim[def.verb == 'drink' and 'drink' or 'eat']
    player:setBusy((anim and anim.duration) or 3000)

    addNeed(src, 'hunger', def.hunger)
    addNeed(src, 'thirst', def.thirst)

    TriggerClientEvent('qs-needs:consume', src, def.verb == 'drink' and 'drink' or 'eat')

    local itemDef = core:GetItem(item)
    local label = (itemDef and itemDef.label) or item
    local msg = (def.verb == 'drink')
        and T('drank', label)
        or T('ate', label)
    TriggerClientEvent('qs:client:notify', src, msg, 'success')
end)

AddEventHandler('qs:server:characterLoaded', function(src)
    if core:GetMetadata(src, 'hunger') == nil then core:SetMetadata(src, 'hunger', 100) end
    if core:GetMetadata(src, 'thirst') == nil then core:SetMetadata(src, 'thirst', 100) end
end)

CreateThread(function()
    while true do
        Wait(NeedsConfig.DecayInterval)
        for _, player in pairs(core:GetPlayers()) do
            local src = player and player.source
            if src then
                addNeed(src, 'hunger', -NeedsConfig.DecayHunger)
                addNeed(src, 'thirst', -NeedsConfig.DecayThirst)
            end
        end
    end
end)
