local function license(src)
    return GetPlayerIdentifierByType(src, Config.Identifier or 'license')
end

RegisterNetEvent('qs:colors:request', function()
    local src = source
    local lic = license(src)
    local palette = false
    if lic then
        local raw = MySQL.scalar.await('SELECT `palette` FROM `player_colors` WHERE `license` = ?', { lic })
        if raw then
            local ok, decoded = pcall(json.decode, raw)
            if ok and type(decoded) == 'table' then palette = decoded end
        end
    end
    TriggerClientEvent('qs:colors:load', src, palette)
end)

RegisterNetEvent('qs:colors:save', function(palette)
    local src = source
    if type(palette) ~= 'table' then return end
    local lic = license(src)
    if not lic then return end
    MySQL.query(
        'INSERT INTO `player_colors` (`license`, `palette`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `palette` = VALUES(`palette`)',
        { lic, json.encode(palette) }
    )
end)

RegisterNetEvent('qs:colors:clear', function()
    local src = source
    local lic = license(src)
    if not lic then return end
    MySQL.query('DELETE FROM `player_colors` WHERE `license` = ?', { lic })
end)
