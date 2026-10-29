-- SPDX-License-Identifier: GPL-3.0-only
-- Contains code from ESX Legacy (https://github.com/esx-framework/esx_core)
-- Copyright (C) 2022-2026 ESX Framework
-- Modified for qscore in 2026: adapted to run on top of qs-core. See NOTICE.

if Config.CustomInventory ~= 'qs' then return end

MySQL.ready(function()
    ESX.Items = exports['qs-inventory']:GetItemList()
end)

ESX.GetItemLabel = function(item)
    return exports['qs-inventory']:GetItemLabel(item)
end

exports('GetUsableItems', function()
    return Core.UsableItemsCallbacks
end)

ESX.RegisterUsableItem = function(item, cb)
    Core.UsableItemsCallbacks[item] = cb
    exports['qs-inventory']:CreateUsableItem(item, cb)
end

ESX.UseItem = function(source, item, ...)
    if ESX.Items[item] then
        return exports['qs-inventory']:UseItem(item, source, ...)
    else
        print(('[^3WARNING^7] Item ^5"%s"^7 was used but does not exist!'):format(item))
    end
end
