Bans = {}

local function licenseOf(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 8) == 'license:' then return id end
    end
    return nil
end

function Bans.IsBanned(licenseOrSource)
    if not Config.EnableBans then return false end

    local license = licenseOrSource
    if type(licenseOrSource) == 'number' then
        license = licenseOf(licenseOrSource)
    end
    if not license then return false end

    local row = MySQL.single.await(
        'SELECT reason, UNIX_TIMESTAMP(expires) AS exp FROM `bans` WHERE license = ? ORDER BY id DESC LIMIT 1',
        { license }
    )
    if not row then return false end
    if row.exp and row.exp <= os.time() then return false end
    return true, row.reason or 'Banned'
end

function Bans.Add(targetSrc, minutes, reason, adminName)
    local license = licenseOf(targetSrc)
    if not license then return false end

    local expires = (minutes and minutes > 0) and os.date('%Y-%m-%d %H:%M:%S', os.time() + minutes * 60) or nil
    MySQL.insert.await('INSERT INTO `bans` (license, name, reason, banned_by, expires) VALUES (?, ?, ?, ?, ?)', {
        license, GetPlayerName(targetSrc), reason, adminName, expires,
    })
    Utils.Log('admin', 'Player banned', ('%s (%s)\nBy: %s\nReason: %s\nExpires: %s')
        :format(GetPlayerName(targetSrc), license, adminName, reason, expires or 'never'))
    DropPlayer(targetSrc, ('Banned: %s'):format(reason or '-'))
    return true
end

function Bans.Remove(license)
    MySQL.update('DELETE FROM `bans` WHERE `license` = ?', { license })
    return true
end

function Bans.ExploitBan(playerId, origin)
    return Bans.Add(playerId, 0, origin or 'exploit', 'Anti Cheat')
end

exports('IsPlayerBanned', Bans.IsBanned)
exports('AddBan', Bans.Add)
exports('RemoveBan', Bans.Remove)
exports('ExploitBan', Bans.ExploitBan)

AddEventHandler('playerConnecting', function(_, _, deferrals)
    if not Config.EnableBans then return end
    local src = source

    deferrals.defer()
    Wait(0)

    local license = licenseOf(src)
    if not license then deferrals.done() return end

    local banned, reason = Bans.IsBanned(license)
    if banned then
        deferrals.done(T('banned', reason or '-', T('ban_permanent')))
        return
    end

    deferrals.done()
end)
