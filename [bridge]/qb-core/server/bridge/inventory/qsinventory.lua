-- qs-inventory QB mode resolves usable callbacks via QBCore.Functions.CanUseItem.
-- Keep registrations local; do not delegate back to qs-core (avoids circular CreateUsableItem chain).
exports('GetUsableItems', function()
    return QBCore.UsableItems
end)
