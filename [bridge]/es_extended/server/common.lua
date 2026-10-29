Core = Core or {}
Core.PlayerFunctionOverrides = Core.PlayerFunctionOverrides or {}
Core.UsableItemsCallbacks = Core.UsableItemsCallbacks or {}

if Config.CustomInventory then
    SetConvarReplicated('inventory:framework', 'esx')
    SetConvarReplicated('inventory:weight', tostring(Config.MaxWeight * 1000))
end
