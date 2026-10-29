local DEFAULT_GROUP = 'user'

AddEventHandler('playerConnecting', function()
    local src = source
    local lic = Permissions.LicenseOf(src)
    if not lic then return end
    CreateThread(function()
        local group = MySQL.scalar.await('SELECT `group` FROM `player_groups` WHERE `license` = ?', { lic })
        if group then Permissions.ApplyPrincipal(lic, group) end
    end)
end)

local function allowed(source)
    return source == 0 or IsPlayerAceAllowed(source, 'command.qs')
end

RegisterCommand('setgroup', function(source, args)
    if not allowed(source) then return end

    local target = tonumber(args[1])
    local group = args[2] and args[2]:lower() or nil
    if not target or not group then
        print('^3[qs-core] Usage: setgroup <serverId> <group>   e.g. setgroup 1 admin^7')
        return
    end

    local lic = Permissions.LicenseOf(target)
    if not lic then
        print(('^1[qs-core] Player %s is not online or has no license identifier.^7'):format(target))
        return
    end

    MySQL.update(
        'INSERT INTO `player_groups` (`license`, `group`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `group` = VALUES(`group`)',
        { lic, group }
    )
    Permissions.ApplyPrincipal(lic, group)

    print(('^2[qs-core] %s (%s) is now group.%s^7'):format(GetPlayerName(target) or ('#' .. target), lic, group))

    local player = QS.GetPlayer(target)
    if player then player:emit('qs:client:notify', T('group_set', group), 'success') end
end, false)

RegisterCommand('removegroup', function(source, args)
    if not allowed(source) then return end

    local target = tonumber(args[1])
    if not target then
        print('^3[qs-core] Usage: removegroup <serverId>^7')
        return
    end

    local lic = Permissions.LicenseOf(target)
    if not lic then
        print(('^1[qs-core] Player %s is not online.^7'):format(target))
        return
    end

    local prev = MySQL.scalar.await('SELECT `group` FROM `player_groups` WHERE `license` = ?', { lic })
    MySQL.update('DELETE FROM `player_groups` WHERE `license` = ?', { lic })
    if prev and prev ~= DEFAULT_GROUP then
        ExecuteCommand(('remove_principal identifier.%s group.%s'):format(lic, prev))
    end

    print(('^2[qs-core] Removed group from %s (%s)^7'):format(GetPlayerName(target) or ('#' .. target), lic))
    local player = QS.GetPlayer(target)
    if player then player:emit('qs:client:notify', T('group_removed'), 'info') end
end, false)
