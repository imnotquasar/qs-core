local core = exports['qs-core']

RegisterNetEvent('qs-corechat:server:send', function(text)
    local src = source
    text = tostring(text or '')
    if #text == 0 then return end
    if #text > 256 then text = text:sub(1, 256) end

    local name
    local player = core:GetPlayer(src)
    if player and player.PlayerData and player.PlayerData.charinfo then
        local ci = player.PlayerData.charinfo
        name = (((ci.firstname or '') .. ' ' .. (ci.lastname or '')):gsub('^%s*(.-)%s*$', '%1'))
    end
    if not name or name == '' then name = GetPlayerName(src) end

    TriggerClientEvent('qs-corechat:client:message', -1, { author = name, text = text })
end)
