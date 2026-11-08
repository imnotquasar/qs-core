Items = Items or {}

local base = {
    water    = { label = 'Water Bottle', weight = 500, useable = true,  description = 'Restores thirst.' },
    bread    = { label = 'Bread',        weight = 300, useable = true,  description = 'Restores hunger.' },
    bandage  = { label = 'Bandage',      weight = 100, useable = true,  description = 'Restores a bit of health.' },
    phone    = { label = 'Phone',        weight = 190, useable = true,  description = 'Your smartphone.' },
    id_card  = { label = 'ID Card',      weight = 10,  useable = false, description = 'Government issued identification.' },

    weapon_pistol = { label = 'Pistol', weight = 1000, useable = true, weapon = 'WEAPON_PISTOL', ammo = 12, description = 'A compact sidearm.' },

    lockpick   = { label = 'Lockpick',   weight = 100,  useable = true,  description = 'For when you lost your keys.' },
    repairkit  = { label = 'Repair Kit', weight = 2500, useable = true,  description = 'Patches up a vehicle.' },
    screwdriver = { label = 'Screwdriver', weight = 200, useable = true, description = 'Handy little tool.' },
}

function QS.RegisterItem(name, data)
    if type(name) ~= 'string' or type(data) ~= 'table' then return false end
    data.label = data.label or name
    data.weight = tonumber(data.weight) or 0
    data.useable = data.useable or false
    Items[name] = data
    return true
end

function QS.RegisterItems(tbl)
    if type(tbl) ~= 'table' then return end
    for name, data in pairs(tbl) do
        QS.RegisterItem(name, data)
    end
end

function QS.GetItem(name)
    return Items[name]
end

function QS.GetItems()
    return Items
end

function QS.UpdateItemDefinition(name, data)
    if not Items[name] then return false end
    return QS.RegisterItem(name, data)
end

function QS.RemoveItemDefinition(name)
    if not Items[name] then return false end
    Items[name] = nil
    return true
end

QS.RegisterItems(base)

exports('RegisterItem', QS.RegisterItem)
exports('RegisterItems', QS.RegisterItems)
exports('GetItem', QS.GetItem)
exports('GetItems', QS.GetItems)
exports('UpdateItemDefinition', QS.UpdateItemDefinition)
exports('RemoveItemDefinition', QS.RemoveItemDefinition)
