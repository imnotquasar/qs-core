-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from ESX Legacy (https://github.com/esx-framework/esx_core)
-- Copyright (C) 2022-2026 ESX Framework
-- Modified for qscore in 2026: adapted to run on top of qs-core. See NOTICE.

if Config.CustomInventory ~= 'ox' then return end

MySQL.ready(function()
    TriggerEvent('__cfx_export_ox_inventory_Items', function(ref)
        if ref then
            ESX.Items = ref()
        end
    end)

    AddEventHandler('ox_inventory:itemList', function(items)
        ESX.Items = items
    end)
end)

ESX.GetItemLabel = function(item)
    item = exports.ox_inventory:Items(item)
    if item then
        return item.label
    end
end

function setPlayerInventory(playerId, xPlayer, inventory, isNew)
    exports.ox_inventory:setPlayerInventory(xPlayer, inventory)
    if isNew then
        local shared = json.decode(GetConvar('inventory:accounts', '["money"]'))

        for i = 1, #shared do
            local name = shared[i]
            local account = Config.StartingAccountMoney[name]
            if account then
                exports.ox_inventory:AddItem(playerId, name, account)
            end
        end
    end
end
