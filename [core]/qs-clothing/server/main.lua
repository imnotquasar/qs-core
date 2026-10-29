local core = exports['qs-core']

RegisterCommand('clothing', function(src)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'command.qs') then
        TriggerClientEvent('qs:client:notify', src, T('no_permission') or 'No permission', 'error')
        return
    end
    if src ~= 0 then TriggerClientEvent('qs-clothing:client:open', src, { disabled = {} }) end
end, false)

RegisterNetEvent('qs-clothing:server:save', function(skin)
    local src = source
    if type(skin) ~= 'table' then return end
    core:SetSkin(src, skin)
    TriggerClientEvent('qs:client:notify', src, T('outfit_saved'), 'success')
end)
